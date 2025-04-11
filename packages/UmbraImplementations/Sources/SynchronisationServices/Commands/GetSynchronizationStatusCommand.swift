import Foundation
import LoggingInterfaces
import LoggingTypes
import SynchronisationInterfaces

/**
 Command for retrieving the status of a synchronization operation.

 This command encapsulates the logic for checking the status of an existing
 synchronization operation, following the command pattern architecture.
 */
public class GetSynchronizationStatusCommand: BaseSynchronisationCommand, SynchronisationCommand {
  /// The result type for this command
  public typealias ResultType=SynchronisationStatus

  /// The identifier of the operation to check
  private let operationID: String

  /**
   Initializes a new get status command.

   - Parameters:
      - operationID: The identifier of the operation to check
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
   Executes the get status command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The current status of the operation
   - Throws: SynchronisationError if the operation cannot be found
   */
  public func execute(context _: LogContextDTO) async throws -> SynchronisationStatus {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "getStatus",
      operationID: operationID
    )

    // Log operation start
    await logger.log(.debug, "Retrieving status for operation", context: operationContext)

    // Get the operation info from the store
    guard let operation=Self.activeOperations[operationID] else {
      // Log error
      await logger.log(
        .error,
        "Operation not found",
        context: operationContext
      )

      throw SynchronisationError.operationNotFound(operationID)
    }

    // Log success
    await logger.log(
      .debug,
      "Retrieved operation status: \(operation.status.rawValue)",
      context: operationContext
    )

    return operation.status
  }
}
