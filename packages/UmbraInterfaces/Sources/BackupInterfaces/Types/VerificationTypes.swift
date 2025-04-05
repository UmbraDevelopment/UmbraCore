import Foundation

/// Defines the level of verification to perform on a backup
///
/// This enum provides different levels of thoroughness for verification
/// operations, allowing for trade-offs between speed and comprehensiveness.
public enum VerificationLevel: String, Sendable, Equatable, CaseIterable {
  /// Basic verification that checks repository structure only
  case basic

  /// Standard verification that checks data integrity
  case standard

  /// Full verification that checks both repository structure and data integrity
  case full

  /// Extended verification that performs cryptographic validation of all data
  case extended
}

/// Options for verification operations
///
/// This structure encapsulates the options available when verifying backups,
/// allowing for customised verification behaviour.
public struct VerifyOptions: Sendable, Equatable {
  /// The level of verification to perform
  public let level: VerificationLevel

  /// Whether to check data integrity
  public let checkDataIntegrity: Bool

  /// Whether to use read data from storage
  public let readData: Bool

  /// Whether to verify snapshot structure
  public let checkStructure: Bool

  /// Creates a new set of verification options
  /// - Parameters:
  ///   - level: The verification level
  ///   - checkDataIntegrity: Whether to check data integrity
  ///   - readData: Whether to read data from storage
  ///   - checkStructure: Whether to verify snapshot structure
  public init(
    level: VerificationLevel = .standard,
    checkDataIntegrity: Bool=true,
    readData: Bool=true,
    checkStructure: Bool=true
  ) {
    self.level=level
    self.checkDataIntegrity=checkDataIntegrity
    self.readData=readData
    self.checkStructure=checkStructure
  }

  /// Default verification options (standard level)
  public static let `default`=VerifyOptions()

  /// Quick verification options (basic level, no data read)
  public static let quick=VerifyOptions(
    level: .basic,
    checkDataIntegrity: false,
    readData: false,
    checkStructure: true
  )

  /// Thorough verification options (extended level)
  public static let thorough=VerifyOptions(
    level: .extended,
    checkDataIntegrity: true,
    readData: true,
    checkStructure: true
  )
}
