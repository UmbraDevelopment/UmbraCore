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
 */
public protocol ErrorLoggingProtocol: Sendable {
  /**
   Logs an error with the appropriate level and context.

   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - context: Optional contextual information about the error
   */
  func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    context: ErrorContext?
  ) async

  /**
   Logs an error with debug level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  func debug<E: Error>(_ error: E, context: ErrorContext?) async

  /**
   Logs an error with info level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  func info<E: Error>(_ error: E, context: ErrorContext?) async

  /**
   Logs an error with warning level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  func warning<E: Error>(_ error: E, context: ErrorContext?) async

  /**
   Logs an error with error level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
   */
  func error<E: Error>(_ error: E, context: ErrorContext?) async
}

/**
 Severity levels for error logging.
 */
public enum ErrorLogLevel: String, Sendable, CaseIterable {
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
}
