import Foundation
import PersistenceInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Command for updating an existing item in persistent storage.
 
 This command encapsulates the logic for updating a persistable item,
 following the command pattern architecture.
 */
public class UpdateItemCommand<T: Persistable>: BasePersistenceCommand, PersistenceCommand {
    /// The result type for this command
    public typealias ResultType = T
    
    /// The item to update
    private let item: T
    
    /**
     Initialises a new update item command.
     
     - Parameters:
        - item: The item to update
        - provider: Provider for persistence operations
        - logger: Logger instance for logging operations
     */
    public init(
        item: T,
        provider: PersistenceProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.item = item
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the update item command.
     
     - Parameters:
        - context: The persistence context for the operation
     - Returns: The updated item
     - Throws: PersistenceError if the operation fails
     */
    public func execute(context: PersistenceContextDTO) async throws -> T {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "updateItem",
            entityType: T.typeIdentifier,
            entityId: item.id,
            additionalMetadata: [
                ("timestamp", (value: "\(Date())", privacyLevel: .public))
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "updateItem", context: operationContext)
        
        do {
            // Check if the item exists
            guard let _ = try await provider.read(id: item.id, type: T.self) else {
                throw PersistenceError.itemNotFound(
                    "Cannot update item of type \(T.typeIdentifier) with ID \(item.id): not found"
                )
            }
            
            // Update the item using the provider
            let updatedItem = try await provider.update(item: item)
            
            // Log success
            await logOperationSuccess(
                operation: "updateItem",
                context: operationContext,
                additionalMetadata: [
                    ("itemId", (value: updatedItem.id, privacyLevel: .public)),
                    ("newVersion", (value: String(updatedItem.version), privacyLevel: .public))
                ]
            )
            
            return updatedItem
            
        } catch let error as PersistenceError {
            // Log failure
            await logOperationFailure(
                operation: "updateItem",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to PersistenceError
            let persistenceError = PersistenceError.general(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "updateItem",
                error: persistenceError,
                context: operationContext
            )
            
            throw persistenceError
        }
    }
}
