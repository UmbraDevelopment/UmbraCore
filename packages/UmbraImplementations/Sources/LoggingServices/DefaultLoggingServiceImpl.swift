import LoggingInterfaces
import LoggingTypes

/// Default implementation of the LoggingProtocol
///
/// This implementation provides a basic logging service that can be used
/// throughout the application. It follows the Alpha Dot Five architecture
/// pattern of having concrete implementations separate from interfaces.
public actor DefaultLoggingServiceImpl: LoggingProtocol {

  /// The logging actor required by LoggingProtocol
  public let loggingActor: LoggingActor

  /// Initialises a new DefaultLoggingServiceImpl
  public init(loggingActor: LoggingActor?=nil) {
    // Create a default logging actor if none provided
    self.loggingActor=loggingActor ?? LoggingActor(destinations: [])
  }

  /// Core logging method required by CoreLoggingProtocol
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log as DTO
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Forward to the logging actor
    await loggingActor.log(level, message, context: context)
  }

  /// Legacy method for backwards compatibility
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    // Create a context DTO from the legacy context
    let contextDTO=BaseLogContextDTO(
      domainName: "Legacy",
      source: context.source ?? "Unknown",
      metadata: context.toPrivacyMetadata()
    )

    // Forward to the core logging method
    await log(level, message, context: contextDTO)
  }

  /// Helper method to convert metadata to LogMetadataDTOCollection
  /// - Parameter metadata: The metadata to convert
  /// - Returns: A LogMetadataDTOCollection
  private func createMetadataCollection(from metadata: LogMetadataDTOCollection?)
  -> LogMetadataDTOCollection {
    metadata ?? LogMetadataDTOCollection()
  }

  // MARK: - Convenience Logging Methods

  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata
  ///   - source: Source component identifier
  public func trace(
    _ message: String,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    let context=BaseLogContextDTO(
      domainName: "Trace",
      source: source ?? "Unknown",
      metadata: createMetadataCollection(from: metadata)
    )
    await log(.trace, message, context: context)
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata
  ///   - source: Source component identifier
  public func debug(
    _ message: String,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    let context=BaseLogContextDTO(
      domainName: "Debug",
      source: source ?? "Unknown",
      metadata: createMetadataCollection(from: metadata)
    )
    await log(.debug, message, context: context)
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata
  ///   - source: Source component identifier
  public func info(
    _ message: String,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    let context=BaseLogContextDTO(
      domainName: "Info",
      source: source ?? "Unknown",
      metadata: createMetadataCollection(from: metadata)
    )
    await log(.info, message, context: context)
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata
  ///   - source: Source component identifier
  public func warning(
    _ message: String,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    let context=BaseLogContextDTO(
      domainName: "Warning",
      source: source ?? "Unknown",
      metadata: createMetadataCollection(from: metadata)
    )
    await log(.warning, message, context: context)
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata
  ///   - source: Source component identifier
  public func error(
    _ message: String,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    let context=BaseLogContextDTO(
      domainName: "Error",
      source: source ?? "Unknown",
      metadata: createMetadataCollection(from: metadata)
    )
    await log(.error, message, context: context)
  }

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata
  ///   - source: Source component identifier
  public func critical(
    _ message: String,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    let context=BaseLogContextDTO(
      domainName: "Critical",
      source: source ?? "Unknown",
      metadata: createMetadataCollection(from: metadata)
    )
    await log(.critical, message, context: context)
  }

  // MARK: - Privacy Logging Methods

  public func logPrivateData(_ message: PrivacyString) async {
    let context=BaseLogContextDTO(
      domainName: "PrivacyLogging",
      source: "PrivacyLogger",
      metadata: LogMetadataDTOCollection()
    )
    await log(.debug, message.rawValue, context: context)
  }

  public func logRestrictedData(_ message: PrivacyString) async {
    let context=BaseLogContextDTO(
      domainName: "PrivacyLogging",
      source: "PrivacyLogger",
      metadata: LogMetadataDTOCollection()
    )
    await log(.info, message.rawValue, context: context)
  }

  public func logPublicData(_ message: PrivacyString) async {
    let context=BaseLogContextDTO(
      domainName: "PrivacyLogging",
      source: "PrivacyLogger",
      metadata: LogMetadataDTOCollection()
    )
    await log(.info, message.rawValue, context: context)
  }
}
