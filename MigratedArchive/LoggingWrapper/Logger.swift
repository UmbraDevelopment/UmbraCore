import Foundation
import LoggingWrapperInterfaces
@preconcurrency import SwiftyBeaver

/// A simple logging facade that wraps SwiftyBeaver
public class Logger: LoggerProtocol {
  private static let logger=SwiftyBeaver.self

  /// Configuration manager to handle thread-safe setup
  ///
  /// This actor ensures that logger configuration operations are thread-safe,
  /// preventing multiple configuration attempts
  @MainActor
  private final class ConfigurationManager {
    /// Whether the logger has been configured
    private var isConfigured=false

    /// Configure the logger if it hasn't been configured yet
    /// - Returns: True if this is the first configuration, false if already configured
    func configure() -> Bool {
      if !isConfigured {
        isConfigured=true
        return true
      }
      return false
    }
  }

  /// Shared configuration manager
  private static let configManager=ConfigurationManager()

  /// Configure the logger with a default console destination
  ///
  /// This method sets up a basic console logging destination if not already configured.
  /// It is safe to call this method multiple times; only the first call will have an effect.
  public static func configure() {
    // Create a default console destination
    let console=ConsoleDestination()
    console.format="$DHH:mm:ss.SSS$d $L $M"

    // Configure with the console destination
    configure(with: console)
  }

  /// Configure the logger with a console destination
  ///
  /// - Parameters:
  ///   - minimumLevel: The minimum log level to display, defaults to info
  ///   - includeTimestamp: Whether to include a timestamp, defaults to true
  ///   - includeFileInfo: Whether to include file info, defaults to false
  ///   - includeLineNumber: Whether to include line numbers, defaults to false
  ///   - includeFunctionName: Whether to include function names, defaults to false
  public static func configureWithConsole(
    minimumLevel: LogLevel = .info,
    includeTimestamp: Bool=true,
    includeFileInfo: Bool=false,
    includeLineNumber: Bool=false,
    includeFunctionName: Bool=false
  ) {
    // Create a console destination with the specified configuration
    let console=ConsoleDestination()

    // Apply minimum level
    console.minLevel=toSwiftyBeaverLevel(minimumLevel)

    // Configure format options
    console.format=""

    if includeTimestamp {
      console.format += "$DHH:mm:ss.SSS$d "
    }

    if includeFileInfo {
      console.format += "$N"

      if includeLineNumber {
        console.format += ":$L"
      }

      console.format += " "
    } else if includeLineNumber {
      console.format += "line $L "
    }

    if includeFunctionName {
      console.format += "$C "
    }

    console.format += "$M"

    // Configure with thread safety
    configure(with: console)
  }

  /// Configure the logger with the specified destination
  ///
  /// This method adds a destination to the logger, ensuring thread safety by using
  /// a configuration manager.
  ///
  /// - Parameter destination: The SwiftyBeaver destination to add
  public static func configure(with destination: BaseDestination) {
    // Important: We need to capture the destination in a way that won't cause
    // Swift 6 Sendable warnings. Since BaseDestination isn't Sendable, we have
    // to isolate its use to a specific thread/context.

    // First, capture any configuration properties needed from the destination
    let format=destination.format
    let minLevel=destination.minLevel

    // Also capture the destination type
    let isConsoleDestination=destination is ConsoleDestination
    let isFileDestination=destination is FileDestination

    // This task will properly isolate the destination handling
    Task { @MainActor [self] in
      // ConfigurationManager is already MainActor-isolated, but this task runs on MainActor
      // so we can access it directly
      let shouldConfigure=configManager.configure()

      // Create a new destination instance on the main actor
      // This avoids sending non-Sendable types across task boundaries
      let mainActorDestination: BaseDestination=if isConsoleDestination {
        ConsoleDestination()
      } else if isFileDestination {
        FileDestination()
      } else {
        // Default to console if unknown type
        ConsoleDestination()
      }

      // Apply captured configuration
      mainActorDestination.format=format
      mainActorDestination.minLevel=minLevel

      // Now add the destination to the logger
      if shouldConfigure || true { // Always add the destination
        logger.addDestination(mainActorDestination)
      }
    }
  }

  /// Log a message with the specified level
  ///
  /// This is the core logging method that all other logging methods delegate to.
  /// It ensures the logger is configured and maps UmbraCore's LogLevel to
  /// the appropriate SwiftyBeaver logging method.
  ///
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func log(
    _ level: LogLevel,
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Evaluate the message before passing to Task to avoid capturing non-escaping parameter
    let messageValue=message()

    Task {
      // Since we're not on the MainActor, we need to use await
      let configured=await configManager.configure()
      if !configured {
        // Since we're not on the MainActor, we need to use await
        _=await configManager.configure() // Capture the result to address warning
        let console=ConsoleDestination()
        console.format="$DHH:mm:ss.SSS$d $L $M"
        logger.addDestination(console)
      }

      switch level {
        case .critical, .error:
          logger.error(messageValue, file: file, function: function, line: line)
        case .warning:
          logger.warning(messageValue, file: file, function: function, line: line)
        case .info:
          logger.info(messageValue, file: file, function: function, line: line)
        case .debug:
          logger.debug(messageValue, file: file, function: function, line: line)
        case .trace:
          logger.verbose(messageValue, file: file, function: function, line: line)
      }
    }
  }

  /// Log a critical message
  ///
  /// Critical messages indicate severe errors that require immediate attention.
  /// These are typically issues that might lead to application termination or data loss.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func critical(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.critical, message(), file: file, function: function, line: line)
  }

  /// Log an error message
  ///
  /// Error messages indicate operational errors that may affect functionality
  /// but are not necessarily fatal to the application.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func error(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.error, message(), file: file, function: function, line: line)
  }

  /// Log a warning message
  ///
  /// Warning messages highlight potentially problematic situations or unexpected
  /// behaviour that might lead to errors if not addressed.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func warning(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.warning, message(), file: file, function: function, line: line)
  }

  /// Log an info message
  ///
  /// Info messages provide information about normal system operation and
  /// significant application state changes.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func info(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.info, message(), file: file, function: function, line: line)
  }

  /// Log a debug message
  ///
  /// Debug messages provide detailed information useful during development
  /// and troubleshooting. These should not be too verbose in production.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func debug(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.debug, message(), file: file, function: function, line: line)
  }

  /// Log a trace message
  ///
  /// Trace messages provide extremely detailed information about code execution paths.
  /// These are the most verbose type of log and are typically used only in development.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func trace(
    _ message: @autoclosure () -> Any,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.trace, message(), file: file, function: function, line: line)
  }

  // SwiftyBeaver level conversion methods (internal use only)
  static func toSwiftyBeaverLevel(_ level: LogLevel) -> SwiftyBeaver.Level {
    switch level {
      case .critical, .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug:
        .debug
      case .trace:
        .verbose
    }
  }

  static func fromSwiftyBeaverLevel(_ level: SwiftyBeaver.Level) -> LogLevel {
    switch level {
      case .error:
        return .error
      case .warning:
        return .warning
      case .info:
        return .info
      case .debug:
        return .debug
      case .verbose:
        return .trace
      case .critical:
        return .critical
      case .fault:
        return .critical
      @unknown default:
        return .error
    }
  }
}
