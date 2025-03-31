import Foundation

/**
 * Result of a backup operation with generically-typed success value.
 *
 * This structure provides a standardised way to return operation results
 * with optional progress reporting, following the Alpha Dot Five architecture
 * pattern for structured return types.
 */
public struct BackupOperationResult<Success>: Sendable, Equatable where Success: Sendable,
Success: Equatable {
  /// The operation-specific result
  public let value: Success

  /// Optional progress reporting stream
  public let progressStream: AsyncStream<BackupProgress>?

  /// Metadata about the operation
  public let metadata: [String: String]?

  /**
   * Creates a new operation result.
   *
   * - Parameters:
   *   - value: The operation-specific result
   *   - progressStream: Optional progress reporting stream
   *   - metadata: Metadata about the operation
   */
  public init(
    value: Success,
    progressStream: AsyncStream<BackupProgress>?=nil,
    metadata: [String: String]?=nil
  ) {
    self.value=value
    self.progressStream=progressStream
    self.metadata=metadata
  }

  /**
   * Compares two BackupOperationResult instances for equality.
   *
   * Note that the progressStream property is not compared as AsyncStream
   * does not conform to Equatable.
   *
   * - Parameters:
   *   - lhs: The first result to compare
   *   - rhs: The second result to compare
   * - Returns: True if the results are equal, false otherwise
   */
  public static func == (
    lhs: BackupOperationResult<Success>,
    rhs: BackupOperationResult<Success>
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
}

/**
 * Metadata about a backup operation.
 *
 * This structure provides standardised metadata for all backup operations,
 * including timing information and operation-specific parameters.
 */
public struct BackupOperationMetadata: Sendable, Equatable {
  /// The time the operation started
  public let startTime: Date

  /// The time the operation completed
  public let endTime: Date

  /// The duration of the operation in seconds
  public let duration: TimeInterval

  /// Optional operation type
  public let operationType: String?

  /// Optional additional metadata
  public let additionalInfo: [String: String]

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
    operationType: String?=nil,
    additionalInfo: [String: String]=[:]
  ) {
    self.startTime=startTime
    self.endTime=endTime
    duration=endTime.timeIntervalSince(startTime)
    self.operationType=operationType
    self.additionalInfo=additionalInfo
  }
}
