import ErrorLoggingInterfaces
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

 This aligns with the Alpha Dot Five architecture principles for privacy-aware logging.
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

  /**
   Maps the privacy level to the corresponding LogPrivacyLevel.

   - Returns: The equivalent LogPrivacyLevel for this privacy level
   */
  public func toLogPrivacyLevel() -> LogPrivacyLevel {
    switch self {
      case .public:
        .public
      case .restricted:
        .private
      case .private:
        .sensitive
    }
  }
}

/**
 # Error Logger Configuration

 Configuration settings for the ErrorLoggerActor implementation,
 following the Alpha Dot Five architecture principles.

 ## Features

 This configuration allows customisation of:
 - Minimum log level
 - Default error log level
 - Source information inclusion
 - Metadata privacy handling
 - Contextual error formatting options

 ## Thread Safety

 This structure is Sendable and immutable, making it safe to
 share across actor isolation boundaries.
 */
public struct ErrorLoggerConfiguration: Sendable {
  /// Minimum logging level
  public let minimumLevel: ErrorLoggingLevel

  /// Default level to use when logging errors without explicit level
  public let defaultErrorLevel: ErrorLoggingLevel

  /// Whether to include source code information (file, function, line)
  public let includeSourceInfo: Bool

  /// Privacy level for metadata in logs
  public let metadataPrivacyLevel: PrivacyLevel

  /// Whether to include stack traces in error logs
  public let includeStackTraces: Bool

  /// Maximum depth for nested errors
  public let maxNestedErrorDepth: Int

  /**
   Initialises a new error logger configuration with custom settings.

   - Parameters:
     - minimumLevel: Minimum level for all error logs
     - defaultErrorLevel: Level to use when not specified
     - includeSourceInfo: Whether to log source information
     - metadataPrivacyLevel: Privacy level for log metadata
     - includeStackTraces: Whether to include stack traces in error logs
     - maxNestedErrorDepth: Maximum depth for nested errors
   */
  public init(
    minimumLevel: ErrorLoggingLevel = .info,
    defaultErrorLevel: ErrorLoggingLevel = .error,
    includeSourceInfo: Bool=true,
    metadataPrivacyLevel: PrivacyLevel = .private,
    includeStackTraces: Bool=false,
    maxNestedErrorDepth: Int=3
  ) {
    self.minimumLevel=minimumLevel
    self.defaultErrorLevel=defaultErrorLevel
    self.includeSourceInfo=includeSourceInfo
    self.metadataPrivacyLevel=metadataPrivacyLevel
    self.includeStackTraces=includeStackTraces
    self.maxNestedErrorDepth=maxNestedErrorDepth
  }

  /**
   Creates a configuration with debug settings.

   This factory method creates a configuration suitable for development
   and debugging environments with more verbose logging.

   - Returns: A configuration optimised for debugging
   */
  public static func debugConfiguration() -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(
      minimumLevel: .debug,
      defaultErrorLevel: .debug,
      includeSourceInfo: true,
      metadataPrivacyLevel: .public,
      includeStackTraces: true,
      maxNestedErrorDepth: 5
    )
  }

  /**
   Creates a configuration with production settings.

   This factory method creates a configuration suitable for production
   environments with appropriate privacy controls and reduced verbosity.

   - Returns: A configuration optimised for production use
   */
  public static func productionConfiguration() -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(
      minimumLevel: .warning,
      defaultErrorLevel: .error,
      includeSourceInfo: false,
      metadataPrivacyLevel: .private,
      includeStackTraces: false,
      maxNestedErrorDepth: 1
    )
  }

  /**
   Creates a configuration with testing settings.

   This factory method creates a configuration suitable for automated testing
   with balanced verbosity and privacy controls.

   - Returns: A configuration optimised for testing
   */
  public static func testingConfiguration() -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(
      minimumLevel: .info,
      defaultErrorLevel: .warning,
      includeSourceInfo: true,
      metadataPrivacyLevel: .restricted,
      includeStackTraces: true,
      maxNestedErrorDepth: 3
    )
  }
}
