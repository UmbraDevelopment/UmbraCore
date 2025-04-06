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
 */
public actor ErrorLoggerService: ErrorLoggingProtocol {
  // MARK: - Properties

  /// The underlying logger implementation
  private let logger: PrivacyAwareLoggingProtocol

  /// Domain/subsystem identifier for logs
  private let subsystem = "ErrorHandlingService"

  // MARK: - Initialisation

  /**
   Initialises a new error logger service.

   - Parameter logger: The underlying logger to use for output
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger = logger
  }

  // MARK: - ErrorLoggingProtocol Conformance

  /**
   Logs an error with the specified level and optional context.

   - Parameters:
     - error: The error to log
     - level: The severity level for this error
     - options: Configuration options for error logging
   */
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions? = nil
  ) async {
    // Create default context with basic information
    let context = ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: [:],
      timestamp: Date()
    )

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
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    context: ErrorContext,
    options: ErrorLoggingOptions? = nil
  ) async {
    // Extract privacy level from options
    let privacyLevel = options?.privacyLevel ?? ErrorPrivacyLevel.standard

    // Create metadata for the error
    let errorMetadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: context.source.file,
      function: context.source.function,
      line: context.source.line
    )
    
    // Convert to LogMetadataDTOCollection
    let logMetadataCollection = convertToMetadataCollection(errorMetadata)

    let logMessage = formatErrorMessage(error, privacyLevel: privacyLevel)
    
    // Create log context
    let logContext = BaseLogContextDTO(
      domainName: subsystem,
      source: context.source.file,
      metadata: logMetadataCollection,
      correlationID: nil
    )

    // Use the appropriate log level method with context
    switch level {
      case .debug:
        await logger.debug(logMessage, context: logContext)
      case .info:
        await logger.info(logMessage, context: logContext)
      case .warning:
        await logger.warning(logMessage, context: logContext)
      case .error:
        await logger.error(logMessage, context: logContext)
      case .critical:
        await logger.critical(logMessage, context: logContext)
    }
  }
  
  /**
   Converts PrivacyMetadata to LogMetadataDTOCollection.
   
   - Parameter metadata: The privacy metadata to convert
   - Returns: A corresponding LogMetadataDTOCollection
   */
  private func convertToMetadataCollection(_ metadata: PrivacyMetadata) -> LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    
    // Use subscript to access PrivacyMetadata elements
    for key in metadata.keys {
      guard let value = metadata[key] else { continue }
      
      switch value.privacy {
        case .public:
          collection = collection.withPublic(key: key, value: value.stringValue)
        case .private:
          collection = collection.withPrivate(key: key, value: value.stringValue)
        case .sensitive:
          collection = collection.withPrivate(key: key, value: value.stringValue)
        case .auto:
          collection = collection.withPrivate(key: key, value: value.stringValue)
        case .hash:
          collection = collection.withPrivate(key: key, value: value.stringValue)
      }
    }
    
    return collection
  }

  /**
   Formats an error into a loggable message.

   - Parameters:
      - error: The error to format
      - privacyLevel: The privacy level to apply to sensitive parts
   - Returns: A formatted error message string
   */
  private func formatErrorMessage(_ error: some Error, privacyLevel: ErrorPrivacyLevel) -> String {
    let errorType = String(describing: type(of: error))
    let description: String

    switch privacyLevel {
      case .minimal:
        // Just log the error type for minimal privacy exposure
        description = "Error occurred"
      case .standard:
        // Default behaviour - use localizedDescription
        description = error.localizedDescription
      case .enhanced, .maximum:
        // More detailed - include debug description where possible
        let debugError = error as CustomDebugStringConvertible
        description = debugError.debugDescription
    }

    return "[\(errorType)] \(description)"
  }

  // MARK: - Helper Methods for Error Contexts

  /**
   Creates metadata for an error from a LoggableError.

   - Parameters:
     - error: The loggable error
     - privacyLevel: The privacy level to apply to sensitive fields
   - Returns: Metadata for the error
   */
  private func createMetadataFromLoggable(
    _ error: LoggableErrorProtocol,
    privacyLevel: ErrorPrivacyLevel
  ) -> PrivacyMetadata {
    var metadata = PrivacyMetadata()

    // Add basic error properties
    metadata["errorType"] = PrivacyMetadataValue(
      value: String(describing: type(of: error)),
      privacy: .public
    )

    metadata["errorMessage"] = PrivacyMetadataValue(
      value: error.getLogMessage(),
      privacy: .auto
    )

    return metadata
  }

  /**
   Maps an ErrorPrivacyLevel to a LogPrivacyLevel value.

   - Parameter level: The privacy level
   - Returns: The corresponding LogPrivacyLevel
   */
  private func mapPrivacyLevel(_ level: ErrorPrivacyLevel) -> LogPrivacyLevel {
    switch level {
      case .minimal:
        return .private
      case .standard:
        return .auto
      case .enhanced, .maximum:
        return .public
    }
  }

  /**
   Creates metadata for any error type.

   - Parameters:
     - error: The error
     - privacyLevel: The privacy level to apply
     - file: Source file of the error
     - function: Source function of the error
     - line: Source line of the error
   - Returns: Metadata for the error
   */
  private func createErrorMetadata(
    _ error: some Error,
    privacyLevel: ErrorPrivacyLevel,
    file: String,
    function: String,
    line: Int
  ) -> PrivacyMetadata {
    // If it's a LoggableError, use its specialized metadata
    if let loggableError = error as? LoggableErrorProtocol {
      var metadata = createMetadataFromLoggable(loggableError, privacyLevel: privacyLevel)
      
      // Add source context
      let sourceMetadata = createSourceMetadata(file: file, function: function, line: line)
      for key in sourceMetadata.keys {
        if let value = sourceMetadata[key] {
          metadata[key] = value
        }
      }
      
      return metadata
    }
    
    // Otherwise create generic metadata
    var metadata = createBasicErrorMetadata(error, privacyLevel: privacyLevel)
    
    // Add source context
    let sourceMetadata = createSourceMetadata(file: file, function: function, line: line)
    for key in sourceMetadata.keys {
      if let value = sourceMetadata[key] {
        metadata[key] = value
      }
    }
    
    return metadata
  }
  
  /**
   Creates metadata about the error source location.
   
   - Parameters:
     - file: Source file
     - function: Source function
     - line: Source line
   - Returns: Source metadata
   */
  private func createSourceMetadata(
    file: String,
    function: String,
    line: Int
  ) -> PrivacyMetadata {
    var metadata = PrivacyMetadata()

    // Add source information with appropriate privacy levels
    metadata["file"] = PrivacyMetadataValue(value: URL(fileURLWithPath: file).lastPathComponent, privacy: .public)
    metadata["function"] = PrivacyMetadataValue(value: function, privacy: .public)
    metadata["line"] = PrivacyMetadataValue(value: String(line), privacy: .public)
    
    return metadata
  }
  
  /**
   Creates basic metadata for a standard error.
   
   - Parameters:
     - error: The error
     - privacyLevel: Privacy level to apply
   - Returns: Basic error metadata
   */
  private func createBasicErrorMetadata(
    _ error: some Error,
    privacyLevel: ErrorPrivacyLevel
  ) -> PrivacyMetadata {
    var metadata = PrivacyMetadata()
    
    // Add basic error information
    metadata["errorType"] = PrivacyMetadataValue(
      value: String(describing: type(of: error)),
      privacy: .public
    )
    
    metadata["errorDescription"] = PrivacyMetadataValue(
      value: error.localizedDescription,
      privacy: .auto
    )
    
    // Add domain if available
    if let domainError = error as? ErrorDomainProtocol {
      metadata["errorDomain"] = PrivacyMetadataValue(
        value: String(describing: type(of: domainError)),
        privacy: .public
      )
    }
    
    // Add additional info for NSError
    let nsError = error as NSError
    metadata["errorCode"] = PrivacyMetadataValue(
      value: String(nsError.code),
      privacy: .public
    )
    
    metadata["errorDomain"] = PrivacyMetadataValue(
      value: nsError.domain,
      privacy: .public
    )
    
    return metadata
  }
  
  /**
   Logs a diagnostic message with context.
   
   - Parameters:
     - message: The message to log
     - level: The log level
     - context: Optional context information
   */
  public func logDiagnostic(
    _ message: String,
    level: ErrorLogLevel,
    context: ErrorContext? = nil
  ) async {
    let actualContext = context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      ),
      metadata: [:],
      timestamp: Date()
    )
    
    // Create a metadata collection
    let contextMetadata = LogMetadataDTOCollection()
      .withPublic(key: "subsystem", value: subsystem)
      .withPublic(key: "file", value: actualContext.source.file)
      .withPublic(key: "function", value: actualContext.source.function)
      .withPublic(key: "line", value: String(actualContext.source.line))
    
    // Create the log context
    let logContext = BaseLogContextDTO(
      domainName: subsystem,
      source: actualContext.source.file,
      metadata: contextMetadata,
      correlationID: nil
    )

    // Log with the appropriate level
    switch level {
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
  
  // MARK: - Required protocol methods
  
  /// Logs an error with the debug level
  public func debug<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    await logError(error, level: .debug, context: context ?? ErrorContext(
      source: ErrorSource(file: #file, function: #function, line: #line),
      metadata: [:],
      timestamp: Date()
    ), options: options)
  }
  
  /// Logs an error with the info level
  public func info<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    await logError(error, level: .info, context: context ?? ErrorContext(
      source: ErrorSource(file: #file, function: #function, line: #line),
      metadata: [:],
      timestamp: Date()
    ), options: options)
  }
  
  /// Logs an error with the warning level
  public func warning<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    await logError(error, level: .warning, context: context ?? ErrorContext(
      source: ErrorSource(file: #file, function: #function, line: #line),
      metadata: [:],
      timestamp: Date()
    ), options: options)
  }
  
  /// Logs an error with the error level
  public func error<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    await logError(error, level: .error, context: context ?? ErrorContext(
      source: ErrorSource(file: #file, function: #function, line: #line),
      metadata: [:],
      timestamp: Date()
    ), options: options)
  }
  
  /// Logs an error with the critical level
  public func critical<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    await logError(error, level: .critical, context: context ?? ErrorContext(
      source: ErrorSource(file: #file, function: #function, line: #line),
      metadata: [:],
      timestamp: Date()
    ), options: options)
  }
}
