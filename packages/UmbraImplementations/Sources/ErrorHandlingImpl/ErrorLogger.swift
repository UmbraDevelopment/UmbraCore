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
 
 ## Privacy Control
 
 This implementation follows the Alpha Dot Five architecture's privacy-by-design
 principles, ensuring sensitive error information is properly classified and
 protected in logs.
 */
public actor ErrorLogger: ErrorLoggingProtocol {
  /// The underlying logger implementation
  private let logger: DomainLogger

  /// The subsystem for error logging
  private let subsystem = "ErrorHandling"

  /**
   Initialises a new error logger with the provided logging implementation.

   - Parameter logger: The underlying logger to use for output
   */
  public init(logger: DomainLogger) {
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
    options: ErrorLoggingOptions?
  ) async {
    let logContext = createLogContext(for: error, context: context)
    let logLevel = mapErrorLogLevel(level)
    
    if let loggableError = convertToLoggableError(error, context: context) {
      // If we have a LoggableErrorDTO, use the domain logger's error method
      await logger.error(
        loggableError,
        context: logContext,
        privacyLevel: determinePrivacyLevel(for: error, options: options)
      )
    } else {
      // For regular errors, use the standard logging with context
      let message = formatErrorMessage(error)
      
      // Log with the appropriate level using context-based methods
      switch logLevel {
        case .debug:
          await logger.debug(message, context: logContext)
        case .info:
          await logger.info(message, context: logContext)
        case .warning:
          await logger.warning(message, context: logContext)
        case .error, .critical:
          await logger.error(message, context: logContext)
      }
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
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    let actualContext = context ?? ErrorContext(
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
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    let actualContext = context ?? ErrorContext(
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
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    let actualContext = context ?? ErrorContext(
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
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    let actualContext = context ?? ErrorContext(
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
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    let actualContext = context ?? ErrorContext(
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

  // MARK: - Private Helper Methods

  /**
   Creates a structured LogContextDTO from an error and context.
   
   - Parameters:
     - error: The error to create context for
     - context: The error context
   - Returns: A log context DTO suitable for privacy-aware logging
   */
  private func createLogContext(for error: Error, context: ErrorContext) -> LogContextDTO {
    let source = "\(context.source.file):\(context.source.line)"
    let metadataDict = createMetadata(for: error, context: context)
    
    let errorDomain = extractErrorDomain(from: error)
    let correlationID = context.correlationID
    
    // Create a CoreLogContext to ensure consistent logging format
    return CoreLogContext(
      source: source,
      correlationID: correlationID,
      metadata: createMetadataCollection(from: metadataDict)
    )
  }
  
  /**
   Converts an Error to a LoggableErrorDTO if possible.
   
   - Parameters:
     - error: The error to convert
     - context: The error context
   - Returns: A LoggableErrorDTO if conversion is possible, nil otherwise
   */
  private func convertToLoggableError(_ error: Error, context: ErrorContext) -> LoggableErrorDTO? {
    // If it's already a LoggableErrorDTO, return it
    if let loggableError = error as? LoggableErrorDTO {
      return loggableError
    }
    
    // For NSError, create a LoggableErrorDTO
    if let nsError = error as NSError {
      return LoggableErrorDTO(
        error: error,
        domain: nsError.domain,
        code: nsError.code,
        message: nsError.localizedDescription,
        details: nsError.userInfo.description,
        source: context.source.function
      )
    }
    
    // For other errors, create a generic LoggableErrorDTO
    return LoggableErrorDTO(
      error: error,
      message: error.localizedDescription,
      details: String(describing: error),
      source: context.source.function
    )
  }
  
  /**
   Determines the appropriate privacy level for an error.
   
   - Parameters:
     - error: The error to determine privacy level for
     - options: Error logging options
   - Returns: The appropriate privacy classification
   */
  private func determinePrivacyLevel(for error: Error, options: ErrorLoggingOptions?) -> PrivacyClassification {
    // If options specify a privacy level, use it
    if let options = options, let privacyLevel = options.privacyLevel {
      return privacyLevel
    }
    
    // Default privacy levels based on error type
    if error is NSError {
      // NSError might contain sensitive user info
      return .private
    }
    
    // If the error conforms to CustomStringConvertible and has a description
    // containing sensitive terms, classify as sensitive
    let description = String(describing: error).lowercased()
    let sensitiveTerms = [
      "password", "credential", "token", "key", "secret", "private", "auth", "cipher"
    ]
    
    if sensitiveTerms.contains(where: { description.contains($0) }) {
      return .sensitive
    }
    
    // Default to private for most errors
    return .private
  }

  /**
   Creates a metadata dictionary for an error.

   - Parameters:
      - error: The error to extract metadata from
      - context: The error context
   - Returns: Dictionary of error metadata
   */
  private func createMetadata(for error: Error, context: ErrorContext) -> [String: String] {
    var metadata = [String: String]()
    
    // Add error type
    metadata["errorType"] = String(describing: type(of: error))
    
    // Add source information
    metadata["file"] = context.source.file
    metadata["function"] = context.source.function
    metadata["line"] = String(context.source.line)
    
    // Add domain information
    metadata["domain"] = extractErrorDomain(from: error)
    
    // Add timestamp
    let formatter = ISO8601DateFormatter()
    metadata["timestamp"] = formatter.string(from: context.timestamp)
    
    // Add correlation ID if available
    if let correlationID = context.correlationID {
      metadata["correlationID"] = correlationID
    }
    
    // Add context metadata
    for (key, value) in context.metadata {
      metadata[key] = String(describing: value)
    }
    
    // Add NSError specific information
    if let nsError = error as NSError {
      metadata["errorCode"] = String(nsError.code)
      metadata["errorDomain"] = nsError.domain
      
      // Add user info, but filter out sensitive keys
      let sensitiveKeys = ["NSUnderlyingError", "NSSensitiveKeys"]
      for (key, value) in nsError.userInfo where !sensitiveKeys.contains(key) {
        metadata["userInfo.\(key)"] = String(describing: value)
      }
    }
    
    return metadata
  }
  
  /**
   Creates a metadata collection with appropriate privacy classifications.
   
   - Parameter dict: Dictionary of metadata entries
   - Returns: A LogMetadataDTOCollection with privacy classifications
   */
  private func createMetadataCollection(from dict: [String: String]) -> LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    
    // Public metadata
    let publicKeys = ["errorType", "domain", "timestamp", "subsystem"]
    for key in publicKeys where dict[key] != nil {
      collection = collection.withPublic(key: key, value: dict[key]!)
    }
    
    // Private metadata
    let privateKeys = ["file", "function", "line", "correlationID", "errorCode", "errorDomain"]
    for key in privateKeys where dict[key] != nil {
      collection = collection.withPrivate(key: key, value: dict[key]!)
    }
    
    // Sensitive metadata - anything else might contain sensitive information
    let processedKeys = publicKeys + privateKeys
    for (key, value) in dict where !processedKeys.contains(key) {
      // User info might contain sensitive data
      if key.starts(with: "userInfo.") {
        collection = collection.withSensitive(key: key, value: value)
      } else {
        collection = collection.withPrivate(key: key, value: value)
      }
    }
    
    return collection
  }

  /**
   Maps ErrorLogLevel to LogLevel.

   - Parameter errorLevel: The error log level
   - Returns: The corresponding log level
   */
  private func mapErrorLogLevel(_ errorLevel: ErrorLogLevel) -> LogLevel {
    switch errorLevel {
      case .trace:
        return .debug
      case .debug:
        return .debug
      case .info:
        return .info
      case .warning:
        return .warning
      case .error:
        return .error
      case .critical:
        return .error
    }
  }

  /**
   Formats an error into a user-friendly message.

   - Parameter error: The error to format
   - Returns: A formatted error message
   */
  private func formatErrorMessage(_ error: Error) -> String {
    if let loggableError = error as? LoggableErrorDTO {
      return "[\(loggableError.domain)] \(loggableError.message)"
    } else if let nsError = error as NSError {
      return "[\(nsError.domain):\(nsError.code)] \(nsError.localizedDescription)"
    } else {
      return "[\(type(of: error))] \(error.localizedDescription)"
    }
  }
  
  /**
   Extracts the error domain from an error.
   
   - Parameter error: The error to extract domain from
   - Returns: The error domain
   */
  private func extractErrorDomain(from error: Error) -> String {
    if let domainError = error as? ErrorDomainProtocol {
      return domainError.domain
    } else if let nsError = error as NSError {
      return nsError.domain
    } else {
      return "Generic"
    }
  }
}
