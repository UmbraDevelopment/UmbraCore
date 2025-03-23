import UmbraCoreTypes

/// Foundation-independent DTO for representing service status information
/// This DTO provides status, version, and additional metadata about services
/// without requiring Foundation types.
public struct ServiceStatusDTO: Sendable, Equatable {
  /// Current service status
  public let status: String

  /// Service version
  public let version: String

  /// String information about the service
  public let stringInfo: [String: String]

  /// Integer information about the service
  public let intInfo: [String: Int]

  /// Create a service status DTO
  /// - Parameters:
  ///   - status: Current service status
  ///   - version: Service version
  ///   - stringInfo: String metadata
  ///   - intInfo: Integer metadata
  public init(
    status: String,
    version: String,
    stringInfo: [String: String]=[:],
    intInfo: [String: Int]=[:]
  ) {
    self.status=status
    self.version=version
    self.stringInfo=stringInfo
    self.intInfo=intInfo
  }

  /// Returns whether the current service is available
  public var isAvailable: Bool {
    status.lowercased() == "available" || status.lowercased() == "online"
  }

  /// Returns the service version as components
  public func versionComponents() -> [Int] {
    version.split(separator: ".").compactMap { Int($0) }
  }
}

/// Extension with factory methods for common service statuses
extension ServiceStatusDTO {
  /// Returns a service status indicating the service is available
  /// - Parameter version: Service version
  /// - Returns: A service status DTO
  public static func available(version: String="1.0.0") -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: "Available",
      version: version,
      stringInfo: ["state": "running"]
    )
  }

  /// Returns a service status indicating the service is unavailable
  /// - Parameter reason: Reason for unavailability
  /// - Returns: A service status DTO
  public static func unavailable(reason: String) -> ServiceStatusDTO {
    ServiceStatusDTO(
      status: "Unavailable",
      version: "0.0.0",
      stringInfo: ["reason": reason]
    )
  }

  /// Returns a service status indicating the service is in maintenance
  /// - Parameter estimatedCompletionTime: Estimated completion time
  /// - Returns: A service status DTO
  public static func maintenance(estimatedCompletionTime: String?=nil) -> ServiceStatusDTO {
    var info=["state": "maintenance"]
    if let time=estimatedCompletionTime {
      info["estimatedCompletion"]=time
    }

    return ServiceStatusDTO(
      status: "Maintenance",
      version: "1.0.0",
      stringInfo: info
    )
  }
}
