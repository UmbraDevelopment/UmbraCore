import Foundation

/**
 * Protocol for cancellation handling in backup operations.
 *
 * This type provides a standardised approach to cancellation handling
 * in the Alpha Dot Five architecture, ensuring consistent and reliable
 * cancellation support across backup services.
 */
@preconcurrency
public protocol BackupCancellationToken: Sendable {
  /**
   * Checks if the operation has been cancelled.
   *
   * - Returns: `true` if the operation has been cancelled, `false` otherwise
   */
  var isCancelled: Bool { get async }

  /**
   * Cancels the operation associated with this token.
   */
  func cancel() async
}

/**
 * Actor-based implementation of BackupCancellationToken.
 *
 * This implementation provides thread-safe cancellation handling using Swift's actor model,
 * offering better safety guarantees and simpler code than manually synchronized approaches.
 */
public actor BackupOperationCancellationToken: BackupCancellationToken {
  /// Flag to indicate if the operation has been cancelled
  private var cancelled: Bool=false

  /**
   * Creates a new backup operation cancellation token.
   */
  public init() {}

  /**
   * Checks if the operation has been cancelled.
   *
   * This provides actor-safe access to the cancellation state through Swift's
   * structured concurrency model.
   *
   * - Returns: `true` if the operation has been cancelled, `false` otherwise
   */
  public var isCancelled: Bool {
    get async {
      cancelled
    }
  }

  /**
   * Cancels the operation associated with this token.
   *
   * This method safely updates the actor-protected state.
   */
  public func cancel() async {
    cancelled=true
  }
}
