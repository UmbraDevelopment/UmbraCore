import Foundation
import LoggingInterfaces
import LoggingTypes
import ErrorHandlingInterfaces
import ErrorCoreTypes

/**
 # ErrorLogger

 A specialised logger for error handling that provides domain-specific
 logging methods with appropriate privacy controls and contextual
 information.

 This component enhances error logs with consistent formatting, privacy
 annotations, and structured metadata to improve debugging and analysis.
 */
public final class ErrorLogger: ErrorLoggingProtocol, @unchecked Sendable {
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
  public func logError<E: Error>(
    _ error: E,
    level: ErrorLogLevel,
    options: ErrorLoggingOptions?
  ) async {
    // Create a default context with source information
    let sourceInfo = ErrorSource(subsystem: subsystem, file: #file, function: #function, line: #line)
    let context = ErrorContext(source: sourceInfo)
    
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
    let privacyLevel = options?.privacyLevel ?? .private
    
    let metadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: context.file,
      function: context.function,
      line: context.line
    )
    
    let logMessage = formatErrorMessage(error, privacyLevel: privacyLevel)
    
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: metadata, privacy: LogPrivacy.private, source: context.source ?? subsystem)
    case .info:
      await logger.info(logMessage, metadata: metadata, privacy: LogPrivacy.private, source: context.source ?? subsystem)
    case .warning:
      await logger.warning(logMessage, metadata: metadata, privacy: LogPrivacy.private, source: context.source ?? subsystem)
    case .error:
      await logger.error(logMessage, metadata: metadata, privacy: LogPrivacy.private, source: context.source ?? subsystem)
    case .critical:
      await logger.critical(logMessage, metadata: metadata, privacy: LogPrivacy.private, source: context.source ?? subsystem)
    }
  }

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
    // Create ErrorSource if context is nil
    let sourceInfo = ErrorSource(subsystem: subsystem, file: #file, function: #function, line: #line)
    // Use provided context or create a default one
    let effectiveContext = context ?? ErrorContext(source: sourceInfo)
    
    await logError(error, level: .debug, context: effectiveContext, options: options)
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
    // Create ErrorSource if context is nil
    let sourceInfo = ErrorSource(subsystem: subsystem, file: #file, function: #function, line: #line)
    // Use provided context or create a default one
    let effectiveContext = context ?? ErrorContext(source: sourceInfo)
    
    await logError(error, level: .info, context: effectiveContext, options: options)
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
    // Create ErrorSource if context is nil
    let sourceInfo = ErrorSource(subsystem: subsystem, file: #file, function: #function, line: #line)
    // Use provided context or create a default one
    let effectiveContext = context ?? ErrorContext(source: sourceInfo)
    
    await logError(error, level: .warning, context: effectiveContext, options: options)
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
    // Create ErrorSource if context is nil
    let sourceInfo = ErrorSource(subsystem: subsystem, file: #file, function: #function, line: #line)
    // Use provided context or create a default one
    let effectiveContext = context ?? ErrorContext(source: sourceInfo)
    
    await logError(error, level: .error, context: effectiveContext, options: options)
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
    // Create ErrorSource if context is nil
    let sourceInfo = ErrorSource(subsystem: subsystem, file: #file, function: #function, line: #line)
    // Use provided context or create a default one
    let effectiveContext = context ?? ErrorContext(source: sourceInfo)
    
    await logError(error, level: .critical, context: effectiveContext, options: options)
  }
  
  /**
   Logs a debug message with appropriate metadata.
   
   - Parameters:
     - message: The message to log
     - metadata: Additional contextual information
     - file: The file where the log was generated
     - function: The function where the log was generated
     - line: The line where the log was generated
   */
  public func debug(
    _ message: String,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) async {
    let contextMetadata = createContextMetadata(
      error: nil,
      privacyLevel: .private,
      file: file,
      function: function,
      line: line,
      additionalMetadata: metadata
    )
    
    // Convert DTO collection to PrivacyMetadata
    let privacyMetadata = PrivacyMetadata(dtoCollection: contextMetadata)
    
    await logger.debug(message, metadata: privacyMetadata, source: subsystem)
  }
  
  // MARK: - Helper Methods
  
  /**
   Creates metadata for error logs with appropriate privacy annotations.
   
   - Parameters:
     - error: The error to create metadata for
     - privacyLevel: The base privacy level to apply
     - file: The file where the error occurred
     - function: The function where the error occurred
     - line: The line where the error occurred
     
   - Returns: A collection of metadata entries
   */
  private func createErrorMetadata(
    _ error: Error,
    privacyLevel: LogPrivacy,
    file: String,
    function: String,
    line: Int
  ) -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()
    
    // Basic context information (public)
    metadata.add(LogMetadataDTO(key: "subsystem", value: subsystem, privacy: .public))
    metadata.add(LogMetadataDTO(key: "errorType", value: String(describing: type(of: error)), privacy: .public))
    
    // File and location information (private)
    let fileName = (file as NSString).lastPathComponent
    metadata.add(LogMetadataDTO(key: "file", value: fileName, privacy: .private))
    metadata.add(LogMetadataDTO(key: "function", value: function, privacy: .private))
    metadata.add(LogMetadataDTO(key: "line", value: String(line), privacy: .private))
    
    // Error specific information (privacy depends on level)
    if privacyLevel == .private || privacyLevel == .sensitive {
      // NSError properties with enhanced privacy
      let nsError = error as NSError
      metadata.add(LogMetadataDTO(key: "errorCode", value: String(nsError.code), privacy: .private))
      metadata.add(LogMetadataDTO(key: "errorDomain", value: nsError.domain, privacy: .private))
      
      // Check for underlying error (cast to NSError is always valid, but userInfo might be empty)
      if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
        metadata.add(LogMetadataDTO(key: "underlyingErrorDescription", value: underlyingError.localizedDescription, privacy: .sensitive))
        metadata.add(LogMetadataDTO(key: "underlyingErrorType", value: String(describing: type(of: underlyingError)), privacy: .private))
      }
      
      // Detailed user info if available
      if !nsError.userInfo.isEmpty {
        for (key, value) in nsError.userInfo where key != NSUnderlyingErrorKey {
          let stringValue = String(describing: value)
          metadata.add(LogMetadataDTO(key: "userInfo.\(key)", value: stringValue, privacy: .sensitive))
        }
      }
    }
    
    return metadata
  }
  
  /**
   Creates context metadata from file, function, and line information.
   
   - Parameters:
     - error: The error associated with the log (optional)
     - privacyLevel: The base privacy level to apply
     - file: The file where the log was generated
     - function: The function where the log was generated
     - line: The line where the log was generated
     - additionalMetadata: Additional metadata to include
     
   - Returns: A metadata collection
   */
  private func createContextMetadata(
    error: Error?,
    privacyLevel: LogPrivacy,
    file: String,
    function: String,
    line: Int,
    additionalMetadata: [String: String]?
  ) -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()
    
    let fileName = (file as NSString).lastPathComponent
    metadata.add(LogMetadataDTO(key: "file", value: fileName, privacy: .private))
    metadata.add(LogMetadataDTO(key: "function", value: function, privacy: .private))
    metadata.add(LogMetadataDTO(key: "line", value: String(line), privacy: .private))
    
    if let additionalMetadata = additionalMetadata {
      for (key, value) in additionalMetadata {
        metadata.add(LogMetadataDTO(key: key, value: value, privacy: .private))
      }
    }
    
    return metadata
  }
  
  /**
   Formats an error message appropriate for the privacy level.
   
   - Parameters:
     - error: The error to format
     - privacyLevel: The privacy level to apply
     
   - Returns: A formatted error message
   */
  private func formatErrorMessage(_ error: Error, privacyLevel: LogPrivacy) -> String {
    switch privacyLevel {
    case .public:
      return "Error encountered"
    case .private:
      return "Error: \(error.localizedDescription)"
    case .sensitive:
      if error is ErrorDomainProtocol {
        return "[SENSITIVE] Error of type \(type(of: error))"
      } else {
        return "[SENSITIVE] Error"
      }
    case .auto:
      let nsError = error as NSError
      return "[AUTO] \(error.localizedDescription) [Code: \(nsError.code), Domain: \(nsError.domain)]"
    }
  }
  
  /**
   Formats detailed error information based on privacy level.
   
   - Parameters:
     - error: The error to format
     - privacyLevel: The privacy level to apply
     
   - Returns: Formatted error details
   */
  private func formatErrorDetail(_ error: Error, privacyLevel: LogPrivacy) -> String {
    switch privacyLevel {
    case .public:
      return "Error"
    case .private:
      return error.localizedDescription
    case .sensitive, .auto:
      let nsError = error as NSError
      return "\(error.localizedDescription) (Code: \(nsError.code), Domain: \(nsError.domain))"
    }
  }
  
  /**
   Determines the appropriate privacy annotation for a metadata key-value pair.
   
   - Parameters:
     - key: The metadata key
     - value: The metadata value
     - baseLevel: The base privacy level
     
   - Returns: The appropriate privacy level
   */
  private func determinePrivacyAnnotation(
    for key: String,
    value: String,
    baseLevel: LogPrivacy
  ) -> LogPrivacy {
    // Define privacy rules based on metadata keys
    let sensitiveKeys = [
      "password", "key", "token", "secret", "auth", "credential",
      "certificate", "hash", "seed", "pin", "passphrase"
    ]
    
    // Check if this is a sensitive key
    for sensitiveKey in sensitiveKeys {
      if key.lowercased().contains(sensitiveKey) {
        return .sensitive
      }
    }
    
    // Otherwise use the base level
    switch baseLevel {
    case .public:
      return .public
    case .private:
      return .private
    case .sensitive, .auto:
      return .sensitive
    }
  }
}
