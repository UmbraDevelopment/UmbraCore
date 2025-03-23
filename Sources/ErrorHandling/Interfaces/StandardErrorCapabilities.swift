import Foundation

/// Protocol defining standard capabilities that all domain-specific error types should implement
///
/// This protocol provides default implementations for common error handling functionality,
/// promoting consistency across different error domains while reducing code duplication.
public protocol StandardErrorCapabilities: UmbraError, Error, Sendable, CustomStringConvertible {
  /// Returns a standardised string description combining domain, code, and error description
  var standardDescription: String { get }

  /// Creates a formatted error message with optional contextual information
  func formatErrorMessage(_ message: String, context: [String: Any]?) -> String
}

// MARK: - Default Implementations

extension StandardErrorCapabilities {
  /// Standardised string description implementation
  public var standardDescription: String {
    "[\(domain).\(code)] \(errorDescription)"
  }

  /// Default implementation for CustomStringConvertible
  public var description: String {
    standardDescription
  }

  /// Formats an error message with optional context
  public func formatErrorMessage(_ message: String, context: [String: Any]?=nil) -> String {
    guard let context, !context.isEmpty else {
      return message
    }

    let contextString=context.map { key, value in "\(key): \(value)" }.joined(separator: ", ")
    return "\(message) (Context: \(contextString))"
  }
}
