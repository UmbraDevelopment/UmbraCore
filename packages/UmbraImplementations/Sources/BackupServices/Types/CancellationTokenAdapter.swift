import BackupInterfaces
import Foundation

/// Adapter for converting between different cancellation token implementations
///
/// This adapter provides clean conversion between token types from different modules,
/// avoiding tight coupling while maintaining type safety.
public struct CancellationTokenAdapter {
    
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
    
    init(token: BackupOperationCancellationToken) {
        self.token = token
    }
    
    var isCancelled: Bool {
        get async {
            await token.isCancelled
        }
    }
    
    func cancel() async {
        await token.cancel()
    }
    
    func onCancel(_ callback: @escaping () -> Void) async {
        await token.onCancel(callback)
    }
}

/// Extension to BackupOperationCancellationToken for tracking with BackupOperation
extension BackupOperationCancellationToken {
    /// Register this token with the given operation
    ///
    /// - Parameter operation: The operation to associate with this token
    public func register(for operation: BackupOperation) async {
        // Implementation specific to the service
        // This would depend on how operations are tracked
    }
}
