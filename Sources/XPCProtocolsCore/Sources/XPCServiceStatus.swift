/**
 # XPC Service Status

 This file defines the structure for reporting XPC service status information
 in a standardized format across all UmbraCore XPC services.

 ## Features

 * Timestamp information for when status was captured
 * Protocol and service version information
 * Optional device identification
 * Support for additional service-specific status information
 * Full Codable support for serialization
 */

import Foundation

/// Status information about an XPC service
///
/// This struct provides detailed information about the current state of an XPC service,
/// including its operational status, version information, and other metadata.
public struct XPCServiceStatus: Codable, Hashable, Sendable {
  /// When the status was captured
  public var timestamp: Date

  /// Version of the XPC protocol used
  public var protocolVersion: String

  /// Version of the service implementation
  public var serviceVersion: String?

  /// Device identifier if available
  public var deviceIdentifier: String?

  /// Additional status information
  public var additionalInfo: [String: String]?

  /// Creates a new service status object
  /// - Parameters:
  ///   - timestamp: When the status was captured
  ///   - protocolVersion: Protocol version
  ///   - serviceVersion: Service version
  ///   - deviceIdentifier: Device identifier
  ///   - additionalInfo: Additional metadata
  public init(
    timestamp: Date,
    protocolVersion: String,
    serviceVersion: String?=nil,
    deviceIdentifier: String?=nil,
    additionalInfo: [String: String]?=nil
  ) {
    self.timestamp=timestamp
    self.protocolVersion=protocolVersion
    self.serviceVersion=serviceVersion
    self.deviceIdentifier=deviceIdentifier
    self.additionalInfo=additionalInfo
  }

  /// Creates a status with common failure information
  /// - Parameters:
  ///   - errorReason: Reason for the failure
  ///   - protocolVersion: Protocol version
  /// - Returns: Status object indicating failure
  public static func failure(
    errorReason: String,
    protocolVersion: String
  ) -> XPCServiceStatus {
    XPCServiceStatus(
      timestamp: Date(),
      protocolVersion: protocolVersion,
      additionalInfo: ["errorReason": errorReason, "isActive": "false"]
    )
  }

  /// A convenience initializer for creating service status
  /// - Parameters:
  ///   - isActive: Whether the service is active
  ///   - version: The version of the service
  ///   - serviceType: Type of service
  ///   - additionalInfo: Additional information about the service
  public init(
    isActive: Bool,
    version: String,
    serviceType: String,
    additionalInfo: [String: String]=[:]
  ) {
    var info=additionalInfo
    info["isActive"]=isActive ? "true" : "false"
    info["serviceType"]=serviceType

    self.init(
      timestamp: Date(),
      protocolVersion: "1.0",
      serviceVersion: version,
      additionalInfo: info
    )
  }
}
