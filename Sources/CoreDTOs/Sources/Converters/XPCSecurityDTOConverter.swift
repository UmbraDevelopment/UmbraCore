import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore
import CoreDTOs.Security

/// Converts between SecurityError and SecurityErrorDTO
public enum XPCSecurityDTOConverter {
  // MARK: - Convert to DTO

  /// Convert a SecurityError to SecurityErrorDTO
  /// - Parameter error: The error to convert
  /// - Returns: A Foundation-independent SecurityErrorDTO error
  public static func toDTO(_ error: SecurityError) -> SecurityErrorDTO {
    // Create a generic error DTO with appropriate values
    return SecurityErrorDTO(
      code: error.code,
      domain: error.domain,
      message: error.errorDescription,
      details: extractErrorDetails(from: error.context)
    )
  }
  
  /// Extract details from an error context
  /// - Parameter context: The error context
  /// - Returns: Dictionary of details
  private static func extractErrorDetails(from context: ErrorContext) -> [String: String] {
    // Extract all context values that can be represented as strings
    var details = [String: String]()
    
    if let contextData = context.value(for: "details") as? [String: Any] {
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
  public static func fromDTO(_ dto: SecurityErrorDTO) -> Error {
    // Create a generic SecurityError with appropriate values
    return SecurityError(
      domain: dto.domain,
      code: dto.code,
      errorDescription: dto.message,
      source: nil,
      underlyingError: nil,
      context: createContextFromDetails(dto.details)
    )
  }
  
  /// Create an ErrorContext from DTO details
  /// - Parameter details: Details dictionary
  /// - Returns: An ErrorContext instance
  private static func createContextFromDetails(_ details: [String: String]) -> ErrorContext {
    var context = ErrorContext()
    
    if !details.isEmpty {
      context = context.adding(key: "details", value: details)
    }
    
    return context
  }
}
