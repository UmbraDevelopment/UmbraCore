import APIInterfaces
import CoreSecurityTypes
import DateTimeTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 # Alpha API Service

 This is the main implementation of the API Service for the Alpha Dot Five architecture.
 It provides a unified entry point for all API operations across different domains.

 ## Thread Safety

 This implementation uses Swift actors to ensure all operations are thread-safe,
 with proper isolation of mutable state.

 ## Privacy-Aware Logging

 All operations are logged with privacy-aware context information, ensuring
 sensitive data is properly protected during logging.

 ## Domain Routing

 Operations are routed to appropriate domain handlers based on their types
 and requirements, with consistent error handling.
 */
public actor AlphaAPIService: APIService {
  // MARK: - Private Properties

  /// Configuration for the API service
  private let configuration: APIConfigurationDTO

  /// Domain handlers for different API operation domains
  private let domainHandlers: [APIDomain: any DomainHandler]

  /// Logger for operation recording with privacy controls
  private let logger: LoggingProtocol

  /// Active operations tracking
  private var activeOperations: [String: Task<Any, Error>]=[:]

  // MARK: - Initialisation

  /**
   Initialises a new API service with the provided dependencies.

   - Parameters:
      - configuration: Configuration for the API service
      - domainHandlers: Domain-specific operation handlers
      - logger: Logger for operation recording
   */
  public init(
    configuration: APIConfigurationDTO,
    domainHandlers: [APIDomain: any DomainHandler],
    logger: LoggingProtocol
  ) {
    self.configuration=configuration
    self.domainHandlers=domainHandlers
    self.logger=logger
  }

  // MARK: - APIService Protocol Implementation

  /**
   Executes an API operation synchronously, returning the result or throwing an error.

   - Parameters:
      - operation: The operation to execute
      - options: Optional execution options

   - Returns: The result of the operation

   - Throws: APIError if the operation fails
   */
  public func execute<T: APIOperation>(
    _ operation: T,
    options: APIExecutionOptions?=nil
  ) async throws -> T.ResultType {
    let operationID=UUID().uuidString
    let operationMetadata=PrivacyMetadata([
      "operation_id": .public(operationID),
      "operation_type": .public(String(describing: T.self)),
      "domain": .public(getDomain(for: operation).rawValue)
    ])

    // Log the operation start
    await logger.info(
      "Starting API operation",
      metadata: operationMetadata,
      source: "AlphaAPIService"
    )

    do {
      // Get the appropriate domain handler
      let handler=try getDomainHandler(for: operation)

      // Create a task for this operation
      let operationTask=Task<Any, Error> {
        // Execute with timeout if specified
        if let timeout=options?.timeoutMilliseconds ?? configuration.timeoutMilliseconds {
          try await withTimeout(milliseconds: timeout) {
            try await handler.execute(operation)
          }
        } else {
          try await handler.execute(operation)
        }
      }

      // Store the task
      activeOperations[operationID]=operationTask

      do {
        // Wait for the operation to complete
        let result=try await operationTask.value

        // Type-check the result
        guard let typedResult=result as? T.ResultType else {
          throw APIError.operationFailed(
            message: "Type mismatch: Expected \(T.ResultType.self), got \(type(of: result))",
            code: "TYPE_MISMATCH",
            underlyingError: nil
          )
        }

        // Log success
        let resultMetadata=operationMetadata.merging(PrivacyMetadata([
          "status": .public("success"),
          "duration_ms": .public(String(Date().timeIntervalSince1970 * 1000))
        ]))

        await logger.info(
          "API operation completed successfully",
          metadata: resultMetadata,
          source: "AlphaAPIService"
        )

        // Remove from active operations
        activeOperations[operationID]=nil

        return typedResult
      } catch {
        // Log failure
        let errorMetadata=operationMetadata.merging(PrivacyMetadata([
          "status": .public("failed"),
          "error": .private(error.localizedDescription)
        ]))

        await logger.error(
          "API operation failed",
          metadata: errorMetadata,
          source: "AlphaAPIService"
        )

        // Remove from active operations
        activeOperations[operationID]=nil

        // Map the error to an APIError
        throw mapToAPIError(error)
      }
    } catch {
      // Log handler resolution failure
      let errorMetadata=operationMetadata.merging(PrivacyMetadata([
        "status": .public("failed"),
        "error": .private(error.localizedDescription)
      ]))

      await logger.error(
        "Failed to resolve domain handler for operation",
        metadata: errorMetadata,
        source: "AlphaAPIService"
      )

      throw mapToAPIError(error)
    }
  }

  /**
   Executes an API operation and wraps the result in an APIResult.
   This method never throws, making it suitable for non-critical operations.

   - Parameters:
      - operation: The operation to execute
      - options: Optional execution options

   - Returns: APIResult containing either the result or an error
   */
  public func executeWithResult<T: APIOperation>(
    _ operation: T,
    options: APIExecutionOptions?=nil
  ) async -> APIResult<T.ResultType> {
    do {
      let result=try await execute(operation, options: options)
      return .success(result)
    } catch {
      let apiError: APIError=if let error=error as? APIError {
        error
      } else {
        mapToAPIError(error)
      }

      return .failure(apiError)
    }
  }

  /**
   Cancels all currently executing operations.

   - Parameter options: Optional cancellation options
   */
  public func cancelAllOperations(options: APICancellationOptions?=nil) async {
    // Log the cancellation
    await logger.info(
      "Cancelling all API operations",
      metadata: PrivacyMetadata([
        "operation_count": .public(String(activeOperations.count)),
        "reason": .public(options?.reason ?? "user_request")
      ]),
      source: "AlphaAPIService"
    )

    // Cancel all operations
    for (id, task) in activeOperations {
      task.cancel()

      // Log each cancellation
      await logger.debug(
        "Cancelled operation",
        metadata: PrivacyMetadata([
          "operation_id": .public(id)
        ]),
        source: "AlphaAPIService"
      )
    }

    // Clear the active operations
    activeOperations.removeAll()
  }

  /**
   Cancels a specific operation by its ID.

   - Parameters:
      - operationID: The ID of the operation to cancel
      - options: Optional cancellation options

   - Returns: true if the operation was found and cancelled, false otherwise
   */
  public func cancelOperation(
    withID operationID: String,
    options: APICancellationOptions?=nil
  ) async -> Bool {
    guard let task=activeOperations[operationID] else {
      await logger.debug(
        "Operation not found for cancellation",
        metadata: PrivacyMetadata([
          "operation_id": .public(operationID)
        ]),
        source: "AlphaAPIService"
      )
      return false
    }

    // Log the cancellation
    await logger.info(
      "Cancelling API operation",
      metadata: PrivacyMetadata([
        "operation_id": .public(operationID),
        "reason": .public(options?.reason ?? "user_request")
      ]),
      source: "AlphaAPIService"
    )

    // Cancel the task
    task.cancel()

    // Remove from active operations
    activeOperations.removeIf(key: operationID)

    return true
  }

  // MARK: - Private Helper Methods

  /**
   Gets the domain handler for a given operation.

   - Parameter operation: The operation to get a handler for
   - Returns: The appropriate domain handler
   - Throws: APIError if no handler is found
   */
  private func getDomainHandler(for operation: some APIOperation) throws -> any DomainHandler {
    let domain=getDomain(for: operation)

    guard let handler=domainHandlers[domain] else {
      throw APIError.operationNotSupported(
        message: "No handler found for domain: \(domain)",
        code: "DOMAIN_NOT_SUPPORTED",
        underlyingError: nil
      )
    }

    if !handler.supports(operation) {
      throw APIError.operationNotSupported(
        message: "Operation \(type(of: operation)) not supported by handler for domain \(domain)",
        code: "OPERATION_NOT_SUPPORTED",
        underlyingError: nil
      )
    }

    return handler
  }

  /**
   Determines the domain for a given operation.

   - Parameter operation: The operation to determine the domain for
   - Returns: The appropriate APIDomain
   */
  private func getDomain(for operation: some APIOperation) -> APIDomain {
    if let domainOperation=operation as? any DomainAPIOperation {
      return type(of: domainOperation).domain
    }

    // Default domain routing based on operation type
    switch operation {
      case is any SecurityAPIOperation:
        return .security
      case is any RepositoryAPIOperation:
        return .repository
      case is any BackupAPIOperation:
        return .backup
      default:
        return .system
    }
  }

  /**
   Maps any error to an APIError for consistent error handling.

   - Parameter error: The original error
   - Returns: An appropriate APIError
   */
  private func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError=error as? APIError {
      return apiError
    }

    // Handle NSError
    if let nsError=error as? NSError {
      switch nsError.domain {
        case NSURLErrorDomain:
          return APIError.networkError(
            message: nsError.localizedDescription,
            code: String(nsError.code),
            underlyingError: nsError
          )
        default:
          break
      }
    }

    // Generic error mapping
    return APIError.operationFailed(
      message: error.localizedDescription,
      code: "OPERATION_FAILED",
      underlyingError: error
    )
  }

  /**
   Executes an operation with a timeout.

   - Parameters:
      - milliseconds: The timeout in milliseconds
      - operation: The operation to execute

   - Returns: The result of the operation
   - Throws: TimeoutError if the operation times out
   */
  private func withTimeout<T>(
    milliseconds: UInt64,
    _ operation: () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      // Execute the actual operation
      group.addTask {
        try await operation()
      }

      // Execute a timeout task
      group.addTask {
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
        throw APIError.timeout(
          message: "Operation timed out after \(milliseconds) milliseconds",
          code: "OPERATION_TIMEOUT"
        )
      }

      // Return the first result (or throw the first error)
      let result=try await group.next()!

      // Cancel any remaining tasks
      group.cancelAll()

      return result
    }
  }
}

// MARK: - Helper Extensions

extension Dictionary {
  mutating func removeIf(key: Key) {
    if self[key] != nil {
      removeValue(forKey: key)
    }
  }
}
