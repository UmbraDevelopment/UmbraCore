import CoreErrors
import SecurityProtocolsCore
import XPCProtocolsCore

/// Provides standardised error mapping between different security error types
public enum SecurityErrorMapper {
  /// Map any error to Security.Protocols error type
  /// - Parameter error: The error to map
  /// - Returns: A Security.Protocols representation of the error
  public static func toSecurityError(_ error: Error) -> UmbraErrors.Security.Protocols {
    // Delegate to the canonical implementation in CoreErrors
    CoreErrors.SecurityErrorMapper.mapToProtocolError(error)
  }

  /// Map any error to CoreErrors.SecurityError
  /// - Parameter error: The error to map
  /// - Returns: A CoreErrors.SecurityError representation of the error
  public static func toCoreError(_ error: Error) -> UmbraErrors.Security.Core {
    // Delegate to the canonical implementation in CoreErrors
    CoreErrors.SecurityErrorMapper.mapToCoreError(error)
  }

  /// Map any error to XPC security error type
  /// - Parameter error: The error to map
  /// - Returns: An CoreErrors.XPCErrors.SecurityError representation
  public static func toXPCError(_ error: Error) -> UmbraErrors.Security.XPC {
    // Delegate to the canonical implementation in CoreErrors
    CoreErrors.SecurityErrorMapper.mapToXPCError(error)
  }
}
