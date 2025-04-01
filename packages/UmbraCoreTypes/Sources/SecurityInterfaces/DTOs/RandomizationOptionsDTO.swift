import Foundation

/// Data transfer object representing configuration options for random data generation.
///
/// This type provides all the necessary parameters for configuring the randomisation
/// service, including security levels and entropy sources.
public struct RandomizationOptionsDTO: Sendable, Equatable {
  /// The security level to use for random data generation
  public let securityLevel: RandomizationSecurityLevelDTO

  /// The entropy source to use
  public let entropySource: EntropySourceDTO

  /// Whether to use additional entropy mixing
  public let useEntropyMixing: Bool

  /// Additional options for the randomisation service
  public let additionalOptions: [String: String]

  /// Creates a new randomisation options configuration
  /// - Parameters:
  ///   - securityLevel: The security level to use
  ///   - entropySource: The entropy source to use
  ///   - useEntropyMixing: Whether to use additional entropy mixing
  ///   - additionalOptions: Additional options for the randomisation service
  public init(
    securityLevel: RandomizationSecurityLevelDTO,
    entropySource: EntropySourceDTO,
    useEntropyMixing: Bool=true,
    additionalOptions: [String: String]=[:]
  ) {
    self.securityLevel=securityLevel
    self.entropySource=entropySource
    self.useEntropyMixing=useEntropyMixing
    self.additionalOptions=additionalOptions
  }

  /// Default randomisation options with standard security level
  public static let `default`=RandomizationOptionsDTO(
    securityLevel: .standard,
    entropySource: .system,
    useEntropyMixing: true
  )

  /// High-security randomisation options
  public static let highSecurity=RandomizationOptionsDTO(
    securityLevel: .high,
    entropySource: .hardwareRNG,
    useEntropyMixing: true
  )

  /// Basic randomisation options for non-security-critical applications
  public static let basic=RandomizationOptionsDTO(
    securityLevel: .basic,
    entropySource: .system,
    useEntropyMixing: false
  )
}

/// The security level to use for random data generation
public enum RandomizationSecurityLevelDTO: String, Sendable, Equatable, CaseIterable {
  /// High security level for cryptographic applications
  case high="High"

  /// Standard security level for most applications
  case standard="Standard"

  /// Basic security level for non-security-critical applications
  case basic="Basic"
}

/// The entropy source to use for random data generation
public enum EntropySourceDTO: String, Sendable, Equatable, CaseIterable {
  /// System entropy source (e.g., /dev/urandom on Unix)
  case system="System"

  /// Hardware random number generator
  case hardwareRNG="HardwareRNG"

  /// Cryptographic RNG
  case cryptographicRNG="CryptographicRNG"

  /// Hybrid entropy source (combines multiple sources)
  case hybrid="Hybrid"
}
