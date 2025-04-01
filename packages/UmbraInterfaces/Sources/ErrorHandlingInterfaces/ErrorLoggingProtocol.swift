import ErrorCoreTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLoggingProtocol

 Protocol defining requirements for error logging components.

 This protocol establishes a consistent interface for logging errors across
 the system. It bridges error handling with the logging system, following
 the Alpha Dot Five architecture principles.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for error logging operations:

 ```swift
 actor ErrorLoggingActor: ErrorLoggingProtocol {
     // Private state should be isolated within the actor
     private let logger: PrivacyAwareLoggingProtocol
     private let metadataCollector: ErrorMetadataCollector

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class ErrorLogger: ErrorLoggingProtocol {
     private let actor: ErrorLoggingActor

     // Forward all protocol methods to the actor
     public func logError<E>(_ error: E, level: ErrorLogLevel, options: ErrorLoggingOptions?) async where E: Error {
         await actor.logError(error, level: level, options: options)
     }
 }
 ```

 ## Privacy Considerations

 Error logging potentially involves sensitive application data. Implementations must:
 - Apply privacy redaction to sensitive fields in error details
 - Properly sanitise stack traces and context information
 - Ensure sensitive error details are not exposed in logs
 - Implement appropriate classification of errors for auditing
 */
public protocol ErrorLoggingProtocol: Sendable {
  /**
   Logs an error with the appropriate level and context.

   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - options: Configuration options for error logging
   */
  func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions?
  ) async

  /**
   Logs an error with the appropriate level and context.

   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    context: ErrorContext,
    options: ErrorLoggingOptions?
  ) async

  /**
   Logs an error with debug level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  func debug<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async

  /**
   Logs an error with info level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  func info<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async

  /**
   Logs an error with warning level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  func warning<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async

  /**
   Logs an error with error level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  func error<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async

  /**
   Logs an error with critical level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  func critical<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async
}

/// Default implementations for optional parameters
extension ErrorLoggingProtocol {
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions?=nil
  ) async {
    await logError(error, level: level, options: options)
  }

  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    context: ErrorContext,
    options: ErrorLoggingOptions?=nil
  ) async {
    await logError(error, level: level, context: context, options: options)
  }

  public func debug(_ error: some Error, context: ErrorContext?=nil) async {
    await debug(error, context: context, options: nil as ErrorLoggingOptions?)
  }

  public func info(_ error: some Error, context: ErrorContext?=nil) async {
    await info(error, context: context, options: nil as ErrorLoggingOptions?)
  }

  public func warning(_ theError: some Error, context: ErrorContext?=nil) async {
    await warning(theError, context: context, options: nil as ErrorLoggingOptions?)
  }

  public func error(_ theError: some Error, context: ErrorContext?=nil) async {
    await error(theError, context: context, options: nil as ErrorLoggingOptions?)
  }

  public func critical(_ theError: some Error, context: ErrorContext?=nil) async {
    await critical(theError, context: context, options: nil as ErrorLoggingOptions?)
  }
}

/**
 Severity levels for error logging.
 */
public enum ErrorLogLevel: String, Sendable, CaseIterable, Comparable {
  /// Debug-level errors (typically only logged in development)
  case debug

  /// Informational errors (not critical but worth noting)
  case info

  /// Warning-level errors (potential problems)
  case warning

  /// Error-level errors (definite problems)
  case error

  /// Critical-level errors (severe problems)
  case critical

  public static func < (lhs: ErrorLogLevel, rhs: ErrorLogLevel) -> Bool {
    let order: [ErrorLogLevel]=[.debug, .info, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/**
 Options for configuring error logging behaviour.
 */
public struct ErrorLoggingOptions: Sendable, Equatable {
  /// Standard options for most error logging
  public static let standard=ErrorLoggingOptions()

  /// Whether to include stack traces in the log
  public let includeStackTrace: Bool

  /// Whether to include the source code location
  public let includeSourceLocation: Bool

  /// Privacy level for logging this error
  public let privacyLevel: ErrorPrivacyLevel

  /// Additional metadata to include in the log
  public let additionalMetadata: [String: String]

  /// User-facing message template (if applicable)
  public let userMessageTemplate: String?

  /// Whether to report this error to a monitoring service
  public let reportToMonitoring: Bool

  /// Creates new error logging options
  public init(
    includeStackTrace: Bool=true,
    includeSourceLocation: Bool=true,
    privacyLevel: ErrorPrivacyLevel = .standard,
    additionalMetadata: [String: String]=[:],
    userMessageTemplate: String?=nil,
    reportToMonitoring: Bool=true
  ) {
    self.includeStackTrace=includeStackTrace
    self.includeSourceLocation=includeSourceLocation
    self.privacyLevel=privacyLevel
    self.additionalMetadata=additionalMetadata
    self.userMessageTemplate=userMessageTemplate
    self.reportToMonitoring=reportToMonitoring
  }
}
