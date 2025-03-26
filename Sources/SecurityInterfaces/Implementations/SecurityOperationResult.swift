import Foundation
import UmbraCoreTypes

/// Result of a security operation with Foundation types
public struct SecurityOperationResult: Sendable, Equatable {
  /// The result data from the operation
  public let data: SecureBytes?

  /// Error code if operation failed
  public let errorCode: Int?

  /// Error message if operation failed
  public let errorMessage: String?

  /// Success flag
  public let success: Bool

  /// Create a successful result with data
  /// - Parameter data: The result data
  public init(data: SecureBytes) {
    self.data = data
    self.errorCode = nil
    self.errorMessage = nil
    self.success = true
  }

  /// Create a failure result with error information
  /// - Parameters:
  ///   - errorCode: The error code
  ///   - errorMessage: The error message
  public init(errorCode: Int, errorMessage: String) {
    self.data = nil
    self.errorCode = errorCode
    self.errorMessage = errorMessage
    self.success = false
  }

  /// Create from a result DTO
  /// - Parameter dto: The DTO to convert from
  public init(from dto: SecurityResultDTO) {
    self.data = dto.data
    self.errorCode = dto.errorCode
    self.errorMessage = dto.errorMessage
    self.success = dto.success
  }

  /// Convert to a DTO
  /// - Returns: SecurityResultDTO representation
  public func toDTO() -> SecurityResultDTO {
    if success, let data {
      SecurityResultDTO(success: true, data: data, errorCode: nil, errorMessage: nil, error: nil)
    } else {
      SecurityResultDTO(
        success: false,
        data: nil,
        errorCode: errorCode,
        errorMessage: errorMessage,
        error: nil
      )
    }
  }
}

/// DTO for security operation results
/// This type exists to avoid including the consolidated SecurityResultDTO
/// and creating circular dependencies
public struct SecurityResultDTO: Sendable, Equatable {
  /// Whether the operation succeeded
  public let success: Bool
  
  /// Result data if successful
  public let data: SecureBytes?
  
  /// Error code if failed
  public let errorCode: Int?
  
  /// Error message if failed
  public let errorMessage: String?
  
  /// Associated error object if available
  public let error: Error?
  
  /// Create a new result DTO
  /// - Parameters:
  ///   - success: Whether the operation succeeded
  ///   - data: Result data if successful
  ///   - errorCode: Error code if failed
  ///   - errorMessage: Error message if failed
  ///   - error: Associated error object if available
  public init(
    success: Bool,
    data: SecureBytes?,
    errorCode: Int?,
    errorMessage: String?,
    error: Error?
  ) {
    self.success = success
    self.data = data
    self.errorCode = errorCode
    self.errorMessage = errorMessage
    self.error = error
  }
  
  /// Create a successful result with data
  /// - Parameter data: The result data
  /// - Returns: A successful result DTO
  public static func success(data: SecureBytes) -> SecurityResultDTO {
    SecurityResultDTO(success: true, data: data, errorCode: nil, errorMessage: nil, error: nil)
  }
  
  /// Create a failure result with error information
  /// - Parameters:
  ///   - code: Error code
  ///   - message: Error message
  ///   - error: Optional error object
  /// - Returns: A failure result DTO
  public static func failure(
    code: Int,
    message: String,
    error: Error? = nil
  ) -> SecurityResultDTO {
    SecurityResultDTO(
      success: false,
      data: nil,
      errorCode: code,
      errorMessage: message,
      error: error
    )
  }
  
  /// Equality check that ignores the error property
  public static func == (lhs: SecurityResultDTO, rhs: SecurityResultDTO) -> Bool {
    lhs.success == rhs.success &&
    lhs.data == rhs.data &&
    lhs.errorCode == rhs.errorCode &&
    lhs.errorMessage == rhs.errorMessage
  }
}
