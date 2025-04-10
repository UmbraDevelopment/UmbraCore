import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingServices

/**
 Utilities for logging services specific to the security implementation.
 
 This file provides helper functions for working with logging services
 within the security implementation module.
 */
public enum SecurityLoggingUtilities {
    /**
     Creates a wrapper that converts a LoggingServiceActor to LoggingProtocol.
     
     - Parameter logger: The logging service actor to wrap
     - Returns: A LoggingProtocol instance that delegates to the actor
     */
    public static func createLoggingWrapper(logger: LoggingServiceActor) async -> LoggingProtocol {
        // Create a basic logger that wraps the logging service actor
        return StandardLogger(source: "Security") { message, level, metadata in
            await logger.log(message: message, level: level, metadata: metadata)
        }
    }
    
    /**
     Creates a secure logger for privacy-aware logging.
     
     - Parameters:
        - subsystem: The subsystem identifier
        - category: The category for logs
     - Returns: A privacy-aware logger for secure operations
     */
    public static func createSecureLogger(
        subsystem: String,
        category: String
    ) async -> LoggingProtocol {
        // Create a privacy-aware logger with production settings
        return await LoggerFactory.createPrivacyAwareLogger(
            source: "\(subsystem).\(category)",
            minimumLogLevel: .info,
            privacyFilterEnabled: true
        )
    }
}

/**
 A simple logger implementation that delegates to a closure.
 This allows us to bridge between different logger implementations.
 */
private actor StandardLogger: LoggingProtocol {
    private let source: String
    private let logHandler: (String, LogLevel, PrivacyMetadata?) async -> Void
    
    init(source: String, logHandler: @escaping (String, LogLevel, PrivacyMetadata?) async -> Void) {
        self.source = source
        self.logHandler = logHandler
    }
    
    public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await logHandler(message, .debug, metadata)
    }
    
    public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await logHandler(message, .info, metadata)
    }
    
    public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await logHandler(message, .warning, metadata)
    }
    
    public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await logHandler(message, .error, metadata)
    }
    
    public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await logHandler(message, .critical, metadata)
    }
}
