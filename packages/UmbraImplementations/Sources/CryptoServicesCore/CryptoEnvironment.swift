import Foundation

/// Environment information for cryptographic services.
///
/// This struct provides a standardised way to access environment-specific
/// configuration and capabilities for cryptographic operations.
///
/// The environment influences security policy decisions, cryptographic
/// algorithm selection, and logging behaviour based on whether the application
/// is running in production, staging, development, or test environments.
public struct CryptoEnvironment: Sendable, Equatable {
  /// The type of environment
  public enum EnvironmentType: String, Sendable, Codable, CaseIterable {
    /// Production environment with maximum security
    case production

    /// Staging environment with near-production security
    case staging

    /// Development environment with standard security
    case development

    /// Test environment with relaxed security
    case test
  }

  /// The type of this environment
  public let type: EnvironmentType

  /// Whether hardware security is available
  public let hasHardwareSecurity: Bool

  /// Whether enhanced logging is enabled
  public let isLoggingEnhanced: Bool

  /// Platform identifier (iOS, macOS, etc.)
  public let platformIdentifier: String

  /// Additional environment parameters
  public let parameters: [String: String]

  /// Name of the environment
  public var name: String {
    type.rawValue
  }

  /// Whether this is a production environment
  public var isProduction: Bool {
    type == .production
  }

  /// Whether this is a development environment
  public var isDevelopment: Bool {
    type == .development || type == .test
  }

  /// Creates a new environment configuration.
  ///
  /// - Parameters:
  ///   - type: The environment type
  ///   - hasHardwareSecurity: Whether hardware security is available
  ///   - isLoggingEnhanced: Whether enhanced logging is enabled
  ///   - platformIdentifier: Platform identifier
  ///   - parameters: Additional environment parameters
  public init(
    type: EnvironmentType,
    hasHardwareSecurity: Bool=false,
    isLoggingEnhanced: Bool=false,
    platformIdentifier: String="default",
    parameters: [String: String]=[:]
  ) {
    self.type=type
    self.hasHardwareSecurity=hasHardwareSecurity
    self.isLoggingEnhanced=isLoggingEnhanced
    self.platformIdentifier=platformIdentifier
    self.parameters=parameters
  }

  /// Standard production environment configuration
  public static var production: CryptoEnvironment {
    CryptoEnvironment(type: .production, hasHardwareSecurity: true)
  }

  /// Standard development environment configuration
  public static var development: CryptoEnvironment {
    CryptoEnvironment(type: .development, isLoggingEnhanced: true)
  }

  /// Standard test environment configuration
  public static var test: CryptoEnvironment {
    CryptoEnvironment(type: .test, isLoggingEnhanced: true)
  }
}
