import LoggingTypes
import LoggingInterfaces

/// Factory for creating privacy-aware logging instances.
/// This provides a clean interface for creating loggers with different configurations.
public enum PrivacyAwareLoggingFactory {
    /// Create a logger with privacy features
    /// - Parameters:
    ///   - minimumLevel: The minimum log level to process (defaults to .info)
    ///   - identifier: The identifier for the logger, typically the subsystem name
    ///   - backend: The backend to use for writing logs (defaults to OSLogPrivacyBackend)
    ///   - privacyLevel: The default privacy level for unannotated values
    /// - Returns: A logger that implements the PrivacyAwareLoggingProtocol
    public static func createLogger(
        minimumLevel: LogLevel = .info,
        identifier: String,
        backend: LoggingBackend? = nil,
        privacyLevel: LogPrivacyLevel = .auto
    ) -> any PrivacyAwareLoggingProtocol {
        // Use the provided backend or create a default OSLogPrivacyBackend
        let loggingBackend = backend ?? OSLogPrivacyBackend(subsystem: identifier)
        
        // Create and return the logger
        return PrivacyAwareLogger(
            minimumLevel: minimumLevel,
            identifier: identifier,
            backend: loggingBackend
        )
    }
    
    /// Create a console-based logger for development and testing
    /// - Parameters:
    ///   - minimumLevel: The minimum log level to process (defaults to .debug)
    ///   - identifier: The identifier for the logger
    /// - Returns: A logger that implements the PrivacyAwareLoggingProtocol
    public static func createConsoleLogger(
        minimumLevel: LogLevel = .debug,
        identifier: String
    ) -> any PrivacyAwareLoggingProtocol {
        // Create a console backend
        let consoleBackend = ConsoleLoggingBackend()
        
        // Create and return the logger
        return PrivacyAwareLogger(
            minimumLevel: minimumLevel,
            identifier: identifier,
            backend: consoleBackend
        )
    }
    
    /// Create a logger that writes to multiple backends
    /// - Parameters:
    ///   - minimumLevel: The minimum log level to process
    ///   - identifier: The identifier for the logger
    ///   - backends: The backends to write logs to
    /// - Returns: A logger that implements the PrivacyAwareLoggingProtocol
    public static func createMultiLogger(
        minimumLevel: LogLevel,
        identifier: String,
        backends: [LoggingBackend]
    ) -> any PrivacyAwareLoggingProtocol {
        // Create a multi-backend
        let multiBackend = MultiLoggingBackend(backends: backends)
        
        // Create and return the logger
        return PrivacyAwareLogger(
            minimumLevel: minimumLevel,
            identifier: identifier,
            backend: multiBackend
        )
    }
}
