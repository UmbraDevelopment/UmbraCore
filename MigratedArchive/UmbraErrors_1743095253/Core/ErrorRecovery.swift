import Foundation

/// Status of a recovery operation
///
/// This enum represents the possible outcomes of an error recovery attempt,
/// allowing for clear communication about whether recovery succeeded.
public enum RecoveryStatus: Sendable, Equatable {
  /// The recovery operation succeeded completely
  case succeeded

  /// The recovery operation partially succeeded
  case partialSuccess

  /// The recovery operation failed
  case failed

  /// The recovery operation was cancelled
  case cancelled

  /// The recovery operation is still in progress
  case inProgress
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
