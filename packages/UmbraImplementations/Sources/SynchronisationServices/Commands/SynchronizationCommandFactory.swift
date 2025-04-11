import Foundation
import LoggingInterfaces
import SynchronisationInterfaces

/**
 Factory for creating synchronization command objects.

 This factory is responsible for creating specific command objects that encapsulate
 the logic for each synchronization operation, following the command pattern architecture.
 */
public struct SynchronizationCommandFactory {
  /// Logging instance for synchronization operations
  private let logger: PrivacyAwareLoggingProtocol

  /**
   Initializes a new synchronization command factory.

   - Parameters:
      - logger: Logger instance for synchronization operations
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }

  /**
   Creates a command for synchronizing data between a local source and a remote destination.

   - Parameters:
      - operationID: Unique identifier for this operation
      - source: Local data source information
      - destination: Remote destination information
      - options: Additional synchronization options
   - Returns: A configured synchronize command
   */
  public func createSynchronizeCommand(
    operationID: String,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    options: SynchronisationOptions
  ) -> SynchronizeCommand {
    SynchronizeCommand(
      operationID: operationID,
      source: source,
      destination: destination,
      options: options,
      logger: logger
    )
  }

  /**
   Creates a command for verifying consistency between a local source and a remote destination.

   - Parameters:
      - operationID: Unique identifier for this operation
      - source: Local data source information
      - destination: Remote destination information
      - options: Additional verification options
   - Returns: A configured verify consistency command
   */
  public func createVerifyConsistencyCommand(
    operationID: String,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    options: SynchronisationVerificationOptions
  ) -> VerifyConsistencyCommand {
    VerifyConsistencyCommand(
      operationID: operationID,
      source: source,
      destination: destination,
      options: options,
      logger: logger
    )
  }

  /**
   Creates a command for retrieving the status of a synchronization operation.

   - Parameter operationID: The identifier of the operation to check
   - Returns: A configured get status command
   */
  public func createGetStatusCommand(
    operationID: String
  ) -> GetSynchronizationStatusCommand {
    GetSynchronizationStatusCommand(
      operationID: operationID,
      logger: logger
    )
  }

  /**
   Creates a command for listing synchronization operations.

   - Parameters:
      - filter: Optional filter for specific operation types or statuses
      - limit: Maximum number of operations to return
      - offset: Number of operations to skip from the start
   - Returns: A configured list operations command
   */
  public func createListOperationsCommand(
    filter: SynchronisationFilter?=nil,
    limit: Int=50,
    offset: Int=0
  ) -> ListSynchronizationOperationsCommand {
    ListSynchronizationOperationsCommand(
      filter: filter,
      limit: limit,
      offset: offset,
      logger: logger
    )
  }

  /**
   Creates a command for cancelling a synchronization operation.

   - Parameter operationID: The identifier of the operation to cancel
   - Returns: A configured cancel operation command
   */
  public func createCancelOperationCommand(
    operationID: String
  ) -> CancelSynchronizationOperationCommand {
    CancelSynchronizationOperationCommand(
      operationID: operationID,
      logger: logger
    )
  }
}
