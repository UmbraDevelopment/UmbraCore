import Foundation
import LoggingInterfaces
import SynchronisationInterfaces

/**
 Actor-based implementation of the SynchronisationServiceProtocol that uses
 the command pattern internally for operation encapsulation.

 This implementation follows the Alpha Dot Five architecture principles by:
 1. Using actor isolation for thread safety
 2. Implementing privacy-aware logging with appropriate data classification
 3. Using proper British spelling in documentation
 4. Providing comprehensive error handling
 5. Using command pattern for improved maintainability and testability
 */
public actor SynchronizationServicesActor: SynchronisationServiceProtocol {
  // MARK: - Private Properties

  /// Factory for creating synchronization command objects
  private let commandFactory: SynchronizationCommandFactory

  /// Logging instance for synchronization operations
  private let logger: PrivacyAwareLoggingProtocol

  // MARK: - Initialization

  /**
   Initializes a new synchronization services actor.

   - Parameters:
      - logger: Logger instance for synchronization operations
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
    commandFactory=SynchronizationCommandFactory(logger: logger)
  }

  // MARK: - SynchronisationServiceProtocol Implementation

  public func synchronise(
    operationID: String,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    options: SynchronisationOptions
  ) async throws -> SynchronisationResult {
    // Create a log context for this operation
    let context=LogContextDTO(
      operationName: "synchronize",
      sourceComponent: "SynchronizationServices",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "operationID", value: operationID)
        .withPublic(key: "sourceType", value: source.type.rawValue)
        .withPublic(key: "destinationType", value: destination.type.rawValue)
    )

    // Create the command using the factory
    let command=commandFactory.createSynchronizeCommand(
      operationID: operationID,
      source: source,
      destination: destination,
      options: options
    )

    // Execute the command
    return try await command.execute(context: context)
  }

  public func getStatus(operationID: String) async throws -> SynchronisationStatus {
    // Create a log context for this operation
    let context=LogContextDTO(
      operationName: "getStatus",
      sourceComponent: "SynchronizationServices",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "operationID", value: operationID)
    )

    // Create the command using the factory
    let command=commandFactory.createGetStatusCommand(operationID: operationID)

    // Execute the command
    return try await command.execute(context: context)
  }

  public func cancelOperation(operationID: String) async -> Bool {
    // Create a log context for this operation
    let context=LogContextDTO(
      operationName: "cancelOperation",
      sourceComponent: "SynchronizationServices",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "operationID", value: operationID)
    )

    // Create the command using the factory
    let command=commandFactory.createCancelOperationCommand(operationID: operationID)

    do {
      // Execute the command
      return try await command.execute(context: context)
    } catch {
      // Log error
      await logger.log(
        .error,
        "Error cancelling operation: \(error.localizedDescription)",
        context: context
      )

      return false
    }
  }

  public func listOperations(
    filter: SynchronisationFilter?,
    limit: Int,
    offset: Int
  ) async throws -> [SynchronisationOperationInfo] {
    // Create a log context for this operation
    let context=LogContextDTO(
      operationName: "listOperations",
      sourceComponent: "SynchronizationServices",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "limit", value: String(limit))
        .withPublic(key: "offset", value: String(offset))
        .withPublic(key: "hasFilter", value: String(filter != nil))
    )

    // Create the command using the factory
    let command=commandFactory.createListOperationsCommand(
      filter: filter,
      limit: limit,
      offset: offset
    )

    // Execute the command
    return try await command.execute(context: context)
  }

  public func verifyConsistency(
    operationID: String,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    options: SynchronisationVerificationOptions
  ) async throws -> SynchronisationVerificationResult {
    // Create a log context for this operation
    let context=LogContextDTO(
      operationName: "verifyConsistency",
      sourceComponent: "SynchronizationServices",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "operationID", value: operationID)
        .withPublic(key: "sourceType", value: source.type.rawValue)
        .withPublic(key: "destinationType", value: destination.type.rawValue)
        .withPublic(key: "verificationDepth", value: options.depth.rawValue)
    )

    // Create the command using the factory
    let command=commandFactory.createVerifyConsistencyCommand(
      operationID: operationID,
      source: source,
      destination: destination,
      options: options
    )

    // Execute the command
    return try await command.execute(context: context)
  }
}
