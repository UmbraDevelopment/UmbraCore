import Foundation

/**
 Protocol defining the operations that must be supported by persistence providers.
 
 This protocol abstracts the underlying storage mechanism, allowing for
 multiple implementations with different storage technologies.
 */
public protocol PersistenceProviderProtocol {
    // MARK: - CRUD Operations
    
    /**
     Creates a new item in persistent storage.
     
     - Parameters:
        - item: The item to create
     - Returns: The created item with any generated fields
     - Throws: PersistenceError if the operation fails
     */
    func create<T: Persistable>(item: T) async throws -> T
    
    /**
     Reads an item from persistent storage.
     
     - Parameters:
        - id: The ID of the item to read
        - type: The type of the item to read
     - Returns: The requested item, or nil if not found
     - Throws: PersistenceError if the operation fails
     */
    func read<T: Persistable>(id: String, type: T.Type) async throws -> T?
    
    /**
     Updates an existing item in persistent storage.
     
     - Parameters:
        - item: The item to update
     - Returns: The updated item
     - Throws: PersistenceError if the operation fails
     */
    func update<T: Persistable>(item: T) async throws -> T
    
    /**
     Deletes an item from persistent storage.
     
     - Parameters:
        - id: The ID of the item to delete
        - type: The type of the item to delete
     - Returns: Whether the deletion was successful
     - Throws: PersistenceError if the operation fails
     */
    func delete<T: Persistable>(id: String, type: T.Type) async throws -> Bool
    
    // MARK: - Query Operations
    
    /**
     Queries items matching specified criteria.
     
     - Parameters:
        - type: The type of items to query
        - options: Options for the query
     - Returns: Array of matching items
     - Throws: PersistenceError if the operation fails
     */
    func query<T: Persistable>(type: T.Type, options: QueryOptionsDTO) async throws -> [T]
    
    /**
     Counts items matching specified criteria.
     
     - Parameters:
        - type: The type of items to count
        - filter: Optional filter criteria
     - Returns: Count of matching items
     - Throws: PersistenceError if the operation fails
     */
    func count<T: Persistable>(type: T.Type, filter: [String: Any]?) async throws -> Int
    
    // MARK: - Transactions
    
    /**
     Begins a transaction.
     
     - Throws: PersistenceError if the operation fails
     */
    func beginTransaction() async throws
    
    /**
     Commits the current transaction.
     
     - Throws: PersistenceError if the operation fails
     */
    func commitTransaction() async throws
    
    /**
     Rolls back the current transaction.
     
     - Throws: PersistenceError if the operation fails
     */
    func rollbackTransaction() async throws
    
    /**
     Executes operations within a transaction.
     
     - Parameters:
        - operations: The operations to execute within the transaction
     - Returns: The result of the operations
     - Throws: PersistenceError if the operation fails
     */
    func inTransaction<T>(_ operations: () async throws -> T) async throws -> T
    
    // MARK: - Migrations
    
    /**
     Applies a schema migration.
     
     - Parameters:
        - migration: The migration to apply
     - Returns: The result of the migration
     - Throws: PersistenceError if the operation fails
     */
    func applyMigration(migration: MigrationDTO) async throws -> MigrationResultDTO
    
    /**
     Gets the current schema version.
     
     - Returns: The current schema version
     - Throws: PersistenceError if the operation fails
     */
    func getCurrentSchemaVersion() async throws -> Int
    
    /**
     Gets the history of applied migrations.
     
     - Returns: Array of applied migrations
     - Throws: PersistenceError if the operation fails
     */
    func getMigrationHistory() async throws -> [MigrationDTO]
    
    // MARK: - Backup and Restore
    
    /**
     Prepares the database for backup.
     
     - Returns: URL to the prepared backup location
     - Throws: PersistenceError if the operation fails
     */
    func prepareForBackup() async throws -> URL
    
    /**
     Creates a backup of the database.
     
     - Parameters:
        - options: Options for the backup
     - Returns: The result of the backup operation
     - Throws: PersistenceError if the operation fails
     */
    func createBackup(options: BackupOptionsDTO) async throws -> BackupResultDTO
    
    /**
     Restores the database from a backup.
     
     - Parameters:
        - url: URL to the backup
        - password: Optional password if the backup is encrypted
     - Returns: Whether the restore was successful
     - Throws: PersistenceError if the operation fails
     */
    func restoreFromBackup(url: URL, password: String?) async throws -> Bool
    
    // MARK: - File Operations
    
    /**
     Gets a URL for a file in the database's secure storage area.
     
     - Parameters:
        - filename: Name of the file
        - inDirectory: Optional subdirectory
        - create: Whether to create the directory if it doesn't exist
     - Returns: URL to the file
     - Throws: PersistenceError if the operation fails
     */
    func getSecureFileURL(filename: String, inDirectory: String?, create: Bool) async throws -> URL
    
    /**
     Saves data to a file in the database's secure storage area.
     
     - Parameters:
        - data: The data to save
        - filename: Name of the file
        - inDirectory: Optional subdirectory
     - Returns: URL where the file was saved
     - Throws: PersistenceError if the operation fails
     */
    func saveToSecureFile(data: Data, filename: String, inDirectory: String?) async throws -> URL
    
    /**
     Reads data from a file in the database's secure storage area.
     
     - Parameters:
        - filename: Name of the file
        - inDirectory: Optional subdirectory
     - Returns: The file contents
     - Throws: PersistenceError if the operation fails
     */
    func readFromSecureFile(filename: String, inDirectory: String?) async throws -> Data
}
