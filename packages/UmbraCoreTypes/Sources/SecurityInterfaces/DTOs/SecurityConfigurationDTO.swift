import CoreSecurityTypes
import Foundation

/// Data transfer object representing configuration options for the security service.
///
/// This type provides a centralised place for configuring the security service,
/// including security levels, algorithms, and operational modes.
public struct SecurityConfigurationDTO: Sendable, Equatable {
  /// The security level to use
  public let securityLevel: SecurityLevelDTO

  /// The logging level for security operations
  public let loggingLevel: SecurityLogLevelDTO

  /// Options for secure random number generation
  public let randomizationOptions: RandomizationOptionsDTO

  /// Creates a new security configuration
  /// - Parameters:
  ///   - securityLevel: The security level to use
  ///   - loggingLevel: The logging level for security operations
  ///   - randomizationOptions: Options for secure random number generation
  public init(
    securityLevel: SecurityLevelDTO = .standard,
    loggingLevel: SecurityLogLevelDTO = .warning,
    randomizationOptions: RandomizationOptionsDTO = .default
  ) {
    self.securityLevel=securityLevel
    self.loggingLevel=loggingLevel
    self.randomizationOptions=randomizationOptions
  }

  /// Default configuration with standard security settings
  public static let `default`=SecurityConfigurationDTO()

  /// Configuration optimised for high-security environments
  public static let highSecurity=SecurityConfigurationDTO(
    securityLevel: .high,
    loggingLevel: .warning,
    randomizationOptions: .highEntropy
  )

  /// Configuration optimised for performance
  public static let performance=SecurityConfigurationDTO(
    securityLevel: .basic,
    loggingLevel: .error,
    randomizationOptions: .fast
  )
}
