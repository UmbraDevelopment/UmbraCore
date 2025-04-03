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
      case .credentialsNotFound(let message):
        return "Credentials not found: \(message)"
      case .accessDenied(let message):
        return "Access denied: \(message)"
      case .keychainError(let message):
        return "Keychain error: \(message)"
      case .dataCorruption(let message):
        return "Data corruption: \(message)"
      case .unexpected(let message):
        return "Unexpected error: \(message)"
    }
  }
}
