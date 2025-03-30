import LoggingTypes

/// Protocol defining the backend interface for logging implementations.
/// This separation allows for different logging destinations while
/// maintaining a consistent logging API.
public protocol LoggingBackend: Sendable {
    /// Write a log message to the backend
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to write
    ///   - context: Contextual information about the log entry
    ///   - subsystem: The subsystem identifier
    func writeLog(
        level: LogLevel,
        message: String,
        context: LogContext,
        subsystem: String
    ) async
    
    /// Check if a log with the specified level should be processed
    /// - Parameters:
    ///   - level: The log level to check
    ///   - minimumLevel: The minimum level to allow
    /// - Returns: True if the log should be processed, false otherwise
    func shouldLog(level: LogLevel, minimumLevel: LogLevel) -> Bool
}

/// Default implementation for basic functionality
extension LoggingBackend {
    /// Default implementation to check if a log with the specified level should be processed
    /// - Parameters:
    ///   - level: The log level to check
    ///   - minimumLevel: The minimum level to allow
    /// - Returns: True if the log level is greater than or equal to the minimum level
    public func shouldLog(level: LogLevel, minimumLevel: LogLevel) -> Bool {
        return level >= minimumLevel
    }
}
