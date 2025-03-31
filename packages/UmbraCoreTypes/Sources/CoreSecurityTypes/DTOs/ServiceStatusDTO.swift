import Foundation

/**
 Data transfer object for security service status.

 This DTO provides a standardised way to report the status of security services
 while maintaining type safety and actor isolation.
 */
public struct ServiceStatusDTO: Sendable, Equatable, Codable {
  /// Service operational status
  public enum Status: String, Sendable, Equatable, Codable {
    /// Service is operational
    case operational

    /// Service is degraded but functioning
    case degraded

    /// Service is offline or unavailable
    case offline

    /// Service status is unknown
    case unknown

    /// Service is starting up
    case starting

    /// Service is shutting down
    case shuttingDown
  }

  /// Current service status
  public let status: Status

  /// Timestamp when the status was determined
  public let timestamp: Date

  /// Optional detailed status message
  public let message: String?

  /// Provider type reporting this status
  public let providerType: SecurityProviderType

  /// Status code for more detailed reporting
  public let statusCode: Int

  /// Additional status metadata
  public let metadata: [String: String]?

  /**
   Initialises a new service status report.

   - Parameters:
     - status: Operational status of the service
     - timestamp: Time when the status was determined
     - message: Optional detailed status message
     - providerType: Provider type reporting this status
     - statusCode: Detailed status code
     - metadata: Additional status metadata
   */
  public init(
    status: Status,
    timestamp: Date=Date(),
    message: String?=nil,
    providerType: SecurityProviderType,
    statusCode: Int=0,
    metadata: [String: String]?=nil
  ) {
    self.status=status
    self.timestamp=timestamp
    self.message=message
    self.providerType=providerType
    self.statusCode=statusCode
    self.metadata=metadata
  }

  /// Creates an operational status report
  public static func operational(
    providerType: SecurityProviderType,
    message: String?=nil
  ) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: .operational,
      message: message,
      providerType: providerType
    )
  }

  /// Creates a degraded status report
  public static func degraded(
    providerType: SecurityProviderType,
    message: String,
    statusCode: Int=1
  ) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: .degraded,
      message: message,
      providerType: providerType,
      statusCode: statusCode
    )
  }

  /// Creates an offline status report
  public static func offline(
    providerType: SecurityProviderType,
    message: String,
    statusCode: Int=2
  ) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: .offline,
      message: message,
      providerType: providerType,
      statusCode: statusCode
    )
  }
}
