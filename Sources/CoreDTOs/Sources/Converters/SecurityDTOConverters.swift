

import UmbraErrors
import UmbraErrorsCore
import Foundation
import SecurityBridgeTypes

/// Security-related DTO conversion utilities
public enum SecurityDTOConverters {
  /// Convert a local error to a DTO error
  /// - Parameter error: Local error to convert
  /// - Returns: DTO error
  public static func toDTO(_ error: Error) -> Error {
    if let securityError=error as? UmbraErrors.Security.Core {
      return XPCSecurityDTOConverter.toDTO(securityError)
    }
    return error
  }

  /// Convert a DTO error to a local error
  /// - Parameter error: DTO error to convert
  /// - Returns: Local error
  public static func fromDTO(_ error: Error) -> Error {
    if let protocolsError=error as? UmbraErrors.Security.Protocols {
      return XPCSecurityDTOConverter.fromDTO(protocolsError)
    }
    return error
  }
}
