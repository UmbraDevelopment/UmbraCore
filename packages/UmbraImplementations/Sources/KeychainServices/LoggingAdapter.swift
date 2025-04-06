import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Keychain Logging Adapter

 This adapter wraps a LoggingServiceProtocol instance and adapts it to the
 LoggingProtocol interface, compatible with the Alpha Dot Five architecture.

 It enables using logging services across module boundaries while maintaining
 type safety and privacy controls.
 */
public actor LoggingAdapter: LoggingProtocol, CoreLoggingProtocol {
  private let loggingService: LoggingServiceProtocol
  private let _loggingActor: LoggingActor
  
  /// The domain name for this logger
  public let domainName: String = "KeychainServices"

  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    _loggingActor
  }

  /**
   Create a new logging adapter wrapping the given logging service.

   - Parameter loggingService: The logging service to wrap
   */
  public init(wrapping loggingService: LoggingServiceProtocol) {
    self.loggingService = loggingService
    self._loggingActor = LoggingActor(destinations: [], minimumLogLevel: .info)
  }
  
  // MARK: - CoreLoggingProtocol Implementation
  
  /// Required CoreLoggingProtocol implementation
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage = "[\(domainName)] \(message)"
    
    // Use the appropriate loggers
    if let loggingService = self.loggingService as? LoggingProtocol {
      await loggingService.log(level, formattedMessage, context: context)
    } else {
      // Legacy fallback for older LoggingServiceProtocol
      let metadata = context.asLogMetadata()
      let source = context.getSource() ?? domainName
      
      // Use the appropriate level-specific method
      switch level {
        case .trace:
          await loggingService.verbose(formattedMessage, metadata: metadata, source: source)
        case .debug:
          await loggingService.debug(formattedMessage, metadata: metadata, source: source)
        case .info:
          await loggingService.info(formattedMessage, metadata: metadata, source: source)
        case .warning:
          await loggingService.warning(formattedMessage, metadata: metadata, source: source)
        case .error:
          await loggingService.error(formattedMessage, metadata: metadata, source: source)
        case .critical:
          await loggingService.critical(formattedMessage, metadata: metadata, source: source)
      }
    }
    
    // Also log to the actor
    await loggingActor.log(level, formattedMessage, context: context)
  }
  
  // MARK: - LoggingProtocol Implementation
  
  /**
   Log a message with trace level and context

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }
  
  /**
   Log a message with debug level and context

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }
  
  /**
   Log a message with info level and context

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }
  
  /**
   Log a message with warning level and context

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }
  
  /**
   Log a message with error level and context

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }
  
  /**
   Log a message with critical level and context

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  // MARK: - Legacy Methods (Deprecated)

  /**
   Log a message with debug level

   - Parameters:
     - message: The message to log
     - metadata: Any metadata to include
     - source: The source of the log message

   - Warning: This method is deprecated. Use debug(_:context:) instead.
   */
  @available(*, deprecated, message: "Use debug(_:context:) instead")
  public func debug(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String = "KeychainServices"
  ) async {
    let context = BaseLogContextDTO(
      source: source,
      metadata: convertToLogMetadataDTO(metadata)
    )
    await debug(message, context: context)
  }

  /**
   Log a message with info level

   - Parameters:
     - message: The message to log
     - metadata: Any metadata to include
     - source: The source of the log message
     
   - Warning: This method is deprecated. Use info(_:context:) instead.
   */
  @available(*, deprecated, message: "Use info(_:context:) instead")
  public func info(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String = "KeychainServices"
  ) async {
    let context = BaseLogContextDTO(
      source: source,
      metadata: convertToLogMetadataDTO(metadata)
    )
    await info(message, context: context)
  }

  /**
   Log a message with warning level

   - Parameters:
     - message: The message to log
     - metadata: Any metadata to include
     - source: The source of the log message
     
   - Warning: This method is deprecated. Use warning(_:context:) instead.
   */
  @available(*, deprecated, message: "Use warning(_:context:) instead")
  public func warning(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String = "KeychainServices"
  ) async {
    let context = BaseLogContextDTO(
      source: source,
      metadata: convertToLogMetadataDTO(metadata)
    )
    await warning(message, context: context)
  }

  /**
   Log a message with error level

   - Parameters:
     - message: The message to log
     - metadata: Any metadata to include
     - source: The source of the log message
     
   - Warning: This method is deprecated. Use error(_:context:) instead.
   */
  @available(*, deprecated, message: "Use error(_:context:) instead")
  public func error(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String = "KeychainServices"
  ) async {
    let context = BaseLogContextDTO(
      source: source,
      metadata: convertToLogMetadataDTO(metadata)
    )
    await error(message, context: context)
  }

  /**
   Log a message with critical level

   - Parameters:
     - message: The message to log
     - metadata: Any metadata to include
     - source: The source of the log message
     
   - Warning: This method is deprecated. Use critical(_:context:) instead.
   */
  @available(*, deprecated, message: "Use critical(_:context:) instead")
  public func critical(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String = "KeychainServices"
  ) async {
    let context = BaseLogContextDTO(
      source: source,
      metadata: convertToLogMetadataDTO(metadata)
    )
    await critical(message, context: context)
  }

  // MARK: - Private Helpers

  /**
   Convert PrivacyMetadata to LogMetadataDTOCollection for use with the new context-based logging
   
   - Parameter metadata: The privacy metadata to convert
   - Returns: A metadata DTO collection
   */
  private func convertToLogMetadataDTO(_ metadata: PrivacyMetadata?) -> LogMetadataDTOCollection {
    guard let metadata = metadata else {
      return LogMetadataDTOCollection()
    }
    
    let collection = LogMetadataDTOCollection()
    
    // Convert metadata to the new format
    // This is a simplified conversion
    
    return collection
  }
}
