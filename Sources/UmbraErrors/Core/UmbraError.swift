import Foundation
import OSLog

/// A protocol that all UmbraCore errors must conform to.
/// This provides a consistent interface for error handling across the codebase.
public protocol UmbraError: Error, Sendable, CustomStringConvertible {
  /// The domain that this error belongs to, e.g., "Security", "Repository"
  var domain: String { get }

  /// A unique code that identifies this error within its domain
  var code: String { get }

  /// A human-readable description of the error
  var errorDescription: String { get }

  /// Optional source information about where the error occurred
  var source: ErrorSource? { get }

  /// Optional underlying error that caused this error
  var underlyingError: Error? { get }

  /// Additional context information about the error
  var context: ErrorContext { get }

  /// Creates a new instance of the error with additional context
  func with(context: ErrorContext) -> Self

  /// Creates a new instance of the error with a specified underlying error
  func with(underlyingError: Error) -> Self

  /// Creates a new instance of the error with source information
  func with(source: ErrorSource) -> Self
}

/// Default implementation for UmbraError
extension UmbraError {
  public var description: String {
    var desc="[\(domain):\(code)] \(errorDescription)"

    if let source {
      desc += " (at \(source.function) in \(source.file):\(source.line))"
    }

    return desc
  }

  /// Default implementation returns an empty context
  public var context: ErrorContext {
    ErrorContext()
  }

  /// Default implementation returns nil
  public var underlyingError: Error? {
    nil
  }

  /// Default implementation returns nil
  public var source: ErrorSource? {
    nil
  }
}

/// A protocol for domain-specific error types
public protocol DomainError: UmbraError {
  /// The domain identifier for this error type
  static var domain: String { get }
}

/// Default implementation for DomainError
extension DomainError {
  public var domain: String {
    Self.domain
  }
}

/// Logger for the UmbraErrors system
private let errorLogger=Logger(subsystem: "com.umbracorp.UmbraCore", category: "Errors")

/// Extension to provide logging capabilities to UmbraError
extension UmbraError {
  /// Logs this error with the appropriate log level
  public func log(level: OSLogType = .error, privacy: OSLogPrivacy = .public) {
    switch level {
      case .debug:
        errorLogger.debug("\(self, privacy: privacy)")
      case .info:
        errorLogger.info("\(self, privacy: privacy)")
      case .error:
        errorLogger.error("\(self, privacy: privacy)")
      case .fault:
        errorLogger.fault("\(self, privacy: privacy)")
      default:
        errorLogger.log("\(self, privacy: privacy)")
    }
  }
}
