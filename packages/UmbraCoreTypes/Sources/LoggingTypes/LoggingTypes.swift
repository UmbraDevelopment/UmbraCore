/// Provides rich contextual information about log events with privacy annotations
public struct LogContext: Sendable, Equatable, Hashable, LogContextDTO {
  /// Component that generated the log
  public let source: String?
  
  /// Additional structured data with privacy annotations (internal use)
  private let privacyMetadata: PrivacyMetadata?
  
  /// Domain name for the logging context
  public let domainName: String
  
  /// For tracking related logs across components
  public let correlationID: String?
  
  /// When the log was created
  public let timestamp: LogTimestamp
  
  /// Privacy-aware metadata for this log context
  public var metadata: LogMetadataDTOCollection {
    toMetadata()
  }

  /// Initialiser with default values
  ///
  /// Note: This overload is for non-async contexts. The timestamp
  /// is pre-generated to avoid async initialisation.
  ///
  /// - Parameters:
  ///   - source: Source component identifier
  ///   - metadata: Optional metadata
  ///   - correlationId: Unique identifier for correlating related logs
  ///   - timestamp: Timestamp (defaults to a pre-generated value)
  public init(
    source: String,
    metadata: PrivacyMetadata?=nil,
    correlationID: LogIdentifier=LogIdentifier.unique(),
    timestamp: LogTimestamp=LogTimestamp(secondsSinceEpoch: 1_609_459_200.0),
    domainName: String = "DefaultDomain"
  ) {
    self.source = source
    self.privacyMetadata = metadata
    self.correlationID = correlationID.description
    self.timestamp = timestamp
    self.domainName = domainName
  }
  
  /// Async initialiser that generates a current timestamp
  ///
  /// - Parameters:
  ///   - source: Source component identifier
  ///   - metadata: Optional metadata
  ///   - correlationId: Unique identifier for correlating related logs
  public static func create(
    source: String,
    metadata: PrivacyMetadata?=nil,
    correlationID: LogIdentifier=LogIdentifier.unique(),
    domainName: String = "DefaultDomain"
  ) async -> LogContext {
    let timestamp = await LogTimestamp.now()
    return LogContext(
      source: source,
      metadata: metadata,
      correlationID: correlationID,
      timestamp: timestamp,
      domainName: domainName
    )
  }
  
  /// Get the privacy metadata for logging purposes
  /// - Returns: The privacy metadata for this context
  public func toPrivacyMetadata() -> PrivacyMetadata {
    return privacyMetadata ?? PrivacyMetadata()
  }
  
  /// Get the source information
  /// - Returns: Source information for logs, or a default if not available
  public func getSource() -> String {
    return source ?? "UnknownSource"
  }
  
  /// Get the metadata collection
  /// - Returns: The metadata collection for this context
  public func toMetadata() -> LogMetadataDTOCollection {
    guard let metadata = privacyMetadata else {
      return LogMetadataDTOCollection()
    }
    
    // Convert PrivacyMetadata to LogMetadataDTOCollection
    var result = LogMetadataDTOCollection()
    
    // Access the metadata through public API
    for key in metadata.keys {
      if let value = metadata.value(forKey: key) {
        switch value.privacyClassification {
        case .public:
          result = result.withPublic(key: key, value: value.stringValue)
        case .private:
          result = result.withPrivate(key: key, value: value.stringValue)
        case .sensitive:
          result = result.withSensitive(key: key, value: value.stringValue)
        case .hash:
          result = result.withHashed(key: key, value: value.stringValue)
        default:
          result = result.withAuto(key: key, value: value.stringValue)
        }
      }
    }
    
    return result
  }

  /// Create a new context with updated metadata
  /// - Parameter newMetadata: The metadata to add to the existing metadata
  /// - Returns: A new context with combined metadata
  public func withUpdatedMetadata(_ newMetadata: PrivacyMetadata) -> LogContext {
    var combinedMetadata = privacyMetadata ?? PrivacyMetadata()
    combinedMetadata.merge(newMetadata)
 
    return LogContext(
      source: getSource(),
      metadata: combinedMetadata,
      correlationID: LogIdentifier(value: correlationID ?? ""),
      timestamp: timestamp,
      domainName: domainName
    )
  }
 
  /// Create a new context with a different source
  /// - Parameter newSource: The new source component identifier
  /// - Returns: A new context with the updated source
  public func withSource(_ newSource: String) -> LogContext {
    LogContext(
      source: newSource,
      metadata: privacyMetadata,
      correlationID: LogIdentifier(value: correlationID ?? ""),
      timestamp: timestamp,
      domainName: domainName
    )
  }

  /// Required for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(source)
    hasher.combine(privacyMetadata)
    hasher.combine(correlationID)
    hasher.combine(timestamp)
    hasher.combine(domainName)
  }

  /// Required for Equatable conformance
  public static func == (lhs: LogContext, rhs: LogContext) -> Bool {
    lhs.source == rhs.source &&
      lhs.privacyMetadata == rhs.privacyMetadata &&
      lhs.correlationID == rhs.correlationID &&
      lhs.timestamp == rhs.timestamp &&
      lhs.domainName == rhs.domainName
  }
}
