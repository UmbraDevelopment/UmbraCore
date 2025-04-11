import Foundation
import LoggingInterfaces
import LoggingTypes
import SynchronisationInterfaces

/**
 Command for cancelling a synchronization operation.

 This command encapsulates the logic for cancelling an ongoing synchronization
 operation, following the command pattern architecture.
 */
public class CancelSynchronizationOperationCommand: BaseSynchronisationCommand,
SynchronisationCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// The identifier of the operation to cancel
  private let operationID: String

  /**
   Initializes a new cancel operation command.

   - Parameters:
      - operationID: The identifier of the operation to cancel
      - logger: Logger instance for synchronization operations
   */
  public init(
    operationID: String,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.operationID=operationID

    super.init(logger: logger)
  }

  /**
   Executes the cancel operation command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: True if the operation was found and cancelled, false otherwise
   */
  public func execute(context _: LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "cancelOperation",
      operationID: operationID
    )

    // Log operation start
    await logger.log(.info, "Cancelling operation", context: operationContext)

    // Get the operation info from the store
    guard let operation=Self.activeOperations[operationID] else {
      // Log warning
      await logger.log(
        .warning,
        "Operation not found",
        context: operationContext
      )

      return false
    }

    // Check if the operation is already in a terminal state
    if operation.status.isTerminal {
      // Log warning
      await logger.log(
        .warning,
        "Cannot cancel operation in terminal state: \(operation.status.rawValue)",
        context: operationContext
      )

      return false
    }

    // Update the operation status to cancelled
    updateOperationStatus(operationID: operationID, status: .cancelled)

    // Log success
    await logger.log(
      .info,
      "Operation cancelled successfully",
      context: operationContext
    )

    return true
  }
}
