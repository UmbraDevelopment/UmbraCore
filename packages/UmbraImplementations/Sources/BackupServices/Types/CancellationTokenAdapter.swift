import BackupInterfaces
import Foundation

/// Adapter for converting between different cancellation token implementations
///
/// This adapter provides clean conversion between token types from different modules,
/// avoiding tight coupling while maintaining type safety.
public enum CancellationTokenAdapter {

  /// Converts a BackupOperationCancellationTokenImpl to a ProgressCancellationToken
  ///
  /// This allows BackupOperationCancellationTokenImpl to be used with progress reporting
  /// systems that expect a ProgressCancellationToken.
  ///
  /// - Parameter token: The token to convert
  /// - Returns: A ProgressCancellationToken that delegates to the original token
  public static func asProgressCancellationToken(
    _ token: BackupOperationCancellationTokenImpl
  ) -> ProgressCancellationToken {
    ProgressCancellationTokenAdapter(token: token)
  }
}

/// Adapter that allows a BackupOperationCancellationTokenImpl to be used as a
/// ProgressCancellationToken
private final class ProgressCancellationTokenAdapter: ProgressCancellationToken,
@unchecked Sendable {
  private let token: BackupOperationCancellationTokenImpl
  private var _isCancelled: Bool=false

  init(token: BackupOperationCancellationTokenImpl) {
    self.token=token
    // Set up task to monitor the cancellation state
    Task {
      await self.updateCancellationState()
    }
  }

  var isCancelled: Bool {
    // This needs to be synchronous for protocol conformance
    _isCancelled
  }

  /**
   * Updates the local cancellation state from the token.
   */
  private func updateCancellationState() {
    Task {
      let cancelled=await token.isCancelled
      _isCancelled=cancelled
    }
  }

  /**
   * Cancels the operation.
   */
  public func cancel() {
    Task {
      await token.cancel()
      _isCancelled=true
    }
  }
}

/// Extension to provide async capabilities as needed
extension ProgressCancellationTokenAdapter {
  /**
   * Registers a callback to be called when the operation is cancelled.
   *
   * - Parameter callback: The callback to register
   */
  public func registerCancellationCallback(_ callback: @escaping () -> Void) {
    Task {
      while !_isCancelled {
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        await self.updateCancellationState()
        if self._isCancelled {
          callback()
          break
        }
      }
    }
  }
}

/// Extension to BackupOperationCancellationTokenImpl for tracking with BackupOperation
extension BackupOperationCancellationTokenImpl {
  /// Register this token with the given operation
  ///
  /// - Parameter operation: The operation to register with
  /// - Returns: The token for chaining
  @discardableResult
  public func registerWith(_ operation: BackupOperation) -> Self {
    operation.registerCancellationToken(self)
    return self
  }
}
