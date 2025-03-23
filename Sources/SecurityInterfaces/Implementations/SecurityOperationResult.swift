import Foundation
import SecurityProtocolsCore
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
    self.data=data
    errorCode=nil
    errorMessage=nil
    success=true
  }

  /// Create a failure result with error details
  /// - Parameters:
  ///   - code: Error code
  ///   - message: Error message
  public init(errorCode: Int, errorMessage: String) {
    data=nil
    self.errorCode=errorCode
    self.errorMessage=errorMessage
    success=false
  }

  /// Convert to a DTO
  /// - Returns: SecurityResultDTO representation
  public func toDTO() -> SecurityProtocolsCore.SecurityResultDTO {
    if success, let data {
      SecurityProtocolsCore.SecurityResultDTO(data: data)
    } else if let errorCode, let errorMessage {
      SecurityProtocolsCore.SecurityResultDTO(errorCode: errorCode, errorMessage: errorMessage)
    } else {
      SecurityProtocolsCore.SecurityResultDTO(
        success: false,
        error: .internalError("Unknown error"),
        errorDetails: "Operation failed"
      )
    }
  }
}
