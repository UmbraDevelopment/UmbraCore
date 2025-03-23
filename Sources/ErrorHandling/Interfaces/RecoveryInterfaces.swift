import Foundation

/// Likelihood of a recovery option succeeding
public enum RecoveryLikelihood: Comparable, Sendable {
  /// Very likely to succeed (>90% chance)
  case high

  /// Moderately likely to succeed (50-90% chance)
  case medium

  /// Less likely to succeed (<50% chance)
  case low

  /// Unknown likelihood of success
  case unknown

  /// Comparison implementation for Comparable protocol
  public static func < (lhs: RecoveryLikelihood, rhs: RecoveryLikelihood) -> Bool {
    let order: [RecoveryLikelihood]=[.unknown, .low, .medium, .high]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/// Protocol for error recovery options
public protocol RecoveryOption: Sendable {
  /// A unique identifier for this recovery option
  var id: UUID { get }

  /// User-facing title for this recovery option
  var title: String { get }

  /// Additional description of what this recovery will do
  var description: String? { get }

  /// Whether this recovery option can disrupt the user's workflow
  var isDisruptive: Bool { get }

  /// Action to perform when the recovery option is selected
  func perform() async
}

/// Protocol for providing recovery options for errors
public protocol RecoveryOptionsProvider: Sendable {
  /// Get recovery options for a specific error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  func recoveryOptions(for error: some Error) -> [any RecoveryOption]
}

/// Protocol for services that can provide error recovery
public protocol ErrorRecoveryService: Sendable {
  /// Attempt to automatically recover from an error
  /// - Parameters:
  ///   - error: The error to recover from
  ///   - context: Additional context for recovery
  /// - Returns: Whether recovery was successful
  func attemptRecovery(from error: some Error, context: [String: Any]?) async -> Bool

  /// Get available recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Available recovery options
  func getRecoveryOptions(for error: some Error) -> [any RecoveryOption]

  /// Register a provider of recovery options
  /// - Parameter provider: The provider to register
  func registerProvider(_ provider: any RecoveryOptionsProvider)
}
