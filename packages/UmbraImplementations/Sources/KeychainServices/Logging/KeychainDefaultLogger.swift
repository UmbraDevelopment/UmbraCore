import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog

/**
 A simple logger implementation for the KeychainServices module.

 This logger provides a basic, standalone implementation of LoggingProtocol
 that can be used when a full logging service isn't needed or available.
 It follows the Alpha Dot Five architecture principles.
 */
public actor KeychainDefaultLogger: LoggingProtocol {

  // MARK: - Properties

  /// Dummy logging actor implementation to satisfy protocol requirements
  public var loggingActor: LoggingActor {
    fatalError("LoggingActor not implemented in KeychainDefaultLogger")
  }

  // MARK: - Initialisation

  public init() {}

  // MARK: - LoggingProtocol Methods

  /// Log a trace message
  public func trace(_ message: String, metadata _: LogMetadata?=nil, source: String) async {
    await printLog(level: .trace, message: message, source: source)
  }

  /// Log a debug message
  public func debug(_ message: String, metadata _: LogMetadata?=nil, source: String) async {
    await printLog(level: .debug, message: message, source: source)
  }

  /// Log an info message
  public func info(_ message: String, metadata _: LogMetadata?=nil, source: String) async {
    await printLog(level: .info, message: message, source: source)
  }

  /// Log a warning message
  public func warning(_ message: String, metadata _: LogMetadata?=nil, source: String) async {
    await printLog(level: .warning, message: message, source: source)
  }

  /// Log an error message
  public func error(_ message: String, metadata _: LogMetadata?=nil, source: String) async {
    await printLog(level: .error, message: message, source: source)
  }

  /// Log a critical message
  public func critical(_ message: String, metadata _: LogMetadata?=nil, source: String) async {
    await printLog(level: .critical, message: message, source: source)
  }

  /// Implementation of CoreLoggingProtocol
  public func log(_ level: LoggingTypes.LogLevel, _ message: String, context: LogContextDTO) async {
    // Using context.source and context.domainName (or a default if needed)
    await printLog(level: level, message: message, source: context.source ?? "UnknownSource")
  }

  // MARK: - Private Helper Methods

  /// Helper to print a log message to the console
  private func printLog(level: LoggingTypes.LogLevel, message: String, source: String) async {
    let timestamp=ISO8601DateFormatter().string(from: Date())
    let levelString=levelToString(level).uppercased()
    print("\(timestamp) [\(source)] [\(levelString)]: \(message)")
  }

  /// Convert LogLevel to string representation
  private func levelToString(_ level: LoggingTypes.LogLevel) -> String {
    switch level {
      case .trace: return "TRACE"
      case .debug: return "DEBUG"
      case .info: return "INFO"
      case .warning: return "WARNING"
      case .error: return "ERROR"
      case .critical: return "CRITICAL"
      @unknown default: return "UNKNOWN"
    }
  }
}

/// Create a default logger for the KeychainServices module
public func createKeychainLogger() -> LoggingProtocol {
  KeychainDefaultLogger()
}
