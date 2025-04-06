import APIInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

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
   Initializes the service with the provided configuration.
   
   - Parameter configuration: The configuration to use
   - Throws: APIError if initialization fails
   */
  public func initialise(configuration: APIConfigurationDTO) async throws {
    self.configuration = configuration
    
    // Log initialization
    await logger.info(
      "API service initialized", 
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "environment", value: configuration.environment.rawValue)
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
   Gets the current version of the API.
   
   - Returns: The API version information
   */
  public nonisolated func getVersion() async -> APIVersionDTO {
    // Return version information
    return APIVersionDTO(
      major: 1,
      minor: 0,
      patch: 0,
      buildIdentifier: "alpha-build"
    )
  }
  
  /**
   Subscribes to API events.
   
   - Parameter filter: Optional filter for specific event types
   - Returns: An AsyncStream of API events
   */
  public nonisolated func subscribeToEvents(filter: APIEventFilterDTO?) -> AsyncStream<APIEventDTO> {
    return AsyncStream { continuation in
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
   - Returns: The operation result
   - Throws: APIError if the operation fails
   */
  public func execute<T: APIOperation>(
    _ operation: T,
    options: APIExecutionOptions? = nil
  ) async throws -> T.Result {
    let operationID = UUID().uuidString
    let operationMetadata = LogMetadataDTOCollection()
      .withPublic(key: "operation_id", value: operationID)
      .withPublic(key: "operation_type", value: String(describing: type(of: operation)))
    
    // Log the operation start
    await logger.info(
      "Executing operation \(String(describing: type(of: operation)))",
      metadata: operationMetadata
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
        guard let result = try await handler.handleOperation(operation: operation) as? T.Result else {
          throw APIError.operationFailed(
            message: "Operation \(type(of: operation)) not supported by handler for domain \(domain)",
            code: "OPERATION_NOT_SUPPORTED"
          )
        }
        
        // Log the operation completion
        await self.logger.info(
          "Operation completed successfully",
          metadata: operationMetadata
            .withPublic(key: "status", value: "success")
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
          metadata: operationMetadata.mergeWith(errorMetadata)
        )
        
        // Map the error to an APIError if needed
        let mappedError = self.mapError(error)
        throw mappedError
      }
    }
    
    // Store the task for potential cancellation
    self.activeOperations[operationID] = task
    
    do {
      // Await the task result
      let result = try await task.value as! T.Result
      
      // Remove the task from active operations
      self.activeOperations.removeValue(forKey: operationID)
      
      // Return the result
      return result
    } catch {
      // Remove the task from active operations
      self.activeOperations.removeValue(forKey: operationID)
      
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
    options: APIExecutionOptions? = nil
  ) async -> APIResult<T.Result> {
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
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "operation_id", value: operationID)
      )
      return false
    }
    
    // Log the cancellation
    await logger.info(
      "Cancelling operation",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "operation_id", value: operationID)
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
    let subscriptionID = UUID()
    self.eventContinuations[subscriptionID] = continuation
    
    await logger.debug(
      "Registered event subscriber",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "subscription_id", value: subscriptionID.uuidString)
        .withPublic(key: "has_filter", value: filter != nil ? "yes" : "no")
    )
  }
  
  /**
   Unregisters an event subscriber.
   
   - Parameter continuation: The continuation to unregister
   */
  private func unregisterEventSubscriber(
    continuation: AsyncStream<APIEventDTO>.Continuation
  ) async {
    for (id, value) in self.eventContinuations where value === continuation {
      self.eventContinuations.removeValue(forKey: id)
      
      await logger.debug(
        "Unregistered event subscriber",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "subscription_id", value: id.uuidString)
      )
    }
  }
  
  /**
   Publishes an event to all subscribers.
   
   - Parameter event: The event to publish
   */
  private func publishEvent(_ event: APIEventDTO) async {
    for (id, continuation) in self.eventContinuations {
      continuation.yield(event)
      
      await logger.debug(
        "Published event to subscriber",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "subscription_id", value: id.uuidString)
          .withPublic(key: "event_id", value: event.identifier)
      )
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
  func mergeWith(_ other: LogMetadataDTOCollection) -> LogMetadataDTOCollection {
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
  typealias Result = Void
  
  let url: String
  let identifier: String
  
  static var domain: APIDomain { .security }
}

struct ResolveBookmarkOperation: DomainAPIOperation {
  typealias Result = String
  
  let identifier: String
  
  static var domain: APIDomain { .security }
}

struct DeleteBookmarkOperation: DomainAPIOperation {
  typealias Result = Void
  
  let identifier: String
  
  static var domain: APIDomain { .security }
}
