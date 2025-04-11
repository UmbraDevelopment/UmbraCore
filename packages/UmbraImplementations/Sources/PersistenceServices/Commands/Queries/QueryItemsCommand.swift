import Foundation
import PersistenceInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Command for querying items from persistent storage.
 
 This command encapsulates the logic for retrieving multiple items with filtering,
 sorting and pagination options, following the command pattern architecture.
 */
public class QueryItemsCommand<T: Persistable>: BasePersistenceCommand, PersistenceCommand {
    /// The result type for this command
    public typealias ResultType = [T]
    
    /// Options for the query
    private let options: QueryOptionsDTO
    
    /**
     Initialises a new query items command.
     
     - Parameters:
        - options: Options for the query
        - provider: Provider for persistence operations
        - logger: Logger instance for logging operations
     */
    public init(
        options: QueryOptionsDTO = .default,
        provider: PersistenceProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.options = options
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the query items command.
     
     - Parameters:
        - context: The persistence context for the operation
     - Returns: Array of matching items
     - Throws: PersistenceError if the operation fails
     */
    public func execute(context: PersistenceContextDTO) async throws -> [T] {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "queryItems",
            entityType: T.typeIdentifier,
            additionalMetadata: [
                ("hasFilter", (value: String(options.filter != nil), privacyLevel: .public)),
                ("limit", (value: options.limit.map(String.init) ?? "none", privacyLevel: .public)),
                ("offset", (value: options.offset.map(String.init) ?? "0", privacyLevel: .public)),
                ("includeDeleted", (value: String(options.includeDeleted), privacyLevel: .public))
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "queryItems", context: operationContext)
        
        do {
            // Query items using the provider
            let items = try await provider.query(type: T.self, options: options)
            
            // Log success
            await logOperationSuccess(
                operation: "queryItems",
                context: operationContext,
                additionalMetadata: [
                    ("itemCount", (value: String(items.count), privacyLevel: .public))
                ]
            )
            
            return items
            
        } catch let error as PersistenceError {
            // Log failure
            await logOperationFailure(
                operation: "queryItems",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to PersistenceError
            let persistenceError = PersistenceError.invalidQuery(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "queryItems",
                error: persistenceError,
                context: operationContext
            )
            
            throw persistenceError
        }
    }
}
