import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog

/**
 # Keychain Default Logger

 A simple logger implementation for the KeychainServices module.

 This logger provides a basic, standalone implementation of LoggingProtocol
 that can be used when a full logging service isn't needed or available.
 It follows the Alpha Dot Five architecture principles.

 ## Privacy Controls

 This logger implements comprehensive privacy controls for sensitive information:
 - Public information is logged normally
 - Private information is redacted in production builds
 - Sensitive information is always redacted

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in logging operations.
 */
public actor KeychainDefaultLogger: LoggingProtocol {

  // MARK: - Properties

  /// Dummy logging actor implementation to satisfy protocol requirements
  public var loggingActor: LoggingActor {
    fatalError("LoggingActor not implemented in KeychainDefaultLogger")
  }

  // MARK: - Initialisation

  public init() {}

  // MARK: - LoggingProtocol Methods with LogMetadataDTOCollection

  /**
   Log a trace message with privacy-aware metadata.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func trace(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    await printLog(level: .debug, message: message, metadata: metadata, source: source)
  }

  /**
   Log a debug message with privacy-aware metadata.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func debug(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    await printLog(level: .debug, message: message, metadata: metadata, source: source)
  }

  /**
   Log an info message with privacy-aware metadata.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func info(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    await printLog(level: .info, message: message, metadata: metadata, source: source)
  }

  /**
   Log a warning message with privacy-aware metadata.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func warning(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String
  ) async {
    await printLog(level: .error, message: message, metadata: metadata, source: source)
  }

  /**
   Log an error message with privacy-aware metadata.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func error(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    await printLog(level: .error, message: message, metadata: metadata, source: source)
  }

  /**
   Log a critical message with privacy-aware metadata.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func critical(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String
  ) async {
    await printLog(level: .fault, message: message, metadata: metadata, source: source)
  }

  // MARK: - Private Helper Methods

  /**
   Print a log message with the specified level and metadata.

   - Parameters:
     - level: The log level
     - message: The message to log
     - metadata: The privacy-aware metadata collection
     - source: The source of the log message
   */
  private func printLog(
    level: OSLogType,
    message: String,
    metadata: LogMetadataDTOCollection?,
    source: String
  ) async {
    let logger=Logger(subsystem: "com.umbra.keychainservices", category: source)

    // Format metadata if available
    var metadataString=""
    if let metadata, !metadata.entries.isEmpty {
      metadataString=" " + formatMetadata(metadata)
    }

    // Log with appropriate level
    let formattedMessage="[\(source)] \(message)\(metadataString)"
    switch level {
      case .debug:
        logger.debug("\(formattedMessage, privacy: .public)")
      case .info:
        logger.info("\(formattedMessage, privacy: .public)")
      case .error:
        logger.error("\(formattedMessage, privacy: .public)")
      case .fault:
        logger.critical("\(formattedMessage, privacy: .public)")
      default:
        logger.log("\(formattedMessage, privacy: .public)")
    }
  }

  /**
   Format metadata as a string with privacy controls.

   - Parameter metadata: The privacy-aware metadata collection
   - Returns: A formatted string representation of the metadata
   */
  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String]=[]

    for entry in metadata.entries {
      // Format based on privacy level
      let value=switch entry.privacyLevel {
        case .public:
          entry.value
        case .private:
          #if DEBUG
            entry.value
          #else
            "<private>"
          #endif
        case .sensitive:
          #if DEBUG
            "<sensitive: \(entry.value)>"
          #else
            "<sensitive>"
          #endif
        case .hash:
          "<hashed>"
        case .auto:
          "<auto-redacted>"
      }

      parts.append("\(entry.key)=\(value)")
    }

    return "{\(parts.joined(separator: ", "))}"
  }

  /**
   Implementation of CoreLoggingProtocol.

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: The context for the log entry
   */
  public func log(_ level: LoggingTypes.LogLevel, _ message: String, context: LogContextDTO) async {
    // Using context.source and context.metadata
    await printLog(
      level: levelToOSLogType(level),
      message: message,
      metadata: context.metadata,
      source: context.getSource()
    )
  }

  /**
   Convert LogLevel to OSLogType.

   - Parameter level: The log level to convert
   - Returns: An OSLogType representation of the log level
   */
  private func levelToOSLogType(_ level: LoggingTypes.LogLevel) -> OSLogType {
    switch level {
      case .trace: return .debug
      case .debug: return .debug
      case .info: return .info
      case .warning: return .error
      case .error: return .error
      case .critical: return .fault
      @unknown default: return .default
    }
  }
}

/**
 Create a default logger for the KeychainServices module.

 - Returns: A privacy-aware logger suitable for keychain operations
 */
public func createKeychainLogger() -> LoggingProtocol {
  KeychainDefaultLogger()
}
