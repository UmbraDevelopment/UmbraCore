import Foundation
import LoggingInterfaces
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
struct OSLogUsageExample {
    static func osLogExamples() async {
        // 1. Create a basic OSLog logger
        let logger = LoggingServiceFactory.createOSLogger(
            subsystem: "com.example.umbra",
            category: "Application"
        )
        
        // 2. Basic logging (privacy defaults to auto)
        await logger.log(level: .info, message: "Application started")
        await logger.log(level: .debug, message: "Debug information", metadata: LogMetadata(["process": "main"]))
        
        // 3. Privacy-aware logging for sensitive data
        let username = "john.smith"
        let sessionId = "ABC123XYZ789"
        
        // Public information
        await logger.log(
            level: .info,
            message: PrivacyAnnotatedString("User logged in", privacy: .public),
            metadata: LogMetadata(["module": "Authentication"])
        )
        
        // Private information - viewable in debug, redacted in release
        await logger.log(
            level: .info,
            message: PrivacyAnnotatedString("User \(username) logged in", privacy: .private)
        )
        
        // Sensitive information - always redacted
        await logger.log(
            level: .info,
            message: PrivacyAnnotatedString("Session \(sessionId) created", privacy: .sensitive)
        )
        
        // 4. Custom metadata privacy
        await logger.log(
            level: .debug,
            message: PrivacyAnnotatedString("Auth process completed", privacy: .public),
            metadata: LogMetadata(["user": username, "session": sessionId]),
            metadataPrivacy: .sensitive
        )
        
        // 5. Comprehensive logging with multiple destinations
        let comprehensiveLogger = LoggingServiceFactory.createComprehensiveLogger(
            subsystem: "com.example.umbra",
            category: "Application",
            logDirectoryPath: "/tmp/logs"
        )
        
        await comprehensiveLogger.log(
            level: .error,
            message: "Failed to load resource",
            metadata: LogMetadata(["resource": "config.json"])
        )
    }
    
    static func logSensitiveInformation(
        logger: LoggingInterfaces.LoggingServiceProtocol,
        userId: String,
        apiKey: String,
        email: String
    ) async {
        // Example showing privacy best practices for various types of data
        
        // 1. User IDs - .private (visible in development, not in production logs)
        await (logger as? LoggingServiceActor)?.log(
            level: .info,
            message: PrivacyAnnotatedString("Processing request for user \(userId)", privacy: .private)
        )
        
        // 2. API Keys - .sensitive (always redacted)
        await (logger as? LoggingServiceActor)?.log(
            level: .debug,
            message: PrivacyAnnotatedString("Using API key \(apiKey)", privacy: .sensitive)
        )
        
        // 3. Email - .private (visible in development, not in production logs)
        await (logger as? LoggingServiceActor)?.log(
            level: .info,
            message: PrivacyAnnotatedString("Sending notification to \(email)", privacy: .private)
        )
        
        // 4. Structured information with mixed privacy
        let metadata = LogMetadata([
            "userId": userId,
            "requestTime": "\(Date())",
            "operation": "AccountUpdate"
        ])
        
        await (logger as? LoggingServiceActor)?.log(
            level: .info,
            message: PrivacyAnnotatedString("Account operation completed", privacy: .public),
            metadata: metadata,
            metadataPrivacy: .private
        )
    }
}
