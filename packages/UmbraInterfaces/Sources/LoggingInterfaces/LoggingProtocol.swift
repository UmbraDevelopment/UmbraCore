import Foundation
import LoggingTypes

/// Protocol defining the standard logging interface
public protocol LoggingProtocol: CoreLoggingProtocol {
  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func trace(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func debug(_ message: String, context: LogContextDTO) async

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func info(_ message: String, context: LogContextDTO) async

  /// Log a notice message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func notice(_ message: String, context: LogContextDTO) async

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func warning(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func error(_ message: String, context: LogContextDTO) async

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func critical(_ message: String, context: LogContextDTO) async

  /// Get the underlying logging actor
  /// - Returns: The logging actor used by this logger
  var loggingActor: LoggingActor { get }
}

/// Default implementations for LoggingProtocol to ensure compatibility with CoreLoggingProtocol
extension LoggingProtocol {
  /// Maps the individual log level methods to the core logMessage method
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String
  ) async {
    let context=await LogContext.create(source: source, metadata: metadata)
    await logMessage(level, message, context: context)
  }

  /// Implementation of trace level logging using the core method
  public func trace(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }

  /// Implementation of debug level logging using the context DTO
  func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /// Implementation of info level logging using the context DTO
  func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /// Implementation of notice level logging using the context DTO
  func notice(_ message: String, context: LogContextDTO) async {
    await log(.notice, message, context: context)
  }

  /// Implementation of warning level logging using the core method
  public func warning(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  /// Implementation of error level logging using the context DTO
  func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /// Implementation of critical level logging using the context DTO
  func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  // Default implementations for deprecated methods
  // These bridge to the context-based method, creating a temporary context.
  // This is inefficient and should be phased out.

  func debug(
    _ message: String,
    metadata: [String: LoggingTypes.PrivacyLevel]? = nil,
    source: String
  ) async {
    let context = SimpleLogContext(source: source, metadata: metadata)
    await log(.debug, message, context: context)
  }

  func info(
    _ message: String,
    metadata: [String: LoggingTypes.PrivacyLevel]? = nil,
    source: String
  ) async {
    let context = SimpleLogContext(source: source, metadata: metadata)
    await log(.info, message, context: context)
  }

  func notice(
    _ message: String,
    metadata: [String: LoggingTypes.PrivacyLevel]? = nil,
    source: String
  ) async {
    let context = SimpleLogContext(source: source, metadata: metadata)
    await log(.notice, message, context: context)
  }

  func error(
    _ message: String,
    metadata: [String: LoggingTypes.PrivacyLevel]? = nil,
    source: String
  ) async {
    let context = SimpleLogContext(source: source, metadata: metadata)
    await log(.error, message, context: context)
  }

  func critical(
    _ message: String,
    metadata: [String: LoggingTypes.PrivacyLevel]? = nil,
    source: String
  ) async {
    let context = SimpleLogContext(source: source, metadata: metadata)
    await log(.critical, message, context: context)
  }
}

// MARK: - Simple Context for Deprecated Method Bridging

/// A basic implementation of LogContextDTO used internally to bridge
/// deprecated logging methods to the new context-based system.
struct SimpleLogContext: LogContextDTO {
  let domainName: String = "BridgedContext"
  let source: String?
  let correlationID: String?
  private(set) var metadataCollection: [String: LoggingTypes.PrivacyLevel]

  // Computed property to conform to LogContextDTO's metadata requirement
  var metadata: LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    for (key, privacyLevel) in metadataCollection {
      // Convert LoggingTypes.PrivacyLevel to LoggingTypes.PrivacyClassification
      let privacyClassification = Self.convertPrivacyLevelToClassification(privacyLevel)
      collection = collection.with(key: key, value: "...", privacyLevel: privacyClassification) // Using builder
      // NOTE: The actual value isn't stored in SimpleLogContext, using placeholder "..."
      // This bridge context primarily cares about the *keys* and their *privacy levels*.
    }
    return collection
  }

  init(source: String?, correlationID: UUID? = nil, metadata: [String: LoggingTypes.PrivacyLevel]? = nil) {
    self.source = source
    self.correlationID = correlationID?.uuidString // Convert UUID? to String?
    self.metadataCollection = metadata ?? [:]
  }

  // Conformance to LogContextDTO's update requirement
  // This method might not be directly called on SimpleLogContext if it's only used internally for bridging.
  // However, providing a basic implementation for completeness.
  mutating func updateMetadata(_ newMetadata: [String: LoggingTypes.PrivacyLevel]) {
    metadataCollection.merge(newMetadata) { _, new in new }
  }

  // Conformance to LogContextDTO's withUpdatedMetadata requirement
  func withUpdatedMetadata(_ metadataUpdate: LogMetadataDTOCollection) -> SimpleLogContext {
    var newContext = self
    for entry in metadataUpdate.entries {
      // Convert LoggingTypes.PrivacyClassification back to LoggingTypes.PrivacyLevel
      let privacyLevel = Self.convertPrivacyClassificationToLevel(entry.privacyLevel)
      newContext.metadataCollection[entry.key] = privacyLevel
    }
    return newContext
  }

  // Helper to convert PrivacyLevel enum to PrivacyClassification enum
  private static func convertPrivacyLevelToClassification(_ level: LoggingTypes.PrivacyLevel) -> LoggingTypes.PrivacyClassification {
      switch level {
      case .public: return .public
      case .private, .sensitive: return .private // Treat sensitive as private for classification
      // Add other cases if PrivacyLevel expands
      default: return .private // Default fallback
      }
  }

  // Helper to convert PrivacyClassification enum back to PrivacyLevel enum
  private static func convertPrivacyClassificationToLevel(_ classification: LoggingTypes.PrivacyClassification) -> LoggingTypes.PrivacyLevel {
      switch classification {
      case .public: return .public
      case .private, .sensitive: return .private // Map private/sensitive classification back to private level
      case .hash: return .private // Map hash back to private as PrivacyLevel has no hash
      case .auto: return .public // Default auto to public
      // Add @unknown default if necessary when Swift evolves
      }
  }
}

/// Errors that can occur during logging operations
public enum LoggingError: Error, Sendable, Hashable {
  /// Failed to initialise logging system
  case initialisationFailed(reason: String)

  /// Failed to write log
  case writeFailed(reason: String)

  /// Failed to write to log destination
  case destinationWriteFailed(destination: String, reason: String)

  /// Log level filter prevented message from being logged
  case filteredByLevel(
    messageLevel: LogLevel,
    minimumLevel: LogLevel
  )

  /// Invalid configuration provided
  case invalidConfiguration(description: String)

  /// Operation not supported by this logger
  case operationNotSupported(description: String)

  /// Destination with specified identifier not found
  case destinationNotFound(identifier: String)

  /// Duplicate destination identifier
  case duplicateDestination(identifier: String)

  /// Error during privacy processing
  case privacyProcessingFailed(reason: String)
}

public enum LogLevel: Int, Sendable, Comparable {
  case trace = -1
  case debug = 0
  case info = 1
  case notice = 2
  case warning = 3
  case error = 4
  case critical = 5

  // Manual implementation for Comparable
  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
