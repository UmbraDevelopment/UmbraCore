import Foundation

/// Options for configuring random data generation services
public struct RandomizationOptionsDTO: Sendable, Codable, Equatable {
  /// Source of randomness to use
  public enum RandomSource: String, Sendable, Codable, Equatable, CaseIterable {
    /// Use system cryptographic random number generator
    case system
    /// Use hardware random number generator if available
    case hardware
    /// Use a combination of sources for increased entropy
    case hybrid
  }

  /// Quality level for random generation
  public enum QualityLevel: String, Sendable, Codable, Equatable, CaseIterable {
    /// Standard quality suitable for most applications
    case standard
    /// High quality suitable for sensitive cryptographic operations
    case high
    /// Maximum quality with additional rounds of mixing
    case maximum
  }

  /// The source of randomness to use
  public let source: RandomSource

  /// Quality level for random generation
  public let quality: QualityLevel

  /// Optional seed data to influence randomization
  public let seedData: Data?

  /// Whether to use additional entropy from system events
  public let useSystemEntropy: Bool

  /// Creates a new randomization options configuration
  /// - Parameters:
  ///   - source: Source of randomness
  ///   - quality: Quality level for random generation
  ///   - seedData: Optional seed data
  ///   - useSystemEntropy: Whether to use system entropy
  public init(
    source: RandomSource = .system,
    quality: QualityLevel = .standard,
    seedData: Data?=nil,
    useSystemEntropy: Bool=true
  ) {
    self.source=source
    self.quality=quality
    self.seedData=seedData
    self.useSystemEntropy=useSystemEntropy
  }

  /// Default randomization options suitable for general use
  public static let `default`=RandomizationOptionsDTO(
    source: .system,
    quality: .standard,
    seedData: nil,
    useSystemEntropy: true
  )

  /// High entropy randomization options for cryptographic operations
  public static let highEntropy=RandomizationOptionsDTO(
    source: .hybrid,
    quality: .high,
    seedData: nil,
    useSystemEntropy: true
  )

  /// Fast randomization options optimised for performance
  public static let fast=RandomizationOptionsDTO(
    source: .system,
    quality: .standard,
    seedData: nil,
    useSystemEntropy: false
  )
}
