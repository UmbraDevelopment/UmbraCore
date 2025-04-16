import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Actor implementation of the persistence service.

 This actor provides a thread-safe implementation of persistence operations
 using the command pattern and Swift's actor model for concurrency safety.
 */
public actor PersistenceServicesActor {
  /// Factory for creating persistence commands
  private let commandFactory: PersistenceCommandFactory

  /// Logger for operation logging
  private let logger: PrivacyAwareLoggingProtocol

  /**
   Initialises a new persistence services actor.

   - Parameters:
      - commandFactory: Factory for creating persistence commands
      - logger: Logger for operation logging
   */
  public init(
    commandFactory: PersistenceCommandFactory,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.commandFactory=commandFactory
    self.logger=logger
  }

  // MARK: - CRUD Operations

  /**
   Creates a new item in persistent storage.

   - Parameters:
      - item: The item to create
      - context: Optional context for the operation
   - Returns: The created item with any generated fields
   - Throws: PersistenceError if the operation fails
   */
  public func createItem<T: Persistable>(
    _ item: T,
    context: PersistenceContextDTO?=nil
  ) async throws -> T {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "createItem",
      category: "PersistenceService"
    )

    let command=commandFactory.createCreateCommand(item: item)
    return try await command.execute(context: operationContext)
  }

  /**
   Reads an item from persistent storage.

   - Parameters:
      - id: The ID of the item to read
      - type: The type of the item to read
      - context: Optional context for the operation
   - Returns: The requested item, or nil if not found
   - Throws: PersistenceError if the operation fails
   */
  public func readItem<T: Persistable>(
    id: String,
    type _: T.Type,
    context: PersistenceContextDTO?=nil
  ) async throws -> T? {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "readItem",
      category: "PersistenceService"
    )

    let command=commandFactory.createReadCommand(id: id) as ReadItemCommand<T>
    return try await command.execute(context: operationContext)
  }

  /**
   Updates an existing item in persistent storage.

   - Parameters:
      - item: The item to update
      - context: Optional context for the operation
   - Returns: The updated item
   - Throws: PersistenceError if the operation fails
   */
  public func updateItem<T: Persistable>(
    _ item: T,
    context: PersistenceContextDTO?=nil
  ) async throws -> T {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "updateItem",
      category: "PersistenceService"
    )

    let command=commandFactory.createUpdateCommand(item: item)
    return try await command.execute(context: operationContext)
  }

  /**
   Deletes an item from persistent storage.

   - Parameters:
      - id: The ID of the item to delete
      - type: The type of the item to delete
      - hardDelete: Whether to perform a hard delete
      - context: Optional context for the operation
   - Returns: Whether the deletion was successful
   - Throws: PersistenceError if the operation fails
   */
  public func deleteItem<T: Persistable>(
    id: String,
    type _: T.Type,
    hardDelete: Bool=false,
    context: PersistenceContextDTO?=nil
  ) async throws -> Bool {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "deleteItem",
      category: "PersistenceService"
    )

    let command=commandFactory.createDeleteCommand(
      id: id,
      hardDelete: hardDelete
    ) as DeleteItemCommand<T>

    return try await command.execute(context: operationContext)
  }

  // MARK: - Query Operations

  /**
   Queries items matching specified criteria.

   - Parameters:
      - type: The type of items to query
      - options: Options for the query
      - context: Optional context for the operation
   - Returns: Array of matching items
   - Throws: PersistenceError if the operation fails
   */
  public func queryItems<T: Persistable>(
    type _: T.Type,
    options: QueryOptionsDTO = .default,
    context: PersistenceContextDTO?=nil
  ) async throws -> [T] {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "queryItems",
      category: "PersistenceService"
    )

    let command=commandFactory.createQueryCommand(
      options: options
    ) as QueryItemsCommand<T>

    return try await command.execute(context: operationContext)
  }

  /**
   Executes operations within a transaction.

   - Parameters:
      - transactionName: Name of the transaction for logging
      - context: Optional context for the operation
      - operations: The operations to execute within the transaction
   - Returns: The result of the operations
   - Throws: PersistenceError if the transaction fails
   */
  public func executeInTransaction<T>(
    transactionName: String,
    context: PersistenceContextDTO?=nil,
    operations: @escaping (PersistenceProviderProtocol) async throws -> T
  ) async throws -> T {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "transaction",
      category: "PersistenceService"
    )

    let command=commandFactory.createTransactionCommand(
      transactionName: transactionName,
      operations: operations
    )

    return try await command.execute(context: operationContext)
  }

  // MARK: - Migration Operations

  /**
   Applies a schema migration.

   - Parameters:
      - migration: The migration to apply
      - context: Optional context for the operation
   - Returns: The result of the migration
   - Throws: PersistenceError if the operation fails
   */
  public func applyMigration(
    migration: MigrationDTO,
    context: PersistenceContextDTO?=nil
  ) async throws -> MigrationResultDTO {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "applyMigration",
      category: "PersistenceService"
    )

    let command=commandFactory.createMigrationCommand(migration: migration)
    return try await command.execute(context: operationContext)
  }

  /**
   Gets the current schema version.

   - Returns: The current schema version
   - Throws: PersistenceError if the operation fails
   */
  public func getCurrentSchemaVersion() async throws -> Int {
    try await commandFactory.provider.getCurrentSchemaVersion()
  }

  /**
   Gets the history of applied migrations.

   - Returns: Array of applied migrations
   - Throws: PersistenceError if the operation fails
   */
  public func getMigrationHistory() async throws -> [MigrationDTO] {
    try await commandFactory.provider.getMigrationHistory()
  }

  // MARK: - Backup Operations

  /**
   Creates a backup of the database.

   - Parameters:
      - options: Options for the backup
      - context: Optional context for the operation
   - Returns: The result of the backup operation
   - Throws: PersistenceError if the operation fails
   */
  public func createBackup(
    options: BackupOptionsDTO = .default,
    context: PersistenceContextDTO?=nil
  ) async throws -> BackupResultDTO {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "createBackup",
      category: "PersistenceService"
    )

    let command=commandFactory.createBackupCommand(options: options)
    return try await command.execute(context: operationContext)
  }

  /**
   Restores the database from a backup.

   - Parameters:
      - backupUrl: URL to the backup
      - password: Optional password if the backup is encrypted
      - snapshotId: Optional snapshot ID for Restic backups
      - verify: Whether to verify data integrity after restore
      - context: Optional context for the operation
   - Returns: Whether the restore was successful
   - Throws: PersistenceError if the operation fails
   */
  public func restoreFromBackup(
    backupURL: URL,
    password: String?=nil,
    snapshotID: String?=nil,
    verify: Bool=true,
    context: PersistenceContextDTO?=nil
  ) async throws -> Bool {
    let operationContext=context ?? PersistenceContextDTO(
      operation: "restoreBackup",
      category: "PersistenceService"
    )

    let command=commandFactory.createRestoreCommand(
      backupURL: backupURL,
      password: password,
      snapshotID: snapshotID,
      verify: verify
    )

    return try await command.execute(context: operationContext)
  }

  // MARK: - File Operations

  /**
   Saves data to a file in the database's secure storage area.

   - Parameters:
      - data: The data to save
      - filename: Name of the file
      - inDirectory: Optional subdirectory
      - context: Optional context for the operation
   - Returns: URL where the file was saved
   - Throws: PersistenceError if the operation fails
   */
  public func saveToSecureFile(
    data: Data,
    filename: String,
    inDirectory: String?=nil,
    context: PersistenceContextDTO?=nil
  ) async throws -> URL {
    // Create operation context with metadata
    let operationContext=context ?? PersistenceContextDTO(
      operation: "saveToSecureFile",
      category: "PersistenceService",
      metadata: MetadataDTOCollection()
        .withItem(key: "filename", value: "Value", sensitivity: .protected)
        .withItem(key: "dataSize", value: "\(data.count)", sensitivity: .public)
    )

    // Log operation start
    await logger.log(
      .debug,
      "Saving data to secure file: \(filename)",
      context: LogContextDTO(
        operation: operationContext.operation,
        category: operationContext.category,
        metadata: LogMetadataDTOCollection().withProtected(
          key: "filename", value: filename
        )
      )
    )

    do {
      let fileURL=try await commandFactory.provider.saveToSecureFile(
        data: data,
        filename: filename,
        inDirectory: inDirectory
      )

      // Log success
      await logger.log(
        .info,
        "Successfully saved data to secure file",
        context: LogContextDTO(
          operation: operationContext.operation,
          category: operationContext.category,
          metadata: LogMetadataDTOCollection()
            .withProtected(key: "filePath", value: fileURL.path)
            .withPublic(key: "dataSize", value: "\(data.count)")
        )
      )

      return fileURL

    } catch {
      // Log failure
      await logger.log(
        .error,
        "Failed to save data to secure file: \(error.localizedDescription)",
        context: LogContextDTO(
          operation: operationContext.operation,
          category: operationContext.category,
          metadata: LogMetadataDTOCollection()
            .withProtected(key: "filename", value: filename)
            .withProtected(key: "error", value: error.localizedDescription)
        )
      )

      throw error
    }
  }

  /**
   Reads data from a file in the database's secure storage area.

   - Parameters:
      - filename: Name of the file
      - inDirectory: Optional subdirectory
      - context: Optional context for the operation
   - Returns: The file contents
   - Throws: PersistenceError if the operation fails
   */
  public func readFromSecureFile(
    filename: String,
    inDirectory: String?=nil,
    context: PersistenceContextDTO?=nil
  ) async throws -> Data {
    // Create operation context with metadata
    let operationContext=context ?? PersistenceContextDTO(
      operation: "readFromSecureFile",
      category: "PersistenceService",
      metadata: MetadataDTOCollection()
        .withItem(key: "filename", value: filename, sensitivity: .protected)
    )

    // Log operation start
    await logger.log(
      .debug,
      "Reading data from secure file: \(filename)",
      context: LogContextDTO(
        operation: operationContext.operation,
        category: operationContext.category,
        metadata: LogMetadataDTOCollection().withProtected(
          key: "filename", value: filename
        )
      )
    )

    do {
      let fileData=try await commandFactory.provider.readFromSecureFile(
        filename: filename,
        inDirectory: inDirectory
      )

      // Log success
      await logger.log(
        .info,
        "Successfully read data from secure file",
        context: LogContextDTO(
          operation: operationContext.operation,
          category: operationContext.category,
          metadata: LogMetadataDTOCollection()
            .withProtected(key: "filename", value: filename)
            .withPublic(key: "dataSize", value: "\(fileData.count)")
        )
      )

      return fileData

    } catch {
      // Log failure
      await logger.log(
        .error,
        "Failed to read data from secure file: \(error.localizedDescription)",
        context: LogContextDTO(
          operation: operationContext.operation,
          category: operationContext.category,
          metadata: LogMetadataDTOCollection()
            .withProtected(key: "filename", value: filename)
            .withProtected(key: "error", value: error.localizedDescription)
        )
      )

      throw error
    }
  }
}
