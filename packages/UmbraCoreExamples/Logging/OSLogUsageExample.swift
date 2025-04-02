import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/// Example demonstrating usage of OSLog-based logging with privacy controls
///
/// This example shows:
/// - Creating an OSLog-based logger
/// - Basic logging with default privacy
/// - Privacy-annotated logging for sensitive information
/// - Using comprehensive logging with multiple destinations
///
/// Note: This is not intended to be compiled as part of the product,
/// but serves as documentation and reference for developers.
enum OSLogUsageExample {
  static func osLogExamples() async {
    // 1. Create a basic OSLog logger
    let logger=LoggingServiceFactory.createOSLogger(
      subsystem: "com.example.umbra",
      category: "Application"
    )

    // 2. Basic logging
    let nilMetadata: LogMetadata?=nil
    await logger.info("Application started", metadata: nilMetadata, source: "OSLogExample")
    await logger.debug(
      "Debug information",
      metadata: LogMetadata(["process": "main"]),
      source: "OSLogExample"
    )

    // 3. Privacy-aware logging for sensitive data
    let username="john.smith"
    let sessionID="ABC123XYZ789"

    // Public information
    let publicMetadata=LogMetadata(["module": "Authentication"])
    await logger.info(
      PrivacyAnnotatedString("User logged in", privacy: .public).description,
      metadata: publicMetadata,
      source: "OSLogExample"
    )

    // Private information - viewable in debug, redacted in release
    await logger.info(
      PrivacyAnnotatedString("User \(username) logged in", privacy: .private).description,
      metadata: nilMetadata,
      source: "OSLogExample"
    )

    // Sensitive information - always redacted
    await logger.info(
      PrivacyAnnotatedString("Session \(sessionID) created", privacy: .sensitive).description,
      metadata: nilMetadata,
      source: "OSLogExample"
    )

    // 4. Custom metadata privacy
    await logger.debug(
      PrivacyAnnotatedString("Auth process completed", privacy: .public).description,
      metadata: LogMetadata(["user": username, "session": sessionID]),
      source: "OSLogExample"
    )

    // 5. Comprehensive logging with multiple destinations
    let comprehensiveLogger=LoggingServiceFactory.createComprehensiveLogger(
      subsystem: "com.example.umbra",
      category: "Application",
      logDirectoryPath: "/tmp/logs"
    )

    await comprehensiveLogger.error(
      "Failed to load resource",
      metadata: LogMetadata(["resource": "config.json"]),
      source: "OSLogExample"
    )
  }

  static func logSensitiveInformation(
    logger: LoggingInterfaces.LoggingServiceProtocol,
    userID: String,
    apiKey: String,
    email: String
  ) async {
    // Example showing privacy best practices for various types of data

    // 1. User IDs - .private (visible in development, not in production logs)
    await (logger as? LoggingServiceActor)?.info(
      PrivacyAnnotatedString("Processing request for user \(userID)", privacy: .private)
        .description,
      metadata: nil,
      source: "OSLogExample"
    )

    // 2. API Keys - .sensitive (always redacted)
    await (logger as? LoggingServiceActor)?.debug(
      PrivacyAnnotatedString("Using API key \(apiKey)", privacy: .sensitive).description,
      metadata: nil,
      source: "OSLogExample"
    )

    // 3. Email - .private (visible in development, not in production logs)
    await (logger as? LoggingServiceActor)?.info(
      PrivacyAnnotatedString("Sending notification to \(email)", privacy: .private).description,
      metadata: nil,
      source: "OSLogExample"
    )

    // 4. Structured information with mixed privacy
    let metadata=LogMetadata([
      "userId": userID,
      "requestTime": "\(Date())",
      "operation": "AccountUpdate"
    ])

    await (logger as? LoggingServiceActor)?.info(
      PrivacyAnnotatedString("Account operation completed", privacy: .public).description,
      metadata: metadata,
      source: "OSLogExample"
    )
  }
}
