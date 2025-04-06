import BackupInterfaces
import Foundation

/// Adapter for converting between different cancellation token implementations
///
/// This adapter provides clean conversion between token types from different modules,
/// avoiding tight coupling while maintaining type safety.
public enum CancellationTokenAdapter {

  /// Converts a BackupOperationCancellationToken to a ProgressCancellationToken
  ///
  /// This allows BackupOperationCancellationToken to be used with progress reporting
  /// systems that expect a ProgressCancellationToken.
  ///
  /// - Parameter token: The token to adapt
  /// - Returns: A ProgressCancellationToken that delegates to the original token
  public static func asProgressCancellationToken(
    _ token: BackupOperationCancellationToken
  ) -> ProgressCancellationToken {
    ProgressCancellationTokenAdapter(token: token)
  }
}

/// Adapter that allows a BackupOperationCancellationToken to be used as a ProgressCancellationToken
private final class ProgressCancellationTokenAdapter: ProgressCancellationToken {
  private let token: BackupOperationCancellationToken
  private var _isCancelled: Bool = false
  
  init(token: BackupOperationCancellationToken) {
    self.token = token
    // Set up task to monitor the cancellation state
    Task {
      self._isCancelled = await token.isCancelled
    }
  }

  var isCancelled: Bool {
    // This needs to be synchronous for protocol conformance
    return _isCancelled
  }

  func cancel() {
    // This needs to be synchronous for protocol conformance
    Task {
      await token.cancel()
      self._isCancelled = true
    }
  }
  
  // This was likely used for callback registration but isn't in the protocol
  // We'll keep it as an extension method
}

// Extension to provide async capabilities as needed
extension ProgressCancellationTokenAdapter {
  func onCancel(_ callback: @escaping () -> Void) {
    Task {
      while !_isCancelled {
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        self._isCancelled = await token.isCancelled
        if self._isCancelled {
          callback()
          break
        }
      }
    }
  }
}

/// Extension to BackupOperationCancellationToken for tracking with BackupOperation
extension BackupOperationCancellationToken {
  /// Register this token with the given operation
  ///
  /// - Parameter operation: The operation to associate with this token
  public func register(for _: BackupOperation) async {
    // Implementation specific to the service
    // This would depend on how operations are tracked
  }
}
