import Foundation

/// Errors specific to security operations in Restic
public enum SecurityError: Error, CustomStringConvertible {
  /// Credentials not found for the given repository
  case credentialsNotFound(String)

  /// Access denied when trying to access credentials
  case accessDenied(String)

  /// Generic keychain error
  case keychainError(String)

  /// Data corruption error
  case dataCorruption(String)

  /// Unexpected error during security operations
  case unexpected(String)

  /// Human-readable description of the error
  public var description: String {
    switch self {
      case let .credentialsNotFound(message):
        "Credentials not found: \(message)"
      case let .accessDenied(message):
        "Access denied: \(message)"
      case let .keychainError(message):
        "Keychain error: \(message)"
      case let .dataCorruption(message):
        "Data corruption: \(message)"
      case let .unexpected(message):
        "Unexpected error: \(message)"
    }
  }
}
