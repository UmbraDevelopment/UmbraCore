import LoggingTypes
import LoggingInterfaces

/// A logging backend that writes to multiple other backends.
/// This allows for logs to be sent to different destinations simultaneously.
public struct MultiLoggingBackend: LoggingBackend {
    /// The backends to write logs to
    private let backends: [LoggingBackend]
    
    /// Creates a new multi-backend with the specified backends
    /// - Parameter backends: The backends to write logs to
    public init(backends: [LoggingBackend]) {
        self.backends = backends
    }
    
    /// Writes a log message to all backends
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - context: Contextual information about the log
    ///   - subsystem: The subsystem identifier
    public func writeLog(
        level: LogLevel,
        message: String,
        context: LogContext,
        subsystem: String
    ) async {
        // Write to each backend in parallel
        await withTaskGroup(of: Void.self) { group in
            for backend in backends {
                group.addTask {
                    await backend.writeLog(
                        level: level,
                        message: message,
                        context: context,
                        subsystem: subsystem
                    )
                }
            }
        }
    }
    
    /// Checks if a log should be processed by checking all backends
    /// - Parameters:
    ///   - level: The log level to check
    ///   - minimumLevel: The minimum level to allow
    /// - Returns: True if any backend would process the log
    public func shouldLog(level: LogLevel, minimumLevel: LogLevel) -> Bool {
        // If any backend would log this, return true
        return backends.contains { backend in
            backend.shouldLog(level: level, minimumLevel: minimumLevel)
        }
    }
}
