import Foundation

/// Represents the result of validating a log destination configuration
public struct LogDestinationValidationResultDTO: Sendable, Equatable {
  /// Whether the destination configuration is valid
  public let isValid: Bool

  /// Any errors encountered during validation
  public let errors: [String]

  /// Messages from the validation process
  public let validationMessages: [String]

  /// Creates a new validation result
  /// - Parameters:
  ///   - isValid: Whether the destination is valid
  ///   - errors: Any validation errors
  ///   - validationMessages: Additional validation messages
  public init(isValid: Bool, errors: [String]=[], validationMessages: [String]=[]) {
    self.isValid=isValid
    self.errors=errors
    self.validationMessages=validationMessages.isEmpty ? errors : validationMessages
  }
}
