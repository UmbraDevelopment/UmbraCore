import UmbraCoreTypes
// Removing imports that cause circular dependencies
// import UmbraErrors
// import UmbraErrorsCore
import CoreDTOs.Security

/// Converts between SecurityError and SecurityErrorDTO
public enum XPCSecurityDTOConverter {
  // MARK: - Convert to DTO

  /// Convert a SecurityError to SecurityErrorDTO
  /// - Parameter error: The error to convert
  /// - Returns: A Foundation-independent SecurityErrorDTO error
  public static func toDTO(_ error: Error) -> Error {
    // Simplified conversion to avoid circular dependencies
    if let securityError = error as? Error {
      // Create a generic error DTO with minimal information
      // Return the original error as we can't create a SecurityErrorDTO without proper imports
      return error
    }
    return error
  }
  
  /// Extract details from an error context
  /// - Parameter context: The error context
  /// - Returns: Dictionary of details
  private static func extractErrorDetails(from context: [String: Any]) -> [String: String] {
    // Extract all context values that can be represented as strings
    var details = [String: String]()
    
    if let contextData = context["details"] as? [String: Any] {
      for (key, value) in contextData {
        details[key] = String(describing: value)
      }
    }
    
    return details
  }

  // MARK: - Convert from DTO

  /// Convert a SecurityErrorDTO to SecurityError
  /// - Parameter dto: The DTO error to convert
  /// - Returns: A SecurityError instance
  public static func fromDTO(_ dto: Error) -> Error {
    // Simplified conversion to avoid circular dependencies
    // Return the original error as we can't create a SecurityError without proper imports
    return dto
  }
}
