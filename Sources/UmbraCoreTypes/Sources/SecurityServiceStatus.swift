import Foundation

/// Represents the status of a security service
/// Used for health checks and monitoring
public struct SecurityServiceStatus: Sendable, Equatable, Hashable {
  /// Current operational status of the service
  public let status: String

  /// Version of the service
  public let version: String

  /// Timestamp when the status was generated
  public let timestamp: TimeInterval

  /// Additional metrics as key-value pairs
  public let metrics: [String: Double]

  /// Additional string information as key-value pairs
  public let stringInfo: [String: String]

  /// Create a new security service status
  /// - Parameters:
  ///   - status: The current status (e.g., "active", "degraded", "offline")
  ///   - version: The service version
  ///   - timestamp: The timestamp when the status was generated (defaults to current time)
  ///   - metrics: Numeric metrics for the service
  ///   - stringInfo: Additional string information about the service
  public init(
    status: String,
    version: String,
    timestamp: TimeInterval=Date().timeIntervalSince1970,
    metrics: [String: Double]=[:],
    stringInfo: [String: String]=[:]
  ) {
    self.status=status
    self.version=version
    self.timestamp=timestamp
    self.metrics=metrics
    self.stringInfo=stringInfo
  }

  /// Legacy initializer to support migration from dictionary-based approach
  /// - Parameters:
  ///   - status: The current status
  ///   - version: The service version
  ///   - info: Additional service information in dictionary format
  public init(status: String, version: String, info: [String: Any]) {
    self.status=status
    self.version=version
    timestamp=(info["timestamp"] as? TimeInterval) ?? Date().timeIntervalSince1970

    // Extract metrics
    var extractedMetrics: [String: Double]=[:]
    for (key, value) in info {
      if let numericValue=value as? Double {
        extractedMetrics[key]=numericValue
      }
    }
    metrics=extractedMetrics

    // Extract string info
    var extractedStringInfo: [String: String]=[:]
    for (key, value) in info {
      if let stringValue=value as? String {
        extractedStringInfo[key]=stringValue
      } else if !(value is Double) {
        // Convert non-string, non-double values to strings
        extractedStringInfo[key]=String(describing: value)
      }
    }
    stringInfo=extractedStringInfo
  }

  // Required for Equatable/Hashable
  public static func == (lhs: SecurityServiceStatus, rhs: SecurityServiceStatus) -> Bool {
    lhs.status == rhs.status &&
      lhs.version == rhs.version &&
      lhs.timestamp == rhs.timestamp &&
      lhs.metrics == rhs.metrics &&
      lhs.stringInfo == rhs.stringInfo
  }

  // Required for Hashable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(status)
    hasher.combine(version)
    hasher.combine(timestamp)
    hasher.combine(metrics)
    hasher.combine(stringInfo)
  }
}
