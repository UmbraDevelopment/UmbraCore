/// Extension to LogEntry to support privacy annotations
///
/// Provides privacy-aware versions of LogEntry creation and manipulation,
/// allowing for fine-grained privacy control over logged information.
extension LogEntry {
  /// Create a log entry with privacy annotations
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message with privacy annotation
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  ///   - entryId: Optional unique identifier (auto-generated if nil)
  /// - Returns: A new log entry
  public static func privacyAware(
    level: LogLevel,
    message: PrivacyString,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    entryID: LogIdentifier? = nil
  ) -> (entry: LogEntry, messagePrivacy: [Range<String.Index>: LogPrivacyLevel], metadataPrivacy: LogPrivacyLevel) {
    // Create a timestamp that doesn't require async
    let timestamp = LogTimestamp(secondsSinceEpoch: 1_609_459_200.0)
    
    let entry = LogEntry(
      level: level,
      message: message.rawValue,
      metadata: metadata,
      source: source ?? "",
      entryID: entryID,
      timestamp: timestamp
    )

    return (entry, message.privacyAnnotations, metadata != nil ? .private : .public)
  }
  
  /// Create a log entry with privacy annotations asynchronously (gets current timestamp)
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message with privacy annotation
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  ///   - entryId: Optional unique identifier (auto-generated if nil)
  /// - Returns: A new log entry
  public static func privacyAwareAsync(
    level: LogLevel,
    message: PrivacyString,
    metadata: PrivacyMetadata? = nil,
    source: String? = nil,
    entryID: LogIdentifier? = nil
  ) async -> (entry: LogEntry, messagePrivacy: [Range<String.Index>: LogPrivacyLevel], metadataPrivacy: LogPrivacyLevel) {
    let timestamp = await LogTimestamp.now()
    
    let entry = LogEntry(
      level: level,
      message: message.rawValue,
      metadata: metadata,
      source: source ?? "",
      entryID: entryID,
      timestamp: timestamp
    )

    return (entry, message.privacyAnnotations, metadata != nil ? .private : .public)
  }

  /// Get a privacy-annotated version of the message
  /// - Parameter privacy: The privacy level to apply (defaults to .auto)
  /// - Returns: A privacy-annotated string
  public func messageWithPrivacy(_ privacy: LogPrivacyLevel = .auto) -> PrivacyString {
    PrivacyString(rawValue: message, privacyAnnotations: [message.startIndex..<message.endIndex: privacy])
  }
}
