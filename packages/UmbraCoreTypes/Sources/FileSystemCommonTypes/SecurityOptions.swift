import Foundation

/// Security level for file operations
public enum SecurityLevel: String, Sendable, Equatable, Hashable {
  /// Standard security level - normal file operations
  case standard

  /// Elevated security level - data is protected during normal operation
  case elevated

  /// High security level - data is protected with additional safeguards
  case high

  /// Restricted security level - special permissions required
  case restricted
}

/// Security options for file path access
public struct SecurityOptions: Sendable, Equatable, Hashable {
  /// The security level
  public let level: SecurityLevel

  /// Additional security attributes
  public let attributes: [String: String]

  /// Creates a new SecurityOptions instance
  /// - Parameters:
  ///   - level: The security level
  ///   - attributes: Additional security attributes
  public init(level: SecurityLevel, attributes: [String: String]=[:]) {
    self.level=level
    self.attributes=attributes
  }
}
