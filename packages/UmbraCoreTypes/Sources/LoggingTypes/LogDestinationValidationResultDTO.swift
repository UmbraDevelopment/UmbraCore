import Foundation

/// Represents the result of validating a log destination configuration
public struct LogDestinationValidationResultDTO: Sendable, Equatable {
    /// Whether the destination configuration is valid
    public let isValid: Bool
    
    /// Any errors encountered during validation
    public let errors: [String]
    
    /// Creates a new validation result
    /// - Parameters:
    ///   - isValid: Whether the destination is valid
    ///   - errors: Any validation errors
    public init(isValid: Bool, errors: [String] = []) {
        self.isValid = isValid
        self.errors = errors
    }
}
