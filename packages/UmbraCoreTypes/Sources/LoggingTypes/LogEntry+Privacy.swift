/// Extension to LogEntry to support privacy annotations
///
/// Provides privacy-aware versions of LogEntry creation and manipulation,
/// allowing for fine-grained privacy control over logged information.
public extension LogEntry {
    /// Create a log entry with privacy annotations
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message with privacy annotation
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    ///   - entryId: Optional unique identifier (auto-generated if nil)
    /// - Returns: A new log entry
    static func privacyAware(
        level: UmbraLogLevel,
        message: PrivacyAnnotatedString,
        metadata: LogMetadata? = nil,
        source: String? = nil,
        entryId: String? = nil
    ) -> (entry: LogEntry, messagePrivacy: LogPrivacy, metadataPrivacy: LogPrivacy) {
        let entry = LogEntry(
            level: level,
            message: message.content,
            metadata: metadata,
            source: source,
            entryId: entryId
        )
        
        return (entry, message.privacy, metadata != nil ? .private : .public)
    }
    
    /// Get a privacy-annotated version of the message
    /// - Parameter privacy: The privacy level to apply (defaults to .auto)
    /// - Returns: A privacy-annotated string
    func messageWithPrivacy(_ privacy: LogPrivacy = .auto) -> PrivacyAnnotatedString {
        PrivacyAnnotatedString(message, privacy: privacy)
    }
}
