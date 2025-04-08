/**
 # Repository API Operations

 Defines operations related to repository management in the Umbra system.
 These operations follow the Alpha Dot Five architecture principles with
 strict typing and clear domain boundaries.
 */

/**
 Base protocol for all repository-related API operations.
 */
public protocol RepositoryAPIOperation: DomainAPIOperation {}

/// Default domain for repository operations
extension RepositoryAPIOperation {
  public static var domain: APIDomain {
    .repository
  }
}

/**
 Operation to list all repositories with optional filtering.
 */
public struct ListRepositoriesOperation: RepositoryAPIOperation {
  /// The operation result type
  public typealias ResultType=[RepositoryInfo]

  /// Whether to include detailed information about each repository
  public let includeDetails: Bool

  /// Optional status filter for repositories
  public let statusFilter: RepositoryStatus?

  /**
   Initialises a new list repositories operation.

   - Parameters:
      - includeDetails: Whether to include detailed information
      - statusFilter: Optional status filter
   */
  public init(
    includeDetails: Bool=false,
    statusFilter: RepositoryStatus?=nil
  ) {
    self.includeDetails=includeDetails
    self.statusFilter=statusFilter
  }
}

/**
 Operation to get detailed information about a specific repository.
 */
public struct GetRepositoryOperation: RepositoryAPIOperation {
  /// The operation result type
  public typealias ResultType=RepositoryDetails

  /// The repository identifier
  public let repositoryID: String

  /// Whether to include snapshot information
  public let includeSnapshots: Bool

  /**
   Initialises a new get repository operation.

   - Parameters:
      - repositoryID: The repository identifier
      - includeSnapshots: Whether to include snapshot information
   */
  public init(
    repositoryID: String,
    includeSnapshots: Bool=false
  ) {
    self.repositoryID=repositoryID
    self.includeSnapshots=includeSnapshots
  }
}

/**
 Operation to create a new repository.
 */
public struct CreateRepositoryOperation: RepositoryAPIOperation {
  /// The operation result type
  public typealias ResultType=RepositoryInfo

  /// The repository creation parameters
  public let parameters: RepositoryCreationParameters

  /**
   Initialises a new create repository operation.

   - Parameter parameters: The repository creation parameters
   */
  public init(parameters: RepositoryCreationParameters) {
    self.parameters=parameters
  }
}

/**
 Operation to update an existing repository.
 */
public struct UpdateRepositoryOperation: RepositoryAPIOperation {
  /// The operation result type
  public typealias ResultType=RepositoryInfo

  /// The repository identifier
  public let repositoryID: String

  /// The repository update parameters
  public let parameters: RepositoryUpdateParameters

  /**
   Initialises a new update repository operation.

   - Parameters:
      - repositoryID: The repository identifier
      - parameters: The repository update parameters
   */
  public init(
    repositoryID: String,
    parameters: RepositoryUpdateParameters
  ) {
    self.repositoryID=repositoryID
    self.parameters=parameters
  }
}

/**
 Operation to delete a repository.
 */
public struct DeleteRepositoryOperation: RepositoryAPIOperation {
  /// The operation result type
  public typealias ResultType=Void

  /// The repository identifier
  public let repositoryID: String

  /// Whether to force deletion even if the repository contains snapshots
  public let force: Bool

  /**
   Initialises a new delete repository operation.

   - Parameters:
      - repositoryID: The repository identifier
      - force: Whether to force deletion
   */
  public init(
    repositoryID: String,
    force: Bool=false
  ) {
    self.repositoryID=repositoryID
    self.force=force
  }
}

/**
 Repository status enumeration.
 */
public enum RepositoryStatus: String, Sendable {
  /// The repository is ready for use
  case ready

  /// The repository is initialising
  case initialising

  /// The repository is currently being modified
  case modifying

  /// The repository is locked by another process
  case locked

  /// The repository is corrupt or damaged
  case damaged

  /// The repository is being repaired
  case repairing
}

/**
 Basic repository information structure.
 */
public struct RepositoryInfo: Sendable {
  /// Unique identifier for the repository
  public let id: String

  /// Display name for the repository
  public let name: String

  /// Current status of the repository
  public let status: RepositoryStatus

  /// Path to the repository
  public let path: String

  /**
   Initialises a new repository information structure.

   - Parameters:
      - id: The repository identifier
      - name: The repository name
      - status: The repository status
      - path: The repository path
   */
  public init(
    id: String,
    name: String,
    status: RepositoryStatus,
    path: String
  ) {
    self.id=id
    self.name=name
    self.status=status
    self.path=path
  }
}

import DateTimeTypes

/**
 Detailed repository information structure.
 */
public struct RepositoryDetails: Sendable {
  /// Basic repository information
  public let info: RepositoryInfo

  /// When the repository was created
  public let createdAt: DateTimeDTO

  /// When the repository was last modified
  public let lastModifiedAt: DateTimeDTO

  /// Total size of the repository in bytes
  public let totalSizeBytes: UInt64

  /// Number of snapshots in the repository
  public let snapshotCount: Int

  /// Whether the repository is encrypted
  public let isEncrypted: Bool

  /**
   Initialises a new repository details structure.

   - Parameters:
      - info: Basic repository information
      - createdAt: Creation timestamp
      - lastModifiedAt: Last modification timestamp
      - totalSizeBytes: Total size in bytes
      - snapshotCount: Number of snapshots
      - isEncrypted: Whether the repository is encrypted
   */
  public init(
    info: RepositoryInfo,
    createdAt: DateTimeDTO,
    lastModifiedAt: DateTimeDTO,
    totalSizeBytes: UInt64,
    snapshotCount: Int,
    isEncrypted: Bool
  ) {
    self.info = info
    self.createdAt = createdAt
    self.lastModifiedAt = lastModifiedAt
    self.totalSizeBytes = totalSizeBytes
    self.snapshotCount = snapshotCount
    self.isEncrypted = isEncrypted
  }
  
  /**
   Initialises a new repository details structure with string dates.
   This is provided for backward compatibility.

   - Parameters:
      - info: Basic repository information
      - createdAt: Creation timestamp as ISO8601 string
      - lastModifiedAt: Last modification timestamp as ISO8601 string
      - totalSizeBytes: Total size in bytes
      - snapshotCount: Number of snapshots
      - isEncrypted: Whether the repository is encrypted
   */
  public init(
    info: RepositoryInfo,
    createdAt: String,
    lastModifiedAt: String,
    totalSizeBytes: UInt64,
    snapshotCount: Int,
    isEncrypted: Bool
  ) {
    self.info = info
    
    // Parse dates or use current time if parsing fails
    if let createdDate = DateTimeDTO.fromISO8601String(createdAt) {
      self.createdAt = createdDate
    } else {
      self.createdAt = DateTimeDTO.now()
    }
    
    if let modifiedDate = DateTimeDTO.fromISO8601String(lastModifiedAt) {
      self.lastModifiedAt = modifiedDate
    } else {
      self.lastModifiedAt = DateTimeDTO.now()
    }
    
    self.totalSizeBytes = totalSizeBytes
    self.snapshotCount = snapshotCount
    self.isEncrypted = isEncrypted
  }
}

/**
 Parameters for creating a new repository.
 */
public struct RepositoryCreationParameters: Sendable {
  /// Name for the repository
  public let name: String

  /// Path for the repository
  public let path: String

  /// Whether to encrypt the repository
  public let encrypt: Bool

  /// Encryption password, required if encrypt is true
  public let password: String?

  /**
   Initialises new repository creation parameters.

   - Parameters:
      - name: The repository name
      - path: The repository path
      - encrypt: Whether to encrypt the repository
      - password: The encryption password
   */
  public init(
    name: String,
    path: String,
    encrypt: Bool=false,
    password: String?=nil
  ) {
    self.name=name
    self.path=path
    self.encrypt=encrypt
    self.password=password
  }
}

/**
 Parameters for updating an existing repository.
 */
public struct RepositoryUpdateParameters: Sendable {
  /// New name for the repository
  public let name: String?

  /**
   Initialises new repository update parameters.

   - Parameter name: The new repository name
   */
  public init(name: String?=nil) {
    self.name=name
  }
}
