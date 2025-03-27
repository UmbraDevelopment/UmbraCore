import Foundation

/// Extended security error functionality
extension SecurityErrorDTO {
  /// Initialise with a reason and code
  /// - Parameters:
  ///   - reason: The error reason
  ///   - code: The error code
  ///   - domain: The error domain, defaults to security
  /// - Returns: A configured SecurityErrorDTO
  public static func withReasonAndCode(
    reason: String, 
    code: Int, 
    domain: String = ErrorDomain.security
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      domain: domain,
      code: code,
      description: reason
    )
  }
  
  /// Create a generic security error
  /// - Parameters:
  ///   - reason: The error reason
  ///   - code: The error code, defaults to 1000
  /// - Returns: A configured SecurityErrorDTO
  public static func generic(
    reason: String,
    code: Int = 1000
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      domain: ErrorDomain.security,
      code: code,
      description: reason
    )
  }
}
