import UmbraCoreTypes
import Errors

/// FoundationIndependent representation of a security operation result.
/// This data transfer object encapsulates the outcome of security-related operations
/// including success with data or failure with error information.
public struct SecurityResultDTO: Sendable, Equatable {
  // MARK: - Properties

  /// Success or failure status
  public let success: Bool

  /// Operation result data, if successful
  public let data: SecureBytes?

  /// Error code if operation failed
  public let errorCode: Int?

  /// Error message if operation failed
  public let errorMessage: String?

  /// Security error type
  public let error: Errors.SecurityProtocolError?

  // MARK: - Initializers

  /// Initialise a successful result with data
  /// - Parameter data: Result data
  public init(data: SecureBytes) {
    success=true
    self.data=data
    errorCode=nil
    errorMessage=nil
    error=nil
  }

  /// Initialise a successful result without data
  public init() {
    success=true
    data=nil
    errorCode=nil
    errorMessage=nil
    error=nil
  }

  /// Initialise with comprehensive parameters
  /// - Parameters:
  ///   - success: Whether the operation succeeded
  ///   - data: Optional result data
  ///   - errorCode: Optional error code
  ///   - errorMessage: Optional error message
  ///   - error: Optional security protocol error
  public init(
    success: Bool,
    data: SecureBytes?=nil,
    errorCode: Int?=nil,
    errorMessage: String?=nil,
    error: Errors.SecurityProtocolError?=nil
  ) {
    self.success=success
    self.data=data
    self.errorCode=errorCode
    self.errorMessage=errorMessage
    self.error=error
  }

  // MARK: - Factory Methods

  /// Create a successful result with data
  /// - Parameter data: Result data
  /// - Returns: SecurityResultDTO instance
  public static func success(data: SecureBytes) -> SecurityResultDTO {
    SecurityResultDTO(data: data)
  }

  /// Create a successful result without data
  /// - Returns: SecurityResultDTO instance
  public static func success() -> SecurityResultDTO {
    SecurityResultDTO()
  }

  /// Create a failed result with an error message
  /// - Parameters:
  ///   - message: Error message
  ///   - code: Optional error code
  /// - Returns: SecurityResultDTO instance
  public static func failure(
    message: String,
    code: Int=0
  ) -> SecurityResultDTO {
    SecurityResultDTO(
      success: false,
      errorCode: code,
      errorMessage: message
    )
  }

  /// Create a failed result with a SecurityProtocolError
  /// - Parameter error: Security protocol error
  /// - Returns: SecurityResultDTO instance
  public static func failure(
    error: Errors.SecurityProtocolError
  ) -> SecurityResultDTO {
    let message: String
    
    switch error {
    case .internalError(let errorMessage):
      message = "Internal error: \(errorMessage)"
    case .invalidInput(let errorMessage):
      message = "Invalid input: \(errorMessage)"
    case .unsupportedOperation(let name):
      message = "Unsupported operation: \(name)"
    case .keyManagementError(let errorMessage):
      message = "Key management error: \(errorMessage)"
    case .cryptographicError(let errorMessage):
      message = "Cryptographic error: \(errorMessage)"
    case .authenticationFailed(let errorMessage):
      message = "Authentication failed: \(errorMessage)"
    case .storageError(let errorMessage):
      message = "Storage error: \(errorMessage)"
    case .configurationError(let errorMessage):
      message = "Configuration error: \(errorMessage)"
    case .securityError(let errorMessage):
      message = "Security error: \(errorMessage)"
    case .serviceError(let code, let errorMessage):
      message = "Service error (\(code)): \(errorMessage)"
    }
    
    return SecurityResultDTO(
      success: false,
      errorMessage: message,
      error: error
    )
  }

  // MARK: - Conversion Methods

  /// Convert to Result<SecureBytes, SecurityProtocolError>
  /// - Returns: Swift Result type with SecureBytes or SecurityProtocolError
  public func toResult() -> Result<SecureBytes, Errors.SecurityProtocolError> {
    if success, let data = data {
      return .success(data)
    } else if let error = error {
      return .failure(error)
    } else {
      return .failure(.internalError(errorMessage ?? "Unknown error"))
    }
  }

  /// Convert to Result<Void, SecurityProtocolError>
  /// - Returns: Swift Result type with Void or SecurityProtocolError
  public func toVoidResult() -> Result<Void, Errors.SecurityProtocolError> {
    if success {
      return .success(())
    } else if let error = error {
      return .failure(error)
    } else {
      return .failure(.internalError(errorMessage ?? "Unknown error"))
    }
  }
}
