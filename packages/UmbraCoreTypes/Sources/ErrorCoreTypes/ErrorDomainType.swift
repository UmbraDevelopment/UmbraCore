import Foundation

/**
 # ErrorDomainType

 A type that defines the basic structure for error domains in the system.

 Error domains provide a way to organise errors into logical groups,
 enabling more structured error handling and improved diagnostics.
 */
public enum ErrorDomainType: String, Sendable, CaseIterable {
  /// Security-related errors (encryption, authentication, etc.)
  case security="UmbraCore.Security"

  /// Network-related errors (connectivity, HTTP, etc.)
  case network="UmbraCore.Network"

  /// Storage-related errors (file system, persistence, etc.)
  case storage="UmbraCore.Storage"

  /// Configuration-related errors (settings, preferences, etc.)
  case configuration="UmbraCore.Configuration"

  /// Resource-related errors (missing resources, etc.)
  case resource="UmbraCore.Resource"

  /// Validation-related errors (input validation, etc.)
  case validation="UmbraCore.Validation"

  /// Runtime errors that don't fit other categories
  case runtime="UmbraCore.Runtime"

  /// System-level errors (OS interactions, etc.)
  case system="UmbraCore.System"

  /// Application-specific errors
  case application="UmbraCore.Application"

  /// Unknown error domain
  case unknown="UmbraCore.Unknown"

  /**
   Creates an error domain from a string identifier.

   - Parameter identifier: The domain identifier string
   - Returns: The corresponding ErrorDomainType or .unknown if not found
   */
  public static func from(identifier: String) -> ErrorDomainType {
    ErrorDomainType.allCases.first { $0.rawValue == identifier } ?? .unknown
  }
}
