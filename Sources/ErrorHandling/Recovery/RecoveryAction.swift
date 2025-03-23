import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// Represents an action that can be taken to recover from an error
public struct RecoveryAction: Sendable, Equatable {
  /// Unique identifier for the recovery action
  public let id: String

  /// Human-readable title for the recovery action
  public let title: String

  /// Optional detailed description of what the recovery action will do
  public let description: String?

  /// Indicates whether this action should be presented as the default option
  public let isDefault: Bool

  /// The action handler closure that will be called when the action is selected
  /// Note: Marked with @Sendable to ensure proper concurrency safety
  private let actionHandler: @Sendable () -> Void

  /// Creates a new RecoveryAction instance
  /// - Parameters:
  ///   - id: Unique identifier for the recovery action
  ///   - title: Human-readable title for the recovery action
  ///   - description: Optional detailed description of what the recovery action will do
  ///   - isDefault: Indicates whether this action should be presented as the default option
  ///   - handler: The action handler closure that will be called when the action is selected
  public init(
    id: String,
    title: String,
    description: String?=nil,
    isDefault: Bool=false,
    handler: @Sendable @escaping () -> Void
  ) {
    self.id=id
    self.title=title
    self.description=description
    self.isDefault=isDefault
    actionHandler=handler
  }

  /// Execute the recovery action
  public func perform() {
    actionHandler()
  }

  /// Equality comparison for RecoveryAction
  /// Note: Only compares the id, title, description, and isDefault properties
  /// The actionHandler is not compared as functions cannot be compared for equality
  public static func == (lhs: RecoveryAction, rhs: RecoveryAction) -> Bool {
    lhs.id == rhs.id &&
      lhs.title == rhs.title &&
      lhs.description == rhs.description &&
      lhs.isDefault == rhs.isDefault
  }
}

/// Extension to provide factory methods for common recovery actions
extension RecoveryAction {
  /// Creates a retry action
  /// - Parameters:
  ///   - title: Custom title for the retry action (defaults to "Retry")
  ///   - description: Optional description of what will be retried
  ///   - handler: The action to perform when retrying
  /// - Returns: A new RecoveryAction for retrying
  public static func retry(
    title: String="Retry",
    description: String?=nil,
    handler: @Sendable @escaping () -> Void
  ) -> RecoveryAction {
    RecoveryAction(
      id: "retry",
      title: title,
      description: description,
      isDefault: true,
      handler: handler
    )
  }

  /// Creates a cancel action
  /// - Parameters:
  ///   - title: Custom title for the cancel action (defaults to "Cancel")
  ///   - description: Optional description of what will be cancelled
  ///   - handler: The action to perform when cancelling
  /// - Returns: A new RecoveryAction for cancelling
  public static func cancel(
    title: String="Cancel",
    description: String?=nil,
    handler: @Sendable @escaping () -> Void
  ) -> RecoveryAction {
    RecoveryAction(
      id: "cancel",
      title: title,
      description: description,
      handler: handler
    )
  }

  /// Creates an ignore action
  /// - Parameters:
  ///   - title: Custom title for the ignore action (defaults to "Ignore")
  ///   - description: Optional description of what will be ignored
  ///   - handler: The action to perform when ignoring
  /// - Returns: A new RecoveryAction for ignoring
  public static func ignore(
    title: String="Ignore",
    description: String?=nil,
    handler: @Sendable @escaping () -> Void
  ) -> RecoveryAction {
    RecoveryAction(
      id: "ignore",
      title: title,
      description: description,
      handler: handler
    )
  }
}
