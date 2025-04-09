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
    await printLog(level: .trace, message: message, metadata: metadata, source: source)
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
  public func warning(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    await printLog(level: .warning, message: message, metadata: metadata, source: source)
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
  public func critical(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    await printLog(level: .critical, message: message, metadata: metadata, source: source)
  }

  // MARK: - Legacy LoggingProtocol Methods

  /**
   Log a trace message (deprecated method).
   
   - Parameters:
     - message: The message to log
     - metadata: Legacy metadata dictionary
     - source: The source of the log message
   */
  @available(*, deprecated, message: "Use trace(_:metadata:source:) with LogMetadataDTOCollection instead")
  public func trace(_ message: String, metadata _: LogMetadata? = nil, source: String) async {
    await printLog(level: .trace, message: message, metadata: nil, source: source)
  }

  /**
   Log a debug message (deprecated method).
   
   - Parameters:
     - message: The message to log
     - metadata: Legacy metadata dictionary
     - source: The source of the log message
   */
  @available(*, deprecated, message: "Use debug(_:metadata:source:) with LogMetadataDTOCollection instead")
  public func debug(_ message: String, metadata _: LogMetadata? = nil, source: String) async {
    await printLog(level: .debug, message: message, metadata: nil, source: source)
  }

  /**
   Log an info message (deprecated method).
   
   - Parameters:
     - message: The message to log
     - metadata: Legacy metadata dictionary
     - source: The source of the log message
   */
  @available(*, deprecated, message: "Use info(_:metadata:source:) with LogMetadataDTOCollection instead")
  public func info(_ message: String, metadata _: LogMetadata? = nil, source: String) async {
    await printLog(level: .info, message: message, metadata: nil, source: source)
  }

  /**
   Log a warning message (deprecated method).
   
   - Parameters:
     - message: The message to log
     - metadata: Legacy metadata dictionary
     - source: The source of the log message
   */
  @available(*, deprecated, message: "Use warning(_:metadata:source:) with LogMetadataDTOCollection instead")
  public func warning(_ message: String, metadata _: LogMetadata? = nil, source: String) async {
    await printLog(level: .warning, message: message, metadata: nil, source: source)
  }

  /**
   Log an error message (deprecated method).
   
   - Parameters:
     - message: The message to log
     - metadata: Legacy metadata dictionary
     - source: The source of the log message
   */
  @available(*, deprecated, message: "Use error(_:metadata:source:) with LogMetadataDTOCollection instead")
  public func error(_ message: String, metadata _: LogMetadata? = nil, source: String) async {
    await printLog(level: .error, message: message, metadata: nil, source: source)
  }

  /**
   Log a critical message (deprecated method).
   
   - Parameters:
     - message: The message to log
     - metadata: Legacy metadata dictionary
     - source: The source of the log message
   */
  @available(*, deprecated, message: "Use critical(_:metadata:source:) with LogMetadataDTOCollection instead")
  public func critical(_ message: String, metadata _: LogMetadata? = nil, source: String) async {
    await printLog(level: .critical, message: message, metadata: nil, source: source)
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
    await printLog(level: level, message: message, metadata: context.metadata, source: context.getSource())
  }

  // MARK: - Private Helper Methods

  /**
   Helper to print a log message to the console with privacy-aware metadata.
   
   - Parameters:
     - level: The log level
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  private func printLog(level: LoggingTypes.LogLevel, message: String, metadata: LogMetadataDTOCollection?, source: String) async {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let levelString = levelToString(level).uppercased()
    
    // Format metadata with privacy controls if present
    var metadataString = ""
    if let metadata = metadata, !metadata.entries.isEmpty {
      metadataString = " " + formatMetadataCollection(metadata)
    }
    
    print("\(timestamp) [\(source)] [\(levelString)]: \(message)\(metadataString)")
  }

  /**
   Format metadata collection with privacy controls.
   
   - Parameter metadata: The metadata collection to format
   - Returns: A formatted string representation of the metadata
   */
  private func formatMetadataCollection(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String] = []

    for entry in metadata.entries {
      let key = entry.key
      let value = entry.value
      let privacyLevel = entry.privacyLevel

      // Format based on privacy level
      let formattedValue: String

      switch privacyLevel {
        case .public:
          // Public data can be shown as-is
          formattedValue = "\(key): \(value)"

        case .private:
          // In debug builds, show private data with a marker
          #if DEBUG
            formattedValue = "\(key): 🔒[\(value)]"
          #else
            formattedValue = "\(key): 🔒[REDACTED]"
          #endif

        case .sensitive:
          // Sensitive data is always redacted, even in debug builds
          formattedValue = "\(key): 🔐[REDACTED]"

        case .hash:
          // Hash values are shown with a special marker
          formattedValue = "\(key): 🔢[\(value)]"
      }

      parts.append(formattedValue)
    }

    return "{" + parts.joined(separator: ", ") + "}"
  }

  /**
   Convert LogLevel to string representation.
   
   - Parameter level: The log level to convert
   - Returns: A string representation of the log level
   */
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

/**
 Create a default logger for the KeychainServices module.
 
 - Returns: A privacy-aware logger suitable for keychain operations
 */
public func createKeychainLogger() -> LoggingProtocol {
  KeychainDefaultLogger()
}
