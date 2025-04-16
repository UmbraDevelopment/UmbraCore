import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Command for creating a new item in persistent storage.

 This command encapsulates the logic for creating a new persistable item,
 following the command pattern architecture.
 */
public class CreateItemCommand<T: Persistable>: BasePersistenceCommand, PersistenceCommand {
  /// The result type for this command
  public typealias ResultType=T

  /// The item to create
  private let item: T

  /**
   Initialises a new create item command.

   - Parameters:
      - item: The item to create
      - provider: Provider for persistence operations
      - logger: Logger instance for logging operations
   */
  public init(
    item: T,
    provider: PersistenceProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.item=item
    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the create item command.

   - Parameters:
      - context: The persistence context for the operation
   - Returns: The created item with any generated fields
   - Throws: PersistenceError if the operation fails
   */
  public func execute(context _: PersistenceContextDTO) async throws -> T {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "createItem",
      entityType: T.typeIdentifier,
      entityID: item.id,
      additionalMetadata: [
        ("timestamp", (value: "\(Date())", privacyLevel: .public))
      ]
    )

    // Log operation start
    await logOperationStart(operation: "createItem", context: operationContext)

    do {
      // Verify that an item with the same ID doesn't already exist
      if let _=try? await provider.read(id: item.id, type: T.self) {
        throw PersistenceError.itemAlreadyExists(
          "Cannot create item of type \(T.typeIdentifier) with ID \(item.id): already exists"
        )
      }

      // Create the item using the provider
      let createdItem=try await provider.create(item: item)

      // Log success
      await logOperationSuccess(
        operation: "createItem",
        context: operationContext,
        additionalMetadata: [
          ("itemId", (value: createdItem.id, privacyLevel: .public))
        ]
      )

      return createdItem

    } catch let error as PersistenceError {
      // Log failure
      await logOperationFailure(
        operation: "createItem",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to PersistenceError
      let persistenceError=PersistenceError.general(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "createItem",
        error: persistenceError,
        context: operationContext
      )

      throw persistenceError
    }
  }
}
