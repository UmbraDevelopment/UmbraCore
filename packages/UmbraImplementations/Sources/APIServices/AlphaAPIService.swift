import APIInterfaces
import CoreTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 # Alpha API Service

 The Alpha API Service is the main implementation of the API service for the Alpha Dot Five
 architecture. It provides a unified entry point for all API operations, handling error mapping
 and requirements, with consistent error handling.
 */
public actor AlphaAPIService: APIServiceProtocol {
  // MARK: - Private Properties

  /// Configuration for the API service
  private var configuration: APIInterfaces.APIConfigurationDTO

  /// Domain handlers for the service, organized by domain
  private var domainHandlers: [APIDomain: any DomainHandler]

  /// Logger for API service operations
  private let logger: LoggingProtocol

  /// Event continuations for streaming events
  private var eventContinuations: [UUID: AsyncStream<APIEventDTO>.Continuation]=[:]

  /// Active operations tracking
  private var activeOperations: [String: Task<Any, Error>]=[:]

  // MARK: - Initialisation

  /**
   Initializes the API service with the specified configuration and domain handlers.

   - Parameters:
     - configuration: The configuration to use
     - domainHandlers: Handlers for different domains
     - logger: Logger to use for API operations
   */
  public init(
    configuration: APIInterfaces.APIConfigurationDTO,
    domainHandlers: [APIDomain: any DomainHandler],
    logger: LoggingProtocol
  ) {
    self.configuration=configuration
    self.domainHandlers=domainHandlers
    self.logger=logger
  }

  // MARK: - APIServiceProtocol Implementation

  /**
   Initialises the service with the provided configuration

   - Parameter configuration: The configuration to use for initialisation
   - Throws: UmbraErrors.APIError if initialisation fails
   */
  public func initialise(configuration: APIInterfaces.APIConfigurationDTO) async throws {
    self.configuration=configuration

    // Log initialization
    await logger.info(
      "API service initialized",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "initialise",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "environment", value: configuration.environment.rawValue)
      )
    )
  }

  /**
   Creates an encrypted bookmark for the specified URL.

   - Parameters:
     - url: The URL to create a bookmark for
     - identifier: The identifier for the bookmark
   - Throws: APIError if bookmark creation fails
   */
  public nonisolated func createEncryptedBookmark(url: String, identifier: String) async throws {
    // Delegate to the security domain
    let operation=CreateBookmarkOperation(url: url, identifier: identifier)
    try await execute(operation)
  }

  /**
   Resolves an encrypted bookmark to a URL.

   - Parameter identifier: The identifier of the bookmark to resolve
   - Returns: The URL string for the resolved bookmark
   - Throws: APIError if bookmark resolution fails
   */
  public nonisolated func resolveEncryptedBookmark(identifier: String) async throws -> String {
    // Delegate to the security domain
    let operation=ResolveBookmarkOperation(identifier: identifier)
    return try await execute(operation)
  }

  /**
   Deletes an encrypted bookmark.

   - Parameter identifier: The identifier of the bookmark to delete
   - Throws: APIError if bookmark deletion fails
   */
  public nonisolated func deleteEncryptedBookmark(identifier: String) async throws {
    // Delegate to the security domain
    let operation=DeleteBookmarkOperation(identifier: identifier)
    try await execute(operation)
  }

  /**
   Retrieves the API service version information
   - Returns: Version information as APIVersionDTO
   */
  public func getVersion() async -> APIVersionDTO {
    // TODO: Retrieve actual version info. APIConfigurationDTO doesn't store it.
    // Returning placeholder for now.
    APIVersionDTO(major: 0, minor: 0, patch: 1, buildIdentifier: "unknown")
  }

  /**
   Subscribes to API events.

   - Parameter filter: Optional filter for specific event types
   - Returns: An AsyncStream of API events
   */
  public nonisolated func subscribeToEvents(filter: APIEventFilterDTO?)
  -> AsyncStream<APIEventDTO> {
    AsyncStream { continuation in
      Task {
        // Register the continuation
        await self.registerEventSubscriber(continuation: continuation, filter: filter)

        // Keep the stream alive
        do {
          try await Task.sleep(for: .seconds(365 * 24 * 60 * 60)) // Effectively forever
        } catch {
          // Sleep was cancelled, finish the stream
          continuation.finish()
        }
      }
    }
  }

  // MARK: - Public API

  /**
   Executes an API operation with the specified options.

   - Parameters:
     - operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if execution fails
   */
  public func execute<T: APIInterfaces.APIOperation>(
    _ operation: T
  ) async throws -> T.APIOperationResult {
    let operationID=UUID().uuidString
    let operationMetadata=LogMetadataDTOCollection()
      .withPublic(key: "operation_id", value: operationID)
      .withPublic(key: "operation_type", value: String(describing: type(of: operation)))

    // Log the operation start
    await logger.info(
      "Executing operation \(String(describing: type(of: operation)))",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "execute",
        metadata: operationMetadata
      )
    )

    // Create a task for the operation execution
    let task=Task {
      do {
        // Get the domain for this operation
        let domain=self.getDomain(for: operation)

        // Get the handler for this domain
        guard let handler=self.domainHandlers[domain] else {
          throw APIError.operationNotSupported(
            message: "No handler found for domain: \(domain)",
            code: "DOMAIN_NOT_SUPPORTED"
          )
        }

        // Check if the handler can handle this type of operation
        let handlerAnyResult=try await handler.handleOperation(operation: operation)
        guard let handlerTypedResult=handlerAnyResult as? T.APIOperationResult else {
          throw APIError.operationFailed(
            message: "Handler for domain \(domain) returned unexpected type \(type(of: handlerAnyResult)) for operation \(type(of: operation)). Expected \(T.APIOperationResult.self).",
            code: "HANDLER_TYPE_MISMATCH"
          )
        }

        // Log the operation completion
        let operationMetadata=LogMetadataDTOCollection()
          .withPublic(key: "operation_id", value: operationID)
          .withPublic(key: "domain", value: domain)

        await self.logger.info(
          "Operation completed successfully",
          context: BaseLogContextDTO(
            domainName: "APIService",
            source: "execute",
            metadata: operationMetadata
          )
        )

        // Return the operation result
        return handlerTypedResult
      } catch {
        // Log the error
        let errorMetadata=LogMetadataDTOCollection()
          .withPublic(key: "error_type", value: String(describing: type(of: error)))
          .withPrivate(key: "error_detail", value: error.localizedDescription)

        await self.logger.error(
          "Operation failed: \(error.localizedDescription)",
          context: BaseLogContextDTO(
            domainName: "APIService",
            source: "execute",
            metadata: errorMetadata
          )
        )

        // Map the error to an APIError if needed
        let mappedError=self.mapError(error)
        throw mappedError
      }
    }

    // Store the task for potential cancellation
    activeOperations[operationID]=task

    do {
      // Await the task result
      let untypedResult=try await task.value
      guard let typedResult=untypedResult as? T.APIOperationResult else {
        // This should ideally not happen if the handler returns the correct type
        throw APIError.operationFailed(
          message: "Internal error: Task returned unexpected type \(type(of: untypedResult)). Expected \(T.APIOperationResult.self).",
          code: "TYPE_MISMATCH"
        )
      }

      // Remove the task from active operations
      activeOperations.removeValue(forKey: operationID)

      // Return the result
      return typedResult
    } catch {
      // Remove the task from active operations
      activeOperations.removeValue(forKey: operationID)

      // Re-throw the error
      throw error
    }
  }

  /**
   Executes an API operation with the specified options and wraps the result in an APIResult.

   - Parameters:
     - operation: The operation to execute
   - Returns: APIResult containing the operation result or error
   */
  public func tryExecute<T: APIInterfaces.APIOperation>(
    _ operation: T
  ) async -> APIResult<T.APIOperationResult> {
    do {
      let result=try await execute(operation)
      return .success(result)
    } catch {
      let mappedError=mapError(error)
      return .failure(mappedError)
    }
  }

  /**
   Cancels an active operation with the specified ID.

   - Parameter operationID: The ID of the operation to cancel
   - Returns: True if the operation was cancelled, false otherwise
   */
  public func cancelOperation(
    operationID: String
  ) async -> Bool {
    guard let task=activeOperations[operationID] else {
      // Log the operation not found
      await logger.warning(
        "Operation not found for cancellation",
        context: BaseLogContextDTO(
          domainName: "APIService",
          source: "cancelOperation",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "operation_id", value: operationID)
        )
      )
      return false
    }

    // Log the cancellation
    await logger.info(
      "Cancelling operation",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "cancelOperation",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "operation_id", value: operationID)
      )
    )

    // Cancel the task
    task.cancel()

    // Remove from active operations
    activeOperations.removeValue(forKey: operationID)

    return true
  }

  // MARK: - Private Helper Methods

  /**
   Gets the domain for an operation.

   - Parameter operation: The operation to get the domain for
   - Returns: The domain for the operation
   */
  private func getDomain(for operation: some APIOperation) -> APIDomain {
    if let domainOperation=operation as? DomainAPIOperation {
      type(of: domainOperation).domain
    } else {
      // Default to system domain for generic operations
      .system
    }
  }

  /**
   Maps a raw error to an APIError for consistent error handling.

   - Parameter error: The error to map
   - Returns: The mapped APIError
   */
  private func mapError(_ error: Error) -> APIError {
    // If it's already an APIError, return it directly
    if let apiError=error as? APIError {
      return apiError
    }

    // Handle NSError
    if let nsError=error as? NSError {
      switch nsError.domain {
        case NSURLErrorDomain:
          return APIError.networkError(
            message: "Network error: \(nsError.localizedDescription)",
            code: "NETWORK_ERROR_\(nsError.code)"
          )
        default:
          break
      }
    }

    // Default to generic operation failure
    return APIError.operationFailed(
      message: "Operation failed: \(error.localizedDescription)",
      code: "OPERATION_FAILED"
    )
  }

  /**
   Registers an event subscriber.

   - Parameters:
     - continuation: The continuation to register
     - filter: Optional filter for specific event types
   */
  private func registerEventSubscriber(
    continuation: AsyncStream<APIEventDTO>.Continuation,
    filter: APIEventFilterDTO?
  ) async {
    // Log registration
    await logger.info(
      "Registered event subscriber",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "registerEventSubscriber",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "filter", value: String(describing: filter))
      )
    )

    // Store the continuation with a unique ID
    let subscriptionID=UUID()
    eventContinuations[subscriptionID]=continuation
  }

  /**
   Unregisters an event subscriber.

   - Parameter continuation: The continuation to unregister
   */
  private func unregisterEventSubscriber(
    continuation _: AsyncStream<APIEventDTO>.Continuation
  ) async {
    // Log unregistration
    await logger.info(
      "Unregistered event subscriber",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "unregisterEventSubscriber",
        metadata: LogMetadataDTOCollection()
      )
    )

    // Remove the continuation from our collection
    // Since we can't compare continuations directly (they're value types),
    // we'll remove all of them in this test implementation
    eventContinuations.removeAll()
  }

  /**
   Publishes an event to all subscribers.

   - Parameter event: The event to publish
   */
  private func publishEvent(_ event: APIEventDTO) async {
    for (_, continuation) in eventContinuations {
      continuation.yield(event)
    }
  }
}

// MARK: - Domain API Operation Protocol

/**
 Protocol for operations that belong to a specific domain.
 */
public protocol DomainAPIOperation: APIOperation {
  /// The domain this operation belongs to
  static var domain: APIDomain { get }
}

// MARK: - Placeholder Operations for Bookmarks

struct CreateBookmarkOperation: DomainAPIOperation {
  typealias ResultType=Void

  let url: String
  let identifier: String

  static var domain: APIDomain { .security }
}

struct ResolveBookmarkOperation: DomainAPIOperation {
  typealias ResultType=String

  let identifier: String

  static var domain: APIDomain { .security }
}

struct DeleteBookmarkOperation: DomainAPIOperation {
  typealias ResultType=Void

  let identifier: String

  static var domain: APIDomain { .security }
}
