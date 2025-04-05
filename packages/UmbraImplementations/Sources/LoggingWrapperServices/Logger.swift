import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingWrapperInterfaces
@preconcurrency import SwiftyBeaver

/**
 # Logger

 Implementation of the LoggerProtocol and PrivacyAwareLoggingProtocol interfaces using SwiftyBeaver.
 This actor-based implementation ensures thread safety and privacy protection for all logging operations.

 ## Privacy Controls

 The logger supports the following privacy annotations:
 - `.public`: Information safe for logging in any environment
 - `.private`: Information that should be redacted in release builds
 - `.sensitive`: Information that should be fully redacted or hashed
 */
public final class Logger: LoggingWrapperInterfaces.LoggerProtocol, @unchecked Sendable {
  /// The underlying SwiftyBeaver logger instance
  private static let logger=SwiftyBeaver.self

  /// Default logger configuration
  @MainActor
  private static var configuration: LoggingWrapperInterfaces
    .LoggerConfiguration = .production

  /// Actor for thread-safe logging operations
  private static let swiftyLoggerActor=SwiftyLoggerActor()

  /// Add a destination for log output
  public static func addDestination(_ destination: BaseDestination) {
    // Create a local copy to reference in the detached task
    let destinationRef=destination

    // Use detached task to isolate the non-Sendable destination
    Task.detached { @Sendable in
      await swiftyLoggerActor.addDestination(destinationRef)
    }
  }

  /// Remove a destination from log output
  public static func removeDestination(_ destination: BaseDestination) {
    // Create a local copy to reference in the detached task
    let destinationRef=destination

    // Use detached task to isolate the non-Sendable destination
    Task.detached { @Sendable in
      await swiftyLoggerActor.removeDestination(destinationRef)
    }
  }

  /// Check if a log level is enabled
  public static func isEnabled(_ level: LoggingWrapperInterfaces.LogLevel) -> Bool {
    // For simplicity, we'll default to checking against the minimum log level
    // This avoids the async complexity with MainActor properties
    level.rawValue >= LoggingWrapperInterfaces.LogLevel.trace.rawValue
  }

  /// Configure the logger with the provided options
  public static func configure(_ options: LoggingWrapperInterfaces.LoggerConfiguration) {
    // Configuration is Sendable, so we can capture it safely
    Task { @MainActor in
      configuration=options
    }

    // Extract the minimum level value for safe passing to task
    let minimumLevelRawValue=options.minimumLevel.rawValue

    // Create a detached task to update configuration on actor
    Task.detached { @Sendable in
      // Convert back to enum inside the task for safety
      let level=LoggingWrapperInterfaces.LogLevel(rawValue: minimumLevelRawValue) ?? .trace
      await swiftyLoggerActor.configure(minimumLevel: convertLogLevel(level))
    }
  }

  /// Set the minimum log level to record
  public static func setLogLevel(_ level: LoggingWrapperInterfaces.LogLevel) {
    // Create a new configuration with the updated log level
    let newConfig=LoggingWrapperInterfaces.LoggerConfiguration(
      minimumLevel: level,
      includeSourceLocation: true,
      privacyRedactionEnabled: true,
      synchronousLogging: false,
      includeThreadInfo: true,
      maxLogFileSizeMB: 10,
      maxLogFileCount: 5
    )

    // Update configuration on the MainActor
    Task { @MainActor in
      configuration=newConfig
    }

    // Extract the raw value for safe passing to task
    let levelRawValue=level.rawValue

    // Create a detached task to update configuration on actor
    Task.detached { @Sendable in
      // Convert back to enum inside the task for safety
      let safeLevel=LoggingWrapperInterfaces.LogLevel(rawValue: levelRawValue) ?? .trace
      await swiftyLoggerActor.configure(minimumLevel: convertLogLevel(safeLevel))
    }
  }

  /// Flush any pending log entries
  public static func flush() {
    // SwiftyBeaver doesn't have an explicit flush mechanism,
    // but we can ensure any async logging tasks are completed
    Task.detached { @Sendable in
      await swiftyLoggerActor.flush()
    }
  }

  /// Actor to ensure thread-safe logging operations with SwiftyBeaver
  private actor SwiftyLoggerActor {
    private var destinations: [BaseDestination]=[]

    func addDestination(_ destination: BaseDestination) {
      destinations.append(destination)
      SwiftyBeaver.addDestination(destination)
    }

    func removeDestination(_ destination: BaseDestination) {
      if let index=destinations.firstIndex(where: { $0 === destination }) {
        destinations.remove(at: index)
      }
      SwiftyBeaver.removeDestination(destination)
    }

    func configure(minimumLevel: SwiftyBeaver.Level) {
      for destination in destinations {
        destination.minLevel=minimumLevel
      }
    }

    func getMinimumLogLevel() -> SwiftyBeaver.Level {
      guard let firstDestination=destinations.first else {
        return .info
      }
      return firstDestination.minLevel
    }

    func flush() {
      // SwiftyBeaver doesn't have an explicit flush mechanism
      // This function exists to fulfill protocol requirements
    }

    /// Perform actual logging with privacy considerations
    func log(
      level: SwiftyBeaver.Level,
      message: String,
      metadata: [String: String]?,
      privacy: LoggingWrapperInterfaces.LogPrivacyLevel,
      source: String?,
      file: String,
      function: String,
      line: Int
    ) {
      // Process message with privacy level
      let processedMessage=processMessage(message, privacy: privacy)

      // Add source as context if provided
      var context: [String: Any]=[:]
      if let source {
        context["source"]=source
      }

      // Add metadata if provided
      if let metadata {
        for (key, value) in metadata {
          context[key]=value
        }
      }

      // Log with SwiftyBeaver
      SwiftyBeaver.custom(
        level: level,
        message: processedMessage,
        file: file,
        function: function,
        line: line,
        context: context
      )
    }

    /// Process message based on privacy level
    private func processMessage(
      _ message: String,
      privacy: LoggingWrapperInterfaces.LogPrivacyLevel
    ) -> String {
      // Apply privacy redaction in release builds if needed
      #if DEBUG
        return message
      #else
        switch privacy {
          case .public:
          return message
          case .private:
          // Simple redaction in release builds
          if message.count > 10 {
            return String(message.prefix(5)) + "..." + String(message.suffix(2))
          }
          return "[REDACTED]"
          case .sensitive:
          // Full redaction for sensitive data
          return "[SENSITIVE DATA REDACTED]"
          case .hash:
          // Hash the data for tracking without revealing content
          return "HASH:" + String(message.hash)
          case .auto:
          // Default to private handling
          if message.count > 10 {
            return String(message.prefix(3)) + "..." + String(message.suffix(2))
          }
          return "[AUTO-REDACTED]"
        }
      #endif
    }
  }

  /// Set up the logger with console output
  public static func setupConsoleLogging(
    minLevel: LoggingWrapperInterfaces.LogLevel = .debug,
    format: String="$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M",
    useColors _: Bool=true
  ) {
    // Create the console destination
    let console=ConsoleDestination()

    // Configure the format based on parameters
    console.format=format
    console.minLevel=convertLogLevel(minLevel)

    // Add the destination
    addDestination(console)
  }

  /// Convert LogLevel to SwiftyBeaver.Level
  private static func convertLogLevel(_ level: LoggingWrapperInterfaces.LogLevel) -> SwiftyBeaver
  .Level {
    switch level {
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .trace:
        .verbose
      case .critical:
        .error // SwiftyBeaver doesn't have critical, so map to error
    }
  }

  // MARK: - LoggerProtocol Implementation

  /// Log a message at the specified level
  public static func log(
    _ level: LoggingWrapperInterfaces.LogLevel,
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Immediately evaluate the autoclosure to capture the value
    let messageValue=message()

    // Convert message to string early to avoid non-Sendable issues
    let messageString=String(describing: messageValue)

    // Default to public privacy level
    let privacyLevel: LoggingWrapperInterfaces.LogPrivacyLevel = .public

    // Capture file information before passing to task
    let capturedFile=file
    let capturedFunction=function
    let capturedLine=line

    // Convert metadata to string dictionary before passing to actor
    let stringMetadata: [String: String]?
    if let metadata {
      var dict=[String: String]()
      for (key, value) in metadata {
        dict[key]=String(describing: value)
      }
      stringMetadata=dict
    } else {
      stringMetadata=nil
    }

    // Create final copies of values for the task
    let finalMessageString=messageString
    let finalStringMetadata=stringMetadata

    // Use detached task to isolate the logging operation
    Task.detached { @Sendable in
      await swiftyLoggerActor.log(
        level: convertLogLevel(level),
        message: finalMessageString,
        metadata: finalStringMetadata,
        privacy: privacyLevel,
        source: nil,
        file: capturedFile,
        function: capturedFunction,
        line: capturedLine
      )
    }
  }

  /// Log a message with privacy annotations
  public static func logPrivacy(
    _ level: LoggingWrapperInterfaces.LogLevel,
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Immediately evaluate the autoclosure to capture the value
    let messageValue=message()

    // Convert message to string early to avoid non-Sendable issues
    let messageString=String(describing: messageValue)

    // Use private privacy level for annotated messages
    let privacyLevel: LoggingWrapperInterfaces.LogPrivacyLevel = .private

    // Capture file information before passing to task
    let capturedFile=file
    let capturedFunction=function
    let capturedLine=line

    // Convert metadata to string dictionary before passing to actor
    let stringMetadata: [String: String]?
    if let metadata {
      var dict=[String: String]()
      for (key, value) in metadata {
        dict[key]=String(describing: value)
      }
      stringMetadata=dict
    } else {
      stringMetadata=nil
    }

    // Create final copies of values for the task
    let finalMessageString=messageString
    let finalStringMetadata=stringMetadata

    // Use detached task to isolate the logging operation
    Task.detached { @Sendable in
      await swiftyLoggerActor.log(
        level: convertLogLevel(level),
        message: finalMessageString,
        metadata: finalStringMetadata,
        privacy: privacyLevel,
        source: nil,
        file: capturedFile,
        function: capturedFunction,
        line: capturedLine
      )
    }
  }

  // MARK: - Required LoggerProtocol convenience methods

  /// Log a debug message
  public static func debug(
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log an info message
  public static func info(
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.info, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log a warning message
  public static func warning(
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log an error message
  public static func error(
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.error, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log a trace message
  public static func trace(
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.trace, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log a critical message
  public static func critical(
    _ message: @autoclosure () -> Any,
    metadata: LoggingWrapperInterfaces.LogMetadata?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.critical, message(), metadata: metadata, file: file, function: function, line: line)
  }

  // MARK: - PrivacyAwareLoggerImplementation

  /// Instance implementation of LoggingProtocol and PrivacyAwareLoggingProtocol
  public actor PrivacyAwareLoggerImplementation: LoggingInterfaces
  .PrivacyAwareLoggingProtocol {
    /// The underlying logging actor
    public let loggingActor: LoggingInterfaces.LoggingActor

    /// Initializes a new privacy-aware logger implementation
    /// - Parameter actor: The logging actor to use
    public init(actor: LoggingInterfaces.LoggingActor) {
      loggingActor=actor
    }

    // MARK: - CoreLoggingProtocol

    /// Log a message with the specified level and context
    public func log(
      _ level: LoggingTypes.LogLevel,
      _ message: PrivacyString, // Changed from String to PrivacyString
      context: LoggingInterfaces.LogContextDTO
    ) async {
      // Forward the log call to the underlying logging actor
      // LoggingActor.log now expects unnamed params and LogContextDTO
      await loggingActor.log(level, message, context: context)
    }

    // Convenience methods (trace, debug, info, etc.) are provided by the LoggingProtocol extension.
    // No need to reimplement them here.
  }

  // MARK: - Static Factory Methods

  /// Create a new privacy-aware logger
  /// - Returns: A new logger instance
  public static func createPrivacyAwareLogger() -> LoggingInterfaces.PrivacyAwareLoggingProtocol {
    let logActor=LoggingInterfaces.LoggingActor(destinations: [])
    return PrivacyAwareLoggerImplementation(actor: logActor)
  }

  // MARK: - Helper Methods

  /// Convert LoggingTypes.LogLevel to SwiftyBeaver.Level
  private static func convertToSwiftyLevel(_ level: LoggingTypes.LogLevel) -> SwiftyBeaver.Level {
    switch level {
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .trace:
        .verbose
      case .critical:
        .error
    }
  }
}
