import Foundation
import LoggingInterfaces
import LoggingTypes

/// A concrete implementation of LoggingProtocol that uses the actor-based logging system
public final class ActorLogger: LoggingProtocol {
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

  /// Log a message with the specified level and context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    await loggingActor.log(level: level, message: message, context: context)
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
