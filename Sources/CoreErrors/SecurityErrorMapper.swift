import Foundation

/// Mapper for SecurityError to canonical UmbraErrors.Security.Core
import SecurityInterfaces
import SecurityTypes
public enum SecurityErrorMapper {

  /// Maps a SecurityError to a canonical UmbraErrors.Security.Core error
  /// - Parameter error: The SecurityError to map
  /// - Returns: Mapped UmbraErrors.Security.Core error
  public static func mapToSecurityCoreError(_ error: SecurityError) -> Error {
    SecurityError(description: error.description)
  }

  /// Maps a canonical UmbraErrors.Security.Core error to a SecurityError
  /// - Parameter error: The canonical error to map
  /// - Returns: Mapped SecurityError
  public static func mapFromSecurityCoreError(_ error: Error) -> SecurityError {
    if let secError=error as? SecurityError {
      return secError
    }
    return SecurityError(description: "Unknown security error")
  }
}
