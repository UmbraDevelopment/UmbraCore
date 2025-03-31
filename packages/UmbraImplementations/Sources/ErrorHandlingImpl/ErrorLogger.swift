import Foundation
import LoggingInterfaces
import LoggingTypes
import ErrorHandlingInterfaces

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

  /**
   Logs an error with appropriate privacy controls and context.

   - Parameters:
     - error: The error to log
     - level: The severity level of the error
     - privacyLevel: The privacy level to apply to sensitive information
     - file: The file where the error occurred
     - function: The function where the error occurred
     - line: The line where the error occurred
   */
  public func logError(
    _ error: Error,
    level: ErrorLogLevel = .error,
    privacyLevel: ErrorPrivacyLevel = .standard,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) async {
    let metadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: file,
      function: function,
      line: line
    )
    
    let logMessage = formatErrorMessage(error, privacyLevel: privacyLevel)
    
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .info:
      await logger.info(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .warning:
      await logger.warning(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .error:
      await logger.error(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .critical:
      await logger.critical(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    }
  }

  /**
   Logs an error with source information and additional metadata.

   - Parameters:
     - error: The error to log
     - level: The severity level of the error
     - privacyLevel: The privacy level to apply to sensitive information
     - metadata: Additional metadata to include
     - source: The source component identifier
   */
  public func logError(
    _ error: Error,
    level: ErrorLogLevel = .error,
    privacyLevel: ErrorPrivacyLevel = .standard,
    metadata: [String: String],
    source: String? = nil
  ) async {
    var baseMetadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: #file,
      function: #function,
      line: #line
    )

    // Add any additional metadata with appropriate privacy annotations
    for (key, value) in metadata {
      let privacyAnnotation = determinePrivacyAnnotation(for: key, value: value, baseLevel: privacyLevel)
      baseMetadata.add(key: key, value: value, privacy: privacyAnnotation)
    }

    let logMessage = formatErrorMessage(error, privacyLevel: privacyLevel)
    let effectiveSource = source ?? subsystem
    
    // Log with the appropriate level
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: baseMetadata, privacy: .private, source: effectiveSource)
    case .info:
      await logger.info(logMessage, metadata: baseMetadata, privacy: .private, source: effectiveSource)
    case .warning:
      await logger.warning(logMessage, metadata: baseMetadata, privacy: .private, source: effectiveSource)
    case .error:
      await logger.error(logMessage, metadata: baseMetadata, privacy: .private, source: effectiveSource)
    case .critical:
      await logger.critical(logMessage, metadata: baseMetadata, privacy: .private, source: effectiveSource)
    }
  }

  /**
   Logs an error with a custom message and appropriate privacy controls.

   - Parameters:
     - message: The message to log
     - error: The error to include as context
     - level: The severity level of the error
     - privacyLevel: The privacy level to apply to sensitive information
     - file: The file where the error occurred
     - function: The function where the error occurred
     - line: The line where the error occurred
   */
  public func logMessage(
    _ message: String,
    error: Error,
    level: ErrorLogLevel = .error,
    privacyLevel: ErrorPrivacyLevel = .standard,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) async {
    let metadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: file,
      function: function,
      line: line
    )
    
    let logMessage = "\(message) - \(formatErrorDetail(error, privacyLevel: privacyLevel))"
    
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .info:
      await logger.info(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .warning:
      await logger.warning(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .error:
      await logger.error(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    case .critical:
      await logger.critical(logMessage, metadata: metadata, privacy: .private, source: subsystem)
    }
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
      file: file,
      function: function,
      line: line,
      additionalMetadata: metadata
    )
    
    await logger.debug(message, metadata: contextMetadata, privacy: .private, source: subsystem)
  }
  
  /**
   Logs an informational message with appropriate metadata.
   
   - Parameters:
     - message: The message to log
     - metadata: Additional contextual information
     - file: The file where the log was generated
     - function: The function where the log was generated
     - line: The line where the log was generated
   */
  public func info(
    _ message: String,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) async {
    let contextMetadata = createContextMetadata(
      file: file,
      function: function,
      line: line,
      additionalMetadata: metadata
    )
    
    await logger.info(message, metadata: contextMetadata, privacy: .private, source: subsystem)
  }
  
  /**
   Logs a warning message with appropriate metadata.
   
   - Parameters:
     - message: The message to log
     - metadata: Additional contextual information
     - file: The file where the log was generated
     - function: The function where the log was generated
     - line: The line where the log was generated
   */
  public func warning(
    _ message: String,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) async {
    let contextMetadata = createContextMetadata(
      file: file,
      function: function,
      line: line,
      additionalMetadata: metadata
    )
    
    await logger.warning(message, metadata: contextMetadata, privacy: .private, source: subsystem)
  }

  // MARK: - Private Methods

  /**
   Creates metadata for an error log entry with privacy annotations.

   - Parameters:
     - error: The error to create metadata for
     - privacyLevel: The privacy level to apply
     - file: The file where the error occurred
     - function: The function where the error occurred
     - line: The line where the error occurred
   - Returns: Metadata dictionary for the log entry with privacy annotations
   */
  private func createErrorMetadata(
    _ error: Error,
    privacyLevel: ErrorPrivacyLevel,
    file: String,
    function: String,
    line: Int
  ) -> LogMetadataDTO {
    let metadata = LogMetadataDTOCollection()
    
    // Basic context information (public)
    metadata.add(key: "subsystem", value: subsystem, privacy: .public)
    metadata.add(key: "errorType", value: String(describing: type(of: error)), privacy: .public)
    metadata.add(key: "file", value: file, privacy: .private)
    metadata.add(key: "function", value: function, privacy: .private)
    metadata.add(key: "line", value: String(line), privacy: .private)

    // All Swift errors can be bridged to NSError safely without optional casting
    let nsError = error as NSError
    metadata.add(key: "errorCode", value: String(nsError.code), privacy: .public)
    metadata.add(key: "errorDomain", value: nsError.domain, privacy: .public)

    // Determine privacy level for user info based on context
    let userInfoPrivacy = privacyLevel >= .enhanced ? PrivacyLevel.sensitive : PrivacyLevel.private
    
    if !nsError.userInfo.isEmpty {
      metadata.add(
        key: "errorUserInfo", 
        value: String(describing: nsError.userInfo),
        privacy: userInfoPrivacy
      )
    }
    
    // Handle specific error types with extra privacy protection
    if let domainError = error as? ErrorDomainProtocol {
      metadata.add(key: "errorSeverity", value: String(describing: domainError.severity), privacy: .public)
      
      if let domain = domainError.domain {
        metadata.add(key: "errorContextDomain", value: domain.description, privacy: .public)
      }
      
      // For high security domains, apply stricter privacy
      if domainError.domain?.description.contains("Security") == true ||
         domainError.domain?.description.contains("Crypto") == true {
        return applyEnhancedPrivacy(to: metadata)
      }
    }

    return metadata.asDTO()
  }
  
  /**
   Creates context metadata for general logging.
   
   - Parameters:
     - file: The file where the log was generated
     - function: The function where the log was generated
     - line: The line where the log was generated
     - additionalMetadata: Additional metadata to include
   - Returns: Combined metadata with context information
   */
  private func createContextMetadata(
    file: String,
    function: String,
    line: Int,
    additionalMetadata: [String: String]?
  ) -> LogMetadataDTO {
    let metadata = LogMetadataDTOCollection()
    
    // Add basic context information
    metadata.add(key: "subsystem", value: subsystem, privacy: .public)
    metadata.add(key: "file", value: file, privacy: .private)
    metadata.add(key: "function", value: function, privacy: .private)
    metadata.add(key: "line", value: String(line), privacy: .private)
    
    // Add any additional metadata
    if let additionalMetadata = additionalMetadata {
      for (key, value) in additionalMetadata {
        let privacyAnnotation = determinePrivacyAnnotation(for: key, value: value, baseLevel: .standard)
        metadata.add(key: key, value: value, privacy: privacyAnnotation)
      }
    }
    
    return metadata.asDTO()
  }
  
  /**
   Apply enhanced privacy controls to metadata.
   
   - Parameter metadata: The metadata collection to enhance
   - Returns: Enhanced metadata with stricter privacy controls
   */
  private func applyEnhancedPrivacy(to metadata: LogMetadataDTOCollection) -> LogMetadataDTO {
    // In enhanced privacy mode, we minimize the information that's logged
    // to prevent sensitive data leakage
    let enhancedMetadata = LogMetadataDTOCollection()
    
    // Only keep the most essential information
    if let subsystem = metadata.value(for: "subsystem") {
      enhancedMetadata.add(key: "subsystem", value: subsystem, privacy: .public)
    }
    
    if let errorType = metadata.value(for: "errorType") {
      enhancedMetadata.add(key: "errorType", value: errorType, privacy: .public)
    }
    
    if let errorCode = metadata.value(for: "errorCode") {
      enhancedMetadata.add(key: "errorCode", value: errorCode, privacy: .public)
    }
    
    if let errorDomain = metadata.value(for: "errorDomain") {
      enhancedMetadata.add(key: "errorDomain", value: errorDomain, privacy: .public)
    }
    
    // Mark that enhanced privacy was applied
    enhancedMetadata.add(key: "privacyEnhanced", value: "true", privacy: .public)
    
    return enhancedMetadata.asDTO()
  }
  
  /**
   Format an error message with appropriate privacy controls.
   
   - Parameters:
     - error: The error to format
     - privacyLevel: The privacy level to apply
   - Returns: Formatted error message
   */
  private func formatErrorMessage(_ error: Error, privacyLevel: ErrorPrivacyLevel) -> String {
    switch privacyLevel {
    case .minimal:
      return "Error encountered"
    case .standard:
      return "Error encountered: \(formatErrorDetail(error, privacyLevel: privacyLevel))"
    case .enhanced:
      if let domainError = error as? ErrorDomainProtocol {
        return "Error encountered: \(String(describing: type(of: error))) [\(domainError.severity)]"
      } else {
        return "Error encountered: \(String(describing: type(of: error)))"
      }
    case .comprehensive:
      let nsError = error as NSError
      return "Error encountered: \(formatErrorDetail(error, privacyLevel: privacyLevel)) [Code: \(nsError.code), Domain: \(nsError.domain)]"
    }
  }
  
  /**
   Format error details with privacy considerations.
   
   - Parameters:
     - error: The error to format
     - privacyLevel: The privacy level to apply
   - Returns: Formatted error detail
   */
  private func formatErrorDetail(_ error: Error, privacyLevel: ErrorPrivacyLevel) -> String {
    switch privacyLevel {
    case .minimal:
      return String(describing: type(of: error))
    case .standard, .enhanced:
      return String(describing: error)
    case .comprehensive:
      let nsError = error as NSError
      if nsError.userInfo.isEmpty {
        return String(describing: error)
      } else {
        return "\(String(describing: error)) (UserInfo: \(nsError.userInfo))"
      }
    }
  }
  
  /**
   Determine the appropriate privacy annotation for a metadata key-value pair.
   
   - Parameters:
     - key: The metadata key
     - value: The metadata value
     - baseLevel: The base privacy level
   - Returns: The appropriate privacy annotation
   */
  private func determinePrivacyAnnotation(
    for key: String,
    value: String,
    baseLevel: ErrorPrivacyLevel
  ) -> PrivacyLevel {
    // Define privacy rules based on metadata keys
    let sensitiveKeys = [
      "password", "token", "secret", "key", "certificate", 
      "auth", "credential", "private", "hash", "secure"
    ]
    
    // Check if the key contains any sensitive patterns
    for sensitiveKey in sensitiveKeys {
      if key.lowercased().contains(sensitiveKey) {
        return .sensitive
      }
    }
    
    // Determine privacy based on base level
    switch baseLevel {
    case .minimal:
      return .private
    case .standard:
      return .private
    case .enhanced, .comprehensive:
      return .sensitive
    }
  }
}
