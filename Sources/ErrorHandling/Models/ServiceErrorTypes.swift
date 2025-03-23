import Foundation

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

/// Severity level for service errors
@frozen
public enum ServiceErrorSeverity: String, Codable, Sendable {
  /// Critical errors that require immediate attention
  case critical
  /// Serious errors that affect functionality
  case error
  /// Less severe issues that may affect performance
  case warning
  /// Informational issues that don't affect functionality
  case info
}

/// Types of service errors
@frozen
public enum ServiceErrorType: String, Sendable, CaseIterable {
  /// Configuration-related errors
  case configuration="Configuration"
  /// Operation-related errors
  case operation="Operation"
  /// State-related errors
  case state="State"
  /// Resource-related errors
  case resource="Resource"
  /// Dependency-related errors
  case dependency="Dependency"
  /// Network-related errors
  case network="Network"
  /// Authentication-related errors
  case authentication="Authentication"
  /// Timeout-related errors
  case timeout="Timeout"
  /// Initialization-related errors
  case initialization="Initialization"
  /// Lifecycle-related errors
  case lifecycle="Lifecycle"
  /// Permission-related errors
  case permission="Permission"
  /// Unknown errors
  case unknown="Unknown"

  /// User-friendly description of the error type
  public var description: String {
    switch self {
      case .configuration:
        "Configuration Error"
      case .operation:
        "Operation Error"
      case .state:
        "State Error"
      case .resource:
        "Resource Error"
      case .dependency:
        "Dependency Error"
      case .network:
        "Network Error"
      case .authentication:
        "Authentication Error"
      case .timeout:
        "Timeout Error"
      case .initialization:
        "Initialization Error"
      case .lifecycle:
        "Lifecycle Error"
      case .permission:
        "Permission Error"
      case .unknown:
        "Unknown Error"
    }
  }
}
