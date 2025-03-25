import UmbraCoreTypes
import SecurityProtocolsCore.Types

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
  public let error: SecurityProtocolError?

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
  ///   - error: Optional protocol error
  ///   - errorDetails: Optional additional error details
  public init(
    success: Bool,
    data: SecureBytes?=nil,
    errorCode: Int?=nil,
    errorMessage: String?=nil,
    error: SecurityProtocolError?=nil,
    errorDetails: String?=nil
  ) {
    self.success=success
    self.data=data
    self.error=error

    // Handle error codes and messages
    if let error {
      // Extract error code and message from the error
      var code: Int
      var message: String

      switch error {
        case let .internalError(msg):
          code=500
          message=msg
        case let .unsupportedOperation(name):
          code=501
          message="Operation not supported: \(name)"
        case let .serviceError(c, msg):
          code=c
          message=msg
      }

      // If additional details are provided, append them to the error message
      if let details=errorDetails, !details.isEmpty {
        message += " (\(details))"
      }

      self.errorCode=code
      self.errorMessage=message
    } else {
      // Use provided error code and message if no error object
      self.errorCode=errorCode

      // Combine provided error message with details if both exist
      if let message=errorMessage, let details=errorDetails, !details.isEmpty {
        self.errorMessage=message + " (\(details))"
      } else {
        self.errorMessage=errorMessage ?? errorDetails
      }
    }
  }

  // MARK: - Static Constructors

  /// Create a successful result
  /// - Parameter data: Optional result data
  /// - Returns: A success result DTO
  public static func success(withData data: SecureBytes?=nil) -> SecurityResultDTO {
    if let data {
      SecurityResultDTO(data: data)
    } else {
      SecurityResultDTO()
    }
  }

  /// Create a failure result
  /// - Parameters:
  ///   - code: Error code
  ///   - message: Error message
  /// - Returns: A failure result DTO
  public static func failure(
    code: Int,
    message: String
  ) -> SecurityResultDTO {
    SecurityResultDTO(
      success: false,
      errorCode: code,
      errorMessage: message
    )
  }

  /// Create a failure result from a protocol error
  /// - Parameters:
  ///   - error: The protocol error
  ///   - details: Additional details
  /// - Returns: A failure result DTO
  public static func failure(
    error: SecurityProtocolError,
    details: String?=nil
  ) -> SecurityResultDTO {
    SecurityResultDTO(
      success: false,
      error: error,
      errorDetails: details
    )
  }

  // MARK: - Equatable

  public static func == (lhs: SecurityResultDTO, rhs: SecurityResultDTO) -> Bool {
    // Compare success status
    guard lhs.success == rhs.success else { return false }

    // For successful results, compare data
    if lhs.success {
      if let lhsData=lhs.data, let rhsData=rhs.data {
        return lhsData == rhsData
      } else {
        // If either has data and the other doesn't, they're not equal
        return lhs.data == nil && rhs.data == nil
      }
    } else {
      // For failure results, compare error information
      return lhs.errorCode == rhs.errorCode &&
        lhs.errorMessage == rhs.errorMessage
    }
  }
}
