// Updated imports to use the correct modules for Security protocols
import Foundation
import UmbraCoreTypes
import Errors // Import Errors module for error types

/// Maps between platform-specific error types and cross-protocol boundary errors
/// This handles conversion of errors when crossing process boundaries
public struct SecurityBridgeErrorMapper {
  // MARK: - Error Mapping

  /// Maps a platform error to a protocol-friendly error type
  /// - Parameter error: The platform error to map
  /// - Returns: A protocol-friendly error type
  public static func mapToBridgeError(_ error: Error) -> SecurityProtocolError {
    // If already a SecurityProtocolError, pass through unchanged
    if let securityError = error as? SecurityProtocolError {
      return securityError
    }

    // Default fallback for unknown errors
    return SecurityProtocolError.internalError("Unknown error: \(error.localizedDescription)")
  }

  /// Maps a protocol-friendly error to a platform error
  /// - Parameter bridgeError: The protocol error to map
  /// - Returns: A platform-specific error
  public static func mapFromBridgeError(_ bridgeError: SecurityProtocolError) -> Error {
    // Just return the bridge error directly, since we're using SecurityProtocolError
    // throughout the codebase now
    return bridgeError
  }
}
