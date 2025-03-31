import Foundation

/**
 * A token that can be used to cancel an operation.
 *
 * This type provides a standardised approach to cancellation handling
 * in the Alpha Dot Five architecture, ensuring consistent and reliable
 * cancellation support across services.
 */
public protocol BackupCancellationToken: Sendable {
  /**
   * Checks if the operation has been cancelled.
   *
   * - Returns: `true` if the operation has been cancelled, `false` otherwise
   */
  func isCancelled() async -> Bool

  /**
   * Cancels the operation associated with this token.
   */
  func cancel() async
}

/**
 * Standard implementation of the BackupCancellationToken protocol.
 */
public actor StandardBackupCancellationToken: BackupCancellationToken {
  /// Flag to indicate if the operation has been cancelled
  private var cancelled: Bool=false

  /**
   * Creates a new cancellation token.
   */
  public init() {}

  /**
   * Checks if the operation has been cancelled.
   *
   * - Returns: `true` if the operation has been cancelled, `false` otherwise
   */
  public func isCancelled() async -> Bool {
    cancelled
  }

  /**
   * Cancels the operation associated with this token.
   */
  public func cancel() async {
    cancelled=true
  }
}
