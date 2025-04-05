import BackupInterfaces
import Foundation

/**
 * Configuration options for backup verification operations.
 *
 * This class provides options to customise the verification process
 * when checking the integrity of backup snapshots.
 */
public struct VerifyOptions: Sendable, Equatable {
  /// Whether to perform full verification of all data (more thorough but slower)
  public let fullVerification: Bool

  /// Whether to verify cryptographic signatures
  public let verifySignatures: Bool

  /// Maximum number of errors before aborting verification
  public let maxErrors: Int?

  /// Whether to automatically repair corruptions when detected
  public let autoRepair: Bool

  /**
   * Creates a new set of verification options.
   *
   * - Parameters:
   *   - fullVerification: Whether to perform thorough verification (default: false)
   *   - verifySignatures: Whether to verify cryptographic signatures (default: true)
   *   - maxErrors: Maximum errors before aborting, or nil for unlimited (default: 10)
   *   - autoRepair: Whether to repair corruptions automatically (default: false)
   */
  public init(
    fullVerification: Bool=false,
    verifySignatures: Bool=true,
    maxErrors: Int?=10,
    autoRepair: Bool=false
  ) {
    self.fullVerification=fullVerification
    self.verifySignatures=verifySignatures
    self.maxErrors=maxErrors
    self.autoRepair=autoRepair
  }

  /// Default verification options
  public static let `default`=VerifyOptions()

  /// Quick verification options (faster but less thorough)
  public static let quick=VerifyOptions(
    fullVerification: false,
    verifySignatures: false,
    maxErrors: 1,
    autoRepair: false
  )

  /// Thorough verification options (slower but more comprehensive)
  public static let thorough=VerifyOptions(
    fullVerification: true,
    verifySignatures: true,
    maxErrors: nil,
    autoRepair: false
  )

  /// Repair options (verify and attempt to repair issues)
  public static let repair=VerifyOptions(
    fullVerification: true,
    verifySignatures: true,
    maxErrors: nil,
    autoRepair: true
  )
}
