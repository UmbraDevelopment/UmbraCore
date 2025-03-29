import Foundation

/// Mapper for SecurityError to canonical UmbraErrors.Security.Core
// Removing imports to break circular dependency
// import SecurityInterfaces
// import SecurityTypes
// Removing ErrorHandling import to break circular dependency
// import ErrorHandling

// Simple error type to replace SecurityError
private struct GenericSecurityError: Error, CustomStringConvertible {
  let description: String
}

/// Namespace for UmbraErrors.Security.Core enums
public enum UmbraSecurityCoreErrors {
  /// Basic security error type
  public enum Core: Error, CustomStringConvertible {
    /// Generic security error
    case genericError(String)

    public var description: String {
      switch self {
        case let .genericError(message):
          message
      }
    }
  }
}

public enum SecurityErrorMapper {

  /// Maps a SecurityError to a canonical UmbraErrors.Security.Core error
  /// - Parameter error: The SecurityError to map
  /// - Returns: Mapped UmbraErrors.Security.Core error
  public static func mapToSecurityCoreError(_ error: Error) -> Error {
    UmbraSecurityCoreErrors.Core.genericError(error.localizedDescription)
  }

  /// Maps a canonical UmbraErrors.Security.Core error to a SecurityError
  /// - Parameter error: The canonical error to map
  /// - Returns: Mapped SecurityError
  public static func mapFromSecurityCoreError(_ error: Error) -> Error {
    if let secError=error as? UmbraSecurityCoreErrors.Core {
      return GenericSecurityError(description: secError.description)
    }
    return GenericSecurityError(description: error.localizedDescription)
  }
}
