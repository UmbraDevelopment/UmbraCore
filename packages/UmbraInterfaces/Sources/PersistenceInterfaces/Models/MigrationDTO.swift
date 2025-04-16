import Foundation

/**
 Type of migration operation.
 */
public enum MigrationType: String, Codable {
  /// Adding a new schema element (table, column, index)
  case addSchema

  /// Removing a schema element
  case removeSchema

  /// Altering an existing schema element
  case alterSchema

  /// Data transformation (changing data without schema changes)
  case transformData

  /// Repair operation to fix inconsistencies
  case repair

  /// Custom operation defined by the migration
  case custom
}

/**
 Data Transfer Object for database migrations.

 This DTO encapsulates information about a database migration,
 including version information and operations to perform.
 */
public struct MigrationDTO: Codable, Identifiable, Equatable {
  /// Unique identifier for the migration
  public let id: String

  /// Human-readable name for the migration
  public let name: String

  /// Source schema version number
  public let fromVersion: Int

  /// Target schema version number
  public let toVersion: Int

  /// Type of migration operation
  public let type: MigrationType

  /// SQL statements to execute (if applicable)
  public let sqlStatements: [String]?

  /// Custom transformation code identifier (if applicable)
  public let transformationKey: String?

  /// Whether this migration is reversible
  public let isReversible: Bool

  /// Optional script or code for reversing the migration
  public let revertScript: String?

  /// Whether this migration should run in a transaction
  public let useTransaction: Bool

  /// Timestamp when this migration was created
  public let createdAt: Date

  /// Dependencies (IDs of migrations that must be applied first)
  public let dependencies: [String]?

  /// Additional metadata for the migration
  public let metadata: [String: String]

  /**
   Initialises a new migration DTO.

   - Parameters:
      - id: Unique identifier for the migration
      - name: Human-readable name for the migration
      - fromVersion: Source schema version number
      - toVersion: Target schema version number
      - type: Type of migration operation
      - sqlStatements: SQL statements to execute (if applicable)
      - transformationKey: Custom transformation code identifier (if applicable)
      - isReversible: Whether this migration is reversible
      - revertScript: Optional script or code for reversing the migration
      - useTransaction: Whether this migration should run in a transaction
      - createdAt: Timestamp when this migration was created
      - dependencies: Dependencies (IDs of migrations that must be applied first)
      - metadata: Additional metadata for the migration
   */
  public init(
    id: String=UUID().uuidString,
    name: String,
    fromVersion: Int,
    toVersion: Int,
    type: MigrationType,
    sqlStatements: [String]?=nil,
    transformationKey: String?=nil,
    isReversible: Bool=false,
    revertScript: String?=nil,
    useTransaction: Bool=true,
    createdAt: Date=Date(),
    dependencies: [String]?=nil,
    metadata: [String: String]=[:]
  ) {
    self.id=id
    self.name=name
    self.fromVersion=fromVersion
    self.toVersion=toVersion
    self.type=type
    self.sqlStatements=sqlStatements
    self.transformationKey=transformationKey
    self.isReversible=isReversible
    self.revertScript=revertScript
    self.useTransaction=useTransaction
    self.createdAt=createdAt
    self.dependencies=dependencies
    self.metadata=metadata
  }
}

/**
 Result of a migration operation.
 */
public struct MigrationResultDTO: Codable, Equatable {
  /// Whether the migration was successful
  public let success: Bool

  /// The migration that was executed
  public let migration: MigrationDTO

  /// Time taken to execute the migration (in seconds)
  public let executionTime: TimeInterval

  /// Current schema version after migration
  public let currentVersion: Int

  /// Any warnings that occurred during migration
  public let warnings: [String]

  /// Error details if the migration failed
  public let error: String?

  /**
   Initialises a new migration result DTO.

   - Parameters:
      - success: Whether the migration was successful
      - migration: The migration that was executed
      - executionTime: Time taken to execute the migration (in seconds)
      - currentVersion: Current schema version after migration
      - warnings: Any warnings that occurred during migration
      - error: Error details if the migration failed
   */
  public init(
    success: Bool,
    migration: MigrationDTO,
    executionTime: TimeInterval,
    currentVersion: Int,
    warnings: [String]=[],
    error: String?=nil
  ) {
    self.success=success
    self.migration=migration
    self.executionTime=executionTime
    self.currentVersion=currentVersion
    self.warnings=warnings
    self.error=error
  }
}
