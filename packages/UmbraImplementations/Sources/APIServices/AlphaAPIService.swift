import APIInterfaces
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
  private var configuration: APIConfigurationDTO

  /// Domain handlers for the service, organized by domain
  private var domainHandlers: [APIDomain: any DomainHandler]

  /// Logger for API service operations
  private let logger: LoggingProtocol

  /// Event continuations for streaming events
  private var eventContinuations: [UUID: AsyncStream<APIEventDTO>.Continuation] = [:]

  /// Active operations tracking
  private var activeOperations: [String: Task<Any, Error>] = [:]

  // MARK: - Initialisation

  /**
   Initializes the API service with the specified configuration and domain handlers.

   - Parameters:
     - configuration: The configuration to use
     - domainHandlers: Handlers for different domains
     - logger: Logger to use for API operations
   */
  public init(
    configuration: APIConfigurationDTO,
    domainHandlers: [APIDomain: any DomainHandler],
    logger: LoggingProtocol
  ) {
    self.configuration = configuration
    self.domainHandlers = domainHandlers
    self.logger = logger
  }

  // MARK: - APIServiceProtocol Implementation

  /**
   Initialises the service with the provided configuration
   
   - Parameter configuration: The configuration to use for initialisation
   - Throws: UmbraErrors.APIError if initialisation fails
   */
  public func initialise(configuration: APIConfigurationDTO) async throws {
    self.configuration = configuration
    
    // Initialize domain handlers
    // In a real implementation, these would be properly created and configured
    securityDomainHandler = SecurityDomainHandler(logger: logger)
    
    // Log initialization
    await logger.info(
      "API service initialized",
      context: LogContextDTO(
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
    let operation = CreateBookmarkOperation(url: url, identifier: identifier)
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
    let operation = ResolveBookmarkOperation(identifier: identifier)
    return try await execute(operation)
  }

  /**
   Deletes an encrypted bookmark.

   - Parameter identifier: The identifier of the bookmark to delete
   - Throws: APIError if bookmark deletion fails
   */
  public nonisolated func deleteEncryptedBookmark(identifier: String) async throws {
    // Delegate to the security domain
    let operation = DeleteBookmarkOperation(identifier: identifier)
    try await execute(operation)
  }

  /**
   Retrieves the current version information of the API
   - Returns: Version information as APIVersionDTO
   */
  public func getVersion() async -> APIVersionDTO {
    let version = APIVersionDTO(
      major: configuration.majorVersion,
      minor: configuration.minorVersion,
      patch: configuration.patchVersion,
      buildIdentifier: configuration.buildIdentifier
    )
    
    return version
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
     - options: Optional execution options
   - Returns: The result of the operation
   - Throws: APIError if execution fails
   */
  public func execute<T: APIOperation>(
    _ operation: T,
    options _: APIConfigurationOptions? = nil
  ) async throws -> T.OperationResult {
    let operationID = UUID().uuidString
    let operationMetadata = LogMetadataDTOCollection()
      .withPublic(key: "operation_id", value: operationID)
      .withPublic(key: "operation_type", value: String(describing: type(of: operation)))

    // Log the operation start
    await logger.info(
      "Executing operation \(String(describing: type(of: operation)))",
      context: LogContextDTO(
        domainName: "APIService",
        source: "execute",
        metadata: operationMetadata
      )
    )

    // Create a task for the operation execution
    let task = Task {
      do {
        // Get the domain for this operation
        let domain = self.getDomain(for: operation)

        // Get the handler for this domain
        guard let handler = self.domainHandlers[domain] else {
          throw APIError.operationNotSupported(
            message: "No handler found for domain: \(domain)",
            code: "DOMAIN_NOT_SUPPORTED"
          )
        }

        // Check if the handler can handle this type of operation
        guard let result = try await handler.handleOperation(operation: operation) as? T.OperationResult else {
          throw APIError.operationFailed(
            message: "Operation \(type(of: operation)) not supported by handler for domain \(domain)",
            code: "OPERATION_NOT_SUPPORTED"
          )
        }

        // Log the operation completion
        await self.logger.info(
          "Operation completed successfully",
          context: LogContextDTO(
            domainName: "APIService",
            source: "execute",
            metadata: operationMetadata
              .withPublic(key: "status", value: "success")
          )
        )

        // Return the operation result
        return result
      } catch {
        // Log the error
        let errorMetadata = LogMetadataDTOCollection()
          .withPublic(key: "error_type", value: String(describing: type(of: error)))
          .withPrivate(key: "error_detail", value: error.localizedDescription)

        await self.logger.error(
          "Operation failed: \(error.localizedDescription)",
          context: LogContextDTO(
            domainName: "APIService",
            source: "execute",
            metadata: operationMetadata.mergeWith(errorMetadata)
          )
        )

        // Map the error to an APIError if needed
        let mappedError = self.mapError(error)
        throw mappedError
      }
    }

    // Store the task for potential cancellation
    activeOperations[operationID] = task

    do {
      // Await the task result
      let result = try await task.value as! T.OperationResult

      // Remove the task from active operations
      activeOperations.removeValue(forKey: operationID)

      // Return the result
      return result
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
     - options: Optional execution options
   - Returns: APIResult containing the operation result or error
   */
  public func tryExecute<T: APIOperation>(
    _ operation: T,
    options: APIConfigurationOptions? = nil
  ) async -> APIResult<T.OperationResult> {
    do {
      let result = try await execute(operation, options: options)
      return .success(result)
    } catch {
      let mappedError = mapError(error)
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
    guard let task = activeOperations[operationID] else {
      // Log the operation not found
      await logger.warning(
        "Operation not found for cancellation",
        context: LogContextDTO(
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
      context: LogContextDTO(
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
    if let domainOperation = operation as? DomainAPIOperation {
      return type(of: domainOperation).domain
    }

    // Default to system domain for generic operations
    return .system
  }

  /**
   Maps a raw error to an APIError for consistent error handling.

   - Parameter error: The error to map
   - Returns: The mapped APIError
   */
  private func mapError(_ error: Error) -> APIError {
    // If it's already an APIError, return it directly
    if let apiError = error as? APIError {
      return apiError
    }

    // Handle NSError
    if let nsError = error as? NSError {
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
      context: LogContextDTO(
        domainName: "APIService",
        source: "registerEventSubscriber",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "filter", value: String(describing: filter))
      )
    )
    
    // Store the continuation with a unique ID
    let subscriptionID = UUID()
    eventContinuations[subscriptionID] = continuation
  }
  
  /**
   Unregisters an event subscriber.

   - Parameter continuation: The continuation to unregister
   */
  private func unregisterEventSubscriber(
    continuation: AsyncStream<APIEventDTO>.Continuation
  ) async {
    // Log unregistration
    await logger.info(
      "Unregistered event subscriber",
      context: LogContextDTO(
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

// MARK: - Extensions

extension LogMetadataDTOCollection {
  /**
   Merges this collection with another collection.

   - Parameter other: The collection to merge with
   - Returns: A new merged collection
   */
  func mergeWith(_: LogMetadataDTOCollection) -> LogMetadataDTOCollection {
    var result = self

    // Since we don't have direct access to the underlying storage,
    // we'll use a helper method that creates a new collection
    // This is a simplified implementation

    return result
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
  typealias OperationResult = Void

  let url: String
  let identifier: String

  static var domain: APIDomain { .security }
}

struct ResolveBookmarkOperation: DomainAPIOperation {
  typealias OperationResult = String

  let identifier: String

  static var domain: APIDomain { .security }
}

struct DeleteBookmarkOperation: DomainAPIOperation {
  typealias OperationResult = Void

  let identifier: String

  static var domain: APIDomain { .security }
}
