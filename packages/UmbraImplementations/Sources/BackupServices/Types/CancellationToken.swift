import BackupInterfaces
import Foundation

/**
 * A token for cancelling backup operations.
 *
 * This implementation of BackupOperationCancellationToken provides a way to
 * cancel operations and track their state with a unique identifier,
 * following the Alpha Dot Five architecture principles.
 */
public actor BackupOperationCancellationToken: BackupCancellationToken {
  /// Unique identifier for this token
  public let id: String

  /// Whether the operation has been cancelled
  private var cancelled: Bool=false

  /// Callbacks to be executed when the operation is cancelled
  private var cancellationCallbacks: [() -> Void]=[]

  /**
   * Initialises a new cancellation token.
   *
   * - Parameter id: Optional unique identifier for this token
   */
  public init(id: String=UUID().uuidString) {
    self.id=id
  }

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
    if !cancelled {
      cancelled=true

      // Execute all callbacks
      for callback in cancellationCallbacks {
        callback()
      }

      // Clear callbacks
      cancellationCallbacks=[]
    }
  }

  /**
   * Registers a callback to be executed when the operation is cancelled.
   *
   * - Parameter callback: The callback to execute
   */
  public func onCancelled(_ callback: @escaping () -> Void) async {
    if cancelled {
      // If already cancelled, execute immediately
      callback()
    } else {
      // Otherwise, store for later
      cancellationCallbacks.append(callback)
    }
  }

  /**
   * Throws a CancellationError if this token has been cancelled.
   *
   * - Throws: CancellationError if the operation has been cancelled
   */
  public func checkCancelled() async throws {
    if cancelled {
      throw CancellationError()
    }
  }
}
