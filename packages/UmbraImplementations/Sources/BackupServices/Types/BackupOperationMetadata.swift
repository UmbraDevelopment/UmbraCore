import BackupInterfaces
import Foundation

/**
 * Metadata for backup operations.
 *
 * This structure captures metadata about a backup operation, including
 * timing information, operation types, and additional contextual data
 * that can be useful for logging, debugging, and performance analysis.
 */
public struct BackupOperationMetadata: Sendable {
  /// Start time of the operation
  public let startTime: Date

  /// End time of the operation
  public let endTime: Date

  /// Type of operation that was performed
  public let operationType: String

  /// Additional information about the operation
  public let additionalInfo: [String: String]

  /**
   * Duration of the operation in seconds.
   */
  public var duration: TimeInterval {
    endTime.timeIntervalSince(startTime)
  }

  /**
   * Initialises a new operation metadata object.
   *
   * - Parameters:
   *   - startTime: Start time of the operation
   *   - endTime: End time of the operation
   *   - operationType: Type of operation that was performed
   *   - additionalInfo: Optional additional information
   */
  public init(
    startTime: Date,
    endTime: Date,
    operationType: String,
    additionalInfo: [String: String]=[:]
  ) {
    self.startTime=startTime
    self.endTime=endTime
    self.operationType=operationType
    self.additionalInfo=additionalInfo
  }

  /**
   * Creates a new metadata object with additional information.
   *
   * - Parameter info: Additional information to add
   * - Returns: A new metadata object with the combined information
   */
  public func withAdditionalInfo(_ info: [String: String]) -> BackupOperationMetadata {
    var combinedInfo=additionalInfo
    for (key, value) in info {
      combinedInfo[key]=value
    }

    return BackupOperationMetadata(
      startTime: startTime,
      endTime: endTime,
      operationType: operationType,
      additionalInfo: combinedInfo
    )
  }

  /**
   * Returns the metadata as a dictionary for logging.
   *
   * - Returns: Dictionary representation of the metadata
   */
  public func toDictionary() -> [String: String] {
    var result: [String: String]=[
      "startTime": startTime.ISO8601Format(),
      "endTime": endTime.ISO8601Format(),
      "duration": String(format: "%.2f", duration),
      "operationType": operationType
    ]

    // Add all additional info
    for (key, value) in additionalInfo {
      result[key]=value
    }

    return result
  }
}
