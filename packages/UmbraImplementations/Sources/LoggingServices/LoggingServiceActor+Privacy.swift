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
  ///   - source: Optional source component identifier
  public func log(
    level: UmbraLogLevel,
    message: PrivacyAnnotatedString,
    metadata: LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    // Create a privacy-enhanced metadata
    var metadataCollection = metadata ?? LogMetadataDTOCollection()
    
    // Add privacy annotations
    metadataCollection = metadataCollection
      .withPrivate(key: "__privacy_message", value: message.privacy.description)
    
    // Use the standard log method with string message
    await log(level: level, message: message.content, metadata: metadataCollection, source: source)
  }
}
