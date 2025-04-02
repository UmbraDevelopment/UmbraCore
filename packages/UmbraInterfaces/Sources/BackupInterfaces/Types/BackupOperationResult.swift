import Foundation

/**
 * Response container for a backup operation with generically-typed success value.
 *
 * This structure provides a standardised way to return operation responses
 * with optional progress reporting, following the Alpha Dot Five architecture
 * pattern for structured return types.
 */
public struct BackupOperationResponse<Success>: Sendable, Equatable where Success: Sendable,
Success: Equatable {
  /// The operation-specific result
  public let value: Success

  /// Optional progress reporting stream
  public let progressStream: AsyncStream<BackupProgressInfo>?

  /// Strongly-typed metadata about the operation
  public let metadata: BackupOperationResultMetadata?

  /**
   * Creates a new operation response.
   *
   * - Parameters:
   *   - value: The operation-specific result
   *   - progressStream: Optional progress reporting stream
   *   - metadata: Strongly-typed metadata about the operation
   */
  public init(
    value: Success,
    progressStream: AsyncStream<BackupProgressInfo>?=nil,
    metadata: BackupOperationResultMetadata?=nil
  ) {
    self.value=value
    self.progressStream=progressStream
    self.metadata=metadata
  }

  /**
   * Creates a new operation response with the current date for start and end times.
   *
   * - Parameters:
   *   - value: The operation-specific result
   *   - progressStream: Optional progress reporting stream
   *   - operationType: Type of operation performed
   *   - additionalInfo: Additional metadata about the operation
   */
  public init(
    value: Success,
    progressStream: AsyncStream<BackupProgressInfo>?=nil,
    operationType: String,
    additionalInfo: [String: String]=[:]
  ) {
    let now=Date()
    let metadata=BackupOperationResultMetadata(
      startTime: now,
      endTime: now,
      metadata: [.operationType: operationType],
      additionalInfo: additionalInfo
    )

    self.init(
      value: value,
      progressStream: progressStream,
      metadata: metadata
    )
  }

  /**
   * Compares two BackupOperationResponse instances for equality.
   *
   * Note that the progressStream property is not compared as AsyncStream
   * does not conform to Equatable.
   *
   * - Parameters:
   *   - lhs: The first response to compare
   *   - rhs: The second response to compare
   * - Returns: True if the responses are equal, false otherwise
   */
  public static func == (
    lhs: BackupOperationResponse<Success>,
    rhs: BackupOperationResponse<Success>
  ) -> Bool {
    // Compare only the value and metadata, not the progressStream
    // as AsyncStream doesn't conform to Equatable
    let metadataEqual: Bool=switch (lhs.metadata, rhs.metadata) {
      case (.none, .none):
        true
      case let (.some(lhsMetadata), .some(rhsMetadata)):
        lhsMetadata == rhsMetadata
      default:
        false
    }

    return lhs.value == rhs.value && metadataEqual
  }

  /**
   * Returns a new response with updated metadata.
   *
   * - Parameter metadata: The new metadata
   * - Returns: A new response with the updated metadata
   */
  public func with(metadata: BackupOperationResultMetadata) -> BackupOperationResponse<Success> {
    BackupOperationResponse(
      value: value,
      progressStream: progressStream,
      metadata: metadata
    )
  }

  /**
   * Returns a new response with the specified metadata key-value added.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The value to store
   * - Returns: A new response with the added metadata
   */
  public func with(
    key: BackupOperationResultMetadata.MetadataKey,
    value: String
  ) -> BackupOperationResponse<Success> {
    guard let existingMetadata=metadata else {
      // If no metadata exists, create new metadata with current timestamp
      let now=Date()
      let newMetadata=BackupOperationResultMetadata(
        startTime: now,
        endTime: now,
        metadata: [key: value]
      )
      return with(metadata: newMetadata)
    }

    return with(metadata: existingMetadata.with(key: key, value: value))
  }
}

/**
 * Metadata for a backup operation result.
 *
 * This structure provides standardised metadata for all backup operations,
 * including timing information and operation-specific parameters.
 */
public struct BackupOperationResultMetadata: Sendable, Equatable {
  /// The time the operation started
  public let startTime: Date

  /// The time the operation completed
  public let endTime: Date

  /// The duration of the operation in seconds
  public let duration: TimeInterval

  /// Optional operation type
  public let operationType: String?

  /// Optional additional metadata
  public var additionalInfo: [String: String]

  /**
   * Creates new operation metadata.
   *
   * - Parameters:
   *   - startTime: The time the operation started
   *   - endTime: The time the operation completed
   *   - operationType: Optional operation type
   *   - additionalInfo: Optional additional metadata
   */
  public init(
    startTime: Date,
    endTime: Date,
    metadata: [MetadataKey: String]=[:],
    additionalInfo: [String: String]=[:]
  ) {
    self.startTime=startTime
    self.endTime=endTime
    duration=endTime.timeIntervalSince(startTime)
    operationType=metadata[.operationType]
    self.additionalInfo=additionalInfo
  }

  public enum MetadataKey: String, Equatable, Hashable {
    case operationType
  }

  /**
   * Returns a new metadata with the specified key-value added.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The value to store
   * - Returns: A new metadata with the added key-value
   */
  public func with(key: MetadataKey, value: String) -> BackupOperationResultMetadata {
    var newMetadata=self
    newMetadata.additionalInfo[key.rawValue]=value
    return newMetadata
  }
}
