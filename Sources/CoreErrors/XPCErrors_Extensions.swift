import Foundation

// Avoid circular dependency by using typealias for UmbraErrors.Security.Core
// This is temporary until a proper refactoring can break the dependency cycle
import SecurityTypes
public typealias SecurityCoreError=Error

/// XPC Errors namespace
public enum XPCErrors {
  /// XPC Security Error type
  /// This provides a clear namespace for XPC security errors
  public enum SecurityError: Error, Codable {
    /// Communication-related errors
    case communicationError(description: String)
    /// Service-related errors
    case serviceError(description: String)
    /// Validation errors
    case validationError(description: String)
    /// Unknown error
    case unknown(description: String)

    /// Initialize with a description
    public static func withDescription(_ description: String) -> SecurityError {
      .unknown(description: description)
    }
  }
}

/// Security error conversion utilities
public enum SecurityErrorConversion {
  /// Converts a Security Core error to an XPC-specific representation
  /// - Parameter error: The core error as Any
  /// - Returns: The XPC error as Any or nil if conversion is not possible
  public static func coreToXPC(_ error: Any) -> Any? {
    // Use string-based runtime casting to avoid direct dependency on UmbraErrors
    let errorTypeName=String(describing: type(of: error))
    if errorTypeName.contains("Security.Core") {
      // Extract description using mirror if available, otherwise use default
      let description=(error as? CustomStringConvertible)?.description ?? "Unknown security error"
      return XPCErrors.SecurityError.withDescription(description)
    }
    return nil
  }

  /// Converts an XPC-specific error to a core representation
  /// - Parameter error: The XPC error as Any
  /// - Returns: The core error as Any or nil if conversion is not possible
  public static func xpcToCore(_ error: Any) -> Any? {
    if let xpcError=error as? XPCErrors.SecurityError {
      switch xpcError {
        case let .communicationError(description),
             let .serviceError(description),
             let .validationError(description),
             let .unknown(description):
          // Return a generic error type that will be properly cast by the caller
          return NSError(
            domain: "Security.Core",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: description]
          )
      }
    }
    return nil
  }
}
