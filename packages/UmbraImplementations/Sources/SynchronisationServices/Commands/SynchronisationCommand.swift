import Foundation
import LoggingInterfaces
import LoggingTypes
import SynchronisationInterfaces

/**
 Base protocol for all synchronisation operation commands.

 This protocol defines the contract that all synchronisation command implementations
 must fulfil, following the command pattern to encapsulate synchronisation operations in
 discrete command objects with a consistent interface.
 */
public protocol SynchronisationCommand {
  /// The type of result returned by this command when executed
  associatedtype ResultType: Sendable

  /**
   Executes the synchronisation operation.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The result of the operation
   - Throws: SynchronisationError if the operation fails
   */
  func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for synchronisation commands providing common functionality.

 This abstract base class provides shared functionality for all synchronisation commands,
 including standardised logging and utility methods that are commonly needed across
 synchronisation operations.
 */
public class BaseSynchronisationCommand {
  /// Logging instance for synchronisation operations
  protected let logger: PrivacyAwareLoggingProtocol

  /// In-memory store of active operations
  protected static var activeOperations: [String: SynchronisationOperationInfo]=[:]

  /**
   Initialises a new base synchronisation command.

   - Parameters:
      - logger: Logger instance for synchronisation operations
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }

  /**
   Creates a logging context with standardised metadata.

   - Parameters:
      - operation: The name of the operation
      - operationID: The unique operation identifier
      - additionalMetadata: Additional metadata for the log context
   - Returns: A configured log context
   */
  protected func createLogContext(
    operation: String,
    operationID: String,
    additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)]=[:]
  ) -> LogContextDTO {
    // Create a base metadata collection
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "operationID", value: operationID)
      .withPublic(key: "source", value: "SynchronisationService")

    // Add additional metadata with specified privacy levels
    for (key, value) in additionalMetadata {
      switch value.privacyLevel {
        case .public:
          metadata=metadata.withPublic(key: key, value: value.value)
        case .protected:
          metadata=metadata.withProtected(key: key, value: value.value)
        case .private:
          metadata=metadata.withPrivate(key: key, value: value.value)
      }
    }

    // Create and return the log context
    return LogContextDTO(
      operationName: operation,
      sourceComponent: "SynchronisationService",
      metadata: metadata
    )
  }

  /**
   Updates the status of an operation in the shared operation store.

   - Parameters:
      - operationID: The operation to update
      - status: The new status
      - filesProcessed: The number of files processed
      - bytesTransferred: The number of bytes transferred
      - error: Any error that occurred
   */
  protected func updateOperationStatus(
    operationID: String,
    status: SynchronisationStatus,
    filesProcessed: Int?=nil,
    bytesTransferred: Int64?=nil,
    error: SynchronisationError?=nil
  ) {
    // Get the existing operation info or return if not found
    guard var operation=Self.activeOperations[operationID] else {
      return
    }

    // Create a new operation with updated fields
    let updatedOperation=SynchronisationOperationInfo(
      id: operation.id,
      status: status,
      createdAt: operation.createdAt,
      updatedAt: Date(),
      source: operation.source,
      destination: operation.destination,
      filesProcessed: filesProcessed ?? operation.filesProcessed,
      bytesTransferred: bytesTransferred ?? operation.bytesTransferred,
      error: error ?? operation.error
    )

    // Update the operation in the store
    Self.activeOperations[operationID]=updatedOperation
  }

  /**
   Checks if an operation with the given ID exists.

   - Parameter operationID: The operation ID to check
   - Returns: True if the operation exists, false otherwise
   */
  protected func operationExists(operationID: String) -> Bool {
    Self.activeOperations[operationID] != nil
  }

  /**
   Gets an operation by its ID.

   - Parameter operationID: The operation ID to retrieve
   - Returns: The operation info if found, nil otherwise
   */
  protected func getOperation(operationID: String) -> SynchronisationOperationInfo? {
    Self.activeOperations[operationID]
  }
}
