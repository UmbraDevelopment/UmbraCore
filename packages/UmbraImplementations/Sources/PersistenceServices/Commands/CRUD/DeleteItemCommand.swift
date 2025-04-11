import Foundation
import PersistenceInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Command for deleting an item from persistent storage.
 
 This command encapsulates the logic for removing a persistable item,
 following the command pattern architecture.
 */
public class DeleteItemCommand<T: Persistable>: BasePersistenceCommand, PersistenceCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The ID of the item to delete
    private let id: String
    
    /// Whether to perform a hard delete (true) or soft delete (false)
    private let hardDelete: Bool
    
    /**
     Initialises a new delete item command.
     
     - Parameters:
        - id: The ID of the item to delete
        - hardDelete: Whether to perform a hard delete (true) or soft delete (false)
        - provider: Provider for persistence operations
        - logger: Logger instance for logging operations
     */
    public init(
        id: String,
        hardDelete: Bool = false,
        provider: PersistenceProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.id = id
        self.hardDelete = hardDelete
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the delete item command.
     
     - Parameters:
        - context: The persistence context for the operation
     - Returns: Whether the deletion was successful
     - Throws: PersistenceError if the operation fails
     */
    public func execute(context: PersistenceContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "deleteItem",
            entityType: T.typeIdentifier,
            entityId: id,
            additionalMetadata: [
                ("hardDelete", (value: String(hardDelete), privacyLevel: .public)),
                ("timestamp", (value: "\(Date())", privacyLevel: .public))
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "deleteItem", context: operationContext)
        
        do {
            // Check if the item exists
            guard let _ = try await provider.read(id: id, type: T.self) else {
                throw PersistenceError.itemNotFound(
                    "Cannot delete item of type \(T.typeIdentifier) with ID \(id): not found"
                )
            }
            
            // Delete the item using the provider
            let success = try await provider.delete(id: id, type: T.self)
            
            // Log success or failure
            if success {
                await logOperationSuccess(
                    operation: "deleteItem",
                    context: operationContext,
                    additionalMetadata: [
                        ("deleteType", (value: hardDelete ? "hard" : "soft", privacyLevel: .public))
                    ]
                )
            } else {
                await logger.log(
                    .warning,
                    "Delete operation did not report success for item of type \(T.typeIdentifier) with ID \(id)",
                    context: operationContext
                )
            }
            
            return success
            
        } catch let error as PersistenceError {
            // Log failure
            await logOperationFailure(
                operation: "deleteItem",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to PersistenceError
            let persistenceError = PersistenceError.general(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "deleteItem",
                error: persistenceError,
                context: operationContext
            )
            
            throw persistenceError
        }
    }
}
