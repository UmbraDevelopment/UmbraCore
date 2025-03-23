import CoreDTOs
import ErrorHandling
import Foundation

/// A utility to adapt errors from Services module to Foundation-independent DTOs
public enum ServicesErrorAdapter {
  // MARK: - Public Error Conversion Methods

  /// Convert a credential error to a SecurityErrorDTO
  /// - Parameter error: The credential error to convert
  /// - Returns: A SecurityErrorDTO representing the error
  public static func convertCredentialError(_ error: Error) -> SecurityErrorDTO {
    // Check if the error is already a SecurityErrorDTO
    if let securityError=error as? SecurityErrorDTO {
      return securityError
    }

    // Handle known credential error codes
    let errorCode=Int32(error._code)
    let errorDomain="security.credential"

    // Extract error details for specific credential error codes
    let errorDetails=extractCredentialErrorDetails(error)

    // Create appropriate error message based on error code
    var errorMessage="A credential error occurred"

    // Map common credential error codes
    switch errorCode {
      case -25300:
        errorMessage="No permission to access keychain item"
      case -25291:
        errorMessage="No such keychain item"
      case -25292:
        errorMessage="Invalid keychain data"
      case -25293:
        errorMessage="Keychain item already exists"
      case -25294:
        errorMessage="Keychain is locked"
      case -25295:
        errorMessage="User authentication required for keychain access"
      default:
        if
          let localizedError=error as? LocalizedError,
          let description=localizedError.errorDescription
        {
          errorMessage=description
        } else {
          errorMessage="Credential error: \(error.localizedDescription)"
        }
    }

    return SecurityErrorDTO(
      code: errorCode,
      domain: errorDomain,
      message: errorMessage,
      details: errorDetails
    )
  }

  /// Convert a security error to a SecurityErrorDTO
  /// - Parameter error: The security error to convert
  /// - Returns: A SecurityErrorDTO representing the error
  public static func convertSecurityError(_ error: Error) -> SecurityErrorDTO {
    // Check if the error is already a SecurityErrorDTO
    if let securityError=error as? SecurityErrorDTO {
      return securityError
    }

    // Handle known security error codes
    let errorCode=Int32(error._code)
    let errorDomain="security.utils"

    // Extract error details for specific security error types
    let errorDetails=extractSecurityErrorDetails(error)

    // Create appropriate error message based on error code
    let errorMessage: String

      // Map common security error codes
      = switch errorCode
    {
      case -25240:
        "Invalid algorithm"
      case -25241:
        "Invalid key"
      case -25242:
        "Invalid key size"
      case -25243:
        "Invalid data format"
      case -25244:
        "Invalid operation"
      case Int32(OSStatus(errSecAllocate)):
        "Failed to allocate memory for security operation"
      case Int32(OSStatus(errSecDecode)):
        "Failed to decode data for security operation"
      case Int32(OSStatus(errSecAuthFailed)):
        "Authentication failed for security operation"
      default:
        if
          let localizedError=error as? LocalizedError,
          let description=localizedError.errorDescription
        {
          description
        } else {
          "Security error: \(error.localizedDescription)"
        }
    }

    return SecurityErrorDTO(
      code: errorCode,
      domain: errorDomain,
      message: errorMessage,
      details: errorDetails
    )
  }

  /// Convert any error to a SecurityErrorDTO
  /// - Parameter error: The error to convert
  /// - Returns: A SecurityErrorDTO representing the error
  public static func convertAnyError(_ error: Error) -> SecurityErrorDTO {
    // Check if the error is already a SecurityErrorDTO
    if let securityError=error as? SecurityErrorDTO {
      return securityError
    }

    // Check if we have a specialized conversion for this error type
    if error._domain.contains("credential") {
      return convertCredentialError(error)
    } else if error._domain.contains("security") {
      return convertSecurityError(error)
    }

    // Generic error conversion
    return SecurityErrorDTO(
      code: Int32(error._code),
      domain: error._domain,
      message: error.localizedDescription,
      details: ["errorType": String(describing: type(of: error))]
    )
  }

  // MARK: - Private Helper Methods

  /// Extract detailed information from a credential error
  /// - Parameter error: The error to extract details from
  /// - Returns: A dictionary of error details
  private static func extractCredentialErrorDetails(_ error: Error) -> [String: String] {
    var details: [String: String]=[:]

    // Add general error information
    details["errorType"]=String(describing: type(of: error))
    details["errorCode"]="\(error._code)"
    details["errorDomain"]=error._domain

    // Extract specific information for certain error types
    if let nsError=error as? NSError {
      // Add userInfo keys that might be useful
      if let failureReason=nsError.localizedFailureReason {
        details["failureReason"]=failureReason
      }
      if let recoverySuggestion=nsError.localizedRecoverySuggestion {
        details["recoverySuggestion"]=recoverySuggestion
      }

      // Extract any service or account information that might be in the userInfo
      for (key, value) in nsError.userInfo
        where key.contains("service") || key.contains("account")
      {
        details[key]=String(describing: value)
      }
    }

    return details
  }

  /// Extract detailed information from a security error
  /// - Parameter error: The error to extract details from
  /// - Returns: A dictionary of error details
  private static func extractSecurityErrorDetails(_ error: Error) -> [String: String] {
    var details: [String: String]=[:]

    // Add general error information
    details["errorType"]=String(describing: type(of: error))
    details["errorCode"]="\(error._code)"
    details["errorDomain"]=error._domain

    // Extract specific information for certain error types
    if let nsError=error as? NSError {
      // Add userInfo keys that might be useful
      if let failureReason=nsError.localizedFailureReason {
        details["failureReason"]=failureReason
      }
      if let recoverySuggestion=nsError.localizedRecoverySuggestion {
        details["recoverySuggestion"]=recoverySuggestion
      }

      // Extract any algorithm or operation information that might be in the userInfo
      for (key, value) in nsError.userInfo
        where key.contains("algorithm") || key.contains("operation")
      {
        details[key]=String(describing: value)
      }
    }

    return details
  }
}

// MARK: - Security Error Factory Extensions

extension SecurityErrorDTO {
  /// Create a credential error with the specified message and details
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional error details
  /// - Returns: A SecurityErrorDTO for credential errors
  public static func credentialError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: -25300, // General credential error code
      domain: "security.credential",
      message: message,
      details: details
    )
  }

  /// Create a key error with the specified message and details
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional error details
  /// - Returns: A SecurityErrorDTO for key errors
  public static func keyError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: -25241, // Key error code
      domain: "security.key",
      message: message,
      details: details
    )
  }

  /// Create an encryption error with the specified message and details
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional error details
  /// - Returns: A SecurityErrorDTO for encryption errors
  public static func encryptionError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: -25240, // Encryption error code
      domain: "security.encryption",
      message: message,
      details: details
    )
  }

  /// Create a decryption error with the specified message and details
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional error details
  /// - Returns: A SecurityErrorDTO for decryption errors
  public static func decryptionError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: -25243, // Decryption error code
      domain: "security.decryption",
      message: message,
      details: details
    )
  }

  /// Create a permission error with the specified message and details
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional error details
  /// - Returns: A SecurityErrorDTO for permission errors
  public static func permissionError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: -25300, // Permission error code
      domain: "security.permission",
      message: message,
      details: details
    )
  }

  /// Create an authentication error with the specified message and details
  /// - Parameters:
  ///   - message: The error message
  ///   - details: Additional error details
  /// - Returns: A SecurityErrorDTO for authentication errors
  public static func authenticationError(
    message: String,
    details: [String: String]=[:]
  ) -> SecurityErrorDTO {
    SecurityErrorDTO(
      code: Int32(errSecAuthFailed),
      domain: "security.authentication",
      message: message,
      details: details
    )
  }
}
