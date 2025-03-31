import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # ErrorLoggerService

 Implementation of the ErrorLoggingProtocol that bridges errors with the logging system.

 This service provides structured error logging capabilities using the Alpha Dot Five
 architecture principles of privacy-aware logging, actor-based concurrency, and
 domain-specific contextualisation.
 */
public actor ErrorLoggerService: ErrorLoggingProtocol {
  // MARK: - Properties

  /// The underlying logger implementation
  private let logger: PrivacyAwareLoggingProtocol
  
  /// The subsystem identifier for error logs
  private let subsystem = "ErrorHandling"

  // MARK: - Initialisation

  /**
   Initialises a new ErrorLoggerService with the provided logger.

   - Parameter logger: The underlying logger to use
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger = logger
  }

  // MARK: - ErrorLoggingProtocol Implementation

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
    let privacy = mapPrivacyLevel(privacyLevel)
    
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: metadata, privacy: privacy, source: subsystem)
    case .info:
      await logger.info(logMessage, metadata: metadata, privacy: privacy, source: subsystem)
    case .warning:
      await logger.warning(logMessage, metadata: metadata, privacy: privacy, source: subsystem)
    case .error:
      await logger.error(logMessage, metadata: metadata, privacy: privacy, source: subsystem)
    case .critical:
      await logger.critical(logMessage, metadata: metadata, privacy: privacy, source: subsystem)
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
    let privacy = mapPrivacyLevel(privacyLevel)
    
    // Log with the appropriate level
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: baseMetadata, privacy: privacy, source: effectiveSource)
    case .info:
      await logger.info(logMessage, metadata: baseMetadata, privacy: privacy, source: effectiveSource)
    case .warning:
      await logger.warning(logMessage, metadata: baseMetadata, privacy: privacy, source: effectiveSource)
    case .error:
      await logger.error(logMessage, metadata: baseMetadata, privacy: privacy, source: effectiveSource)
    case .critical:
      await logger.critical(logMessage, metadata: baseMetadata, privacy: privacy, source: effectiveSource)
    }
  }

  /**
   Logs an error with a context.

   - Parameters:
     - error: The error to log
     - level: The severity level for logging this error
     - privacyLevel: The privacy level to apply to sensitive information
     - context: Contextual information about the error
   */
  public func logError(
    _ error: some Error,
    level: ErrorLogLevel,
    privacyLevel: ErrorPrivacyLevel = .standard,
    context: ErrorContext
  ) async {
    // Create metadata from the error
    var baseMetadata = createErrorMetadata(
      error,
      privacyLevel: privacyLevel,
      file: #file,
      function: #function,
      line: #line
    )
    
    // Add context metadata with appropriate privacy annotations
    for (key, value) in context.metadata {
      let privacyAnnotation = determinePrivacyAnnotation(for: key, value: value, baseLevel: privacyLevel)
      baseMetadata.add(key: key, value: value, privacy: privacyAnnotation)
    }
    
    // Add domain information if available from context
    if let domain = context.domain {
      baseMetadata.add(key: "errorContextDomain", value: domain.description, privacy: .public)
    }
    
    // Determine effective privacy level based on context
    let effectivePrivacyLevel = determineEffectivePrivacyLevel(context, baseLevel: privacyLevel)
    let logMessage = formatErrorMessage(error, privacyLevel: effectivePrivacyLevel)
    let source = context.source.description
    let privacy = mapPrivacyLevel(effectivePrivacyLevel)
    
    // Log with the appropriate level
    switch level {
    case .debug:
      await logger.debug(logMessage, metadata: baseMetadata, privacy: privacy, source: source)
    case .info:
      await logger.info(logMessage, metadata: baseMetadata, privacy: privacy, source: source)
    case .warning:
      await logger.warning(logMessage, metadata: baseMetadata, privacy: privacy, source: source)
    case .error:
      await logger.error(logMessage, metadata: baseMetadata, privacy: privacy, source: source)
    case .critical:
      await logger.critical(logMessage, metadata: baseMetadata, privacy: privacy, source: source)
    }
  }

  /**
   Logs an error with debug level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - privacyLevel: The privacy level to apply to sensitive information
   */
  public func debug(
    _ error: some Error,
    context: ErrorContext? = nil,
    privacyLevel: ErrorPrivacyLevel = .standard
  ) async {
    if let context = context {
      await logError(error, level: .debug, privacyLevel: privacyLevel, context: context)
    } else {
      await logError(error, level: .debug, privacyLevel: privacyLevel)
    }
  }

  /**
   Logs an error with info level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - privacyLevel: The privacy level to apply to sensitive information
   */
  public func info(
    _ error: some Error,
    context: ErrorContext? = nil,
    privacyLevel: ErrorPrivacyLevel = .standard
  ) async {
    if let context = context {
      await logError(error, level: .info, privacyLevel: privacyLevel, context: context)
    } else {
      await logError(error, level: .info, privacyLevel: privacyLevel)
    }
  }

  /**
   Logs an error with warning level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - privacyLevel: The privacy level to apply to sensitive information
   */
  public func warning(
    _ error: some Error,
    context: ErrorContext? = nil,
    privacyLevel: ErrorPrivacyLevel = .standard
  ) async {
    if let context = context {
      await logError(error, level: .warning, privacyLevel: privacyLevel, context: context)
    } else {
      await logError(error, level: .warning, privacyLevel: privacyLevel)
    }
  }

  /**
   Logs an error with error level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - privacyLevel: The privacy level to apply to sensitive information
   */
  public func error(
    _ error: some Error,
    context: ErrorContext? = nil,
    privacyLevel: ErrorPrivacyLevel = .standard
  ) async {
    if let context = context {
      await logError(error, level: .error, privacyLevel: privacyLevel, context: context)
    } else {
      await logError(error, level: .error, privacyLevel: privacyLevel)
    }
  }
  
  /**
   Logs an error with critical level.

   - Parameters:
      - error: The error to log
      - context: Optional contextual information about the error
      - privacyLevel: The privacy level to apply to sensitive information
   */
  public func critical(
    _ error: some Error,
    context: ErrorContext? = nil,
    privacyLevel: ErrorPrivacyLevel = .standard
  ) async {
    if let context = context {
      await logError(error, level: .critical, privacyLevel: privacyLevel, context: context)
    } else {
      await logError(error, level: .critical, privacyLevel: privacyLevel)
    }
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
  
  // MARK: - Private Helper Methods
  
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
    metadata.add(key: "errorMessage", value: error.localizedDescription, privacy: .private)
    metadata.add(key: "file", value: file, privacy: .private)
    metadata.add(key: "function", value: function, privacy: .private)
    metadata.add(key: "line", value: String(line), privacy: .private)

    // All Swift errors can be bridged to NSError safely without optional casting
    let nsError = error as NSError
    metadata.add(key: "errorCode", value: String(nsError.code), privacy: .public)
    metadata.add(key: "errorDomain", value: nsError.domain, privacy: .public)

    // Add domain information if available
    if let domainError = error as? ErrorDomainProtocol {
      metadata.add(key: "errorSeverity", value: String(describing: domainError.severity), privacy: .public)
      
      if let domain = domainError.domain {
        metadata.add(key: "errorDomainContext", value: domain.description, privacy: .public)
      }
    }
    
    // Determine privacy level for user info based on context
    let userInfoPrivacy = privacyLevel >= .enhanced ? PrivacyLevel.sensitive : PrivacyLevel.private
    
    if !nsError.userInfo.isEmpty {
      metadata.add(
        key: "errorUserInfo", 
        value: String(describing: nsError.userInfo),
        privacy: userInfoPrivacy
      )
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
      return "[\(privacyLevel.rawValue.uppercased())] \(error.localizedDescription)"
    case .enhanced:
      if let domainError = error as? ErrorDomainProtocol {
        return "[\(privacyLevel.rawValue.uppercased())] Error of type \(type(of: error)) with severity \(domainError.severity)"
      } else {
        return "[\(privacyLevel.rawValue.uppercased())] Error of type \(type(of: error))"
      }
    case .comprehensive:
      let nsError = error as NSError
      return "[\(privacyLevel.rawValue.uppercased())] \(error.localizedDescription) [Code: \(nsError.code), Domain: \(nsError.domain)]"
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
  
  /**
   Determine the effective privacy level based on context.
   
   - Parameters:
     - context: The error context
     - baseLevel: The base privacy level
   - Returns: The effective privacy level
   */
  private func determineEffectivePrivacyLevel(
    _ context: ErrorContext,
    baseLevel: ErrorPrivacyLevel
  ) -> ErrorPrivacyLevel {
    // If the context domain suggests higher security needs, enhance privacy
    if let domain = context.domain {
      if domain.description.contains("Security") || 
         domain.description.contains("Crypto") ||
         domain.description.contains("Authentication") {
        // Security domains get enhanced privacy by default
        return baseLevel < .enhanced ? .enhanced : baseLevel
      }
    }
    
    // Check for sensitive metadata keys
    for (key, _) in context.metadata {
      if key.lowercased().contains("password") ||
         key.lowercased().contains("secret") ||
         key.lowercased().contains("token") ||
         key.lowercased().contains("key") {
        // Presence of sensitive keys suggests enhanced privacy
        return baseLevel < .enhanced ? .enhanced : baseLevel
      }
    }
    
    return baseLevel
  }
  
  /**
   Map error privacy level to logging privacy level.
   
   - Parameter errorPrivacyLevel: The error privacy level
   - Returns: The corresponding logging privacy level
   */
  private func mapPrivacyLevel(_ errorPrivacyLevel: ErrorPrivacyLevel) -> PrivacyLevel {
    switch errorPrivacyLevel {
    case .minimal:
      return .public
    case .standard:
      return .private
    case .enhanced, .comprehensive:
      return .sensitive
    }
  }
}
