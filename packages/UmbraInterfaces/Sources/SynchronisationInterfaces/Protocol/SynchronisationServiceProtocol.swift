import CoreDTOs
import Foundation

/**
 Protocol defining the requirements for a synchronisation service.

 This protocol defines the contract that all synchronisation service implementations
 must fulfil, providing a clean interface for data synchronisation operations.
 */
public protocol SynchronisationServiceProtocol: Sendable {
  /**
   Synchronises data between a local source and a remote destination.

   - Parameters:
      - operationID: Unique identifier for this operation
      - source: Local data source information
      - destination: Remote destination information
      - options: Additional synchronisation options
   - Returns: Result of the synchronisation operation
   - Throws: SynchronisationError if the operation fails
   */
  func synchronise(
    operationID: String,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    options: SynchronisationOptions
  ) async throws -> SynchronisationResult

  /**
   Retrieves the status of a specific synchronisation operation.

   - Parameter operationID: The identifier of the operation to check
   - Returns: The current status of the operation
   - Throws: SynchronisationError if the operation cannot be found
   */
  func getStatus(operationID: String) async throws -> SynchronisationStatus

  /**
   Cancels an ongoing synchronisation operation.

   - Parameter operationID: The identifier of the operation to cancel
   - Returns: True if the operation was found and cancelled, false otherwise
   */
  func cancelOperation(operationID: String) async -> Bool

  /**
   Lists all synchronisation operations, both past and present.

   - Parameters:
      - filter: Optional filter for specific operation types or statuses
      - limit: Maximum number of operations to return
      - offset: Number of operations to skip from the start
   - Returns: A list of synchronisation operations matching the criteria
   */
  func listOperations(
    filter: SynchronisationFilter?,
    limit: Int,
    offset: Int
  ) async throws -> [SynchronisationOperationInfo]

  /**
   Verifies the consistency between a local source and a remote destination.

   - Parameters:
      - operationID: Unique identifier for this operation
      - source: Local data source information
      - destination: Remote destination information
      - options: Additional verification options
   - Returns: Result of the verification operation
   - Throws: SynchronisationError if the operation fails
   */
  func verifyConsistency(
    operationID: String,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    options: SynchronisationVerificationOptions
  ) async throws -> SynchronisationVerificationResult
}

/**
 Source for a synchronisation operation.
 */
public struct SynchronisationSource: Sendable, Equatable {
  /// The type of source for the synchronisation
  public let type: SourceType

  /// The path to the source data (if applicable)
  public let path: URL?

  /// Unique identifier for the source (if applicable)
  public let identifier: String?

  /// Additional configuration options for the source
  public let options: [String: String]

  /**
   Initialises a new synchronisation source.

   - Parameters:
      - type: The type of source
      - path: The path to the source data (if applicable)
      - identifier: Unique identifier for the source (if applicable)
      - options: Additional configuration options for the source
   */
  public init(
    type: SourceType,
    path: URL?=nil,
    identifier: String?=nil,
    options: [String: String]=[:]
  ) {
    self.type=type
    self.path=path
    self.identifier=identifier
    self.options=options
  }

  /**
   Supported source types for synchronisation.
   */
  public enum SourceType: String, Sendable, Equatable, CaseIterable {
    /// Local filesystem
    case fileSystem
    /// Database
    case database
    /// Key-value store
    case keyValueStore
    /// Remote API
    case remoteAPI
    /// Memory cache
    case memoryCache
    /// Custom source
    case custom
  }
}

/**
 Destination for a synchronisation operation.
 */
public struct SynchronisationDestination: Sendable, Equatable {
  /// The type of destination for the synchronisation
  public let type: DestinationType

  /// The endpoint URL for the destination (if applicable)
  public let endpoint: URL?

  /// Unique identifier for the destination (if applicable)
  public let identifier: String?

  /// Additional configuration options for the destination
  public let options: [String: String]

  /**
   Initialises a new synchronisation destination.

   - Parameters:
      - type: The type of destination
      - endpoint: The endpoint URL for the destination (if applicable)
      - identifier: Unique identifier for the destination (if applicable)
      - options: Additional configuration options for the destination
   */
  public init(
    type: DestinationType,
    endpoint: URL?=nil,
    identifier: String?=nil,
    options: [String: String]=[:]
  ) {
    self.type=type
    self.endpoint=endpoint
    self.identifier=identifier
    self.options=options
  }

  /**
   Supported destination types for synchronisation.
   */
  public enum DestinationType: String, Sendable, Equatable, CaseIterable {
    /// Cloud storage service
    case cloudStorage
    /// Remote database
    case remoteDatabase
    /// Remote filesystem
    case remoteFileSystem
    /// Content delivery network
    case cdn
    /// Web API
    case webAPI
    /// Custom destination
    case custom
  }
}

/**
 Options for synchronisation operations.
 */
public struct SynchronisationOptions: Sendable, Equatable {
  /// Direction of the synchronisation
  public let direction: SynchronisationDirection

  /// Resolution strategy for conflicts
  public let conflictResolution: ConflictResolutionStrategy

  /// Whether to include metadata in the synchronisation
  public let includeMetadata: Bool

  /// Whether to include system files in the synchronisation
  public let includeSystemFiles: Bool

  /// Maximum bandwidth to use (in KB/s, 0 for unlimited)
  public let maxBandwidth: Int

  /// Additional custom options
  public let customOptions: [String: String]

  /**
   Initialises new synchronisation options.

   - Parameters:
      - direction: Direction of the synchronisation
      - conflictResolution: Resolution strategy for conflicts
      - includeMetadata: Whether to include metadata
      - includeSystemFiles: Whether to include system files
      - maxBandwidth: Maximum bandwidth to use (in KB/s, 0 for unlimited)
      - customOptions: Additional custom options
   */
  public init(
    direction: SynchronisationDirection = .bothDirections,
    conflictResolution: ConflictResolutionStrategy = .newerWins,
    includeMetadata: Bool=true,
    includeSystemFiles: Bool=false,
    maxBandwidth: Int=0,
    customOptions: [String: String]=[:]
  ) {
    self.direction=direction
    self.conflictResolution=conflictResolution
    self.includeMetadata=includeMetadata
    self.includeSystemFiles=includeSystemFiles
    self.maxBandwidth=maxBandwidth
    self.customOptions=customOptions
  }

  /**
   Direction of the synchronisation.
   */
  public enum SynchronisationDirection: String, Sendable, Equatable, CaseIterable {
    /// Source to destination only
    case sourceToDestination
    /// Destination to source only
    case destinationToSource
    /// Both directions (merge)
    case bothDirections
  }

  /**
   Strategy for resolving conflicts during synchronisation.
   */
  public enum ConflictResolutionStrategy: String, Sendable, Equatable, CaseIterable {
    /// Source always wins
    case sourceWins
    /// Destination always wins
    case destinationWins
    /// The newer file wins
    case newerWins
    /// The larger file wins
    case largerWins
    /// Ask the user
    case askUser
    /// Custom conflict resolution
    case custom
  }
}

/**
 Options for verification operations.
 */
public struct SynchronisationVerificationOptions: Sendable, Equatable {
  /// Verification depth
  public let depth: VerificationDepth

  /// Whether to repair inconsistencies automatically
  public let autoRepair: Bool

  /// Hash algorithm to use for content verification
  public let hashAlgorithm: HashAlgorithm

  /// Additional custom options
  public let customOptions: [String: String]

  /**
   Initialises new verification options.

   - Parameters:
      - depth: Verification depth
      - autoRepair: Whether to repair inconsistencies automatically
      - hashAlgorithm: Hash algorithm to use for content verification
      - customOptions: Additional custom options
   */
  public init(
    depth: VerificationDepth = .contentHash,
    autoRepair: Bool=false,
    hashAlgorithm: HashAlgorithm = .sha256,
    customOptions: [String: String]=[:]
  ) {
    self.depth=depth
    self.autoRepair=autoRepair
    self.hashAlgorithm=hashAlgorithm
    self.customOptions=customOptions
  }

  /**
   Depth of verification.
   */
  public enum VerificationDepth: String, Sendable, Equatable, CaseIterable {
    /// Verify existence only
    case existence
    /// Verify size and modification date
    case metadata
    /// Verify content hash
    case contentHash
    /// Deep comparison of all attributes
    case fullCompare
  }

  /**
   Hash algorithm to use for verification.
   */
  public enum HashAlgorithm: String, Sendable, Equatable, CaseIterable {
    /// MD5 hash algorithm
    case md5
    /// SHA-1 hash algorithm
    case sha1
    /// SHA-256 hash algorithm
    case sha256
    /// SHA-512 hash algorithm
    case sha512
  }
}

/**
 Filter for listing synchronisation operations.
 */
public struct SynchronisationFilter: Sendable, Equatable {
  /// Filter by status
  public let status: SynchronisationStatus?

  /// Filter by source type
  public let sourceType: SynchronisationSource.SourceType?

  /// Filter by destination type
  public let destinationType: SynchronisationDestination.DestinationType?

  /// Filter by date range (start)
  public let startDate: Date?

  /// Filter by date range (end)
  public let endDate: Date?

  /**
   Initialises a new synchronisation filter.

   - Parameters:
      - status: Filter by status
      - sourceType: Filter by source type
      - destinationType: Filter by destination type
      - startDate: Filter by date range (start)
      - endDate: Filter by date range (end)
   */
  public init(
    status: SynchronisationStatus?=nil,
    sourceType: SynchronisationSource.SourceType?=nil,
    destinationType: SynchronisationDestination.DestinationType?=nil,
    startDate: Date?=nil,
    endDate: Date?=nil
  ) {
    self.status=status
    self.sourceType=sourceType
    self.destinationType=destinationType
    self.startDate=startDate
    self.endDate=endDate
  }
}

/**
 Information about a synchronisation operation.
 */
public struct SynchronisationOperationInfo: Sendable, Equatable, Identifiable {
  /// Unique identifier for the operation
  public let id: String

  /// Current status of the operation
  public let status: SynchronisationStatus

  /// When the operation was created
  public let createdAt: Date

  /// When the operation was last updated
  public let updatedAt: Date

  /// Source information
  public let source: SynchronisationSource

  /// Destination information
  public let destination: SynchronisationDestination

  /// Number of files processed
  public let filesProcessed: Int

  /// Number of bytes transferred
  public let bytesTransferred: Int64

  /// Any error that occurred
  public let error: SynchronisationError?

  /**
   Initialises a new synchronisation operation info.

   - Parameters:
      - id: Unique identifier for the operation
      - status: Current status of the operation
      - createdAt: When the operation was created
      - updatedAt: When the operation was last updated
      - source: Source information
      - destination: Destination information
      - filesProcessed: Number of files processed
      - bytesTransferred: Number of bytes transferred
      - error: Any error that occurred
   */
  public init(
    id: String,
    status: SynchronisationStatus,
    createdAt: Date,
    updatedAt: Date,
    source: SynchronisationSource,
    destination: SynchronisationDestination,
    filesProcessed: Int,
    bytesTransferred: Int64,
    error: SynchronisationError?=nil
  ) {
    self.id=id
    self.status=status
    self.createdAt=createdAt
    self.updatedAt=updatedAt
    self.source=source
    self.destination=destination
    self.filesProcessed=filesProcessed
    self.bytesTransferred=bytesTransferred
    self.error=error
  }
}

/**
 Result of a synchronisation operation.
 */
public struct SynchronisationResult: Sendable, Equatable {
  /// Whether the operation completed successfully
  public let success: Bool

  /// Number of files synchronised
  public let filesSynchronised: Int

  /// Number of bytes transferred
  public let bytesTransferred: Int64

  /// Number of conflicts detected
  public let conflictsDetected: Int

  /// Number of conflicts resolved
  public let conflictsResolved: Int

  /// Any errors that occurred
  public let errors: [SynchronisationError]

  /// Duration of the operation in seconds
  public let durationSeconds: Double

  /**
   Initialises a new synchronisation result.

   - Parameters:
      - success: Whether the operation completed successfully
      - filesSynchronised: Number of files synchronised
      - bytesTransferred: Number of bytes transferred
      - conflictsDetected: Number of conflicts detected
      - conflictsResolved: Number of conflicts resolved
      - errors: Any errors that occurred
      - durationSeconds: Duration of the operation in seconds
   */
  public init(
    success: Bool,
    filesSynchronised: Int,
    bytesTransferred: Int64,
    conflictsDetected: Int,
    conflictsResolved: Int,
    errors: [SynchronisationError]=[],
    durationSeconds: Double
  ) {
    self.success=success
    self.filesSynchronised=filesSynchronised
    self.bytesTransferred=bytesTransferred
    self.conflictsDetected=conflictsDetected
    self.conflictsResolved=conflictsResolved
    self.errors=errors
    self.durationSeconds=durationSeconds
  }
}

/**
 Result of a verification operation.
 */
public struct SynchronisationVerificationResult: Sendable, Equatable {
  /// Whether the verification completed successfully
  public let success: Bool

  /// Whether the source and destination are consistent
  public let consistent: Bool

  /// Number of files verified
  public let filesVerified: Int

  /// Number of inconsistencies found
  public let inconsistenciesFound: Int

  /// Number of inconsistencies repaired (if auto-repair was enabled)
  public let inconsistenciesRepaired: Int

  /// List of inconsistencies found
  public let inconsistencies: [SynchronisationInconsistency]

  /// Duration of the operation in seconds
  public let durationSeconds: Double

  /**
   Initialises a new verification result.

   - Parameters:
      - success: Whether the verification completed successfully
      - consistent: Whether the source and destination are consistent
      - filesVerified: Number of files verified
      - inconsistenciesFound: Number of inconsistencies found
      - inconsistenciesRepaired: Number of inconsistencies repaired
      - inconsistencies: List of inconsistencies found
      - durationSeconds: Duration of the operation in seconds
   */
  public init(
    success: Bool,
    consistent: Bool,
    filesVerified: Int,
    inconsistenciesFound: Int,
    inconsistenciesRepaired: Int=0,
    inconsistencies: [SynchronisationInconsistency]=[],
    durationSeconds: Double
  ) {
    self.success=success
    self.consistent=consistent
    self.filesVerified=filesVerified
    self.inconsistenciesFound=inconsistenciesFound
    self.inconsistenciesRepaired=inconsistenciesRepaired
    self.inconsistencies=inconsistencies
    self.durationSeconds=durationSeconds
  }
}

/**
 Inconsistency found during a verification operation.
 */
public struct SynchronisationInconsistency: Sendable, Equatable {
  /// The path to the inconsistent file
  public let path: String

  /// The type of inconsistency
  public let type: InconsistencyType

  /// Details about the inconsistency
  public let details: String

  /// Whether the inconsistency was repaired
  public let repaired: Bool

  /**
   Initialises a new synchronisation inconsistency.

   - Parameters:
      - path: The path to the inconsistent file
      - type: The type of inconsistency
      - details: Details about the inconsistency
      - repaired: Whether the inconsistency was repaired
   */
  public init(
    path: String,
    type: InconsistencyType,
    details: String,
    repaired: Bool=false
  ) {
    self.path=path
    self.type=type
    self.details=details
    self.repaired=repaired
  }

  /**
   Type of inconsistency found during verification.
   */
  public enum InconsistencyType: String, Sendable, Equatable, CaseIterable {
    /// File exists in source but not in destination
    case missingInDestination
    /// File exists in destination but not in source
    case missingInSource
    /// File size differs between source and destination
    case sizeMismatch
    /// File modification time differs
    case timeMismatch
    /// File content hash differs
    case contentMismatch
    /// File permissions differ
    case permissionsMismatch
    /// Other inconsistency
    case other
  }
}

/**
 Status of a synchronisation operation.
 */
public enum SynchronisationStatus: String, Sendable, Equatable, CaseIterable {
  /// Operation is queued but not started
  case queued
  /// Operation is preparing to start
  case preparing
  /// Operation is in progress
  case inProgress
  /// Operation completed successfully
  case completed
  /// Operation failed
  case failed
  /// Operation was cancelled
  case cancelled
  /// Operation is paused
  case paused

  /// Whether this status represents a terminal state
  public var isTerminal: Bool {
    switch self {
      case .queued, .preparing, .inProgress, .paused:
        false
      case .completed, .failed, .cancelled:
        true
    }
  }

  /// Whether this status represents a success
  public var isSuccess: Bool {
    self == .completed
  }
}

/**
 Error that can occur during synchronisation operations.
 */
public enum SynchronisationError: Error, Sendable, Equatable {
  /// Invalid source configuration
  case invalidSource(String)
  /// Invalid destination configuration
  case invalidDestination(String)
  /// Connection to the destination failed
  case connectionFailed(String)
  /// Authentication failed
  case authenticationFailed
  /// Permission denied
  case permissionDenied(String)
  /// Network error
  case networkError(String)
  /// IO error
  case ioError(String)
  /// Operation was cancelled
  case cancelled
  /// Operation timed out
  case timeout
  /// Operation not found
  case operationNotFound(String)
  /// Unsupported operation
  case unsupportedOperation(String)
  /// Quota exceeded
  case quotaExceeded
  /// Resource busy
  case resourceBusy(String)
  /// Conflict resolution failed
  case conflictResolutionFailed(String)
  /// Unknown error
  case unknown(String)

  /// A user-friendly description of the error
  public var localizedDescription: String {
    switch self {
      case let .invalidSource(details):
        "Invalid source configuration: \(details)"
      case let .invalidDestination(details):
        "Invalid destination configuration: \(details)"
      case let .connectionFailed(details):
        "Connection failed: \(details)"
      case .authenticationFailed:
        "Authentication failed"
      case let .permissionDenied(details):
        "Permission denied: \(details)"
      case let .networkError(details):
        "Network error: \(details)"
      case let .ioError(details):
        "IO error: \(details)"
      case .cancelled:
        "Operation was cancelled"
      case .timeout:
        "Operation timed out"
      case let .operationNotFound(operationID):
        "Operation not found: \(operationID)"
      case let .unsupportedOperation(details):
        "Unsupported operation: \(details)"
      case .quotaExceeded:
        "Quota exceeded"
      case let .resourceBusy(details):
        "Resource busy: \(details)"
      case let .conflictResolutionFailed(details):
        "Conflict resolution failed: \(details)"
      case let .unknown(details):
        "Unknown error: \(details)"
    }
  }
}
