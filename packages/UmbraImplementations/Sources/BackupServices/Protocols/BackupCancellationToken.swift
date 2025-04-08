import Foundation

/**
 * Protocol for cancellation tokens.
 *
 * This protocol defines the interface for tokens that can be used to
 * cancel operations.
 */
public protocol BackupCancellationToken: Sendable {
  /**
   * Whether the operation has been cancelled.
   */
  var isCancelled: Bool { get async }

  /**
   * Cancels the operation.
   */
  func cancel() async

  /**
   * Registers a callback to be called when the operation is cancelled.
   *
   * - Parameter callback: The callback to register
   */
  func registerCancellationCallback(_ callback: @escaping @Sendable () -> Void) async
}
