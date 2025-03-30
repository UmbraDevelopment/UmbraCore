import LoggingTypes

/// Protocol defining the standard logging interface
public protocol LoggingProtocol: CoreLoggingProtocol {
  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async
  
  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func info(_ message: String, metadata: PrivacyMetadata?, source: String) async

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func error(_ message: String, metadata: PrivacyMetadata?, source: String) async
  
  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async
  
  /// Get the underlying logging actor
  /// - Returns: The logging actor used by this logger
  var loggingActor: LoggingActor { get }
}

/// Default implementations for LoggingProtocol to ensure compatibility with CoreLoggingProtocol
extension LoggingProtocol {
    /// Maps the individual log level methods to the core logMessage method
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Source component identifier
    public func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {
        let context = await LogContext.create(source: source, metadata: metadata)
        await logMessage(level, message, context: context)
    }
    
    /// Implementation of trace level logging using the core method
    public func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.trace, message, metadata: metadata, source: source)
    }
    
    /// Implementation of debug level logging using the core method
    public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.debug, message, metadata: metadata, source: source)
    }
    
    /// Implementation of info level logging using the core method
    public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.info, message, metadata: metadata, source: source)
    }
    
    /// Implementation of warning level logging using the core method
    public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.warning, message, metadata: metadata, source: source)
    }
    
    /// Implementation of error level logging using the core method
    public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.error, message, metadata: metadata, source: source)
    }
    
    /// Implementation of critical level logging using the core method
    public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.critical, message, metadata: metadata, source: source)
    }
}

/// Errors that can occur during logging operations
public enum LoggingError: Error, Sendable, Hashable {
  /// Failed to initialise logging system
  case initialisationFailed(reason: String)

  /// Failed to write log
  case writeFailed(reason: String)

  /// Failed to write to log destination
  case destinationWriteFailed(destination: String, reason: String)

  /// Log level filter prevented message from being logged
  case filteredByLevel(
    messageLevel: LogLevel,
    minimumLevel: LogLevel
  )

  /// Invalid configuration provided
  case invalidConfiguration(description: String)

  /// Operation not supported by this logger
  case operationNotSupported(description: String)

  /// Destination with specified identifier not found
  case destinationNotFound(identifier: String)

  /// Duplicate destination identifier
  case duplicateDestination(identifier: String)
  
  /// Error during privacy processing
  case privacyProcessingFailed(reason: String)
}
