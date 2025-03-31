import Foundation

/// Provides conversion extensions for KeyManagementTypes to other modules
public enum TypeConverters {
  /// Raw representation types for StorageLocation conversions
  public enum RawLocations: String, Codable, Equatable, Sendable {
    case secureEnclave
    case keychain
    case memory
  }

  /// Convert from raw location to canonical StorageLocation
  /// - Parameter rawLocation: Raw location value
  /// - Returns: Canonical StorageLocation
  public static func from(rawLocation: RawLocations) -> StorageLocation {
    switch rawLocation {
      case .secureEnclave:
        .secureEnclave
      case .keychain:
        .keychain
      case .memory:
        .memory
    }
  }

  /// Raw representation types for KeyStatus conversions
  public enum RawStatus: Equatable, Sendable {
    case active
    case compromised
    case retired
    case pendingDeletion(Date)
    case pendingDeletionWithTimestamp(Int64)

    public static func == (lhs: RawStatus, rhs: RawStatus) -> Bool {
      switch (lhs, rhs) {
        case (.active, .active),
             (.compromised, .compromised),
             (.retired, .retired):
          true
        case let (.pendingDeletion(lhsDate), .pendingDeletion(rhsDate)):
          lhsDate == rhsDate
        case let (
        .pendingDeletionWithTimestamp(lhsTimestamp),
        .pendingDeletionWithTimestamp(rhsTimestamp)
      ):
          lhsTimestamp == rhsTimestamp
        case let (.pendingDeletion(lhsDate), .pendingDeletionWithTimestamp(rhsTimestamp)):
          Int64(lhsDate.timeIntervalSince1970) == rhsTimestamp
        case let (.pendingDeletionWithTimestamp(lhsTimestamp), .pendingDeletion(rhsDate)):
          lhsTimestamp == Int64(rhsDate.timeIntervalSince1970)
        default:
          false
      }
    }
  }

  /// Convert from raw status to canonical KeyStatus
  /// - Parameter rawStatus: Raw status value
  /// - Returns: Canonical KeyStatus
  public static func from(rawStatus: RawStatus) -> KeyStatus {
    switch rawStatus {
      case .active:
        .active
      case .compromised:
        .compromised
      case .retired:
        .retired
      case let .pendingDeletion(date):
        .pendingDeletion(date)
      case let .pendingDeletionWithTimestamp(timestamp):
        .pendingDeletionWithTimestamp(timestamp)
    }
  }

  /// Raw representation for KeyMetadata conversions
  public struct RawMetadata: Sendable {
    public var status: RawStatus
    public let storageLocation: RawLocations
    public let accessControls: KeyMetadata.AccessControls
    public let createdAt: Date
    public var lastModified: Date
    public var expiryDate: Date?
    public let algorithm: String
    public let keySize: Int
    public let identifier: String
    public var version: Int
    public var exportable: Bool
    public var isSystemKey: Bool
    public var isProcessIsolated: Bool
    public var customMetadata: [String: String]?

    public var createdAtTimestamp: Int64 {
      Int64(createdAt.timeIntervalSince1970)
    }

    public var lastModifiedTimestamp: Int64 {
      Int64(lastModified.timeIntervalSince1970)
    }

    public var expiryTimestamp: Int64? {
      expiryDate.map { Int64($0.timeIntervalSince1970) }
    }

    public init(
      status: RawStatus = .active,
      storageLocation: RawLocations,
      accessControls: KeyMetadata.AccessControls = .none,
      createdAt: Date=Date(),
      lastModified: Date=Date(),
      expiryDate: Date?=nil,
      algorithm: String,
      keySize: Int,
      identifier: String,
      version: Int=1,
      exportable: Bool=false,
      isSystemKey: Bool=false,
      isProcessIsolated: Bool=false,
      customMetadata: [String: String]?=nil
    ) {
      self.status=status
      self.storageLocation=storageLocation
      self.accessControls=accessControls
      self.createdAt=createdAt
      self.lastModified=lastModified
      self.expiryDate=expiryDate
      self.algorithm=algorithm
      self.keySize=keySize
      self.identifier=identifier
      self.version=version
      self.exportable=exportable
      self.isSystemKey=isSystemKey
      self.isProcessIsolated=isProcessIsolated
      self.customMetadata=customMetadata
    }

    public init(
      status: RawStatus = .active,
      storageLocation: RawLocations,
      accessControls: KeyMetadata.AccessControls = .none,
      createdAtTimestamp: Int64,
      lastModifiedTimestamp: Int64,
      expiryTimestamp: Int64?=nil,
      algorithm: String,
      keySize: Int,
      identifier: String,
      version: Int=1,
      exportable: Bool=false,
      isSystemKey: Bool=false,
      isProcessIsolated: Bool=false,
      customMetadata: [String: String]?=nil
    ) {
      self.status=status
      self.storageLocation=storageLocation
      self.accessControls=accessControls
      createdAt=Date(timeIntervalSince1970: TimeInterval(createdAtTimestamp))
      lastModified=Date(timeIntervalSince1970: TimeInterval(lastModifiedTimestamp))
      if let expiryTimestamp {
        expiryDate=Date(timeIntervalSince1970: TimeInterval(expiryTimestamp))
      } else {
        expiryDate=nil
      }
      self.algorithm=algorithm
      self.keySize=keySize
      self.identifier=identifier
      self.version=version
      self.exportable=exportable
      self.isSystemKey=isSystemKey
      self.isProcessIsolated=isProcessIsolated
      self.customMetadata=customMetadata
    }
  }

  /// Convert from raw metadata to canonical KeyMetadata
  /// - Parameter rawMetadata: Raw metadata value
  /// - Returns: Canonical KeyMetadata
  public static func from(rawMetadata: RawMetadata) -> KeyMetadata {
    KeyMetadata(
      status: from(rawStatus: rawMetadata.status),
      storageLocation: from(rawLocation: rawMetadata.storageLocation),
      accessControls: rawMetadata.accessControls,
      createdAt: rawMetadata.createdAt,
      lastModified: rawMetadata.lastModified,
      expiryDate: rawMetadata.expiryDate,
      algorithm: rawMetadata.algorithm,
      keySize: rawMetadata.keySize,
      identifier: rawMetadata.identifier,
      version: rawMetadata.version,
      exportable: rawMetadata.exportable,
      isSystemKey: rawMetadata.isSystemKey,
      isProcessIsolated: rawMetadata.isProcessIsolated,
      customMetadata: rawMetadata.customMetadata
    )
  }
}

// MARK: - StorageLocation Conversion Extensions

extension StorageLocation {
  /// Convert to raw location representation
  /// - Returns: Raw location representation
  public func toRawLocation() -> TypeConverters.RawLocations {
    switch self {
      case .secureEnclave: .secureEnclave
      case .keychain: .keychain
      case .memory: .memory
    }
  }

  /// Convert from raw location to canonical StorageLocation
  /// - Parameter rawLocation: Raw location value
  /// - Returns: Canonical StorageLocation
  public static func from(rawLocation: TypeConverters.RawLocations) -> StorageLocation {
    TypeConverters.from(rawLocation: rawLocation)
  }
}

// MARK: - KeyStatus Conversion Extensions

extension KeyStatus {
  /// Convert to raw status representation
  /// - Returns: Raw status representation
  public func toRawStatus() -> TypeConverters.RawStatus {
    switch self {
      case .active: .active
      case .compromised: .compromised
      case .retired: .retired
      case let .pendingDeletion(date): .pendingDeletion(date)
    }
  }

  /// Convert from raw status to canonical KeyStatus
  /// - Parameter rawStatus: Raw status value
  /// - Returns: Canonical KeyStatus
  public static func from(rawStatus: TypeConverters.RawStatus) -> KeyStatus {
    TypeConverters.from(rawStatus: rawStatus)
  }
}

// MARK: - KeyMetadata Conversion Extensions

extension KeyMetadata {
  /// Convert to raw metadata representation
  /// - Returns: Raw metadata representation
  public func toRawMetadata() -> TypeConverters.RawMetadata {
    TypeConverters.RawMetadata(
      status: status.toRawStatus(),
      storageLocation: storageLocation.toRawLocation(),
      accessControls: accessControls,
      createdAt: createdAt,
      lastModified: lastModified,
      expiryDate: expiryDate,
      algorithm: algorithm,
      keySize: keySize,
      identifier: identifier,
      version: version,
      exportable: exportable,
      isSystemKey: isSystemKey,
      isProcessIsolated: isProcessIsolated,
      customMetadata: customMetadata
    )
  }

  /// Convert from raw metadata to canonical KeyMetadata
  /// - Parameter rawMetadata: Raw metadata value
  /// - Returns: Canonical KeyMetadata
  public static func from(rawMetadata: TypeConverters.RawMetadata) -> KeyMetadata {
    TypeConverters.from(rawMetadata: rawMetadata)
  }
}

// MARK: - Type Aliases for Raw Types

extension StorageLocation {
  /// Type alias for raw locations type
}

extension KeyStatus {
  /// Type alias for raw status type
}

extension KeyMetadata {
  /// Type alias for raw metadata type
}
