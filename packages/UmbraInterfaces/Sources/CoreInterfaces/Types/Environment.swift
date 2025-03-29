import Foundation

/// Represents the operating environment for UmbraCore
public enum Environment: String, Sendable, Equatable, CaseIterable {
  /// Development environment for building and testing
  case development

  /// Staging environment for pre-production validation
  case staging

  /// Production environment for released software
  case production

  /// Current environment based on build configuration
  public static var current: Environment {
    #if DEBUG
      return .development
    #else
      return .production
    #endif
  }

  /// Checks if the current environment is development
  public static var isDevelopment: Bool {
    current == .development
  }

  /// Checks if the current environment is production
  public static var isProduction: Bool {
    current == .production
  }
}

/// Configuration options for UmbraCore
public struct CoreConfiguration: Sendable, Equatable {
  /// Environment setting
  public let environment: Environment

  /// Enable verbose logging
  public let verboseLogging: Bool

  /// Enable additional security features
  public let enhancedSecurity: Bool

  /// Creates a new core configuration
  /// - Parameters:
  ///   - environment: Target environment
  ///   - verboseLogging: Enable verbose logging
  ///   - enhancedSecurity: Enable additional security features
  public init(
    environment: Environment=Environment.current,
    verboseLogging: Bool=false,
    enhancedSecurity: Bool=true
  ) {
    self.environment=environment
    self.verboseLogging=verboseLogging
    self.enhancedSecurity=enhancedSecurity
  }

  /// Default configuration for the current environment
  public static var `default`: CoreConfiguration {
    CoreConfiguration()
  }

  /// Configuration optimised for development
  public static var development: CoreConfiguration {
    CoreConfiguration(
      environment: .development,
      verboseLogging: true,
      enhancedSecurity: false
    )
  }

  /// Configuration optimised for production
  public static var production: CoreConfiguration {
    CoreConfiguration(
      environment: .production,
      verboseLogging: false,
      enhancedSecurity: true
    )
  }
}
