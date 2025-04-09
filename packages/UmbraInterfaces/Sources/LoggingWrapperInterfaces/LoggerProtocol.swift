/**
 # Logger Protocol

 Protocol defining the standard logging interface for UmbraCore.

 This protocol provides a stable API for logging operations across the codebase,
 decoupling client code from the specific logging implementation.

 ## Actor-Based Logging

 Logger implementations must support actor isolation and concurrency safety.
 Though this interface uses static methods for convenience, implementations
 should use properly isolated actor state internally:

 ```swift
 actor LoggerActor {
     // Private actor-isolated state
     private var configuration: LoggingConfiguration
     private var backend: LoggingBackend

     // Methods for async logging operations
     func logMessage(_ message: String, level: LogLevel, metadata: LogMetadataDTOCollection) async {
         // Thread-safe logging implementation
     }
 }

 // The public Logger class forwards to the isolated actor
 public class Logger: LoggerProtocol {
     private static let actor = LoggerActor()

     public static func info(_ message: @autoclosure () -> Any, metadata: LogMetadataDTOCollection? = nil) {
         Task {
             await actor.logMessage(String(describing: message()), level: .info, metadata: metadata ?? LogMetadataDTOCollection())
         }
     }
 }
 ```

 ## Privacy Considerations

 The logging system must properly handle sensitive information:
 - Use privacy annotations for sensitive data in logging calls
 - Support automatic redaction of personally identifiable information
 - Allow for different privacy behaviours between debug and release builds
 - Implement appropriate sanitisation of potentially sensitive data

 ## Isolation Pattern

 This protocol is part of the Logger Isolation Pattern implemented in UmbraCore.
 The pattern consists of:

 1. **LoggingWrapperInterfaces** - A module containing only interfaces (this module)
    - Contains no implementation details or third-party dependencies
    - Can be safely imported by any module requiring stability

 2. **LoggingWrapperServices** - The implementation module
    - Contains the actual logging implementation
    - Should only be imported by modules not requiring interface stability

 ## Usage

 Modules requiring stability should import `LoggingWrapperInterfaces` rather than
 directly importing implementation modules.

 ```swift
 import LoggingWrapperInterfaces

 func myFunction() {
     // Using the logger through the protocol
     Logger.info("User \(username, privacy: .public) accessed file \(filePath, privacy: .private)")
 }
 ```

 This pattern allows for the internal logging implementation to change without
 breaking compatibility of modules using logging functionality.
 */
import LoggingTypes

public protocol LoggerProtocol {
  /**
   Log a message at the critical level

   - Parameters:
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func critical(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message at the error level

   - Parameters:
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func error(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message at the warning level

   - Parameters:
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func warning(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message at the info level

   - Parameters:
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func info(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message at the debug level

   - Parameters:
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func debug(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message at the trace level

   - Parameters:
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func trace(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message at the specified level

   - Parameters:
     - level: The log level
     - message: The message to log
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func log(
    _ level: LogLevel,
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Log a message with privacy controls

   - Parameters:
     - level: The log level
     - message: The interpolated string containing privacy annotations
     - metadata: Additional context information for the log with privacy annotations
     - file: The file from which the log is sent
     - function: The function from which the log is sent
     - line: The line from which the log is sent
   */
  static func logPrivacy(
    _ level: LogLevel,
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String,
    function: String,
    line: Int
  )

  /**
   Configure the logger with the provided options

   - Parameter options: Configuration options for the logger
   */
  static func configure(_ options: LoggerConfiguration)

  /**
   Set the minimum log level

   - Parameter level: The minimum log level to record
   */
  static func setLogLevel(_ level: LogLevel)

  /**
   Flush any pending log entries

   Ensures all buffered log entries are written to their destinations
   */
  static func flush()
}

/**
 Default implementations for convenience methods
 */
extension LoggerProtocol {
  public static func critical(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    critical(message(), metadata: nil, file: file, function: function, line: line)
  }

  public static func error(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    error(message(), metadata: nil, file: file, function: function, line: line)
  }

  public static func warning(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    warning(message(), metadata: nil, file: file, function: function, line: line)
  }

  public static func info(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    info(message(), metadata: nil, file: file, function: function, line: line)
  }

  public static func debug(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    debug(message(), metadata: nil, file: file, function: function, line: line)
  }

  public static func trace(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    trace(message(), metadata: nil, file: file, function: function, line: line)
  }

  public static func log(
    _ level: LogLevel,
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(level, message(), metadata: nil, file: file, function: function, line: line)
  }
}

/**
 Dictionary type for structured log metadata
 */
// Note: Use LoggingTypes.LogMetadata directly instead of this typealias
// as per Alpha Dot Five architecture principles which discourage typealiases.

/**
 Configuration options for loggers
 */
public struct LoggerConfiguration: Sendable, Equatable {
  /// Standard configuration for most scenarios
  public static let standard=LoggerConfiguration()

  /// Minimum log level to record
  public let minimumLevel: LogLevel

  /// Whether to include source location information
  public let includeSourceLocation: Bool

  /// Whether to enable privacy redaction in logs
  public let privacyRedactionEnabled: Bool

  /// Whether to synchronously flush after each log message
  public let synchronousLogging: Bool

  /// Whether to capture and include thread information
  public let includeThreadInfo: Bool

  /// Maximum log file size in megabytes
  public let maxLogFileSizeMB: Int

  /// Maximum log file count to retain
  public let maxLogFileCount: Int

  /// Creates a new logger configuration
  public init(
    minimumLevel: LogLevel = .info,
    includeSourceLocation: Bool=true,
    privacyRedactionEnabled: Bool=true,
    synchronousLogging: Bool=false,
    includeThreadInfo: Bool=false,
    maxLogFileSizeMB: Int=10,
    maxLogFileCount: Int=5
  ) {
    self.minimumLevel=minimumLevel
    self.includeSourceLocation=includeSourceLocation
    self.privacyRedactionEnabled=privacyRedactionEnabled
    self.synchronousLogging=synchronousLogging
    self.includeThreadInfo=includeThreadInfo
    self.maxLogFileSizeMB=maxLogFileSizeMB
    self.maxLogFileCount=maxLogFileCount
  }

  /// Standard configuration for development environments
  public static var development: LoggerConfiguration {
    LoggerConfiguration(
      minimumLevel: .debug,
      includeSourceLocation: true,
      privacyRedactionEnabled: false,
      synchronousLogging: true,
      includeThreadInfo: true
    )
  }

  /// Standard configuration for production environments
  public static var production: LoggerConfiguration {
    LoggerConfiguration(
      minimumLevel: .info,
      includeSourceLocation: false,
      privacyRedactionEnabled: true,
      synchronousLogging: false,
      includeThreadInfo: false
    )
  }

  public static func == (lhs: LoggerConfiguration, rhs: LoggerConfiguration) -> Bool {
    lhs.minimumLevel == rhs.minimumLevel &&
      lhs.includeSourceLocation == rhs.includeSourceLocation &&
      lhs.privacyRedactionEnabled == rhs.privacyRedactionEnabled &&
      lhs.synchronousLogging == rhs.synchronousLogging &&
      lhs.includeThreadInfo == rhs.includeThreadInfo &&
      lhs.maxLogFileSizeMB == rhs.maxLogFileSizeMB &&
      lhs.maxLogFileCount == rhs.maxLogFileCount
  }
}

/**
 Log entry privacy level
 */
public enum LogPrivacyLevel: String, Sendable, Equatable {
  /// Public data that can be freely logged
  case `public`

  /// Private data that should be redacted in production
  case `private`

  /// Sensitive data that should always be redacted
  case sensitive

  /// Data that should be hashed rather than displayed directly
  case hash

  /// Data that should be automatically categorised
  case auto
}
