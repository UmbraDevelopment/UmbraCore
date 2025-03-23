import Foundation

/// Registry for error recovery providers
/// This class serves as a central registry for all error recovery providers in the system
@MainActor
public final class ErrorRecoveryRegistry {
  /// The shared singleton instance
  public static let shared=ErrorRecoveryRegistry()

  /// Private initialiser to enforce the singleton pattern
  private init() {}

  /// Collection of registered recovery providers
  private var providers: [any RecoveryOptionsProvider]=[]

  /// Register a recovery provider
  /// - Parameter provider: The provider to register
  public func register(_ provider: any RecoveryOptionsProvider) {
    providers.append(provider)
  }

  /// Get recovery options for a specific error from all registered providers
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options, may be empty if no recovery is available
  public func recoveryOptions(for error: some Error) -> [any RecoveryOption] {
    providers.flatMap { provider in
      provider.recoveryOptions(for: error)
    }
  }
}
