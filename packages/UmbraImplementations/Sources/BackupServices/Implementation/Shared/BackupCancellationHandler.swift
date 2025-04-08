import BackupInterfaces
import Foundation

/**
 * Implementation of the cancellation handler for backup operations.
 */
public actor BackupCancellationHandler: BackupInterfaces.CancellationHandlerProtocol {
  /// Map of operation IDs to cancellation tokens
  private var tokens: [UUID: BackupCancellationToken]=[:]

  /// Creates a new cancellation handler
  public init() {}

  /**
   * Registers a cancellation token with an operation.
   *
   * - Parameters:
   *   - token: The cancellation token
   *   - operationID: The operation ID
   */
  public func registerCancellationToken(
    _ token: BackupCancellationToken,
    for operationID: UUID
  ) async {
    tokens[operationID]=token
  }

  /**
   * Cancels an operation by its ID.
   *
   * - Parameter operationID: The operation ID
   * - Returns: Whether the operation was cancelled
   */
  public func cancelOperation(operationID: UUID) async -> Bool {
    guard let token=tokens[operationID] else {
      return false
    }

    await token.cancel()
    return true
  }

  /**
   * Checks if an operation is cancelled.
   *
   * - Parameter operationID: The operation ID
   * - Returns: Whether the operation is cancelled
   */
  public func isOperationCancelled(operationID: UUID) async -> Bool {
    guard let token=tokens[operationID] else {
      return false
    }

    return await token.isCancelled
  }

  /**
   * Removes a token from the handler.
   *
   * - Parameter operationID: The operation ID
   */
  public func removeToken(for operationID: UUID) {
    tokens.removeValue(forKey: operationID)
  }
}
