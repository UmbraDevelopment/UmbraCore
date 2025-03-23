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

/// Extension to bridge between ErrorSeverity and ErrorNotificationLevel
extension ErrorHandlingCommon.ErrorSeverity {
  /// Converts the error severity to a notification level
  /// - Returns: The corresponding ErrorNotificationLevel
  public func toNotificationLevel() -> ErrorNotificationLevel {
    switch notificationLevel {
      case 4:
        .critical
      case 3:
        .error
      case 2:
        .warning
      case 1:
        .info
      default:
        .debug
    }
  }
}

/// Extension to add ErrorSeverity conversion to ErrorNotificationLevel
extension ErrorNotificationLevel {
  /// Convert a notification level to a severity level
  /// - Returns: The corresponding ErrorSeverity
  public func toSeverityLevel() -> ErrorHandlingCommon.ErrorSeverity {
    switch self {
      case .critical:
        return .critical
      case .error:
        return .error
      case .warning:
        return .warning
      case .info:
        return .info
      case .debug:
        return .debug
      @unknown default:
        return .debug
    }
  }
}
