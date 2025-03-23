import UmbraCoreTypes

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

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
  public let error: UmbraErrors.Security.Protocols?

  // MARK: - Initializers

  /// Initialize a successful result with data
  /// - Parameter data: The operation result data
  public init(data: SecureBytes) {
    success=true
    self.data=data
    errorCode=nil
    errorMessage=nil
    error=nil
  }

  /// Initialize a successful result without data
  public init() {
    success=true
    data=nil
    errorCode=nil
    errorMessage=nil
    error=nil
  }

  /// Initialize with success flag and optional data
  /// - Parameters:
  ///   - success: Whether the operation succeeded
  ///   - data: Optional result data
  public init(success: Bool, data: SecureBytes?=nil) {
    self.success=success
    self.data=data
    errorCode=nil
    errorMessage=nil
    error=nil
  }

  /// Initialize a security result
  ///
  /// - Parameters:
  ///   - success: Result status
  ///   - error: Optional error type
  ///   - errorDetails: Optional detailed error message
  public init(
    success: Bool,
    error: UmbraErrors.Security.Protocols?=nil,
    errorDetails: String?=nil
  ) {
    self.success=success
    data=nil
    self.error=error

    // Derive error code based on error type
    if let error {
      switch error {
        case .invalidFormat:
          errorCode=1001
        case .unsupportedOperation:
          errorCode=1002
        case .incompatibleVersion:
          errorCode=1003
        case .missingProtocolImplementation:
          errorCode=1004
        case .invalidState:
          errorCode=1005
        case .internalError:
          errorCode=1006
        case .invalidInput:
          errorCode=1007
        case .encryptionFailed:
          errorCode=1008
        case .decryptionFailed:
          errorCode=1009
        case .randomGenerationFailed:
          errorCode=1010
        case .storageOperationFailed:
          errorCode=1011
        case .serviceError:
          errorCode=1012
        case .notImplemented:
          errorCode=1013
        @unknown default:
          errorCode=1099
      }

      // Set error description
      errorMessage=errorDetails ?? String(describing: error)
    } else {
      errorCode=nil
      errorMessage=errorDetails
    }
  }

  /// Initialize a failure result with error details
  /// - Parameters:
  ///   - errorCode: Numeric error code
  ///   - errorMessage: Human-readable error message
  public init(errorCode: Int, errorMessage: String) {
    success=false
    data=nil
    self.errorCode=errorCode
    self.errorMessage=errorMessage
    error = .internalError("Error code: \(errorCode), Message: \(errorMessage)")
  }

  // MARK: - Utility Methods

  /// Create a successful result with the given data
  /// - Parameter data: Result data
  /// - Returns: A success result DTO
  public static func success(data: SecureBytes) -> SecurityResultDTO {
    SecurityResultDTO(data: data)
  }

  /// Create a successful result with no data
  /// - Returns: A success result DTO
  public static func success() -> SecurityResultDTO {
    SecurityResultDTO()
  }

  /// Create a failure result with the given error information
  /// - Parameters:
  ///   - code: Error code
  ///   - message: Error message
  /// - Returns: A failure result DTO
  public static func failure(code: Int, message: String) -> SecurityResultDTO {
    SecurityResultDTO(errorCode: code, errorMessage: message)
  }

  /// Create a failure result DTO
  /// - Parameters:
  ///   - error: The security error type
  ///   - details: Optional error details
  /// - Returns: A failure result DTO
  public static func failure(
    error: UmbraErrors.Security.Protocols,
    details: String?=nil
  ) -> SecurityResultDTO {
    SecurityResultDTO(success: false, error: error, errorDetails: details)
  }

  // MARK: - Equatable Conformance

  /// Compares two SecurityResultDTO instances for equality
  /// - Parameters:
  ///   - lhs: Left-hand side instance
  ///   - rhs: Right-hand side instance
  /// - Returns: True if the instances are equal, false otherwise
  public static func == (lhs: SecurityResultDTO, rhs: SecurityResultDTO) -> Bool {
    // Compare success status
    guard lhs.success == rhs.success else { return false }

    // For successful results, compare data
    if lhs.success {
      if let lhsData=lhs.data, let rhsData=rhs.data {
        return lhsData == rhsData
      } else {
        // If one has data and the other doesn't, they're not equal
        return lhs.data == nil && rhs.data == nil
      }
    } else {
      // For failure results, compare error codes and messages
      if lhs.errorCode != rhs.errorCode {
        return false
      }

      // Compare error types
      if let lhsError=lhs.error, let rhsError=rhs.error {
        // Compare error types by their string representation
        // This is a simple approach; a more robust solution would compare the enum cases directly
        return String(describing: lhsError) == String(describing: rhsError)
      } else {
        // If one has an error and the other doesn't, they're not equal
        return lhs.error == nil && rhs.error == nil
      }
    }
  }
}
