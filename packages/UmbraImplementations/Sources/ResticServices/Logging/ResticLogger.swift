import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingServices
import ResticInterfaces

/// Domain-specific logger for Restic operations
///
/// This logger provides specialised logging functionality for Restic operations
/// with enhanced privacy controls and contextual information following the
/// Alpha Dot Five architecture.
public struct ResticLogger: LoggingInterfaces.DomainLogger, CoreLoggingProtocol, PrivacyAwareLoggingProtocol {
  /// The domain name for this logger
  public let domainName: String = "ResticService"
  
  /// The underlying logging protocol
  private let underlyingLogger: any LoggingProtocol
  
  /// Access to the underlying logging actor
  public var loggingActor: LoggingActor {
    underlyingLogger.loggingActor
  }
  
  /// Creates a new ResticLogger
  ///
  /// - Parameter underlyingLogger: The underlying logging protocol
  public init(underlyingLogger: any LoggingProtocol) {
    self.underlyingLogger = underlyingLogger
  }
  
  /// Log a message with a log context
  ///
  /// - Parameters:
  ///   - level: The severity level
  ///   - message: The message to log
  ///   - context: The domain context
  public func logWithContext(
    _ level: LogLevel,
    _ message: String,
    context: any LogContextDTO
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: context.toPrivacyMetadata(),
      source: context.getSource()
    )
  }
  
  /// Log a privacy-annotated message with a log context
  ///
  /// - Parameters:
  ///   - level: The severity level
  ///   - message: The privacy-annotated message
  ///   - context: The domain context
  public func logWithContext(
    _ level: LogLevel,
    _ message: PrivacyAnnotatedString,
    context: any LogContextDTO
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: context.toPrivacyMetadata(),
      source: context.getSource()
    )
  }
  
  /// Log a message with specified parameters
  ///
  /// - Parameters:
  ///   - level: The severity level
  ///   - message: The message to log
  ///   - context: The log context
  public func logMessage(
    _ level: LogLevel,
    _ message: String,
    context: LogContext
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: context.metadata,
      source: context.source
    )
  }
  
  /// Log an error with context and privacy classification
  ///
  /// - Parameters:
  ///   - error: The error to log
  ///   - context: The domain-specific context
  ///   - privacyLevel: The privacy level for the error details
  public func logError(
    _ error: Error,
    context: any LogContextDTO, 
    privacyLevel: PrivacyClassification
  ) async {
    // Determine privacy level for errors
    let logPrivacyLevel: LogPrivacyLevel = switch privacyLevel {
      case .public: .public
      case .private: .private
      case .sensitive: .sensitive
    }
    
    // Format error message with context
    let message = "Error in Restic operation: \(error.localizedDescription)"
    
    // Create privacy metadata for the error
    var metadata = context.toPrivacyMetadata()
    metadata.add(key: "errorDescription", value: error.localizedDescription, privacy: logPrivacyLevel)
    
    if let loggableError = error as? LoggableErrorProtocol {
      // Add additional error context if available
      metadata.merge(with: loggableError.getPrivacyMetadata())
    }
    
    // Log through underlying logger with appropriate metadata
    await underlyingLogger.log(.error, message, metadata: metadata, source: context.getSource())
  }
  
  /// Log sensitive information with appropriate privacy controls
  ///
  /// - Parameters:
  ///   - level: The severity level
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values that should be handled with privacy controls
  ///   - source: The component source
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    source: String
  ) async {
    // Convert standard LogMetadata to privacy-aware metadata
    var privacyMetadata = PrivacyMetadata()
    
    if let values = sensitiveValues {
      for (key, value) in values {
        let privacyLevel: LogPrivacyLevel
        
        // Apply privacy levels based on key naming patterns
        if key.hasSuffix("Password") || key.hasSuffix("Secret") || key.hasSuffix("Key") {
          privacyLevel = .sensitive
        } else if key.hasSuffix("Id") || key.hasSuffix("Email") || key.hasSuffix("Name") {
          privacyLevel = .private
        } else {
          privacyLevel = .public
        }
        
        // Add to privacy metadata with appropriate privacy level
        privacyMetadata.add(key: key, value: value, privacy: privacyLevel)
      }
    }
    
    // Log through underlying logger with privacy metadata
    await underlyingLogger.log(level, message, metadata: privacyMetadata, source: source)
  }
  
  /// Log a message with specific level, metadata and source
  ///
  /// - Parameters:
  ///   - level: The severity level for the log entry
  ///   - message: The message to log
  ///   - metadata: Privacy-annotated metadata for the log entry
  ///   - source: Source context for the log
  ///   - file: Source file information
  ///   - function: Function information
  ///   - line: Line number information
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: metadata,
      source: source ?? domainName
    )
  }
  
  /// Log a privacy-annotated message with specific level
  ///
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The privacy-annotated message
  ///   - metadata: Additional metadata
  ///   - source: The source context
  public func log(
    _ level: LogLevel,
    _ message: PrivacyString,
    metadata: PrivacyMetadata? = nil,
    source: String
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: metadata,
      source: source
    )
  }
  
  /// Log a trace message
  ///
  /// - Parameters:
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source information
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public func trace(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await log(.trace, message, metadata: metadata, source: source, file: file, function: function, line: line)
  }
  
  /// Log a debug message
  ///
  /// - Parameters:
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source information
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public func debug(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await log(.debug, message, metadata: metadata, source: source, file: file, function: function, line: line)
  }
  
  /// Log an info message
  ///
  /// - Parameters:
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source information
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public func info(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await log(.info, message, metadata: metadata, source: source, file: file, function: function, line: line)
  }
  
  /// Log a warning message
  ///
  /// - Parameters:
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source information
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public func warning(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await log(.warning, message, metadata: metadata, source: source, file: file, function: function, line: line)
  }
  
  /// Log an error message
  ///
  /// - Parameters:
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source information
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public func error(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await log(.error, message, metadata: metadata, source: source, file: file, function: function, line: line)
  }
  
  /// Log a critical error message
  ///
  /// - Parameters:
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source information
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public func critical(
    _ message: String,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    await log(.critical, message, metadata: metadata, source: source, file: file, function: function, line: line)
  }
  
  // MARK: - Privacy-Aware Logging Protocol Compliance
  
  /// Log a trace message with privacy annotations
  ///
  /// - Parameters:
  ///   - message: The privacy-annotated message
  ///   - source: The source context
  public func trace(
    _ message: PrivacyString,
    source: String
  ) async {
    await log(.trace, message, metadata: nil, source: source)
  }
  
  /// Log a debug message with privacy annotations
  ///
  /// - Parameters:
  ///   - message: The privacy-annotated message
  ///   - source: The source context
  public func debug(
    _ message: PrivacyString,
    source: String
  ) async {
    await log(.debug, message, metadata: nil, source: source)
  }
  
  /// Log an info message with privacy annotations
  ///
  /// - Parameters:
  ///   - message: The privacy-annotated message
  ///   - source: The source context
  public func info(
    _ message: PrivacyString,
    source: String
  ) async {
    await log(.info, message, metadata: nil, source: source)
  }
  
  /// Log a warning message with privacy annotations
  ///
  /// - Parameters:
  ///   - message: The privacy-annotated message
  ///   - source: The source context
  public func warning(
    _ message: PrivacyString,
    source: String
  ) async {
    await log(.warning, message, metadata: nil, source: source)
  }
  
  /// Log an error message with privacy annotations
  ///
  /// - Parameters:
  ///   - message: The privacy-annotated message
  ///   - source: The source context
  public func error(
    _ message: PrivacyString,
    source: String
  ) async {
    await log(.error, message, metadata: nil, source: source)
  }
  
  /// Log a critical message with privacy annotations
  ///
  /// - Parameters:
  ///   - message: The privacy-annotated message
  ///   - source: The source context
  public func critical(
    _ message: PrivacyString,
    source: String
  ) async {
    await log(.critical, message, metadata: nil, source: source)
  }
}
