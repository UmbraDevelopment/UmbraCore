import Foundation
import LoggingInterfaces
import LoggingTypes

/// A concrete implementation of LoggingProtocol that uses the actor-based logging system
public actor ActorLogger: LoggingProtocol {
  /// The underlying logging actor
  public let loggingActor: LoggingActor

  /// Default source identifier for logs
  private let defaultSource: String

  /// Initialise a new actor logger
  /// - Parameters:
  ///   - loggingActor: The underlying logging actor
  ///   - defaultSource: Default source identifier for logs
  public init(loggingActor: LoggingActor, defaultSource: String="default") {
    self.loggingActor=loggingActor
    self.defaultSource=defaultSource
  }

  /// Log a message with the specified level and context (core protocol requirement)
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Forward to the logging actor using the correct parameter format
    await loggingActor.log(level, message, context: context)
  }

  /// Log a message with the specified level and legacy context (for backwards compatibility)
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log using the legacy format
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    // Create a context DTO from the legacy context
    let contextDTO=BaseLogContextDTO(
      domainName: "Legacy",
      source: context.source ?? defaultSource,
      metadata: context.metadata // Pass the metadata directly, no conversion needed
    )

    await log(level, message, context: contextDTO)
  }

  /// Helper method to convert PrivacyMetadata to LogMetadataDTOCollection
  /// - Parameter metadata: The privacy metadata to convert
  /// - Returns: A LogMetadataDTOCollection with the same entries
  private func createMetadataCollection(from metadata: PrivacyMetadata?)
  -> LogMetadataDTOCollection {
    var collection=LogMetadataDTOCollection()

    // If no metadata, return empty collection
    guard let metadata else {
      return collection
    }

    // Convert each entry based on its privacy level
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

  /// Create default metadata with the given privacy level
  /// - Parameters:
  ///   - key: Metadata key
  ///   - value: Metadata value
  ///   - privacy: Privacy level to apply
  /// - Returns: A PrivacyMetadata object with the specified key-value pair
  public func createMetadata(
    key: String,
    value: String,
    privacy: LogPrivacyLevel = .public
  ) -> PrivacyMetadata {
    var metadata=PrivacyMetadata()
    metadata[key]=PrivacyMetadataValue(value: value, privacy: privacy)
    return metadata
  }

  /// Create a new logger with the same actor but a different default source
  /// - Parameter source: The new default source
  /// - Returns: A new ActorLogger with the specified default source
  public func withSource(_ source: String) -> ActorLogger {
    ActorLogger(loggingActor: loggingActor, defaultSource: source)
  }
}
