import LoggingWrapperInterfaces
@preconcurrency import SwiftyBeaver

/// A simple logging facade that wraps SwiftyBeaver
public class Logger: LoggerProtocol {
  private static let logger = SwiftyBeaver.self

  /// Configuration manager to handle thread-safe setup
  ///
  /// This actor ensures that logger configuration operations are thread-safe,
  /// preventing multiple configuration attempts
  @MainActor
  private final class ConfigurationManager {
    /// Whether the logger has been configured
    private var isConfigured = false

    /// Configure the logger if it hasn't been configured yet
    /// - Returns: True if this is the first configuration, false if already configured
    func configure() -> Bool {
      if !isConfigured {
        isConfigured = true
        return true
      }
      return false
    }
  }

  /// Shared configuration manager
  private static let configManager = ConfigurationManager()

  /// Configure the logger with a default console destination
  ///
  /// This method sets up a basic console logging destination if not already configured.
  /// It is safe to call this method multiple times; only the first call will have an effect.
  public static func configure() {
    // Create a default console destination
    let console = ConsoleDestination()
    console.format = "$DHH:mm:ss.SSS$d $L $M"

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
  public static func configureConsole(
    minimumLevel: LogLevel = .info,
    includeTimestamp: Bool = true,
    includeFileInfo: Bool = false,
    includeLineNumber: Bool = false
  ) {
    // Create the console destination
    let console = ConsoleDestination()

    // Configure the format based on parameters
    var format = ""
    if includeTimestamp {
      format += "$DHH:mm:ss.SSS$d "
    }
    format += "$L "
    if includeFileInfo {
      format += "$N.$F"
      if includeLineNumber {
        format += ":$l"
      }
      format += " "
    }
    format += "$M"
    console.format = format

    // Set minimum level
    console.minLevel = mapLogLevel(minimumLevel)

    // Configure the logger
    configure(with: console)
  }

  /// Configure the logger with a custom destination
  ///
  /// - Parameter destination: The log destination
  public static func configure(with destination: BaseDestination) {
    Task { @MainActor in
      // Only proceed if this is the first configuration
      if await configManager.configure() {
        // Add destination to logger
        logger.addDestination(destination)
      }
    }
  }

  /// Map our LogLevel enum to SwiftyBeaver's level
  /// - Parameter level: Our LogLevel
  /// - Returns: SwiftyBeaver's level
  private static func mapLogLevel(_ level: LogLevel) -> SwiftyBeaver.Level {
    switch level {
    case .critical:
      return .error
    case .error:
      return .error
    case .warning:
      return .warning
    case .info:
      return .info
    case .debug:
      return .debug
    case .trace:
      return .verbose
    }
  }

  /// Log a message at the specified level
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func log(
    _ level: LogLevel,
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    let swiftyLevel = mapLogLevel(level)
    logger.custom(level: swiftyLevel, message: message(), file: file, function: function, line: line)
  }

  /// Log a message at the critical level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func critical(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.critical, message(), file: file, function: function, line: line)
  }

  /// Log a message at the error level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func error(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.error, message(), file: file, function: function, line: line)
  }

  /// Log a message at the warning level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func warning(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.warning, message(), file: file, function: function, line: line)
  }

  /// Log a message at the info level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func info(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.info, message(), file: file, function: function, line: line)
  }

  /// Log a message at the debug level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func debug(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.debug, message(), file: file, function: function, line: line)
  }

  /// Log a message at the trace level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  public static func trace(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.trace, message(), file: file, function: function, line: line)
  }
}
