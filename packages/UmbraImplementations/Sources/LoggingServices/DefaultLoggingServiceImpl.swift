import LoggingInterfaces
import LoggingTypes

/// Default implementation of the LoggingProtocol
///
/// This implementation provides a basic logging service that can be used
/// throughout the application. It follows the Alpha Dot Five architecture
/// pattern of having concrete implementations separate from interfaces.
public final class DefaultLoggingServiceImpl: LoggingProtocol {

  /// The logging actor required by LoggingProtocol
  public let loggingActor: LoggingActor

  /// Initialises a new DefaultLoggingServiceImpl
  public init(loggingActor: LoggingActor?=nil) {
    // Create a default logging actor if none provided
    self.loggingActor=loggingActor ?? LoggingActor(destinations: [])
  }

  /// Implement the core logging functionality required by CoreLoggingProtocol
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    // Forward to the logging actor
    await loggingActor.log(level: level, message: message, context: context)
  }

  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }

  // MARK: - Privacy Logging Methods

  public func logPrivateData(_ message: PrivacyString) async {
    await log(.debug, message.rawValue, metadata: nil, source: "PrivacyLogging")
  }

  public func logRestrictedData(_ message: PrivacyString) async {
    await log(.info, message.rawValue, metadata: nil, source: "PrivacyLogging")
  }

  public func logPublicData(_ message: PrivacyString) async {
    await log(.info, message.rawValue, metadata: nil, source: "PrivacyLogging")
  }
}
