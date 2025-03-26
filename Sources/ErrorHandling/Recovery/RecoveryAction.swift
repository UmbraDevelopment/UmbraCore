import Foundation
import Interfaces
import Protocols
import UmbraErrorsCore

/// Represents an action that can be taken to recover from an error
public struct RecoveryAction: Sendable, Equatable {
  /// Unique identifier for the recovery action
  public let id: String

  /// Human-readable title for the recovery action
  public let title: String

  /// Optional detailed description of what the recovery action will do
  public let description: String?

  /// The action to take when this recovery is chosen
  public let action: () async throws -> Void

  /// Whether this is the default/recommended action
  public let isDefault: Bool

  /// Initialize a new recovery action
  /// - Parameters:
  ///   - id: Unique identifier for the action
  ///   - title: Human-readable title
  ///   - description: Optional detailed description
  ///   - isDefault: Whether this is the default action (defaults to false)
  ///   - action: The action to execute
  public init(
    id: String,
    title: String,
    description: String?=nil,
    isDefault: Bool=false,
    action: @escaping () async throws -> Void
  ) {
    self.id=id
    self.title=title
    self.description=description
    self.isDefault=isDefault
    self.action=action
  }

  /// Equality comparison only compares the id, not the action
  public static func == (lhs: RecoveryAction, rhs: RecoveryAction) -> Bool {
    lhs.id == rhs.id
  }
}

/// Protocol for objects that can provide recovery actions for errors
public protocol RecoveryActionProvider: Sendable {
  /// Get recovery actions for a specific error
  /// - Parameter error: The error to get recovery actions for
  /// - Returns: Array of recovery actions
  func getRecoveryActions(for error: Error) -> [RecoveryAction]
}

/// Default implementation for recovery action providers
public struct DefaultRecoveryActionProvider: RecoveryActionProvider {
  /// Initialize a new provider
  public init() {}

  /// Get recovery actions for a specific error
  /// - Parameter error: The error to get recovery actions for
  /// - Returns: Array of recovery actions
  public func getRecoveryActions(for error: Error) -> [RecoveryAction] {
    // Default implementation returns basic actions like retry and cancel
    var actions: [RecoveryAction]=[]

    // Add retry action
    actions.append(
      RecoveryAction(
        id: "retry",
        title: "Retry",
        description: "Attempt the operation again",
        action: {
          // This would be implemented by the caller
          print("Retry action selected for \(error)")
        }
      )
    )

    // Add cancel action
    actions.append(
      RecoveryAction(
        id: "cancel",
        title: "Cancel",
        description: "Cancel the operation",
        isDefault: true,
        action: {
          // This would be implemented by the caller
          print("Cancel action selected for \(error)")
        }
      )
    )

    return actions
  }
}

/// Protocol for errors that can provide their own recovery actions
public protocol RecoverableErrorWithActions: UmbraError {
  /// Get recovery actions for this error
  /// - Returns: Array of recovery actions
  func getRecoveryActions() -> [RecoveryAction]
}

/// Extension to provide default implementation for recoverable errors
extension RecoverableErrorWithActions {
  /// Default implementation returns an empty array
  public func getRecoveryActions() -> [RecoveryAction] {
    []
  }
}

/// Protocol for recovery action managers
public protocol RecoveryActionService: Sendable {
  /// Register a provider for recovery actions
  /// - Parameter provider: The provider to register
  func registerProvider(_ provider: RecoveryActionProvider)

  /// Get recovery actions for an error
  /// - Parameter error: The error to get recovery actions for
  /// - Returns: Array of recovery actions
  func getRecoveryActions(for error: Error) -> [RecoveryAction]
}

/// Default implementation of recovery action service
public final class RecoveryActionManager: RecoveryActionService {
  /// Shared instance (singleton)
  public static let shared=RecoveryActionManager()

  /// Registered providers
  private var providers: [RecoveryActionProvider]=[]

  /// Private initializer to enforce singleton pattern
  private init() {
    // Register default provider
    registerProvider(DefaultRecoveryActionProvider())
  }

  /// Register a provider for recovery actions
  /// - Parameter provider: The provider to register
  public func registerProvider(_ provider: RecoveryActionProvider) {
    providers.append(provider)
  }

  /// Get recovery actions for an error
  /// - Parameter error: The error to get recovery actions for
  /// - Returns: Array of recovery actions
  public func getRecoveryActions(for error: Error) -> [RecoveryAction] {
    // If error is directly recoverable, use its actions
    if let recoverableError=error as? RecoverableErrorWithActions {
      let actions=recoverableError.getRecoveryActions()
      if !actions.isEmpty {
        return actions
      }
    }

    // Otherwise, ask each provider for actions
    for provider in providers {
      let actions=provider.getRecoveryActions(for: error)
      if !actions.isEmpty {
        return actions
      }
    }

    // If no provider handled it, return empty array
    return []
  }
}
