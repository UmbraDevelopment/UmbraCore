// Export Foundation and OSLog types that are needed for UmbraErrors
@_exported import Foundation
@_exported import OSLog

// Explicitly export the types we need from Foundation
@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID

// The UmbraErrors module directly imports all components from Core, DTOs, Domains, and Mapping
// This allows consumers to just import UmbraErrors without needing to know about the submodules

// Re-export ErrorDTO from the DTOs package
@_exported import struct UmbraErrorsDTOs.ErrorDTO

// Re-export error domains
public enum ErrorDomain {
  // Common domains
  public static let scheduling="Scheduling"
}

/// Configuration errors for the Alpha Dot Five architecture
///
/// These error types represent various failure conditions that can occur
/// during configuration operations. All errors include descriptive messages
/// to facilitate debugging and error handling.
public enum ConfigError: Error, Sendable, Equatable {
  /// Thrown when initialisation of a configuration service fails
  case initialisationError(message: String)

  /// Thrown when attempting to add a configuration source that already exists
  case duplicateSource(message: String)

  /// Thrown when a requested configuration source cannot be found
  case sourceNotFound(message: String)

  /// Thrown when there is a general error with a configuration source
  case sourceError(message: String, error: Error?)

  /// Thrown when attempting to access a configuration value with the wrong type
  case typeMismatch(message: String, expected: String, actual: String)

  /// Thrown when no writable configuration source is available
  case noWritableSource(message: String)

  /// Thrown when attempting to write to a read-only configuration source
  case sourceReadOnly(message: String)

  public static func == (lhs: ConfigError, rhs: ConfigError) -> Bool {
    switch (lhs, rhs) {
      case let (.initialisationError(lm), .initialisationError(rm)):
        lm == rm
      case let (.duplicateSource(lm), .duplicateSource(rm)):
        lm == rm
      case let (.sourceNotFound(lm), .sourceNotFound(rm)):
        lm == rm
      case let (.sourceError(lm, _), .sourceError(rm, _)):
        lm == rm
      case let (.typeMismatch(lm, le, la), .typeMismatch(rm, re, ra)):
        lm == rm && le == re && la == ra
      case let (.noWritableSource(lm), .noWritableSource(rm)):
        lm == rm
      case let (.sourceReadOnly(lm), .sourceReadOnly(rm)):
        lm == rm
      default:
        false
    }
  }
}

// Add CustomStringConvertible conformance to ConfigError
extension ConfigError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .initialisationError(message):
        return "Configuration initialisation error: \(message)"
      case let .duplicateSource(message):
        return "Duplicate configuration source: \(message)"
      case let .sourceNotFound(message):
        return "Configuration source not found: \(message)"
      case let .sourceError(message, error):
        if let error {
          return "Configuration source error: \(message) - \(error)"
        }
        return "Configuration source error: \(message)"
      case let .typeMismatch(message, expected, actual):
        return "Configuration type mismatch: \(message) - Expected: \(expected), Actual: \(actual)"
      case let .noWritableSource(message):
        return "No writable configuration source available: \(message)"
      case let .sourceReadOnly(message):
        return "Configuration source is read-only: \(message)"
    }
  }
}
