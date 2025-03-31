import Foundation

/// Result of a validation operation
public struct ValidationResult: Sendable {
  /// Whether the validation was successful
  public let isValid: Bool

  /// Initialize a new validation result
  /// - Parameter isValid: Whether the validation was successful
  public init(isValid: Bool) {
    self.isValid=isValid
  }
}
