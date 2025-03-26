import Foundation
import UmbraCoreTypes

// Error domain and context types for security bridge operations

/// Error domain namespace for security operations
public enum SecurityErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol for security operations
public protocol SecurityErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base security error context implementation
public struct SecurityBaseErrorContext: SecurityErrorContext {
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

/// Foundation-independent representation of a security protocol error.
/// This type is designed for contexts where Foundation independence is required.
public struct SecurityProtocolsErrorDTO: Error, Sendable, Equatable, CustomStringConvertible {
  // MARK: - Error Code Enum

  /// Enumeration of security error codes
  public enum ErrorCode: Int32, Sendable, Equatable, CustomStringConvertible {
    /// Unknown error
    case unknown=0
    /// Invalid input data or parameters
    case invalidInput=1001
    /// Cryptographic operation failed
    case cryptographicError=1002
    /// Key not found
    case keyNotFound=1003
    /// Service is unavailable
    case serviceUnavailable=1004
    /// Operation not supported
    case unsupportedOperation=1005
    /// Permission denied
    case permissionDenied=1007

    /// String description of the error code
    public var description: String {
      switch self {
        case .unknown:
          "Unknown Error"
        case .invalidInput:
          "Invalid Input"
        case .cryptographicError:
          "Cryptographic Error"
        case .keyNotFound:
          "Key Not Found"
        case .serviceUnavailable:
          "Service Unavailable"
        case .unsupportedOperation:
          "Unsupported Operation"
        case .permissionDenied:
          "Permission Denied"
      }
    }
  }

  // MARK: - Properties

  /// Error code
  public let code: ErrorCode

  /// Error message
  public var message: String {
    details["message"] ?? code.description
  }

  /// Additional details about the error
  public let details: [String: String]

  // MARK: - Initialization

  /// Create a security protocol error DTO
  /// - Parameters:
  ///   - code: Error code
  ///   - details: Additional details
  public init(code: ErrorCode, details: [String: String]=[:]) {
    self.code=code
    self.details=details
  }

  // MARK: - CustomStringConvertible

  /// String description of the error
  public var description: String {
    if details.isEmpty {
      return "\(code.description)"
    }
    return "\(code.description): \(message)"
  }

  // MARK: - Factory Methods

  /// Create an unknown error
  /// - Parameter details: Optional error details
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func unknown(details: String?=nil) -> SecurityProtocolsErrorDTO {
    var detailsDict: [String: String]=[:]
    if let details {
      detailsDict["message"]=details
    }
    return SecurityProtocolsErrorDTO(code: .unknown, details: detailsDict)
  }

  /// Create an invalid input error
  /// - Parameter details: Description of the invalid input
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func invalidInput(details: String) -> SecurityProtocolsErrorDTO {
    SecurityProtocolsErrorDTO(
      code: .invalidInput,
      details: ["message": details]
    )
  }

  /// Create a cryptographic error
  /// - Parameters:
  ///   - operation: The operation that failed
  ///   - details: Error details
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func cryptographicError(
    operation: String,
    details: String
  ) -> SecurityProtocolsErrorDTO {
    SecurityProtocolsErrorDTO(
      code: .cryptographicError,
      details: [
        "operation": operation,
        "message": details
      ]
    )
  }

  /// Create a key not found error
  /// - Parameter identifier: Key identifier
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func keyNotFound(identifier: String) -> SecurityProtocolsErrorDTO {
    SecurityProtocolsErrorDTO(
      code: .keyNotFound,
      details: ["keyIdentifier": identifier]
    )
  }

  /// Create a service unavailable error
  /// - Parameters:
  ///   - service: Service name
  ///   - reason: Reason for unavailability
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func serviceUnavailable(
    service: String="Security Service",
    reason: String="Service is not available"
  ) -> SecurityProtocolsErrorDTO {
    SecurityProtocolsErrorDTO(
      code: .serviceUnavailable,
      details: [
        "service": service,
        "reason": reason
      ]
    )
  }

  /// Create an unsupported operation error
  /// - Parameter operation: Operation name
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func unsupportedOperation(operation: String) -> SecurityProtocolsErrorDTO {
    SecurityProtocolsErrorDTO(
      code: .unsupportedOperation,
      details: ["operation": operation]
    )
  }

  /// Create a permission denied error
  /// - Parameters:
  ///   - operation: Operation name
  ///   - details: Additional details
  /// - Returns: A SecurityProtocolsErrorDTO
  public static func permissionDenied(
    operation: String,
    details: String?=nil
  ) -> SecurityProtocolsErrorDTO {
    var detailsDict: [String: String]=["operation": operation]
    if let details {
      detailsDict["message"]=details
    }
    return SecurityProtocolsErrorDTO(
      code: .permissionDenied,
      details: detailsDict
    )
  }
}
