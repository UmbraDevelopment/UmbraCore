import UmbraCoreTypes

/// FoundationIndependent representation of backup configuration.
/// This data transfer object encapsulates backup configuration options
/// without using any Foundation types.
public struct BackupConfigDTO: Sendable, Equatable {
  // MARK: - Properties

  /// List of source directories to back up
  public let sourceDirectories: [String]

  /// List of patterns to exclude from backup
  public let excludePatterns: [String]

  /// List of tags to apply to the backup
  public let tagList: [String]

  /// Compression level (0-9, where 0 is no compression and 9 is maximum compression)
  public let compressionLevel: Int

  /// Retention policy for this backup
  public let retentionPolicy: RetentionPolicyDTO

  // MARK: - Initializers

  /// Full initializer with all backup configuration options
  /// - Parameters:
  ///   - sourceDirectories: List of source directories to back up
  ///   - excludePatterns: List of patterns to exclude from backup
  ///   - tagList: List of tags to apply to the backup
  ///   - compressionLevel: Compression level (0-9)
  ///   - retentionPolicy: Retention policy for this backup
  public init(
    sourceDirectories: [String],
    excludePatterns: [String]=[],
    tagList: [String]=[],
    compressionLevel: Int=6,
    retentionPolicy: RetentionPolicyDTO
  ) {
    self.sourceDirectories=sourceDirectories
    self.excludePatterns=excludePatterns
    self.tagList=tagList
    // Clamp compression level between 0 and 9
    self.compressionLevel=min(9, max(0, compressionLevel))
    self.retentionPolicy=retentionPolicy
  }

  // MARK: - Factory Methods

  /// Create a default backup configuration
  /// - Parameters:
  ///   - sourceDirectories: List of source directories to back up
  ///   - tagList: List of tags to apply to the backup
  /// - Returns: A BackupConfigDTO with default settings
  public static func defaultConfig(
    sourceDirectories: [String],
    tagList: [String]=[]
  ) -> BackupConfigDTO {
    BackupConfigDTO(
      sourceDirectories: sourceDirectories,
      excludePatterns: [
        "**/.DS_Store",
        "**/node_modules",
        "**/.git",
        "**/Thumbs.db",
        "**/*.tmp",
        "**/~*",
        "**/*.swp"
      ],
      tagList: tagList,
      compressionLevel: 6,
      retentionPolicy: RetentionPolicyDTO.defaultPolicy()
    )
  }

  // MARK: - Utility Methods

  /// Create a copy of this configuration with updated source directories
  /// - Parameter directories: The new list of source directories
  /// - Returns: A new BackupConfigDTO with updated source directories
  public func withSourceDirectories(_ directories: [String]) -> BackupConfigDTO {
    BackupConfigDTO(
      sourceDirectories: directories,
      excludePatterns: excludePatterns,
      tagList: tagList,
      compressionLevel: compressionLevel,
      retentionPolicy: retentionPolicy
    )
  }

  /// Create a copy of this configuration with added source directories
  /// - Parameter directories: Additional source directories to add
  /// - Returns: A new BackupConfigDTO with additional source directories
  public func addingSourceDirectories(_ directories: [String]) -> BackupConfigDTO {
    var newDirectories=sourceDirectories
    for directory in directories {
      if !newDirectories.contains(directory) {
        newDirectories.append(directory)
      }
    }

    return BackupConfigDTO(
      sourceDirectories: newDirectories,
      excludePatterns: excludePatterns,
      tagList: tagList,
      compressionLevel: compressionLevel,
      retentionPolicy: retentionPolicy
    )
  }

  /// Create a copy of this configuration with updated exclude patterns
  /// - Parameter patterns: The new list of exclude patterns
  /// - Returns: A new BackupConfigDTO with updated exclude patterns
  public func withExcludePatterns(_ patterns: [String]) -> BackupConfigDTO {
    BackupConfigDTO(
      sourceDirectories: sourceDirectories,
      excludePatterns: patterns,
      tagList: tagList,
      compressionLevel: compressionLevel,
      retentionPolicy: retentionPolicy
    )
  }

  /// Create a copy of this configuration with updated tags
  /// - Parameter tags: The new list of tags
  /// - Returns: A new BackupConfigDTO with updated tags
  public func withTags(_ tags: [String]) -> BackupConfigDTO {
    BackupConfigDTO(
      sourceDirectories: sourceDirectories,
      excludePatterns: excludePatterns,
      tagList: tags,
      compressionLevel: compressionLevel,
      retentionPolicy: retentionPolicy
    )
  }

  /// Create a copy of this configuration with updated compression level
  /// - Parameter level: The new compression level (0-9)
  /// - Returns: A new BackupConfigDTO with updated compression level
  public func withCompressionLevel(_ level: Int) -> BackupConfigDTO {
    BackupConfigDTO(
      sourceDirectories: sourceDirectories,
      excludePatterns: excludePatterns,
      tagList: tagList,
      compressionLevel: level,
      retentionPolicy: retentionPolicy
    )
  }

  /// Create a copy of this configuration with updated retention policy
  /// - Parameter policy: The new retention policy
  /// - Returns: A new BackupConfigDTO with updated retention policy
  public func withRetentionPolicy(_ policy: RetentionPolicyDTO) -> BackupConfigDTO {
    BackupConfigDTO(
      sourceDirectories: sourceDirectories,
      excludePatterns: excludePatterns,
      tagList: tagList,
      compressionLevel: compressionLevel,
      retentionPolicy: policy
    )
  }
}
