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
  private let subsystem = "ErrorHandling"

  /**
   Initialises a new error logger with the provided logging implementation.

   - Parameter logger: The underlying logger to use for output
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger = logger
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
    let context = ErrorContext(
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
    let metadataDict = createMetadata(for: error, context: context)
    let message = formatErrorMessage(error)
    let source = "\(context.source.file):\(context.source.line)"
    
    // Create a log context with the error metadata
    let logContext = BaseLogContextDTO(
      domainName: subsystem,
      source: source,
      metadata: createMetadataCollection(from: metadataDict),
      correlationID: nil
    )

    // Map ErrorLogLevel to LogLevel
    let logLevel = mapErrorLogLevel(level)

    // Log with the appropriate level using context-based methods
    switch logLevel {
      case .trace:
        await logger.trace(message, context: logContext)
      case .debug:
        await logger.debug(message, context: logContext)
      case .info:
        await logger.info(message, context: logContext)
      case .warning:
        await logger.warning(message, context: logContext)
      case .error:
        await logger.error(message, context: logContext)
      case .critical:
        await logger.critical(message, context: logContext)
    }
  }
  
  /**
   Creates a LogMetadataDTOCollection from a dictionary.
   
   - Parameter dict: The dictionary of metadata
   - Returns: A LogMetadataDTOCollection containing the metadata
   */
  private func createMetadataCollection(from dict: [String: String]) -> LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    
    for (key, value) in dict {
      collection = collection.withPrivate(key: key, value: value)
    }
    
    return collection
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
   Formats an error into a standard message format.

   - Parameter error: The error to format
   - Returns: A formatted error message string
   */
  private func formatErrorMessage(_ error: some Error) -> String {
    if let loggableError = error as? LoggableErrorProtocol {
      return "[\(type(of: loggableError))] \(loggableError.getLogMessage())"
    } else {
      return "[\(type(of: error))] \(error.localizedDescription)"
    }
  }

  /**
   Creates metadata for the error including type and contextual information.

   - Parameters:
      - error: The error to create metadata for
      - context: The error context
   - Returns: A dictionary of metadata for logging
   */
  private func createMetadata(for error: some Error, context: ErrorContext) -> [String: String] {
    var metadata = [String: String]()

    // Add standard error information
    metadata["errorType"] = String(describing: type(of: error))
    
    // Add source information
    metadata["file"] = context.source.file
    metadata["function"] = context.source.function
    metadata["line"] = String(context.source.line)
    
    // Add timestamp
    let dateFormatter = ISO8601DateFormatter()
    metadata["timestamp"] = dateFormatter.string(from: context.timestamp)
    
    // Add any custom metadata from the context
    for (key, value) in context.metadata {
      metadata[key] = String(describing: value)
    }
    
    // Add specific error information for loggable errors
    if let loggableError = error as? LoggableErrorProtocol {
      // Add the log message directly
      metadata["errorMessage"] = loggableError.getLogMessage()
    }
    
    return metadata
  }

  /**
   Maps an ErrorLogLevel to a standard LogLevel.

   - Parameter errorLevel: The error log level
   - Returns: The equivalent standard LogLevel
   */
  private func mapErrorLogLevel(_ errorLevel: ErrorLogLevel) -> LogLevel {
    switch errorLevel {
      case .debug:
        return .debug
      case .info:
        return .info
      case .warning:
        return .warning
      case .error:
        return .error
      case .critical:
        return .critical
    }
  }
}
