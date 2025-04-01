import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Error Logger Service
 
 A thread-safe error logging service implementation that provides structured
 error logging capabilities following the Alpha Dot Five architecture principles.
 
 This implementation supports:
 - Privacy-aware error logging with proper metadata handling
 - Structured, searchable error information
 - Context-enriched log entries for improved debugging
 */
public actor ErrorLoggerService: ErrorLoggingProtocol {
  // MARK: - Properties

  /// The underlying logger implementation
  private let logger: PrivacyAwareLoggingProtocol
  
  /// The subsystem identifier for error logging
  private let subsystem = "ErrorHandling"
  
  // MARK: - Initialisation
  
  /**
   Initialises a new error logger service with the specified logger.
   
   - Parameter logger: The underlying logger to use for logging
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger = logger
  }
  
  /**
   Maps ErrorPrivacyLevel to LogPrivacy for proper logging integration.
   
   - Parameter level: The error privacy level to map
   - Returns: The corresponding LogPrivacy level
   */
  private func mapPrivacyLevel(_ level: ErrorPrivacyLevel) -> LogPrivacyLevel {
    switch level {
    case .minimal:
      return .public
    case .standard:
      return .private
    case .enhanced, .maximum:
      return .sensitive
    }
  }
  
  // MARK: - Error Logging
  
  /**
   Logs an error with the appropriate level.
   
   - Parameters:
      - error: The error to log
      - level: The severity level for logging this error
      - options: Configuration options for error logging
   */
  public func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions?
  ) async {
    // Create a default context with source information
    let context = ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      )
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
  public func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    context: ErrorContext,
    options: ErrorLoggingOptions?
  ) async {
    // Use standard privacy level by default
    let privacyLevel = options?.privacyLevel ?? ErrorPrivacyLevel.standard
    
    let metadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: context.source.file,
      function: context.source.function,
      line: context.source.line
    )
    
    let logMessage = formatErrorMessage(error, privacyLevel: privacyLevel)
    
    // Use the appropriate log level method
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: metadata, source: subsystem)
    case .info:
      await logger.info(logMessage, metadata: metadata, source: subsystem)
    case .warning:
      await logger.warning(logMessage, metadata: metadata, source: subsystem)
    case .error:
      await logger.error(logMessage, metadata: metadata, source: subsystem)
    case .critical:
      await logger.critical(logMessage, metadata: metadata, source: subsystem)
    }
  }
  
  /**
   Formats an error into a loggable message.
   
   - Parameters:
      - error: The error to format
      - privacyLevel: The privacy level to apply to sensitive parts
   
   - Returns: A formatted error message
   */
  private func formatErrorMessage<E: Error>(_ error: E, privacyLevel: ErrorPrivacyLevel) -> String {
    // Format differently based on error type
    if let localizedError = error as? LocalizedError {
      return formatLocalizedError(localizedError, privacyLevel: privacyLevel)
    } else {
      return formatStandardError(error, privacyLevel: privacyLevel)
    }
  }
  
  /**
   Creates metadata for an error log entry.
   
   - Parameters:
      - error: The error to create metadata for
      - privacyLevel: The privacy level to apply
      - file: The file where the error occurred
      - function: The function where the error occurred
      - line: The line where the error occurred
   
   - Returns: Metadata for the error log
   */
  private func createErrorMetadata<E: Error>(
    _ error: E,
    privacyLevel: ErrorPrivacyLevel,
    file: String,
    function: String,
    line: Int
  ) -> PrivacyMetadata {
    var metadata = PrivacyMetadata()
    
    // Map privacy level to LogPrivacy
    _ = mapPrivacyLevel(privacyLevel)
    
    // Add source information with appropriate privacy
    metadata["file"] = PrivacyMetadataValue(value: URL(fileURLWithPath: file).lastPathComponent, privacy: .public)
    metadata["function"] = PrivacyMetadataValue(value: function, privacy: .public)
    metadata["line"] = PrivacyMetadataValue(value: line, privacy: .public)
    
    // Add error type information
    metadata["errorType"] = PrivacyMetadataValue(value: String(describing: type(of: error)), privacy: .public)
    
    // Add domain for domain errors
    if let domainError = error as? ErrorDomainProtocol {
      metadata["errorDomain"] = PrivacyMetadataValue(value: String(describing: domainError), privacy: .public)
    }
    
    // Add localized information for localized errors
    if let localizedError = error as? LocalizedError {
      if let failureReason = localizedError.failureReason {
        metadata["failureReason"] = PrivacyMetadataValue(
          value: failureReason,
          privacy: privacyLevel == .minimal ? .public : .private
        )
      }
      
      if let recoverySuggestion = localizedError.recoverySuggestion {
        metadata["recoverySuggestion"] = PrivacyMetadataValue(value: recoverySuggestion, privacy: .public)
      }
      
      if let helpAnchor = localizedError.helpAnchor {
        metadata["helpAnchor"] = PrivacyMetadataValue(value: helpAnchor, privacy: .public)
      }
    }
    
    return metadata
  }
  
  /**
   Formats a localized error for logging.
   
   - Parameters:
      - error: The localized error to format
      - privacyLevel: The privacy level to apply
   
   - Returns: A formatted error message
   */
  private func formatLocalizedError(_ error: LocalizedError, privacyLevel: ErrorPrivacyLevel) -> String {
    var messageParts: [String] = []
    
    // Include description with appropriate privacy
    messageParts.append("Error: \(error.localizedDescription)")
    
    // Include reason if available
    if let reason = error.failureReason {
      let reasonPrefix = "Reason: "
      if privacyLevel == .minimal {
        messageParts.append("\(reasonPrefix)\(reason)")
      } else {
        messageParts.append("\(reasonPrefix)[PRIVATE]")
      }
    }
    
    // Include recovery suggestion if available
    if let recovery = error.recoverySuggestion {
      messageParts.append("Recovery: \(recovery)")
    }
    
    return messageParts.joined(separator: " | ")
  }
  
  /**
   Formats a standard error for logging.
   
   - Parameters:
      - error: The error to format
      - privacyLevel: The privacy level to apply
   
   - Returns: A formatted error message
   */
  private func formatStandardError<E: Error>(_ error: E, privacyLevel: ErrorPrivacyLevel) -> String {
    // Simple format for standard errors
    let errorDescription = error.localizedDescription
    
    if privacyLevel == .minimal {
      return "Error: \(errorDescription) (\(type(of: error)))"
    } else {
      // For higher privacy levels, only include the type
      return "Error of type \(type(of: error))"
    }
  }
  
  // MARK: - Convenience Logging Methods
  
  /**
   Logs a debug message about an error.
   
   - Parameters:
      - message: The debug message
      - error: Optional error related to the message
      - metadata: Additional contextual information
   */
  public func logDebug(
    _ message: String,
    error: Error? = nil,
    metadata: [String: String]? = nil
  ) async {
    let contextMetadata = createContextMetadata(
      file: #file,
      function: #function,
      line: #line,
      additionalMetadata: metadata
    )
    
    await logger.debug(message, metadata: contextMetadata, source: subsystem)
  }
  
  // MARK: - Helper Methods
  
  /**
   Creates metadata with context information.
   
   - Parameters:
      - file: The file where the log was created
      - function: The function where the log was created
      - line: The line where the log was created
      - additionalMetadata: Additional metadata to include
   
   - Returns: Metadata with context information
   */
  private func createContextMetadata(
    file: String,
    function: String,
    line: Int,
    additionalMetadata: [String: String]?
  ) -> PrivacyMetadata {
    var metadata = PrivacyMetadata()
    
    // Add source information
    metadata["file"] = PrivacyMetadataValue(value: URL(fileURLWithPath: file).lastPathComponent)
    metadata["function"] = PrivacyMetadataValue(value: function)
    metadata["line"] = PrivacyMetadataValue(value: line)
    
    // Add additional metadata if provided
    if let additionalMetadata = additionalMetadata {
      for (key, value) in additionalMetadata {
        metadata[key] = PrivacyMetadataValue(value: value, privacy: .private)
      }
    }
    
    return metadata
  }
  
  // MARK: - Protocol Conformance Methods
  
  /**
   Logs an error with the debug level.
   
   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - options: Configuration options for error logging
   */
  public func debug<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    let effectiveContext = context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      )
    )
    
    await logError(error, level: .debug, context: effectiveContext, options: options)
  }
  
  /**
   Logs an error with the info level.
   
   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - options: Configuration options for error logging
   */
  public func info<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    let effectiveContext = context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      )
    )
    
    await logError(error, level: .info, context: effectiveContext, options: options)
  }
  
  /**
   Logs an error with the warning level.
   
   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - options: Configuration options for error logging
   */
  public func warning<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    let effectiveContext = context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      )
    )
    
    await logError(error, level: .warning, context: effectiveContext, options: options)
  }
  
  /**
   Logs an error with the error level.
   
   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - options: Configuration options for error logging
   */
  public func error<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    let effectiveContext = context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      )
    )
    
    await logError(error, level: .error, context: effectiveContext, options: options)
  }
  
  /**
   Logs an error with the critical level.
   
   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - options: Configuration options for error logging
   */
  public func critical<E: Error>(
    _ error: E,
    context: ErrorContext? = nil,
    options: ErrorLoggingOptions? = nil
  ) async {
    let effectiveContext = context ?? ErrorContext(
      source: ErrorSource(
        file: #file,
        function: #function,
        line: #line
      )
    )
    
    await logError(error, level: .critical, context: effectiveContext, options: options)
  }
}
