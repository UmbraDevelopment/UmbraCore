import Foundation
import PersistenceInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Factory for creating persistence commands.
 
 This class centralises the creation of persistence commands,
 ensuring consistent initialisation and dependencies.
 */
public class PersistenceCommandFactory {
    /// Provider for persistence operations
    private let provider: PersistenceProviderProtocol
    
    /// Logger for operation logging
    private let logger: PrivacyAwareLoggingProtocol
    
    /**
     Initialises a new persistence command factory.
     
     - Parameters:
        - provider: Provider for persistence operations
        - logger: Logger for operation logging
     */
    public init(
        provider: PersistenceProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.provider = provider
        self.logger = logger
    }
    
    // MARK: - CRUD Commands
    
    /**
     Creates a command for creating a new item.
     
     - Parameters:
        - item: The item to create
     - Returns: The create item command
     */
    public func createCreateCommand<T: Persistable>(item: T) -> CreateItemCommand<T> {
        return CreateItemCommand(
            item: item,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for reading an item.
     
     - Parameters:
        - id: The ID of the item to read
     - Returns: The read item command
     */
    public func createReadCommand<T: Persistable>(id: String) -> ReadItemCommand<T> {
        return ReadItemCommand(
            id: id,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for updating an item.
     
     - Parameters:
        - item: The item to update
     - Returns: The update item command
     */
    public func createUpdateCommand<T: Persistable>(item: T) -> UpdateItemCommand<T> {
        return UpdateItemCommand(
            item: item,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for deleting an item.
     
     - Parameters:
        - id: The ID of the item to delete
        - hardDelete: Whether to perform a hard delete
     - Returns: The delete item command
     */
    public func createDeleteCommand<T: Persistable>(
        id: String,
        hardDelete: Bool = false
    ) -> DeleteItemCommand<T> {
        return DeleteItemCommand(
            id: id,
            hardDelete: hardDelete,
            provider: provider,
            logger: logger
        )
    }
    
    // MARK: - Query Commands
    
    /**
     Creates a command for querying items.
     
     - Parameters:
        - options: Options for the query
     - Returns: The query items command
     */
    public func createQueryCommand<T: Persistable>(
        options: QueryOptionsDTO = .default
    ) -> QueryItemsCommand<T> {
        return QueryItemsCommand(
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    // MARK: - Transaction Commands
    
    /**
     Creates a command for executing operations in a transaction.
     
     - Parameters:
        - transactionName: Name of the transaction for logging
        - operations: The operations to execute within the transaction
     - Returns: The transaction command
     */
    public func createTransactionCommand<T>(
        transactionName: String,
        operations: @escaping (PersistenceProviderProtocol) async throws -> T
    ) -> TransactionCommand<T> {
        return TransactionCommand(
            transactionName: transactionName,
            operations: operations,
            provider: provider,
            logger: logger
        )
    }
    
    // MARK: - Migration Commands
    
    /**
     Creates a command for applying a migration.
     
     - Parameters:
        - migration: The migration to apply
     - Returns: The apply migration command
     */
    public func createMigrationCommand(
        migration: MigrationDTO
    ) -> ApplyMigrationCommand {
        return ApplyMigrationCommand(
            migration: migration,
            provider: provider,
            logger: logger
        )
    }
    
    // MARK: - Backup Commands
    
    /**
     Creates a command for creating a backup.
     
     - Parameters:
        - options: Options for the backup
     - Returns: The create backup command
     */
    public func createBackupCommand(
        options: BackupOptionsDTO = .default
    ) -> CreateBackupCommand {
        return CreateBackupCommand(
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for restoring from a backup.
     
     - Parameters:
        - backupUrl: URL to the backup
        - password: Optional password for encrypted backups
        - snapshotId: Optional snapshot ID for Restic backups
        - verify: Whether to verify data integrity after restore
     - Returns: The restore backup command
     */
    public func createRestoreCommand(
        backupUrl: URL,
        password: String? = nil,
        snapshotId: String? = nil,
        verify: Bool = true
    ) -> RestoreBackupCommand {
        return RestoreBackupCommand(
            backupUrl: backupUrl,
            password: password,
            snapshotId: snapshotId,
            verify: verify,
            provider: provider,
            logger: logger
        )
    }
}
