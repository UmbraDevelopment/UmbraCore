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
        self.securityLevel = securityLevel
        self.loggingLevel = loggingLevel
        self.randomizationOptions = randomizationOptions
    }
    
    /// Default configuration with standard security settings
    public static let `default` = SecurityConfigurationDTO()
    
    /// Configuration optimised for high-security environments
    public static let highSecurity = SecurityConfigurationDTO(
        securityLevel: .high,
        loggingLevel: .warning,
        randomizationOptions: .highEntropy
    )
    
    /// Configuration optimised for performance
    public static let performance = SecurityConfigurationDTO(
        securityLevel: .basic,
        loggingLevel: .error,
        randomizationOptions: .fast
    )
}

/// The security level to use for cryptographic operations
public enum SecurityLevelDTO: String, Sendable, Equatable, CaseIterable {
    /// Basic security suitable for non-sensitive data
    case basic
    
    /// Standard security suitable for most applications
    case standard
    
    /// High security for sensitive data
    case high
    
    /// Highest security level, may impact performance
    case maximum
}

/// The logging level for security operations
public enum SecurityLogLevelDTO: String, Sendable, Equatable, CaseIterable {
    /// Logs only errors
    case error
    
    /// Logs warnings and errors
    case warning
    
    /// Logs information, warnings, and errors
    case information
    
    /// Logs detailed information for debugging
    case debug
    
    /// Logs everything including sensitive operations (use with caution)
    case trace
}

/// Options for secure random number generation
public struct RandomizationOptionsDTO: Sendable, Equatable {
    /// The entropy source to use
    public let entropySource: EntropySourceDTO
    
    /// The security level for randomization
    public let securityLevel: RandomizationSecurityLevelDTO
    
    /// Creates a new set of randomization options
    /// - Parameters:
    ///   - entropySource: The entropy source to use
    ///   - securityLevel: The security level for randomization
    public init(
        entropySource: EntropySourceDTO = .system,
        securityLevel: RandomizationSecurityLevelDTO = .standard
    ) {
        self.entropySource = entropySource
        self.securityLevel = securityLevel
    }
    
    /// Default randomization options
    public static let `default` = RandomizationOptionsDTO()
    
    /// Options optimised for high entropy
    public static let highEntropy = RandomizationOptionsDTO(
        entropySource: .system,
        securityLevel: .high
    )
    
    /// Options optimised for performance
    public static let fast = RandomizationOptionsDTO(
        entropySource: .system,
        securityLevel: .basic
    )
}

/// The entropy source to use for random number generation
public enum EntropySourceDTO: String, Sendable, Equatable, CaseIterable {
    /// System entropy source
    case system
    
    /// Hardware entropy source if available
    case hardware
    
    /// Hybrid entropy source combining multiple sources
    case hybrid
}

/// The security level for randomization
public enum RandomizationSecurityLevelDTO: String, Sendable, Equatable, CaseIterable {
    /// Basic security, optimised for performance
    case basic
    
    /// Standard security suitable for most applications
    case standard
    
    /// High security for sensitive applications
    case high
}
