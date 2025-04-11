import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Handles common security operation patterns to reduce duplication.

 This utility class provides templated methods for security operations,
 standardising the flow of execution, logging, and error handling to ensure
 consistent behaviour across all security operations.
 */
public class SecurityOperationHandler {
  /// Logger for operations
  private let logger: LoggingProtocol

  /**
   Initialises a new security operation handler.

   - Parameter logger: Logger for operation tracking and auditing
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   Executes a security operation with standardised logging and error handling.

   - Parameters:
      - operation: The security operation name
      - metadataBuilder: A closure that builds operation-specific metadata
      - action: The core operation logic to execute
   - Returns: The operation result
   - Throws: SecurityError or other operational errors that might occur
   */
  public func executeOperation<T>(
    operation: String,
    component: String,
    metadataBuilder: () -> [String: (value: String, privacyLevel: LogPrivacyLevel)]={ [:] },
    action: (_ context: LogContextDTO, _ operationID: String) async throws -> T
  ) async throws -> (result: T, duration: TimeInterval, operationID: String) {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context
    let metadata=metadataBuilder()
    let logContext=createLogContext(
      operation: operation,
      component: component,
      operationID: operationID,
      metadata: metadata
    )

    // Log operation start
    await logger.debug(
      "Starting security operation: \(operation)",
      context: logContext
    )

    do {
      // Execute the operation
      let result=try await action(logContext, operationID)

      // Calculate duration
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success
      await logger.info(
        "Completed security operation: \(operation)",
        context: logContext.adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacyLevel: .public
        )
      )

      return (result, duration, operationID)
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure
      let errorContext=logContext
        .adding(key: "errorType", value: "\(type(of: error))", privacyLevel: .public)
        .adding(key: "errorMessage", value: error.localizedDescription, privacyLevel: .private)
        .adding(key: "durationMs", value: String(format: "%.2f", duration), privacyLevel: .public)

      await logger.error(
        "Security operation failed: \(operation)",
        context: errorContext
      )

      throw error
    }
  }

  /**
   Creates a standardised log context for security operations.

   - Parameters:
      - operation: Name of the operation being performed
      - component: The component performing the operation
      - operationID: Unique identifier for the operation instance
      - metadata: Additional metadata for the operation
   - Returns: A configured log context DTO
   */
  private func createLogContext(
    operation: String,
    component: String,
    operationID: String,
    metadata: [String: (value: String, privacyLevel: LogPrivacyLevel)]=[:]
  ) -> LogContextDTO {
    // Create base log context
    var logContext=SecurityLogContext(
      operation: operation,
      component: component,
      operationID: operationID
    )

    // Add metadata with appropriate privacy levels
    for (key, (value, privacyLevel)) in metadata {
      logContext=logContext.adding(
        key: key,
        value: value,
        privacyLevel: privacyLevel
      )
    }

    return logContext
  }
}
