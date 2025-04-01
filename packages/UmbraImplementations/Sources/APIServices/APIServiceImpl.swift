import APIInterfaces
import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import UmbraErrors

/**
 # API Service Implementation

 Concrete implementation of the APIService protocol using Swift actors
 for thread safety following the Alpha Dot Five architecture. This
 implementation provides a unified entry point for all API operations,
 delegating to specialised domain handlers.

 ## Thread Safety

 This implementation uses Swift actors to ensure all operations are
 thread-safe, with proper isolation of mutable state.

 ## Privacy-Aware Logging

 Operations are logged with privacy-aware context information, ensuring
 sensitive data is properly protected during logging.

 ## Operation Routing

 Each operation is routed to the appropriate domain handler based on
 its type, with proper error handling and timeout management.
 */
public actor APIServiceImpl: APIService {
  /// Domain handlers for different operation types
  private let domainHandlers: [APIDomain: DomainHandler]

  /// Logger for operation recording
  private let logger: LoggingProtocol?

  /**
   Initialises a new API service implementation.

   - Parameters:
      - domainHandlers: Handlers for different operation domains
      - logger: Optional logger for operation recording
   */
  public init(
    domainHandlers: [APIDomain: DomainHandler],
    logger: LoggingProtocol?=nil
  ) {
    self.domainHandlers=domainHandlers
    self.logger=logger
  }

  /**
   Executes an API operation and returns the result.

   - Parameter operation: The operation to execute

   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  public func execute<T: APIOperation>(_ operation: T) async throws -> T.ResultType {
    await log(.info, "Executing operation: \(String(describing: T.self))")

    let domain=getDomain(for: operation)

    guard let handler=domainHandlers[domain] else {
      let error=APIError
        .operationNotSupported("No handler registered for domain: \(domain.rawValue)")
      await log(.error, "Operation error: \(error)")
      throw error
    }

    do {
      // Execute the operation using the appropriate domain handler
      let result=try await handler.execute(operation)

      // Type-check and cast the result
      guard let typedResult=result as? T.ResultType else {
        throw APIError.operationFailed(
          UmbraErrors.Common
            .typeMismatch(
              "Expected result of type \(T.ResultType.self), but got \(type(of: result))"
            )
        )
      }

      await log(.info, "Operation completed successfully")
      return typedResult
    } catch {
      let apiError=mapError(error, operation: String(describing: T.self), domain: domain)
      await log(.error, "Operation error: \(apiError)")
      throw apiError
    }
  }

  /**
   Executes an API operation with a timeout.

   - Parameters:
      - operation: The operation to execute
      - timeoutSeconds: The timeout in seconds

   - Returns: The result of the operation
   - Throws: APIError.operationTimedOut if the operation times out, or another APIError if it fails
   */
  public func execute<T: APIOperation>(
    _ operation: T,
    timeoutSeconds: Int
  ) async throws -> T.ResultType {
    await log(
      .info,
      "Executing operation with timeout (\(timeoutSeconds)s): \(String(describing: T.self))"
    )

    return try await withTimeout(operation: operation, seconds: timeoutSeconds)
  }

  /**
   Executes an API operation and returns a result that can be success or failure.

   - Parameter operation: The operation to execute

   - Returns: An APIResult containing either the operation result or an error
   */
  public func executeWithResult<T: APIOperation>(_ operation: T) async -> APIResult<T.ResultType> {
    do {
      let result=try await execute(operation)
      return .success(result)
    } catch {
      guard let apiError=error as? APIError else {
        return .failure(APIError.operationFailed(error))
      }
      return .failure(apiError)
    }
  }

  // MARK: - Private Helper Methods

  /**
   Executes an operation with a timeout.

   - Parameters:
      - operation: The operation to execute
      - seconds: The timeout in seconds

   - Returns: The result of the operation
   - Throws: APIError.operationTimedOut if the operation times out, or another APIError if it fails
   */
  private func withTimeout<T: APIOperation>(
    operation: T,
    seconds: Int
  ) async throws -> T.ResultType {
    try await withCheckedThrowingContinuation { continuation in
      // Create a task for the operation
      let task=Task {
        do {
          let result=try await self.execute(operation)
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }

      // Create a task for the timeout
      Task {
        try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)

        // Cancel the operation task if it's still running
        if !task.isCancelled {
          task.cancel()

          let domain=self.getDomain(for: operation)
          let operationName=String(describing: T.self)

          // Log the timeout
          await self.log(.error, "Operation timed out after \(seconds) seconds: \(operationName)")

          // Resume with a timeout error if the operation hasn't completed
          let error=APIError.operationTimedOut(
            "Operation timed out after \(seconds) seconds",
            timeoutSeconds: seconds
          )
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /**
   Gets the domain for an operation.

   - Parameter operation: The operation

   - Returns: The operation domain
   */
  private func getDomain<T: APIOperation>(for operation: T) -> APIDomain {
    if let domainOperation=operation as? DomainAPIOperation {
      return type(of: domainOperation).domain
    }

    // Default to the appropriate domain based on the operation type
    let operationType=String(describing: T.self).lowercased()

    if operationType.contains("repository") {
      return .repository
    } else if operationType.contains("backup") || operationType.contains("snapshot") {
      return .backup
    } else if operationType.contains("security") || operationType.contains("key") {
      return .security
    } else if operationType.contains("system") || operationType.contains("config") {
      return .system
    } else if operationType.contains("preference") || operationType.contains("setting") {
      return .preferences
    }

    // Default to application domain
    return .application
  }

  /**
   Maps any error to an APIError.

   - Parameters:
      - error: The original error
      - operation: The operation name
      - domain: The operation domain

   - Returns: An APIError representing the failure
   */
  private func mapError(
    _ error: Error,
    operation _: String,
    domain _: APIDomain
  ) -> APIError {
    // If it's already an APIError, return it
    if let apiError=error as? APIError {
      return apiError
    }

    // Map the error to an appropriate APIError
    if let nsError=error as NSError {
      switch nsError.domain {
        case NSURLErrorDomain:
          return APIError.serviceUnavailable("Network error: \(nsError.localizedDescription)")

        case NSCocoaErrorDomain:
          if nsError.code == NSUserCancelledError {
            return APIError.operationCancelled("Operation was cancelled by the user")
          }

          if nsError.code == NSFileNoSuchFileError {
            let path=nsError.userInfo[NSFilePathErrorKey] as? String ?? "unknown"
            return APIError.resourceNotFound("File not found", identifier: path)
          }

          return APIError.operationFailed(error)

        default:
          return APIError.operationFailed(error)
      }
    }

    // For all other errors, wrap them in an operationFailed error
    return APIError.operationFailed(error)
  }

  /**
   Logs a message using the configured logger.

   - Parameters:
      - level: The log level
      - message: The message to log
   */
  private func log(_ level: LogLevel, _ message: String) async {
    if let logger {
      await logger.logMessage(level, message, context: .init(source: "APIService"))
    }
  }
}

/**
 Domain-specific operation handler protocol.
 This allows different domains to provide specialised handling for operations.
 */
public protocol DomainHandler: Sendable {
  /**
   Executes an operation and returns the result.

   - Parameter operation: The operation to execute

   - Returns: The result of the operation
   - Throws: Error if the operation fails
   */
  func execute<T: APIOperation>(_ operation: T) async throws -> Any

  /**
   Checks if this handler supports the given operation.

   - Parameter operation: The operation to check

   - Returns: True if the operation is supported, false otherwise
   */
  func supports<T: APIOperation>(_ operation: T) -> Bool
}

/**
 Factory for creating API services.
 */
public enum APIServices {
  /**
   Creates a default API service with the necessary domain handlers.

   - Parameters:
      - repositoryService: The repository service
      - backupService: The backup service
      - securityService: The security service
      - logger: Optional logger for operation recording

   - Returns: A configured API service
   */
  public static func createService(
    repositoryService: RepositoryServiceProtocol,
    backupService: BackupServiceProtocol,
    securityService: SecurityServiceProtocol,
    logger: LoggingProtocol?=nil
  ) async -> APIService {
    // Create domain handlers
    let handlers: [APIDomain: DomainHandler]=[
      .repository: RepositoryDomainHandler(service: repositoryService),
      .backup: BackupDomainHandler(service: backupService),
      .security: SecurityDomainHandler(service: securityService)
    ]

    // Create and return the API service
    return APIServiceImpl(domainHandlers: handlers, logger: logger)
  }

  /**
   Creates a mock API service for testing.

   - Parameter logger: Optional logger for operation recording

   - Returns: A mock API service
   */
  public static func createMockService(
    logger: LoggingProtocol?=nil
  ) async -> APIService {
    MockAPIService(logger: logger)
  }
}
