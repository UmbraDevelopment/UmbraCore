import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLoggerService

 Service implementation for structured error logging.
 
 This service handles the contextual logging of errors across the codebase
 with appropriate privacy controls and structured formatting.
 
 This implementation adheres to the Alpha Dot Five architecture principles,
 particularly around privacy-by-design and actor-based concurrency.
 */
public actor ErrorLoggerService: ErrorLoggingProtocol {
  // MARK: - Properties

  /// The domain logger for error handling
  private let logger: DomainLogger

  /// Default privacy level for error logs
  private let defaultPrivacyLevel: PrivacyClassification = .private

  // MARK: - Initialisation

  /**
   Initialises a new error logger service.

   - Parameter logger: The domain logger to use for error reporting
   */
  public init(logger: DomainLogger) {
    self.logger = logger
  }

  // MARK: - ErrorLoggingProtocol Conformance
  
  /**
   Logs an error with debug level.
   
   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func debug<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    await logError(
      error,
      level: .debug,
      context: context ?? createDefaultContext(),
      options: options
    )
  }
  
  /**
   Logs an error with info level.
   
   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func info<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    await logError(
      error,
      level: .info,
      context: context ?? createDefaultContext(),
      options: options
    )
  }
  
  /**
   Logs an error with warning level.
   
   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func warning<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    await logError(
      error,
      level: .warning,
      context: context ?? createDefaultContext(),
      options: options
    )
  }
  
  /**
   Logs an error with error level.
   
   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func error<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    await logError(
      error,
      level: .error,
      context: context ?? createDefaultContext(),
      options: options
    )
  }
  
  /**
   Logs an error with critical level.
   
   - Parameters:
      - error: The error to log
      - context: Contextual information about the error
      - options: Configuration options for error logging
   */
  public func critical<E: Error>(
    _ error: E,
    context: ErrorContext?,
    options: ErrorLoggingOptions?
  ) async {
    await logError(
      error,
      level: .critical,
      context: context ?? createDefaultContext(),
      options: options
    )
  }

  /**
   Logs an error with the specified level and optional context.

   - Parameters:
     - error: The error to log
     - level: The severity level for this error
     - options: Configuration options for error logging
   */
  public func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions? = nil
  ) async {
    // Create default context with basic information
    let context = createDefaultContext()
    await logError(error, level: level, context: context, options: options)
  }

  /**
   Logs an error with the specified level and context.

   - Parameters:
     - error: The error to log
     - level: The severity level for this error
     - context: Contextual information for the error
     - options: Configuration options for error logging
   */
  public func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    context: ErrorContext,
    options: ErrorLoggingOptions? = nil
  ) async {
    // Convert to LoggableErrorDTO if not already
    let loggableError = convertToLoggableErrorDTO(error, context: context)
    
    // Determine privacy level from options
    _ = mapErrorPrivacyLevel(options?.privacyLevel ?? .standard)
    
    // Create log context with metadata
    let logContext = CoreLogContext(
      source: "\(context.source.file):\(context.source.line)",
      correlationID: loggableError.correlationID ?? context.metadata["correlationID"] ?? UUID().uuidString,
      metadata: loggableError.createMetadataCollection()
    )
    
    // Log using the appropriate level method
    switch level {
      case .debug:
        await logger.debug(loggableError.message, context: logContext)
      case .info:
        await logger.info(loggableError.message, context: logContext)
      case .warning:
        await logger.warning(loggableError.message, context: logContext)
      case .error:
        await logger.error(loggableError.message, context: logContext)
      case .critical:
        await logger.critical(loggableError.message, context: logContext)
    }
  }
  
  /**
   Maps ErrorPrivacyLevel to PrivacyClassification.

   - Parameter level: The error privacy level to map
   - Returns: The corresponding privacy classification
   */
  private func mapErrorPrivacyLevel(_ level: ErrorPrivacyLevel) -> PrivacyClassification {
    switch level {
      case .minimal:
        return .public
      case .standard:
        return .private
      case .enhanced, .maximum:
        return .sensitive
    }
  }
  
  /**
   Creates a default error context with file, function, and line information.
   
   - Returns: A new ErrorContext instance
   */
  private func createDefaultContext() -> ErrorContext {
    ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: [:],
      timestamp: Date()
    )
  }
  
  /**
   Converts an Error to a LoggableErrorDTO.
   
   This method ensures all errors are properly formatted for
   privacy-aware structured logging.
   
   - Parameters:
     - error: The error to convert
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func convertToLoggableErrorDTO<E: Error>(_ error: E, context: ErrorContext) -> LoggableErrorDTO {
    // If already a LoggableErrorDTO, return it
    if let loggableError = error as? LoggableErrorDTO {
      return loggableError
    }
    
    // For LoggableErrorProtocol, adapt to the new DTO format
    if let loggableError = error as? LoggableErrorProtocol {
      return createDTOFromLoggableProtocol(loggableError, context: context)
    }
    
    // Check if this is a standard Swift error that needs specialized handling
    // If you have specialized error types that aren't NSError or LoggableErrorProtocol,
    // you might need custom handling here
    
    // For all other errors, we can safely bridge to NSError
    // In Swift, all Error types can be bridged to NSError without conditional casting
    let nsError = error as NSError
    return createDTOFromNSError(nsError, originalError: error, context: context)
  }
  
  /**
   Creates a LoggableErrorDTO from a LoggableErrorProtocol.
   
   - Parameters:
     - loggableError: The loggable error protocol
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func createDTOFromLoggableProtocol(
    _ loggableError: LoggableErrorProtocol,
    context: ErrorContext
  ) -> LoggableErrorDTO {
    let message = loggableError.getLogMessage()
    let metadata = loggableError.createMetadataCollection()
    let source = loggableError.getSource()
    
    // Extract domain and code if available
    var domain = "Application"
    var code = 0
    var details = ""
    
    // Build details string from metadata entries
    for entry in metadata.entries {
      if entry.privacyLevel == .sensitive {
        details += "\(entry.key): \(entry.value)\n"
      }
      
      // Look for domain and code in metadata
      if entry.key == "domain" {
        domain = entry.value
      }
      
      if entry.key == "code", let codeValue = Int(entry.value) {
        code = codeValue
      }
    }
    
    return LoggableErrorDTO(
      error: loggableError,
      domain: domain,
      code: code,
      message: message,
      details: details,
      source: source,
      correlationID: extractTraceID(from: context)
    )
  }
  
  /**
   Creates a LoggableErrorDTO from an NSError.
   
   - Parameters:
     - nsError: The NSError to convert
     - originalError: The original Error instance
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func createDTOFromNSError<E: Error>(
    _ nsError: NSError,
    originalError: E,
    context: ErrorContext
  ) -> LoggableErrorDTO {
    // Extract user info for details while filtering sensitive keys
    let sensitiveKeys = ["NSUnderlyingError", "NSSensitiveKeys", "NSCredential"]
    var details = ""
    
    for (key, value) in nsError.userInfo where !sensitiveKeys.contains(key) {
      details += "\(key): \(value)\n"
    }
    
    return LoggableErrorDTO(
      error: originalError,
      domain: nsError.domain,
      code: nsError.code,
      message: nsError.localizedDescription,
      details: details,
      source: "\(context.source.file):\(context.source.line)",
      correlationID: extractTraceID(from: context)
    )
  }
  
  /**
   Creates a standard LoggableErrorDTO from a generic Error.
   
   - Parameters:
     - error: The Error to convert
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func createStandardDTO<E: Error>(
    _ error: E,
    context: ErrorContext
  ) -> LoggableErrorDTO {
    return LoggableErrorDTO(
      error: error,
      domain: "App.\(String(describing: type(of: error)))",
      code: 0,
      message: String(describing: error),
      details: String(describing: error),
      source: "\(context.source.file):\(context.source.function):\(context.source.line)",
      correlationID: extractTraceID(from: context)
    )
  }
  
  /**
   Extracts a trace ID from the error context.
   
   - Parameter context: The error context
   - Returns: A trace ID string or nil if not available
   */
  private func extractTraceID(from context: ErrorContext) -> String? {
    return context.metadata["correlationID"] ?? context.metadata["traceID"] ?? UUID().uuidString
  }
}
