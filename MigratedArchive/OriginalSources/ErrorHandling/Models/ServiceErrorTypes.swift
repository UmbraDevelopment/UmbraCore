import Foundation
import UmbraErrorsCore

/**
 * This file provides legacy service error types for backward compatibility.
 * New code should use UmbraErrorsCore types directly.
 *
 * The types in this file map to equivalent types in UmbraErrorsCore
 * and provide conversion utilities to simplify migration.
 */

// MARK: - Service Error Types

/// Severity level for service errors
/// For new code, use UmbraErrorsCore.ErrorSeverity instead
@frozen
public enum ServiceErrorSeverity: String, Codable, Sendable {
  /// Critical errors that require immediate attention
  case critical
  /// Serious errors that affect functionality
  case error
  /// Less severe issues that may affect performance
  case warning
  /// Informational messages that don't indicate problems
  case info
  /// Detailed information for debugging
  case debug

  /// Convert to UmbraErrorsCore.ErrorSeverity
  public var asUmbraErrorSeverity: UmbraErrorsCore.ErrorSeverity {
    switch self {
      case .critical:
        .critical
      case .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug:
        .debug
    }
  }

  /// Create from UmbraErrorsCore.ErrorSeverity
  public static func from(_ severity: UmbraErrorsCore.ErrorSeverity) -> ServiceErrorSeverity {
    switch severity {
      case .critical:
        .critical
      case .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug, .trace:
        .debug
    }
  }
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

/// Properties common to all service errors
public protocol ServiceError: Error, Sendable {
  /// Service that encountered the error
  var service: String { get }

  /// Type of error that occurred
  var errorType: String { get }

  /// Detailed error message
  var message: String { get }

  /// Optional request identifier associated with the error
  var requestID: String? { get }

  /// Error severity level
  var severity: ServiceErrorSeverity { get }

  /// Convert to GenericUmbraError
  var asUmbraError: GenericUmbraError { get }
}

/// Default implementation of asUmbraError
extension ServiceError {
  public var asUmbraError: GenericUmbraError {
    // Create error context
    let errorContext=UmbraErrorsCore.ErrorContext()
      .adding(key: "service", value: service)
      .adding(key: "errorType", value: errorType)
      .adding(key: "message", value: message)
      .adding(key: "requestId", value: requestID ?? "")

    // Create GenericUmbraError with the context
    return GenericUmbraError(
      domain: service,
      code: errorType,
      errorDescription: message ?? "Unknown service error",
      context: errorContext
    )
  }
}

/// Basic implementation of ServiceError
public struct BasicServiceError: ServiceError {
  /// Service that encountered the error
  public let service: String

  /// Type of error that occurred
  public let errorType: String

  /// Detailed error message
  public let message: String

  /// Optional request identifier associated with the error
  public let requestID: String?

  /// Error severity level
  public let severity: ServiceErrorSeverity

  /// Creates a new BasicServiceError
  /// - Parameters:
  ///   - service: Service that encountered the error
  ///   - errorType: Type of error that occurred
  ///   - message: Detailed error message
  ///   - requestId: Optional request identifier
  ///   - severity: Error severity level
  public init(
    service: String,
    errorType: String,
    message: String,
    requestID: String?=nil,
    severity: ServiceErrorSeverity = .error
  ) {
    self.service=service
    self.errorType=errorType
    self.message=message
    self.requestID=requestID
    self.severity=severity
  }
}
