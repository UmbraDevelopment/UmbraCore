import Foundation

// Removing imports that cause circular dependencies
// import UmbraErrors
// import UmbraErrorsCore

/// Security-related DTO conversion utilities
public enum SecurityDTOConverters {
  /// Convert a local error to a DTO error
  /// - Parameter error: Local error to convert
  /// - Returns: DTO error
  public static func toDTO(_ error: Error) -> Error {
    // Using generic Error type since UmbraErrors is removed
    // if let securityError = error as? SecurityError {
    //   return XPCSecurityDTOConverter.toDTO(securityError)
    // }
    error
  }

  /// Convert a DTO error to a local error
  /// - Parameter error: DTO error to convert
  /// - Returns: Local error
  public static func fromDTO(_ error: Error) -> Error {
    // Using generic Error type since UmbraErrors is removed
    // if let securityErrorDTO = error as? SecurityErrorDTO {
    //   return XPCSecurityDTOConverter.fromDTO(securityErrorDTO)
    // }
    error
  }
}
