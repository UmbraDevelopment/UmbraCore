import Foundation
import LoggingInterfaces
import LoggingTypes

/// Factory for creating configured logger instances
public enum LoggerFactory {
  /// Create a standard console logger
  /// - Parameters:
  ///   - source: Source identifier for logs
  ///   - minimumLogLevel: Minimum log level to process
  /// - Returns: A configured logger instance
  public static func createConsoleLogger(
    source: String="default",
    minimumLogLevel: LogLevel = .info
  ) async -> LoggingProtocol {
    // Create a standard console log destination
    let consoleDestination=ConsoleLogDestination(
      identifier: "console",
      minimumLogLevel: minimumLogLevel
    )

    // Create the logging actor with the console destination
    let loggingActor=LoggingActor(
      destinations: [consoleDestination],
      minimumLogLevel: minimumLogLevel
    )

    // Return a configured logger
    return ActorLogger(loggingActor: loggingActor, defaultSource: source)
  }

  /// Create a privacy-aware console logger
  /// - Parameters:
  ///   - source: Source identifier for logs
  ///   - minimumLogLevel: Minimum log level to process
  ///   - privacyFilterEnabled: Whether to enable privacy filtering
  /// - Returns: A configured logger instance
  public static func createPrivacyAwareLogger(
    source: String="default",
    minimumLogLevel: LogLevel = .info,
    privacyFilterEnabled: Bool=true
  ) async -> LoggingProtocol {
    // Create a standard console log destination
    let consoleDestination=ConsoleLogDestination(
      identifier: "console",
      minimumLogLevel: minimumLogLevel
    )

    // Create a privacy-filtered log destination if enabled
    var destinations: [any ActorLogDestination]=[consoleDestination]

    if privacyFilterEnabled {
      let privacyConsole=PrivacyFilteredConsoleDestination(
        identifier: "privacy_console",
        minimumLogLevel: minimumLogLevel
      )
      destinations.append(privacyConsole)
    }

    // Create the logging actor with the destinations
    let loggingActor=LoggingActor(
      destinations: destinations,
      minimumLogLevel: minimumLogLevel
    )

    // Return a configured logger
    return ActorLogger(loggingActor: loggingActor, defaultSource: source)
  }

  /// Create a file-based logger
  /// - Parameters:
  ///   - fileURL: URL of the log file
  ///   - source: Source identifier for logs
  ///   - minimumLogLevel: Minimum log level to process
  ///   - includeConsole: Whether to also log to console
  /// - Returns: A configured logger instance
  public static func createFileLogger(
    fileURL: URL,
    source: String="default",
    minimumLogLevel: LogLevel = .info,
    includeConsole: Bool=true
  ) async -> LoggingProtocol {
    var destinations: [any ActorLogDestination]=[]

    // Add file destination
    let fileDestination=FileLogDestination(
      fileURL: fileURL,
      identifier: "file",
      minimumLogLevel: minimumLogLevel
    )
    destinations.append(fileDestination)

    // Add console destination if requested
    if includeConsole {
      let consoleDestination=ConsoleLogDestination(
        identifier: "console",
        minimumLogLevel: minimumLogLevel
      )
      destinations.append(consoleDestination)
    }

    let loggingActor=LoggingActor(
      destinations: destinations,
      minimumLogLevel: minimumLogLevel
    )

    return ActorLogger(loggingActor: loggingActor, defaultSource: source)
  }
}
