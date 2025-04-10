import LoggingInterfaces
import LoggingTypes

/// Helper extensions to simplify migration from older logging API
/// to the new context-based logging API
extension LoggingProtocol {
  /// Log a message with separate metadata and source parameters
  ///
  /// This is a compatibility method for migrating from the older API
  /// to the new context-based API
  ///
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The log message
  ///   - metadata: Privacy metadata
  ///   - source: The source of the log
  @available(*, deprecated, message: "Use log(_:_:context:) instead")
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Convert PrivacyMetadata to LogMetadataDTOCollection
    var metadataCollection=LogMetadataDTOCollection()

    if let metadata {
      for (key, value) in metadata.entriesDict() {
        switch value.privacy {
          case .public:
            metadataCollection=metadataCollection.withPublic(key: key, value: value.valueString)
          case .private:
            metadataCollection=metadataCollection.withPrivate(key: key, value: value.valueString)
          case .sensitive:
            metadataCollection=metadataCollection.withSensitive(key: key, value: value.valueString)
          case .hash:
            metadataCollection=metadataCollection.withHashed(key: key, value: value.valueString)
          case .auto:
            metadataCollection=metadataCollection.withAuto(key: key, value: value.valueString)
        }
      }
    }

    // Create a context from the parameters
    let context=BaseLogContextDTO(
      domainName: "Legacy",
      source: source,
      metadata: metadataCollection,
      correlationID: nil
    )

    // Forward to the new method
    await log(level, message, context: context)
  }

  /// Log a debug message with separate metadata and source parameters
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Privacy metadata
  ///   - source: The source of the log
  @available(*, deprecated, message: "Use debug(_:context:) instead")
  public func debug(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  /// Log an info message with separate metadata and source parameters
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Privacy metadata
  ///   - source: The source of the log
  @available(*, deprecated, message: "Use info(_:context:) instead")
  public func info(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  /// Log a warning message with separate metadata and source parameters
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Privacy metadata
  ///   - source: The source of the log
  @available(*, deprecated, message: "Use warning(_:context:) instead")
  public func warning(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  /// Log an error message with separate metadata and source parameters
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Privacy metadata
  ///   - source: The source of the log
  @available(*, deprecated, message: "Use error(_:context:) instead")
  public func error(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    await log(.error, message, metadata: metadata, source: source)
  }

  /// Log a critical message with separate metadata and source parameters
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Privacy metadata
  ///   - source: The source of the log
  @available(*, deprecated, message: "Use critical(_:context:) instead")
  public func critical(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    await log(.critical, message, metadata: metadata, source: source)
  }
}
