import BackupInterfaces
import Foundation

/**
 * Implementation of the BackupCancellationToken protocol,
 * following the Alpha Dot Five architecture principles.
 */
public actor BackupCancellationTokenImplementation: BackupCancellationToken {
  /// Unique identifier for this token
  public let id: String

  /// Whether the operation has been cancelled
  private var _isCancelled: Bool=false

  /// Registered callbacks to be invoked on cancellation
  private var callbacks: [() -> Void]=[]

  /**
   * Initialises a new cancellation token.
   *
   * - Parameter id: Unique identifier for this token
   */
  public init(id: String=UUID().uuidString) {
    self.id=id
  }

  /**
   * Checks if the operation has been cancelled.
   */
  public var isCancelled: Bool {
    _isCancelled
  }

  /**
   * Cancels the operation.
   */
  public func cancel() async {
    guard !_isCancelled else { return }

    _isCancelled=true

    // Invoke all registered callbacks
    for callback in callbacks {
      callback()
    }

    // Clear callbacks
    callbacks.removeAll()
  }

  /**
   * Registers a callback to be invoked when the operation is cancelled.
   *
   * - Parameter callback: The callback to invoke
   */
  public func registerCancellationCallback(_ callback: @escaping @Sendable () -> Void) async {
    if _isCancelled {
      // If already cancelled, invoke the callback immediately
      callback()
    } else {
      // Otherwise, store it for later
      callbacks.append(callback)
    }
  }

  /**
   * Throws a CancellationError if this token has been cancelled.
   *
   * - Throws: CancellationError if the operation has been cancelled
   */
  public func checkCancelled() async throws {
    if _isCancelled {
      throw CancellationError()
    }
  }
}
