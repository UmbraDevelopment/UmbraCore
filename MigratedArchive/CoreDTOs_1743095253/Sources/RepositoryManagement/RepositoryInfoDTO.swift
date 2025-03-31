import UmbraCoreTypes

/// FoundationIndependent representation of repository information.
/// This data transfer object encapsulates details about a backup repository
/// without using any Foundation types.
public struct RepositoryInfoDTO: Sendable, Equatable {
  // MARK: - Properties

  /// Unique identifier for the repository
  public let id: String

  /// Repository path (local file path or remote URL formatted as string)
  public let path: String

  /// Whether the repository has been initialised
  public let isInitialised: Bool

  /// Last access timestamp (Unix timestamp - seconds since epoch)
  public let lastAccessed: UInt64?

  /// Whether the repository is on a remote location
  public let isRemote: Bool

  /// Additional repository metadata
  public let metadata: [String: String]

  // MARK: - Initializers

  /// Full initializer with all repository information
  /// - Parameters:
  ///   - id: Unique identifier for the repository
  ///   - path: Repository path (local file path or remote URL formatted as string)
  ///   - isInitialised: Whether the repository has been initialised
  ///   - lastAccessed: Last access timestamp (Unix timestamp - seconds since epoch)
  ///   - isRemote: Whether the repository is on a remote location
  ///   - metadata: Additional repository metadata
  public init(
    id: String,
    path: String,
    isInitialised: Bool,
    lastAccessed: UInt64?=nil,
    isRemote: Bool,
    metadata: [String: String]=[:]
  ) {
    self.id=id
    self.path=path
    self.isInitialised=isInitialised
    self.lastAccessed=lastAccessed
    self.isRemote=isRemote
    self.metadata=metadata
  }

  // MARK: - Factory Methods

  /// Create a local repository information object
  /// - Parameters:
  ///   - id: Unique identifier for the repository
  ///   - path: Local file path to the repository
  ///   - isInitialised: Whether the repository has been initialised
  ///   - lastAccessed: Last access timestamp (Unix timestamp - seconds since epoch)
  ///   - metadata: Additional repository metadata
  /// - Returns: A RepositoryInfoDTO configured for a local repository
  public static func localRepository(
    id: String,
    path: String,
    isInitialised: Bool,
    lastAccessed: UInt64?=nil,
    metadata: [String: String]=[:]
  ) -> RepositoryInfoDTO {
    RepositoryInfoDTO(
      id: id,
      path: path,
      isInitialised: isInitialised,
      lastAccessed: lastAccessed,
      isRemote: false,
      metadata: metadata
    )
  }

  /// Create a remote repository information object
  /// - Parameters:
  ///   - id: Unique identifier for the repository
  ///   - path: Remote URL to the repository as a string
  ///   - isInitialised: Whether the repository has been initialised
  ///   - lastAccessed: Last access timestamp (Unix timestamp - seconds since epoch)
  ///   - metadata: Additional repository metadata
  /// - Returns: A RepositoryInfoDTO configured for a remote repository
  public static func remoteRepository(
    id: String,
    path: String,
    isInitialised: Bool,
    lastAccessed: UInt64?=nil,
    metadata: [String: String]=[:]
  ) -> RepositoryInfoDTO {
    RepositoryInfoDTO(
      id: id,
      path: path,
      isInitialised: isInitialised,
      lastAccessed: lastAccessed,
      isRemote: true,
      metadata: metadata
    )
  }

  // MARK: - Utility Methods

  /// Create a copy of this repository info with updated metadata
  /// - Parameter additionalMetadata: The metadata to add or update
  /// - Returns: A new RepositoryInfoDTO with updated metadata
  public func withUpdatedMetadata(_ additionalMetadata: [String: String]) -> RepositoryInfoDTO {
    var newMetadata=metadata
    for (key, value) in additionalMetadata {
      newMetadata[key]=value
    }

    return RepositoryInfoDTO(
      id: id,
      path: path,
      isInitialised: isInitialised,
      lastAccessed: lastAccessed,
      isRemote: isRemote,
      metadata: newMetadata
    )
  }

  /// Create a copy of this repository info with updated initialisation status
  /// - Parameter isInitialised: The new initialisation status
  /// - Returns: A new RepositoryInfoDTO with updated initialisation status
  public func withInitialisationStatus(_ isInitialised: Bool) -> RepositoryInfoDTO {
    RepositoryInfoDTO(
      id: id,
      path: path,
      isInitialised: isInitialised,
      lastAccessed: lastAccessed,
      isRemote: isRemote,
      metadata: metadata
    )
  }

  /// Create a copy of this repository info with updated access timestamp
  /// - Parameter timestamp: The new access timestamp (Unix timestamp - seconds since epoch)
  /// - Returns: A new RepositoryInfoDTO with updated access timestamp
  public func withAccessTimestamp(_ timestamp: UInt64) -> RepositoryInfoDTO {
    RepositoryInfoDTO(
      id: id,
      path: path,
      isInitialised: isInitialised,
      lastAccessed: timestamp,
      isRemote: isRemote,
      metadata: metadata
    )
  }
}
