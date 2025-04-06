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
    // Convert to LoggableErrorDTO if not already
    let loggableError = convertToLoggableErrorDTO(error, context: context)
    
    // Determine privacy level from options
    let privacyLevel = mapErrorPrivacyLevel(options?.privacyLevel ?? .standard)
    
    // Create log context with metadata
    let logContext = CoreLogContext(
      source: "\(context.source.file):\(context.source.line)",
      correlationID: context.correlationID,
      metadata: loggableError.createMetadataCollection()
    )
    
    // Log using the appropriate level method
    switch level {
      case .debug:
        await logger.debug(loggableError.message, context: logContext, privacyLevel: privacyLevel)
      case .info:
        await logger.info(loggableError.message, context: logContext, privacyLevel: privacyLevel)
      case .warning:
        await logger.warning(loggableError.message, context: logContext, privacyLevel: privacyLevel)
      case .error:
        await logger.error(loggableError, context: logContext, privacyLevel: privacyLevel)
      case .critical:
        await logger.critical(loggableError, context: logContext, privacyLevel: privacyLevel)
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
   Converts an Error to a LoggableErrorDTO.
   
   This method ensures all errors are properly formatted for
   privacy-aware structured logging.
   
   - Parameters:
     - error: The error to convert
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func convertToLoggableErrorDTO(_ error: some Error, context: ErrorContext) -> LoggableErrorDTO {
    // If already a LoggableErrorDTO, return it
    if let loggableError = error as? LoggableErrorDTO {
      return loggableError
    }
    
    // For LoggableErrorProtocol, adapt to the new DTO format
    if let loggableError = error as? LoggableErrorProtocol {
      return createDTOFromLoggableProtocol(loggableError, context: context)
    }
    
    // For NSError, create a structured LoggableErrorDTO
    if let nsError = error as NSError {
      return createDTOFromNSError(nsError, originalError: error, context: context)
    }
    
    // For standard errors, create a basic LoggableErrorDTO
    return createStandardDTO(error, context: context)
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
    let metadata = loggableError.getPrivacyMetadata()
    let source = loggableError.getSource()
    
    // Extract domain and code if available
    var domain = "Application"
    var code = 0
    var details = ""
    
    // Build details string from sensitive metadata
    for key in metadata.entries() {
      if let value = metadata[key], value.privacy == .sensitive {
        details += "\(key): \(value.valueString)\n"
      }
      
      // Look for domain and code in metadata
      if key == "domain", let value = metadata[key] {
        domain = value.valueString
      }
      
      if key == "code", let value = metadata[key], let codeValue = Int(value.valueString) {
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
      correlationID: context.correlationID
    )
  }
  
  /**
   Creates a LoggableErrorDTO from an NSError.
   
   - Parameters:
     - nsError: The NSError
     - originalError: The original error object
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func createDTOFromNSError(
    _ nsError: NSError,
    originalError: Error,
    context: ErrorContext
  ) -> LoggableErrorDTO {
    // Filter sensitive keys from userInfo
    let sensitiveKeys = ["NSUnderlyingError", "NSSensitiveKeys", "NSCredential"]
    let filteredUserInfo = nsError.userInfo.filter { !sensitiveKeys.contains($0.key) }
    let details = filteredUserInfo.description
    
    return LoggableErrorDTO(
      error: originalError,
      domain: nsError.domain,
      code: nsError.code,
      message: nsError.localizedDescription,
      details: details,
      source: "\(context.source.file):\(context.source.line)",
      correlationID: context.correlationID
    )
  }
  
  /**
   Creates a standard LoggableErrorDTO.
   
   - Parameters:
     - error: The error
     - context: The error context
   - Returns: A LoggableErrorDTO instance
   */
  private func createStandardDTO(
    _ error: Error,
    context: ErrorContext
  ) -> LoggableErrorDTO {
    let errorTypeString = String(describing: type(of: error))
    
    return LoggableErrorDTO(
      error: error,
      domain: "Application",
      code: 0,
      message: error.localizedDescription,
      details: String(describing: error),
      source: "\(context.source.file):\(context.source.function):\(context.source.line)",
      correlationID: context.correlationID
    )
  }
}
