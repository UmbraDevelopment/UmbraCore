import ErrorLoggingInterfaces
import Foundation
import LoggingTypes
import UmbraErrors

/**
 # Privacy Level

 Defines the privacy level for handling sensitive information in error logs.
 This helps ensure that personally identifiable information (PII) and other
 sensitive data are handled appropriately based on application requirements.

 ## Levels

 - `public`: Information can be included in logs without restrictions
 - `restricted`: Sensitive information is partially redacted
 - `private`: Sensitive information is fully redacted or excluded
 */
public enum PrivacyLevel: String, Sendable, Comparable, CaseIterable {
  /// Information can be included in logs without restrictions
  case `public`

  /// Sensitive information is partially redacted
  case restricted

  /// Sensitive information is fully redacted or excluded
  case `private`

  /// Allow comparison for determining if one level is more restricted than another
  public static func < (lhs: PrivacyLevel, rhs: PrivacyLevel) -> Bool {
    let order: [PrivacyLevel]=[.public, .restricted, .private]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/**
 # Error Logger Configuration

 Configuration settings for the ErrorLoggerActor implementation,
 following the Alpha Dot Five architecture principles.

 ## Features

 This configuration allows customisation of:
 - Global minimum log level
 - Default error log level
 - Source information inclusion
 - Metadata privacy handling
 - Contextual error formatting options

 ## Thread Safety

 This structure is Sendable and immutable, making it safe to
 share across actor isolation boundaries.
 */
public struct ErrorLoggerConfiguration: Sendable {
  /// Global minimum logging level
  public let globalMinimumLevel: ErrorLoggingLevel

  /// Default level to use when logging errors without explicit level
  public let defaultErrorLevel: ErrorLoggingLevel

  /// Whether to include source code information (file, function, line)
  public let includeSourceInfo: Bool

  /// Privacy level for metadata in logs
  public let metadataPrivacyLevel: PrivacyLevel

  /**
   Initialises a new error logger configuration with custom settings.

   - Parameters:
     - globalMinimumLevel: Minimum level for all error logs
     - defaultErrorLevel: Level to use when not specified
     - includeSourceInfo: Whether to log source information
     - metadataPrivacyLevel: Privacy level for log metadata
   */
  public init(
    globalMinimumLevel: ErrorLoggingLevel = .info,
    defaultErrorLevel: ErrorLoggingLevel = .error,
    includeSourceInfo: Bool=true,
    metadataPrivacyLevel: PrivacyLevel = .private
  ) {
    self.globalMinimumLevel=globalMinimumLevel
    self.defaultErrorLevel=defaultErrorLevel
    self.includeSourceInfo=includeSourceInfo
    self.metadataPrivacyLevel=metadataPrivacyLevel
  }

  /**
   Creates a configuration with debug settings.

   This factory method creates a configuration suitable for development
   and debugging environments with more verbose logging.

   - Returns: Debug-oriented configuration
   */
  public static func debug() -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(
      globalMinimumLevel: .debug,
      defaultErrorLevel: .warning,
      includeSourceInfo: true,
      metadataPrivacyLevel: .public
    )
  }

  /**
   Creates a configuration with production settings.

   This factory method creates a configuration suitable for production
   environments with more conservative logging and privacy settings.

   - Returns: Production-oriented configuration
   */
  public static func production() -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(
      globalMinimumLevel: .warning,
      defaultErrorLevel: .error,
      includeSourceInfo: false,
      metadataPrivacyLevel: .private
    )
  }

  /**
   Creates a configuration with privacy-focused settings.

   This factory method creates a configuration that prioritises
   privacy protection when logging errors.

   - Returns: Privacy-oriented configuration
   */
  public static func privacyFocused() -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(
      globalMinimumLevel: .warning,
      defaultErrorLevel: .error,
      includeSourceInfo: false,
      metadataPrivacyLevel: .restricted
    )
  }
}
