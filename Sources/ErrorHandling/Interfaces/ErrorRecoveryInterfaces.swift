import Foundation

/// Basic implementation of the RecoveryOption protocol
///
/// This struct provides a concrete implementation of the RecoveryOption
/// protocol that can be used directly or as a base for more specialized
/// recovery options.
public struct ErrorRecoveryOption: RecoveryOption, Sendable, Equatable, Identifiable {
  /// Unique identifier for the recovery option
  public let id: UUID

  /// Human-readable title for the recovery option
  public let title: String

  /// Optional detailed description of what the recovery option will do
  public let description: String?

  /// Indicates whether this recovery option is potentially disruptive to the user's workflow
  public let isDisruptive: Bool

  /// The action to perform for this recovery option
  private let actionHandler: @Sendable () async -> Void

  /// Creates a new ErrorRecoveryOption instance
  /// - Parameters:
  ///   - id: Unique identifier for the recovery option (defaults to a new UUID)
  ///   - title: Human-readable title for the recovery option
  ///   - description: Optional detailed description of what the recovery option will do
  ///   - isDisruptive: Whether this recovery option might disrupt the user's workflow
  ///   - handler: The action to perform when this option is selected
  public init(
    id: UUID=UUID(),
    title: String,
    description: String?=nil,
    isDisruptive: Bool=false,
    handler: @escaping @Sendable () async -> Void
  ) {
    self.id=id
    self.title=title
    self.description=description
    self.isDisruptive=isDisruptive
    actionHandler=handler
  }

  /// Perform the recovery action
  public func perform() async {
    await actionHandler()
  }

  /// Equality check based on ID
  public static func == (lhs: ErrorRecoveryOption, rhs: ErrorRecoveryOption) -> Bool {
    lhs.id == rhs.id
  }
}

/// A recovery option that performs no action
extension ErrorRecoveryOption {
  /// Creates a "Cancel" recovery option that performs no action
  public static var cancel: ErrorRecoveryOption {
    ErrorRecoveryOption(
      title: "Cancel",
      description: "Cancel and take no action",
      isDisruptive: false,
      handler: { /* No action */ }
    )
  }

  /// Creates a "Try Again" recovery option
  /// - Parameter handler: The action to perform when trying again
  public static func tryAgain(handler: @escaping @Sendable () async -> Void)
  -> ErrorRecoveryOption {
    ErrorRecoveryOption(
      title: "Try Again",
      description: "Attempt the operation again",
      isDisruptive: false,
      handler: handler
    )
  }
}

/// A container for recovery options with additional context
public struct RecoveryOptions: Sendable {
  /// Title for the recovery options group
  public let title: String

  /// Descriptive message about the error
  public let message: String

  /// Available recovery actions
  public let actions: [RecoveryAction]

  /// Creates a new RecoveryOptions instance
  /// - Parameters:
  ///   - title: Title for the recovery options group
  ///   - message: Descriptive message about the error
  ///   - actions: Available recovery actions
  public init(title: String, message: String, actions: [RecoveryAction]) {
    self.title=title
    self.message=message
    self.actions=actions
  }
}

/// A recovery action that can be performed
public struct RecoveryAction: Sendable, Identifiable {
  /// Unique identifier for this action
  public let id: String

  /// User-facing title for this action
  public let title: String

  /// Action to perform when selected
  private let handler: @Sendable () -> Bool

  /// Creates a new RecoveryAction
  /// - Parameters:
  ///   - id: Unique identifier for this action
  ///   - title: User-facing title for this action
  ///   - handler: Action to perform when selected
  public init(id: String, title: String, handler: @escaping @Sendable () -> Bool) {
    self.id=id
    self.title=title
    self.handler=handler
  }

  /// Perform the recovery action
  /// - Returns: Whether the recovery was successful
  public func perform() -> Bool {
    handler()
  }
}
