import BackupInterfaces
import Foundation

/**
 * Parameters for a backup verification operation.
 *
 * This struct encapsulates all parameters needed for performing
 * a verification of an existing backup snapshot.
 */
public struct BackupVerifyParameters: Sendable, Equatable {
  /// ID of the snapshot to verify, or nil to verify the latest
  public let snapshotID: String?

  /// Options for the verification process
  public let verifyOptions: VerifyOptions?

  /**
   * Creates a new set of verification parameters.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify, or nil to verify the latest
   *   - verifyOptions: Options for the verification process
   */
  public init(
    snapshotID: String?,
    verifyOptions: VerifyOptions?
  ) {
    self.snapshotID=snapshotID
    self.verifyOptions=verifyOptions
  }
}
