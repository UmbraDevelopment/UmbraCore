import FeaturesLoggingErrors
import FeaturesLoggingModels
import FeaturesLoggingProtocols
import Foundation
import SecurityTypes
import SwiftyBeaver

/// A logging service implementation using SwiftyBeaver
public actor LoggingWrapperService: LoggingProtocol {
  private var isInitialized=false
  private var logFilePath: String?
  private let logger=SwiftyBeaver.self

  public init() {}

  /// Initialize the logging service
  /// - Parameter path: Path to the log file
  public func initialize(with path: String) async throws {
    guard !isInitialized else { return }

    // Create log directory if it doesn't exist
    let directoryPath=(path as NSString).deletingLastPathComponent
    do {
      try FileManager.default.createDirectory(
        atPath: directoryPath,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      throw LoggingError.directoryCreationFailed(path: directoryPath)
    }

    // Configure SwiftyBeaver logger with console and file destinations
    let console=ConsoleDestination()
    console.format="$DHH:mm:ss.SSS$d $L $M"
    logger.addDestination(console)

    // Add file destination if path is provided
    let file=FileDestination()
    file.logFileURL=URL(fileURLWithPath: path)
    file.format="$Dyyyy-MM-dd HH:mm:ss.SSS$d [$L] $M"
    file.logFileMaxSize=10 * 1024 * 1024 // 10MB
    file.logFileAmount=10 // Keep up to 10 log files
    logger.addDestination(file)

    // Store the path for reference
    logFilePath=path
    isInitialized=true

    // Log initialization success
    logger.info("Logging initialized to path: \(path)")
  }

  public func log(_ entry: LogEntry) async throws {
    guard isInitialized else {
      throw LoggingError.initializationFailed(reason: "Logging service not initialized")
    }

    guard !entry.message.isEmpty else {
      throw LoggingError.writeError(reason: "Log message cannot be empty")
    }

    let message=entry.metadata?.isEmpty == false ? "\(entry.message) | \(entry.metadata!)" : entry
      .message

    switch entry.level {
      case .debug:
        logger.debug(message)
      case .info:
        logger.info(message)
      case .warning:
        logger.warning(message)
      case .error:
        logger.error(message)
      @unknown default:
        logger.warning("Unknown log level for message: \(message)")
    }
  }

  /// Get the current log file path
  public func getLogFilePath() -> String? {
    logFilePath
  }

  public func stop() async {
    // Remove all destinations
    logger.removeAllDestinations()
    isInitialized=false
    logFilePath=nil
  }
}
