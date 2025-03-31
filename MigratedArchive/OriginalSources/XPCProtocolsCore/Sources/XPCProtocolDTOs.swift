import Foundation
import UmbraCoreTypes
import UmbraErrors

// XPC Protocol DTO definitions
public enum XPCProtocolDTOs {
  /// DTO representing security error information
  public struct SecurityErrorDTO: Codable, Sendable {
    /// Error code
    public let code: Int
    /// Error domain
    public let domain: String
    /// Error description
    public let description: String
    /// Additional properties
    public let properties: [String: String]

    /// Standard initialiser
    /// - Parameters:
    ///   - code: Error code
    ///   - domain: Error domain
    ///   - description: Error description
    ///   - properties: Additional properties
    public init(
      code: Int,
      domain: String,
      description: String,
      properties: [String: String]=[:]
    ) {
      self.code=code
      self.domain=domain
      self.description=description
      self.properties=properties
    }
  }

  /// Status DTO
  public struct ServiceStatusDTO: Codable, Sendable, Equatable {
    /// Status code
    public let code: Int

    /// Status message
    public let message: String

    /// Is service running
    public let isRunning: Bool

    /// Service version
    public let version: String

    /// Additional properties
    public let properties: [String: String]

    /// Standard initialiser
    /// - Parameters:
    ///   - code: Status code (0=OK, non-zero=error)
    ///   - message: Status message
    ///   - isRunning: Is service running
    ///   - version: Service version
    ///   - properties: Additional properties
    public init(
      code: Int=0,
      message: String="OK",
      isRunning: Bool=false,
      version: String="unknown",
      properties: [String: String]=[:]
    ) {
      self.code=code
      self.message=message
      self.isRunning=isRunning
      self.version=version
      self.properties=properties
    }
  }
}
