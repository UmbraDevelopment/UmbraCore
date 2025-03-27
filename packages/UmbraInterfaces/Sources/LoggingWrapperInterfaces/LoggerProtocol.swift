/// Protocol defining the standard logging interface for UmbraCore
///
/// This protocol provides a stable API for logging operations across the codebase,
/// decoupling client code from the specific logging implementation.
///
/// ## Isolation Pattern
///
/// This protocol is part of the Logger Isolation Pattern implemented in UmbraCore.
/// The pattern consists of:
///
/// 1. **LoggingWrapperInterfaces** - A module containing only interfaces (this module)
///    - Contains no implementation details or third-party dependencies
///    - Can be safely imported by any module requiring stability
///
/// 2. **LoggingWrapperServices** - The implementation module
///    - Contains the actual logging implementation
///    - Should only be imported by modules not requiring interface stability
///
/// ## Usage
///
/// Modules requiring stability should import `LoggingWrapperInterfaces` rather than
/// directly importing implementation modules.
///
/// ```swift
/// import LoggingWrapperInterfaces
///
/// func myFunction() {
///     // Using the logger through the protocol
///     Logger.info("This is an informational message")
/// }
/// ```
///
/// This pattern allows for the internal logging implementation to change without
/// breaking compatibility of modules using logging functionality.
public protocol LoggerProtocol {
  /// Log a message at the critical level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func critical(
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )

  /// Log a message at the error level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func error(
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )

  /// Log a message at the warning level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func warning(
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )

  /// Log a message at the info level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func info(
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )

  /// Log a message at the debug level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func debug(
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )

  /// Log a message at the trace level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func trace(
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )

  /// Log a message at the specified level
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - file: The file from which the log is sent
  ///   - function: The function from which the log is sent
  ///   - line: The line from which the log is sent
  static func log(
    _ level: LogLevel,
    _ message: @autoclosure () -> Any,
    file: String,
    function: String,
    line: Int
  )
}
