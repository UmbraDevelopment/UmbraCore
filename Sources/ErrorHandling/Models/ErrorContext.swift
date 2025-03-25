import Foundation
import UmbraErrorsCore

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContextProtocol {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContextProtocol {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

// Use the canonical ErrorContext from UmbraErrorsCore
public typealias ErrorContext = UmbraErrorsCore.ErrorContext

/// Extension to add compatibility with ErrorContextProtocol
extension UmbraErrorsCore.ErrorContext {
    /// Domain value for compatibility with ErrorContextProtocol
    public var domain: String {
        return source ?? "Unknown"
    }
    
    /// Code value for compatibility with ErrorContextProtocol
    public var code: Int {
        if let codeValue = self.value(for: "code") as? Int {
            return codeValue
        }
        return 0
    }
    
    /// Description value for compatibility with ErrorContextProtocol
    public var description: String {
        return details ?? "Unknown error"
    }
}

/// Extension to add conveniences for common context values
extension ErrorContext {
    /// Creates a context with a message
    public static func withMessage(_ message: String) -> ErrorContext {
        return ErrorContext(
            [:],
            source: nil,
            operation: nil,
            details: message
        )
    }
    
    /// Creates a context with a source and message
    public static func withSource(_ source: String, message: String) -> ErrorContext {
        return ErrorContext(
            [:],
            source: source,
            operation: nil,
            details: message
        )
    }
    
    /// Creates a context with an operation and message
    public static func withOperation(_ operation: String, message: String) -> ErrorContext {
        return ErrorContext(
            [:],
            source: nil,
            operation: operation,
            details: message
        )
    }
}

// The rest of the file's functionality has been consolidated into UmbraErrorsCore.ErrorContext
