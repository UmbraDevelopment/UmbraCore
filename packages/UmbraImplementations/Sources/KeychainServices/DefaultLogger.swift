import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog

/**
 # DefaultLogger
 
 A simple logger implementation that provides basic logging functionality
 when no other logger is provided. This ensures that logging is always available
 even in minimal configurations.
 
 This logger uses OSLog on Apple platforms for efficient system integration.
 */
public final class DefaultLogger: LoggingProtocol {
    /// OSLog instance for system logging
    private let logger: Logger
    
    /// Initialise a new logger with the default subsystem and category
    public init() {
        self.logger = Logger(subsystem: "com.umbra.keychainservices", category: "KeychainServices")
    }
    
    /// Log trace message
    public func trace(_ message: String, metadata: LogMetadata?) async {
        logger.debug("TRACE: \(message)")
    }
    
    /// Log debug message
    public func debug(_ message: String, metadata: LogMetadata?) async {
        logger.debug("DEBUG: \(message)")
    }
    
    /// Log info message
    public func info(_ message: String, metadata: LogMetadata?) async {
        logger.info("INFO: \(message)")
    }
    
    /// Log notice message
    public func notice(_ message: String, metadata: LogMetadata?) async {
        logger.notice("NOTICE: \(message)")
    }
    
    /// Log warning message
    public func warning(_ message: String, metadata: LogMetadata?) async {
        logger.warning("WARNING: \(message)")
    }
    
    /// Log error message
    public func error(_ message: String, metadata: LogMetadata?) async {
        logger.error("ERROR: \(message)")
    }
    
    /// Log critical message
    public func critical(_ message: String, metadata: LogMetadata?) async {
        logger.critical("CRITICAL: \(message)")
    }
    
    /// Log generic message with specified level
    public func log(level: LogLevel, message: String, metadata: LogMetadata?) async {
        switch level {
        case .trace:
            await trace(message, metadata: metadata)
        case .debug:
            await debug(message, metadata: metadata)
        case .info:
            await info(message, metadata: metadata)
        case .notice:
            await notice(message, metadata: metadata)
        case .warning:
            await warning(message, metadata: metadata)
        case .error:
            await error(message, metadata: metadata)
        case .critical:
            await critical(message, metadata: metadata)
        }
    }
}
