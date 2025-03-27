import Foundation
import SecurityTypes

/// Result of a security operation
public struct SecurityResult {
  /// Whether the operation was successful
  public let success: Bool

  /// Output data from the operation, if any
  public let data: Data?

  /// Additional metadata about the operation
  public let metadata: [String: String]

  /// Initialise a new SecurityResult
  /// - Parameters:
  ///   - success: Whether the operation was successful
  ///   - data: Output data from the operation, if any
  ///   - metadata: Additional metadata about the operation
  public init(success: Bool, data: Data? = nil, metadata: [String: String] = [:]) {
    self.success = success
    self.data = data
    self.metadata = metadata
  }
}

/// Current status of the security system
public struct SecurityStatus {
  /// Whether the security system is active
  public let isActive: Bool

  /// Numeric status code
  public let statusCode: Int

  /// Human-readable status message
  public let statusMessage: String

  /// Initialise a new SecurityStatus
  /// - Parameters:
  ///   - isActive: Whether the security system is active
  ///   - statusCode: Numeric status code
  ///   - statusMessage: Human-readable status message
  public init(isActive: Bool, statusCode: Int, statusMessage: String) {
    self.isActive = isActive
    self.statusCode = statusCode
    self.statusMessage = statusMessage
  }
}
