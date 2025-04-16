import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Command for reading an existing item from persistent storage.

 This command encapsulates the logic for retrieving a persistable item,
 following the command pattern architecture.
 */
public class ReadItemCommand<T: Persistable>: BasePersistenceCommand, PersistenceCommand {
  /// The result type for this command
  public typealias ResultType=T?

  /// The ID of the item to read
  private let id: String

  /**
   Initialises a new read item command.

   - Parameters:
      - id: The ID of the item to read
      - provider: Provider for persistence operations
      - logger: Logger instance for logging operations
   */
  public init(
    id: String,
    provider: PersistenceProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.id=id
    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the read item command.

   - Parameters:
      - context: The persistence context for the operation
   - Returns: The requested item, or nil if not found
   - Throws: PersistenceError if the operation fails
   */
  public func execute(context _: PersistenceContextDTO) async throws -> T? {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "readItem",
      entityType: T.typeIdentifier,
      entityID: id
    )

    // Log operation start
    await logOperationStart(operation: "readItem", context: operationContext)

    do {
      // Read the item using the provider
      let item=try await provider.read(id: id, type: T.self)

      // Log success or not found
      if item != nil {
        await logOperationSuccess(
          operation: "readItem",
          context: operationContext,
          additionalMetadata: [
            ("found", (value: "true", privacyLevel: .public))
          ]
        )
      } else {
        await logger.log(
          .debug,
          "Item not found: \(T.typeIdentifier) with ID \(id)",
          context: operationContext
        )
      }

      return item

    } catch let error as PersistenceError {
      // Log failure
      await logOperationFailure(
        operation: "readItem",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to PersistenceError
      let persistenceError=PersistenceError.general(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "readItem",
        error: persistenceError,
        context: operationContext
      )

      throw persistenceError
    }
  }
}
