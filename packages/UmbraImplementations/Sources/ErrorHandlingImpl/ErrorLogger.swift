import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLogger

 A specialised logger for error handling that provides domain-specific
 logging methods with appropriate privacy controls and contextual
 information.

 This component enhances error logs with consistent formatting, privacy
 annotations, and structured metadata to improve debugging and analysis.
 */
public actor ErrorLogger: ErrorLoggingProtocol {
  /// The underlying logger implementation
  private let logger: PrivacyAwareLoggingProtocol

  /// The subsystem for error logging
  private let subsystem="ErrorHandling"

  /**
   Initialises a new error logger with the provided logging implementation.

   - Parameter logger: The underlying logger to use for output
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }

  // MARK: - ErrorLoggingProtocol Conformance

  /**
   Logs an error with the appropriate level and context.

   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - options: Configuration options for error logging
   */
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions?
  ) async {
    // Create default context with source information
    let context=ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["subsystem": subsystem],
      timestamp: Date()
    )

    await logError(error, level: level, context: context, options: options)
  }

  /**
   Logs an error with the appropriate level and context.

   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    context: ErrorContext,
    options _: ErrorLoggingOptions?
  ) async {
    // We don't use the privacyLevel here, just the error metadata
    let metadataDict=createMetadata(for: error, context: context)
    let message=formatErrorMessage(error)
    let source="\(context.source.file):\(context.source.line)"

    // Map ErrorLogLevel to LogLevel
    let logLevel=mapErrorLogLevel(level)

    // Log with the appropriate level
    switch logLevel {
      case .trace:
        await logger.trace(message, metadata: metadataDict, source: source)
      case .debug:
        await logger.debug(message, metadata: metadataDict, source: source)
      case .info:
        await logger.info(message, metadata: metadataDict, source: source)
      case .warning:
        await logger.warning(message, metadata: metadataDict, source: source)
      case .error:
        await logger.error(message, metadata: metadataDict, source: source)
      case .critical:
        await logger.critical(message, metadata: metadataDict, source: source)
    }
  }

  /**
   Logs an error with debug level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func debug(
    _ error: some Error,
    context: ErrorContext?=nil,
    options: ErrorLoggingOptions?=nil
  ) async {
    let actualContext=context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["subsystem": subsystem],
      timestamp: Date()
    )

    await logError(error, level: .debug, context: actualContext, options: options)
  }

  /**
   Logs an error with info level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func info(
    _ error: some Error,
    context: ErrorContext?=nil,
    options: ErrorLoggingOptions?=nil
  ) async {
    let actualContext=context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["subsystem": subsystem],
      timestamp: Date()
    )

    await logError(error, level: .info, context: actualContext, options: options)
  }

  /**
   Logs an error with warning level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func warning(
    _ error: some Error,
    context: ErrorContext?=nil,
    options: ErrorLoggingOptions?=nil
  ) async {
    let actualContext=context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["subsystem": subsystem],
      timestamp: Date()
    )

    await logError(error, level: .warning, context: actualContext, options: options)
  }

  /**
   Logs an error with error level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func error(
    _ error: some Error,
    context: ErrorContext?=nil,
    options: ErrorLoggingOptions?=nil
  ) async {
    let actualContext=context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["subsystem": subsystem],
      timestamp: Date()
    )

    await logError(error, level: .error, context: actualContext, options: options)
  }

  /**
   Logs an error with critical level.

   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func critical(
    _ error: some Error,
    context: ErrorContext?=nil,
    options: ErrorLoggingOptions?=nil
  ) async {
    let actualContext=context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: ["subsystem": subsystem],
      timestamp: Date()
    )

    await logError(error, level: .critical, context: actualContext, options: options)
  }

  // MARK: - Helper Methods

  /**
   Formats an error message with standardised structure.

   - Parameter error: The error to format
   - Returns: A formatted error message string
   */
  private func formatErrorMessage(_ error: some Error) -> String {
    // Extract domain name from error type (since we can't access domain directly)
    let domain=(error as? ErrorDomainProtocol).map { String(describing: type(of: $0)) } ?? "General"

    // Format with error type and description
    return "[\(domain)] \(String(describing: type(of: error))): \(error.localizedDescription)"
  }

  /**
   Creates structured metadata for an error log.

   - Parameters:
     - error: The error to create metadata for
     - context: Contextual information about the error
   - Returns: A privacy-aware metadata dictionary
   */
  private func createMetadata(
    for error: some Error,
    context: ErrorContext
  ) -> PrivacyMetadata {
    var metadata=PrivacyMetadata()

    // Add error type information
    metadata["errorType"]=PrivacyMetadataValue(value: String(describing: type(of: error)),
                                               privacy: .public)

    // Add error domain if available - using type name since domain is a static property
    if let domainType=error as? ErrorDomainProtocol {
      let domainName=String(describing: type(of: domainType))
      metadata["errorDomain"]=PrivacyMetadataValue(value: domainName, privacy: .public)
    }

    // Add contextual information from source
    let source=context.source
    metadata["sourceFile"]=PrivacyMetadataValue(value: source.file, privacy: .public)
    metadata["sourceFunction"]=PrivacyMetadataValue(value: source.function, privacy: .public)
    metadata["sourceLine"]=PrivacyMetadataValue(value: String(source.line), privacy: .public)

    // Add subsystem from context metadata if available
    if let subsystem=context.metadata["subsystem"] {
      metadata["sourceSubsystem"]=PrivacyMetadataValue(value: subsystem, privacy: .public)
    } else {
      metadata["sourceSubsystem"]=PrivacyMetadataValue(value: subsystem, privacy: .public)
    }

    // Add timestamp
    let dateFormatter=ISO8601DateFormatter()
    metadata["timestamp"]=PrivacyMetadataValue(
      value: dateFormatter.string(from: context.timestamp),
      privacy: .public
    )

    // Add any other metadata from context
    for (key, value) in context.metadata where key != "subsystem" {
      metadata[key]=PrivacyMetadataValue(value: value, privacy: .auto)
    }

    return metadata
  }

  /**
   Maps the ErrorLogLevel to a LogLevel.

   - Parameter level: The error log level
   - Returns: The corresponding LogLevel
   */
  private func mapErrorLogLevel(_ level: ErrorLogLevel) -> LogLevel {
    switch level {
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }
}
