import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Command for executing operations within a transaction.

 This command encapsulates the logic for transaction management,
 following the command pattern architecture.
 */
public class TransactionCommand<T>: BasePersistenceCommand, PersistenceCommand {
  /// The result type for this command
  public typealias ResultType=T

  /// The operations to execute within the transaction
  private let operations: (PersistenceProviderProtocol) async throws -> T

  /// Name of the transaction for logging
  private let transactionName: String

  /**
   Initialises a new transaction command.

   - Parameters:
      - transactionName: Name of the transaction for logging
      - operations: The operations to execute within the transaction
      - provider: Provider for persistence operations
      - logger: Logger instance for logging operations
   */
  public init(
    transactionName: String,
    operations: @escaping (PersistenceProviderProtocol) async throws -> T,
    provider: PersistenceProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.transactionName=transactionName
    self.operations=operations
    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the transaction command.

   - Parameters:
      - context: The persistence context for the operation
   - Returns: The result of the operations
   - Throws: PersistenceError if the transaction fails
   */
  public func execute(context _: PersistenceContextDTO) async throws -> T {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "transaction",
      entityType: "Transaction",
      additionalMetadata: [
        ("transactionName", (value: transactionName, privacyLevel: .public)),
        ("timestamp", (value: "\(Date())", privacyLevel: .public))
      ]
    )

    // Log operation start
    await logOperationStart(operation: "transaction", context: operationContext)

    do {
      // Begin transaction
      try await provider.beginTransaction()

      await logger.log(
        .debug,
        "Transaction '\(transactionName)' started",
        context: operationContext
      )

      do {
        // Execute the operations
        let result=try await operations(provider)

        // Commit transaction
        try await provider.commitTransaction()

        // Log success
        await logOperationSuccess(
          operation: "transaction",
          context: operationContext,
          additionalMetadata: [
            ("status", (value: "committed", privacyLevel: .public))
          ]
        )

        return result

      } catch {
        // Rollback transaction on error
        do {
          try await provider.rollbackTransaction()

          await logger.log(
            .warning,
            "Transaction '\(transactionName)' rolled back due to error: \(error.localizedDescription)",
            context: operationContext
          )

        } catch let rollbackError {
          await logger.log(
            .error,
            "Failed to rollback transaction '\(transactionName)': \(rollbackError.localizedDescription)",
            context: operationContext
          )
        }

        // Re-throw the original error
        throw error
      }

    } catch let error as PersistenceError {
      // Log failure
      await logOperationFailure(
        operation: "transaction",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to PersistenceError
      let persistenceError=PersistenceError.transactionFailed(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "transaction",
        error: persistenceError,
        context: operationContext
      )

      throw persistenceError
    }
  }
}
