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
public actor Logger: LoggingWrapperInterfaces.LoggerProtocol, @unchecked Sendable {
  /// The underlying SwiftyBeaver logger instance
  private let logger=SwiftyBeaver.self

  /// Singleton actor instance for static method delegation
  private static let shared=Logger()

  /// Current logger configuration
  private var configuration: LoggingWrapperInterfaces.LoggerConfiguration = .production

  /// Collection of active logging destinations
  private var destinations: [BaseDestination]=[]

  /// Private initialiser to enforce singleton pattern for static access
  private init() {}

  /// Add a destination for log output
  public static func addDestination(_ destination: BaseDestination) {
    // Create a local copy to reference in the detached task
    let destinationRef=destination

    // Delegate to actor instance
    Task {
      await shared.addDestination(destinationRef)
    }
  }

  /// Internal actor method to add a destination
  public func addDestination(_ destination: BaseDestination) {
    destinations.append(destination)
    SwiftyBeaver.addDestination(destination)
  }

  /// Remove a destination from log output
  public static func removeDestination(_ destination: BaseDestination) {
    // Create a local copy to reference in the detached task
    let destinationRef=destination

    // Delegate to actor instance
    Task {
      await shared.removeDestination(destinationRef)
    }
  }

  /// Internal actor method to remove a destination
  public func removeDestination(_ destination: BaseDestination) {
    if let index=destinations.firstIndex(where: { $0 === destination }) {
      destinations.remove(at: index)
    }
    SwiftyBeaver.removeDestination(destination)
  }

  /// Check if a log level is enabled
  public static func isEnabled(_ level: LoggingTypes.LogLevel) -> Bool {
    // For simplicity, we'll default to checking against the minimum log level
    // This is a nonisolated operation
    level.rawValue >= LoggingTypes.LogLevel.trace.rawValue
  }

  /// Configure the logger with the provided options
  public static func configure(_ options: LoggingWrapperInterfaces.LoggerConfiguration) {
    // Delegate to actor instance
    Task {
      await shared.configure(options)
    }
  }

  /// Internal actor method to configure the logger
  public func configure(_ options: LoggingWrapperInterfaces.LoggerConfiguration) {
    // Update actor configuration
    configuration=options

    // Update minimum level on all destinations
    let level=convertLogLevel(options.minimumLevel)
    for destination in destinations {
      destination.minLevel=level
    }
  }

  /// Set the minimum log level to record
  public static func setLogLevel(_ level: LoggingTypes.LogLevel) {
    Task {
      await shared.setLogLevel(level)
    }
  }

  /// Internal actor method to set log level
  public func setLogLevel(_ level: LoggingTypes.LogLevel) {
    // Create a new configuration with the updated log level
    let newConfig=LoggingWrapperInterfaces.LoggerConfiguration(
      minimumLevel: level,
      includeSourceLocation: configuration.includeSourceLocation,
      privacyRedactionEnabled: configuration.privacyRedactionEnabled,
      synchronousLogging: configuration.synchronousLogging,
      includeThreadInfo: configuration.includeThreadInfo,
      maxLogFileSizeMB: configuration.maxLogFileSizeMB,
      maxLogFileCount: configuration.maxLogFileCount
    )

    // Update configuration
    configuration=newConfig

    // Update level on all destinations
    let swiftyLevel=convertLogLevel(level)
    for destination in destinations {
      destination.minLevel=swiftyLevel
    }
  }

  /// Flush any pending log entries
  public static func flush() {
    Task {
      await shared.flush()
    }
  }

  /// Actor instance method to flush logs
  public func flush() {
    // SwiftyBeaver doesn't have an explicit flush mechanism,
    // but we can ensure any pending logging operations are completed
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

  /// Set up the logger with console output
  public static func setupConsoleLogging(
    minLevel: LoggingTypes.LogLevel = .debug,
    format: String="$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M",
    useColors: Bool=true
  ) {
    Task {
      await shared.setupConsoleLogging(minLevel: minLevel, format: format, useColors: useColors)
    }
  }

  /// Actor instance method to set up console logging
  public func setupConsoleLogging(
    minLevel: LoggingTypes.LogLevel = .debug,
    format: String="$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M",
    useColors _: Bool=true
  ) {
    // Create the console destination
    let console=ConsoleDestination()

    // Configure the format based on parameters
    console.format=format
    console.minLevel=convertLogLevel(minLevel)
    // Note: useColors property is not available in current version
    // console.useColors = useColors

    // Add the destination
    addDestination(console)
  }

  /// Convert LogLevel to SwiftyBeaver.Level
  private func convertLogLevel(_ level: LoggingTypes.LogLevel) -> SwiftyBeaver.Level {
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
    _ level: LoggingTypes.LogLevel,
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Immediately evaluate the autoclosure to capture the value
    let messageValue=message()

    // Convert message to string early
    let messageString=String(describing: messageValue)

    // Delegate to actor instance
    Task {
      await shared.log(
        level: level,
        message: messageString,
        metadata: metadata,
        privacy: .public,
        file: file,
        function: function,
        line: line
      )
    }
  }

  /// Actor instance method to log a message
  public func log(
    level: LoggingTypes.LogLevel,
    message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    privacy: LoggingWrapperInterfaces.LogPrivacyLevel,
    file: String,
    function: String,
    line: Int
  ) {
    // Process message with privacy level
    let processedMessage=processMessage(message, privacy: privacy)

    // Convert metadata to string dictionary
    var context: [String: Any]=[:]
    if let metadata {
      for entry in metadata.entries {
        // Apply privacy controls based on the entry's privacy level
        let value = switch entry.privacyLevel {
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
            // In a real implementation, this would be hashed
            "<hashed>"
          case .auto:
            // In a real implementation, this would be automatically classified
            "<auto-redacted>"
        }
        
        context[entry.key] = value
      }
    }

    // Log with SwiftyBeaver
    SwiftyBeaver.custom(
      level: convertLogLevel(level),
      message: processedMessage,
      file: file,
      function: function,
      line: line,
      context: context
    )
  }

  /// Log a message with privacy annotations
  public static func logPrivacy(
    _ level: LoggingTypes.LogLevel,
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    // Immediately evaluate the autoclosure to capture the value
    let messageValue=message()

    // Convert message to string early
    let messageString=String(describing: messageValue)

    // Delegate to actor instance with private privacy level
    Task {
      await shared.log(
        level: level,
        message: messageString,
        metadata: metadata,
        privacy: .private,
        file: file,
        function: function,
        line: line
      )
    }
  }

  /// Log a sensitive message
  public static func logSensitive(
    _ level: LoggingTypes.LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadataDTOCollection,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    // Delegate to actor instance with sensitive privacy level
    Task {
      await shared.log(
        level: level,
        message: message,
        metadata: sensitiveValues,
        privacy: .sensitive,
        file: file,
        function: function,
        line: line
      )
    }
  }

  // MARK: - Required LoggerProtocol convenience methods

  /// Log a debug message
  public static func debug(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log an info message
  public static func info(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.info, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log a warning message
  public static func warning(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log an error message
  public static func error(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.error, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log a trace message
  public static func trace(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.trace, message(), metadata: metadata, file: file, function: function, line: line)
  }

  /// Log a critical message
  public static func critical(
    _ message: @autoclosure () -> Any,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    log(.critical, message(), metadata: metadata, file: file, function: function, line: line)
  }

  // MARK: - PrivacyAwareLoggerImplementation

  /// Instance implementation of the PrivacyAwareLoggingProtocol
  public actor PrivacyAwareLoggerImplementation: LoggingInterfaces.PrivacyAwareLoggingProtocol {
    /// The underlying logging actor
    public let loggingActor: LoggingInterfaces.LoggingActor

    /// Initialises a new privacy-aware logger implementation
    /// - Parameter actor: The logging actor to use
    public init(actor: LoggingInterfaces.LoggingActor) {
      loggingActor=actor
    }

    // MARK: - CoreLoggingProtocol

    /// Log a message with the specified level and context
    public func log(
      _ level: LoggingTypes.LogLevel,
      _ message: String,
      context: LoggingTypes.LogContextDTO
    ) async {
      // Forward the log call to the underlying logging actor
      await loggingActor.log(level, message, context: context)
    }

    /// Log a message with privacy annotations
    public func log(
      _ level: LoggingTypes.LogLevel,
      _ message: LoggingTypes.PrivacyString,
      context: LoggingTypes.LogContextDTO
    ) async {
      // Process the privacy string and forward to the logging actor
      let processedMessage=message.processForLogging()
      await loggingActor.log(level, processedMessage, context: context)
    }

    /// Log a potentially sensitive message.
    public func logSensitive(
      _ level: LoggingTypes.LogLevel,
      _ message: String,
      sensitiveValues: LoggingTypes.LogMetadata,
      context: LoggingTypes.LogContextDTO
    ) async {
      // Create a modified context with sensitive values properly handled
      // TODO: Implement proper sensitive value handling according to privacy guidelines
      await loggingActor.log(level, "[Sensitive Log]: \(message)", context: context)
    }

    /// Log an error with privacy controls
    /// - Parameters:
    ///   - error: The error to log
    ///   - privacyLevel: The privacy level to apply to the error details
    ///   - context: The logging context containing metadata, source, etc.
    public func logError(
      _ error: Error,
      privacyLevel: LoggingTypes.LogPrivacyLevel,
      context: LoggingTypes.LogContextDTO
    ) async {
      // Create error metadata with the appropriate privacy level
      var errorContext=context

      // If it's a loggable error with specific privacy metadata, use that,
      // otherwise create metadata based on the provided privacy level
      if let loggableError=error as? LoggableErrorProtocol {
        // Use the error's built-in metadata collection
        let errorMetadataCollection=loggableError.createMetadataCollection()
        errorContext=errorContext
          .withUpdatedMetadata(errorMetadataCollection)
      } else {
        // Create default error metadata with the specified privacy level
        var metadata=LogMetadataDTOCollection()
        let errorTypeString=String(describing: type(of: error))

        metadata=metadata.withPublic(key: "errorType", value: errorTypeString)

        // Apply different privacy levels to the error message based on the setting
        switch privacyLevel {
          case .public:
            metadata=metadata.withPublic(key: "errorMessage", value: error.localizedDescription)
          case .private:
            metadata=metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)
          case .sensitive:
            metadata=metadata.withSensitive(key: "errorMessage", value: error.localizedDescription)
          case .hash:
            // In a real implementation, this would be hashed
            metadata=metadata.withHashed(key: "errorMessage", value: error.localizedDescription)
          case .auto:
            // In a real implementation, this would be automatically classified
            metadata=metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)
        }

        errorContext=errorContext.withUpdatedMetadata(metadata)
      }

      // Log the error at error level
      await log(.error, "Error: \(error.localizedDescription)", context: errorContext)
    }

    /// Provide a basic description for the logger instance
    public nonisolated var description: String {
      "PrivacyAwareLogger for \(String(describing: loggingActor))"
    }

    /// Converts PrivacyMetadata to LogMetadataDTOCollection for error handling
    ///
    /// This function provides a way to convert privacy metadata from errors
    /// to a format suitable for the logging system.
    ///
    /// - Parameter metadata: The privacy metadata to convert
    /// - Returns: A LogMetadataDTOCollection with equivalent entries
    private static func convertToLogMetadataDTOCollection(_ metadata: PrivacyMetadata)
    -> LogMetadataDTOCollection {
      var collection=LogMetadataDTOCollection()

      for entry in metadata.entriesArray {
        switch entry.privacy {
          case .public:
            collection=collection.withPublic(key: entry.key, value: entry.value)
          case .private:
            collection=collection.withPrivate(key: entry.key, value: entry.value)
          case .sensitive:
            collection=collection.withSensitive(key: entry.key, value: entry.value)
          case .hash:
            collection=collection.withHashed(key: entry.key, value: entry.value)
          case .auto:
            // Default to private for auto
            collection=collection.withPrivate(key: entry.key, value: entry.value)
        }
      }

      return collection
    }
  }

  // MARK: - Static Factory Methods

  /// Create a new privacy-aware logger
  /// - Returns: A new logger instance
  public static func createPrivacyAwareLogger() -> LoggingInterfaces.PrivacyAwareLoggingProtocol {
    let logActor=LoggingInterfaces.LoggingActor(destinations: [])
    return PrivacyAwareLoggerImplementation(actor: logActor)
  }
}
