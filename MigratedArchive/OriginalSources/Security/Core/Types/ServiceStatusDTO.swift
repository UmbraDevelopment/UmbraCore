import Foundation

/// Data transfer object representing the status of a security service
public struct ServiceStatusDTO: Equatable, Sendable {
  /// Status enumeration representing service health
  public enum Status: String, Sendable, Equatable {
    /// Service is fully operational and healthy
    case healthy="Healthy"
    /// Service is operational but with reduced capabilities or performance
    case degraded="Degraded"
    /// Service is completely unavailable
    case unavailable="Unavailable"
    /// Service status is unknown or cannot be determined
    case unknown="Unknown"
  }

  /// The current service status
  public let status: Status

  /// The service version
  public let version: String

  /// Timestamp when the status was determined
  public let timestamp: UInt64

  /// Additional status details
  public let details: [String: String]

  /// Initialise with status, version, timestamp and details
  /// - Parameters:
  ///   - status: Service status
  ///   - version: Service version
  ///   - timestamp: Status timestamp (milliseconds since 1970)
  ///   - details: Additional status details
  public init(
    status: Status,
    version: String,
    timestamp: UInt64,
    details: [String: String]=[:]
  ) {
    self.status=status
    self.version=version
    self.timestamp=timestamp
    self.details=details
  }

  /// Create a healthy status
  /// - Parameters:
  ///   - version: Service version
  ///   - timestamp: Optional timestamp (defaults to current time)
  /// - Returns: A ServiceStatusDTO with healthy status
  public static func healthy(
    version: String,
    timestamp: UInt64=UInt64(Date().timeIntervalSince1970 * 1000)
  ) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: .healthy,
      version: version,
      timestamp: timestamp
    )
  }

  /// Create a degraded status
  /// - Parameters:
  ///   - version: Service version
  ///   - reason: Reason for degraded status
  ///   - timestamp: Optional timestamp (defaults to current time)
  /// - Returns: A ServiceStatusDTO with degraded status
  public static func degraded(
    version: String,
    reason: String,
    timestamp: UInt64=UInt64(Date().timeIntervalSince1970 * 1000)
  ) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: .degraded,
      version: version,
      timestamp: timestamp,
      details: ["reason": reason]
    )
  }

  /// Create an unavailable status
  /// - Parameters:
  ///   - version: Service version
  ///   - reason: Reason for unavailability
  ///   - timestamp: Optional timestamp (defaults to current time)
  /// - Returns: A ServiceStatusDTO with unavailable status
  public static func unavailable(
    version: String,
    reason: String,
    timestamp: UInt64=UInt64(Date().timeIntervalSince1970 * 1000)
  ) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: .unavailable,
      version: version,
      timestamp: timestamp,
      details: ["reason": reason]
    )
  }
}
