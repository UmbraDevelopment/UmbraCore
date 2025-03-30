import ErrorLoggingInterfaces
import Foundation
import LoggingTypes
import UmbraErrors
import UmbraErrorsCore

/// Example demonstrating usage of the new Alpha Dot Five error logging system
///
/// This file shows how to:
/// - Create and configure error loggers
/// - Log different types of errors with appropriate context
/// - Use domain-specific filtering and configuration
/// - Work with privacy controls for sensitive error data
enum ErrorLoggingExample {
  /// Run a comprehensive example of error logging
  static func runExample() async {
    print("Starting error logging example...")

    // MARK: - Basic Error Logging

    // Create a default error logger
    let errorLogger=await ErrorLoggerFactory.createDefaultErrorLogger()

    // Create some test errors
    let authError=NSError(
      domain: "AuthService",
      code: 401,
      userInfo: [NSLocalizedDescriptionKey: "Authentication token expired"]
    )

    // Log the auth error with explicit level
    await errorLogger.log(
      authError,
      level: .error,
      file: #file,
      function: #function,
      line: #line
    )

    // Create a standard error with our domain
    struct DocumentError: Error, CustomStringConvertible {
      let reason: String
      var description: String { reason }
    }

    let docError=DocumentError(reason: "Document could not be loaded")

    // Log with explicit level
    await errorLogger.log(
      docError,
      level: .error,
      file: #file,
      function: #function,
      line: #line
    )

    // MARK: - Using Context for Enhanced Error Logging

    // Create a domain error with context
    let errorContext=ErrorContext(
      ["documentId": "12345", "userId": "user789", "attempt": "2"],
      source: "DocumentService",
      operation: "loadDocument",
      details: "Document is corrupted and cannot be opened",
      underlyingError: nil,
      file: #file,
      line: #line,
      function: #function
    )

    // Log with explicit context - provides richer information
    await errorLogger.logWithContext(
      docError,
      context: errorContext,
      level: .error,
      file: #file,
      function: #function,
      line: #line
    )

    // MARK: - Creating Errors with Error Data

    // Error data can be used to create standardised errors
    let networkError=ErrorData(
      domain: "NetworkService",
      code: "NET_SLOW",
      message: "Network connection is slow",
      severity: .warning
    )

    // Log the network error with its default severity
    await errorLogger.log(
      networkError,
      level: .warning,
      file: #file,
      function: #function,
      line: #line
    )

    // MARK: - OSLog Integration

    // Create a logger that integrates with OSLog
    let osLogErrorLogger=await ErrorLoggerFactory.createOSLogErrorLogger(
      subsystem: "com.umbra.errorlogging.example",
      category: "errors"
    )

    // Log errors with OSLog integration
    await osLogErrorLogger.log(
      authError,
      level: .error,
      file: #file,
      function: #function,
      line: #line
    )

    print("Error logging example completed.")
  }
}

/// Sample error data structure for demonstration
struct ErrorData: Error, CustomStringConvertible {
  let domain: String
  let code: String
  let message: String
  let severity: ErrorLoggingLevel

  var description: String {
    "[\(domain):\(code)] \(message)"
  }
}
