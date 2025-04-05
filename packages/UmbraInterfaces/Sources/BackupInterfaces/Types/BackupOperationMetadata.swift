import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * Strongly-typed metadata for backup operations.
 *
 * This structure provides a type-safe way to store and retrieve metadata about
 * backup operations, following the Alpha Dot Five architecture pattern for
 * avoiding stringly-typed APIs.
 */
public struct BackupOperationMetadata: Sendable, Equatable {
  /// Standard metadata keys
  public enum MetadataKey: String, Sendable, CaseIterable {
    case operationType
    case repositoryID
    case snapshotID
    case targetPath
    case compressionLevel
    case verificationEnabled
    case hostname
    case priority
    case excludedCount
    case includedCount
  }

  /// The time the operation started
  public let startTime: Date

  /// The time the operation completed
  public let endTime: Date

  /// The duration of the operation in seconds
  public var duration: TimeInterval {
    endTime.timeIntervalSince(startTime)
  }

  /// Type-safe metadata dictionary
  private let metadata: [MetadataKey: String]

  /// Additional string-based metadata for backward compatibility
  private let additionalInfo: [String: String]

  /**
   * Creates new operation metadata.
   *
   * - Parameters:
   *   - startTime: The time the operation started
   *   - endTime: The time the operation completed
   *   - metadata: Type-safe metadata dictionary
   *   - additionalInfo: Optional additional string-based metadata
   */
  public init(
    startTime: Date,
    endTime: Date,
    metadata: [MetadataKey: String]=[:],
    additionalInfo: [String: String]=[:]
  ) {
    self.startTime=startTime
    self.endTime=endTime
    self.metadata=metadata
    self.additionalInfo=additionalInfo
  }

  /**
   * Retrieves a metadata value for the specified key.
   *
   * - Parameter key: The metadata key
   * - Returns: The value, or nil if not present
   */
  public func value(for key: MetadataKey) -> String? {
    metadata[key]
  }

  /**
   * Retrieves additional metadata for the specified key.
   *
   * - Parameter key: The string key
   * - Returns: The value, or nil if not present
   */
  public func additionalValue(for key: String) -> String? {
    additionalInfo[key]
  }

  /**
   * Returns a new metadata instance with the specified key-value added.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The value to store
   * - Returns: A new metadata instance with the added key-value
   */
  public func with(key: MetadataKey, value: String) -> BackupOperationMetadata {
    var newMetadata=metadata
    newMetadata[key]=value

    return BackupOperationMetadata(
      startTime: startTime,
      endTime: endTime,
      metadata: newMetadata,
      additionalInfo: additionalInfo
    )
  }

  /**
   * Returns a new metadata instance with the specified additional key-value added.
   *
   * - Parameters:
   *   - key: The string key
   *   - value: The value to store
   *   - privacy: The privacy level for this metadata
   * - Returns: A new metadata instance with the added key-value
   */
  public func withAdditional(
    key: String,
    value: String,
    privacy _: LogPrivacy = .private
  ) -> BackupOperationMetadata {
    var newAdditionalInfo=additionalInfo
    newAdditionalInfo[key]=value

    return BackupOperationMetadata(
      startTime: startTime,
      endTime: endTime,
      metadata: metadata,
      additionalInfo: newAdditionalInfo
    )
  }

  /**
   * Returns all metadata as a dictionary with privacy annotations.
   *
   * - Returns: Dictionary of metadata with keys and privacy-annotated values
   */
  public func asLogMetadata() -> [String: PrivacyAnnotatedString] {
    var result: [String: PrivacyAnnotatedString]=[:]

    // Add type-safe metadata with appropriate privacy levels
    for (key, value) in metadata {
      let privacyLevel=privacyLevelForKey(key)
      result[key.rawValue]=value.withPrivacyLevel(privacyLevel)
    }

    // Add duration and timestamps
    result["duration"]=String(format: "%.2f", duration).withPrivacyLevel(.public)
    result["startTime"]=startTime.description.withPrivacyLevel(.public)
    result["endTime"]=endTime.description.withPrivacyLevel(.public)

    // Add additional info with private privacy level by default
    for (key, value) in additionalInfo {
      result[key]=value.withPrivacyLevel(.private)
    }

    return result
  }

  /**
   * Determines the appropriate privacy level for a metadata key.
   *
   * - Parameter key: The metadata key
   * - Returns: The appropriate privacy level
   */
  private func privacyLevelForKey(_ key: MetadataKey) -> LogPrivacy {
    switch key {
      case .operationType, .compressionLevel, .verificationEnabled, .priority, .excludedCount,
           .includedCount:
        .public
      case .hostname:
        .private
      case .repositoryID, .snapshotID, .targetPath:
        .private
    }
  }
}
