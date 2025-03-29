import Foundation
import LoggingInterfaces
import LoggingTypes

/// Extension to LoggingServiceActor to support privacy annotations
extension LoggingServiceActor {
    /// Log a message with privacy annotations
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message with privacy annotation
    ///   - metadata: Optional metadata
    ///   - metadataPrivacy: Privacy level for metadata (defaults to .private)
    ///   - source: Optional source component identifier
    public func log(
        level: UmbraLogLevel,
        message: PrivacyAnnotatedString,
        metadata: LogMetadata? = nil,
        metadataPrivacy: LogPrivacy = .private,
        source: String? = nil
    ) async {
        // Create a privacy-enhanced metadata
        var privacyMetadata = metadata ?? LogMetadata()
        privacyMetadata["__privacy_message"] = message.privacy.description
        privacyMetadata["__privacy_metadata"] = metadataPrivacy.description
        
        // Use the standard log method with string message
        await log(level: level, message: message.content, metadata: privacyMetadata, source: source)
    }
}
