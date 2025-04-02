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
      source: context.getSource() ?? domainName
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
      source: context.getSource() ?? domainName
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
  
  /// Log an error with privacy-enhanced details
  ///
  /// - Parameters:
  ///   - error: The error to log
  ///   - metadata: Additional metadata
  ///   - source: Source context
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line number
  public func error(
    _ error: any Error,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
  ) async {
    if let loggableError = error as? LoggableErrorProtocol {
      await log(
        .error,
        loggableError.getLogMessage(),
        metadata: metadata,
        source: source ?? domainName,
        file: file,
        function: function,
        line: line
      )
    } else {
      await log(
        .error,
        error.localizedDescription,
        metadata: metadata,
        source: source ?? domainName,
        file: file,
        function: function,
        line: line
      )
    }
  }
}
