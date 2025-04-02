import Foundation

/// The security level to use for cryptographic operations
public enum SecurityLevelDTO: String, Sendable, Equatable, CaseIterable {
  /// Basic security suitable for non-sensitive data
  case basic="Basic"

  /// Standard security suitable for most applications
  case standard="Standard"

  /// Enhanced security with stronger algorithms and longer keys
  case enhanced="Enhanced"

  /// High security for sensitive data
  case high="High"

  /// Highest security level, may impact performance
  case maximum="Maximum"
}

/// The logging level for security operations
public enum SecurityLogLevelDTO: String, Sendable, Equatable, CaseIterable {
  /// Debug level logging
  case debug="Debug"

  /// Information level logging
  case information="Information"

  /// Warning level logging
  case warning="Warning"

  /// Error level logging
  case error="Error"

  /// Critical error level logging
  case critical="Critical"
}

/// Security level for randomisation operations
public enum RandomizationSecurityLevelDTO: String, Sendable, Equatable, CaseIterable {
  /// High security level for cryptographic applications
  case high="High"

  /// Standard security level for general use
  case standard="Standard"

  /// Fast mode with lower security for non-sensitive operations
  case fast="Fast"
}

/// Available entropy sources for random number generation
public enum EntropySourceDTO: String, Sendable, Equatable, CaseIterable {
  /// System-provided entropy source (default)
  case system="System"

  /// Hardware random number generator
  case hardwareRNG="HardwareRNG"

  /// Software-based CSPRNG
  case softwareCSPRNG="SoftwareCSPRNG"
}

/// Options for secure random number generation
public struct RandomizationOptionsDTO: Sendable, Equatable {
  /// The security level to use for random data generation
  public let securityLevel: RandomizationSecurityLevelDTO

  /// The entropy source to use
  public let entropySource: EntropySourceDTO

  /// Whether to use additional entropy mixing
  public let useEntropyMixing: Bool

  /// Creates a new set of randomisation options
  /// - Parameters:
  ///   - securityLevel: The security level for randomisation
  ///   - entropySource: The entropy source to use
  ///   - useEntropyMixing: Whether to use entropy mixing
  public init(
    securityLevel: RandomizationSecurityLevelDTO = .standard,
    entropySource: EntropySourceDTO = .system,
    useEntropyMixing: Bool=false
  ) {
    self.securityLevel=securityLevel
    self.entropySource=entropySource
    self.useEntropyMixing=useEntropyMixing
  }

  /// Default randomisation options with standard security level
  public static let `default`=RandomizationOptionsDTO()

  /// High entropy randomisation options
  public static let highEntropy=RandomizationOptionsDTO(
    securityLevel: .high,
    entropySource: .hardwareRNG,
    useEntropyMixing: true
  )

  /// Fast but less secure randomisation options
  public static let fast=RandomizationOptionsDTO(
    securityLevel: .fast,
    entropySource: .system,
    useEntropyMixing: false
  )
}
