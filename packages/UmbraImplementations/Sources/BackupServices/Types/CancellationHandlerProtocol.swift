import BackupInterfaces
import Foundation

/**
 * Protocol for handling cancellation in operations.
 *
 * This protocol provides a standardised approach to handling
 * cancellation in long-running operations, following the
 * Alpha Dot Five architecture's principles.
 */
public protocol CancellationHandlerProtocol: Sendable {
  /**
   * Registers a new operation for cancellation tracking.
   *
   * - Parameter id: Unique identifier for the operation
   * - Returns: A cancellation token for the operation
   */
  func registerOperation(id: String) async -> BackupCancellationToken

  /**
   * Cancels an operation.
   *
   * - Parameter id: Identifier of the operation to cancel
   * - Returns: Whether the operation was found and cancelled
   */
  func cancelOperation(id: String) async -> Bool

  /**
   * Checks if an operation has been cancelled.
   *
   * - Parameter id: Identifier of the operation to check
   * - Returns: Whether the operation has been cancelled
   */
  func isOperationCancelled(id: String) async -> Bool

  /**
   * Unregisters an operation from cancellation tracking.
   *
   * - Parameter id: Identifier of the operation to unregister
   */
  func unregisterOperation(id: String) async

  /**
   * Executes an operation with cancellation support.
   *
   * - Parameters:
   *   - operation: The function to execute
   *   - cancellationToken: Optional token for cancelling the operation
   * - Returns: The result of the operation
   * - Throws: Error if the operation fails or is cancelled
   */
  func withCancellationSupport<T: Sendable>(
    _ operation: @Sendable @escaping () async throws -> T,
    cancellationToken: BackupCancellationToken?
  ) async throws -> T
}
