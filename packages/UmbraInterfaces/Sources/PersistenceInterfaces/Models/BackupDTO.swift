import Foundation

/**
 Type of backup operation.
 */
public enum BackupType: String, Codable {
  /// Full backup of all data
  case full

  /// Incremental backup of changes since last backup
  case incremental

  /// Differential backup of changes since last full backup
  case differential
}

/**
 Options for backup operations.
 */
public struct BackupOptionsDTO: Codable, Equatable {
  /// Type of backup to perform
  public let type: BackupType

  /// Whether to compress the backup
  public let compress: Bool

  /// Whether to encrypt the backup
  public let encrypt: Bool

  /// Password for encryption (if enabled)
  public let encryptionPassword: String?

  /// Whether to verify the backup after creation
  public let verify: Bool

  /// Repository location (for Restic backups)
  public let repositoryLocation: String?

  /// Tags to apply to the backup
  public let tags: [String]

  /// Additional metadata for the backup
  public let metadata: [String: String]

  /**
   Initialises a new backup options DTO.

   - Parameters:
      - type: Type of backup to perform
      - compress: Whether to compress the backup
      - encrypt: Whether to encrypt the backup
      - encryptionPassword: Password for encryption (if enabled)
      - verify: Whether to verify the backup after creation
      - repositoryLocation: Repository location (for Restic backups)
      - tags: Tags to apply to the backup
      - metadata: Additional metadata for the backup
   */
  public init(
    type: BackupType = .full,
    compress: Bool=true,
    encrypt: Bool=false,
    encryptionPassword: String?=nil,
    verify: Bool=true,
    repositoryLocation: String?=nil,
    tags: [String]=[],
    metadata: [String: String]=[:]
  ) {
    self.type=type
    self.compress=compress
    self.encrypt=encrypt
    self.encryptionPassword=encryptionPassword
    self.verify=verify
    self.repositoryLocation=repositoryLocation
    self.tags=tags
    self.metadata=metadata
  }

  /// Default backup options
  public static var `default`: BackupOptionsDTO {
    BackupOptionsDTO()
  }
}

/**
 Result of a backup operation.
 */
public struct BackupResultDTO: Codable, Equatable {
  /// Whether the backup was successful
  public let success: Bool

  /// The ID of the backup (snapshot ID in Restic)
  public let backupID: String?

  /// Location where the backup was stored
  public let location: String?

  /// Size of the backup in bytes
  public let sizeBytes: UInt64?

  /// Number of files in the backup
  public let fileCount: Int?

  /// Time taken to create the backup (in seconds)
  public let executionTime: TimeInterval

  /// Whether the backup was verified successfully
  public let verified: Bool?

  /// Any warnings that occurred during backup
  public let warnings: [String]

  /// Error details if the backup failed
  public let error: String?

  /// Additional metadata about the backup
  public let metadata: [String: String]

  /**
   Initialises a new backup result DTO.

   - Parameters:
      - success: Whether the backup was successful
      - backupId: The ID of the backup (snapshot ID in Restic)
      - location: Location where the backup was stored
      - sizeBytes: Size of the backup in bytes
      - fileCount: Number of files in the backup
      - executionTime: Time taken to create the backup (in seconds)
      - verified: Whether the backup was verified successfully
      - warnings: Any warnings that occurred during backup
      - error: Error details if the backup failed
      - metadata: Additional metadata about the backup
   */
  public init(
    success: Bool,
    backupID: String?=nil,
    location: String?=nil,
    sizeBytes: UInt64?=nil,
    fileCount: Int?=nil,
    executionTime: TimeInterval,
    verified: Bool?=nil,
    warnings: [String]=[],
    error: String?=nil,
    metadata: [String: String]=[:]
  ) {
    self.success=success
    self.backupID=backupID
    self.location=location
    self.sizeBytes=sizeBytes
    self.fileCount=fileCount
    self.executionTime=executionTime
    self.verified=verified
    self.warnings=warnings
    self.error=error
    self.metadata=metadata
  }
}
