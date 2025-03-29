import Foundation
import LoggingInterfaces
import LoggingTypes

/// Thread-safe logging service implementation based on the actor model
///
/// This implementation follows the Alpha Dot Five architecture patterns:
/// - Actor-based for thread safety
/// - Clear separation of concerns
/// - Proper error handling
/// - No unnecessary typealiases
public actor LoggingServiceActor: LoggingServiceProtocol {
    /// Registered log destinations, keyed by identifier
    private var destinations: [String: LoggingTypes.LogDestination]
    
    /// Global minimum log level
    private var minimumLogLevel: LoggingTypes.UmbraLogLevel
    
    /// Default formatter for log entries
    private let formatter: LoggingInterfaces.LogFormatterProtocol
    
    /// Initialise the logging service with specified configuration
    /// - Parameters:
    ///   - destinations: Initial log destinations
    ///   - minimumLogLevel: Global minimum log level
    ///   - formatter: Log formatter to use
    public init(
        destinations: [LoggingTypes.LogDestination] = [],
        minimumLogLevel: LoggingTypes.UmbraLogLevel = .info,
        formatter: LoggingInterfaces.LogFormatterProtocol? = nil
    ) {
        self.destinations = Dictionary(uniqueKeysWithValues: destinations.map { ($0.identifier, $0) })
        self.minimumLogLevel = minimumLogLevel
        self.formatter = formatter ?? DefaultLogFormatter()
    }
    
    // MARK: - LoggingServiceProtocol Implementation
    
    /// Log a verbose message
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    public func verbose(_ message: String, metadata: LoggingTypes.LogMetadata? = nil, source: String? = nil) async {
        await log(
            level: .verbose,
            message: message,
            metadata: metadata,
            source: source
        )
    }
    
    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    public func debug(_ message: String, metadata: LoggingTypes.LogMetadata? = nil, source: String? = nil) async {
        await log(
            level: .debug,
            message: message,
            metadata: metadata,
            source: source
        )
    }
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    public func info(_ message: String, metadata: LoggingTypes.LogMetadata? = nil, source: String? = nil) async {
        await log(
            level: .info,
            message: message,
            metadata: metadata,
            source: source
        )
    }
    
    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    public func warning(_ message: String, metadata: LoggingTypes.LogMetadata? = nil, source: String? = nil) async {
        await log(
            level: .warning,
            message: message,
            metadata: metadata,
            source: source
        )
    }
    
    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    public func error(_ message: String, metadata: LoggingTypes.LogMetadata? = nil, source: String? = nil) async {
        await log(
            level: .error,
            message: message,
            metadata: metadata,
            source: source
        )
    }
    
    /// Log a critical message
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component identifier
    public func critical(_ message: String, metadata: LoggingTypes.LogMetadata? = nil, source: String? = nil) async {
        await log(
            level: .critical,
            message: message,
            metadata: metadata,
            source: source
        )
    }
    
    /// Add a log destination
    /// - Parameter destination: The destination to add
    /// - Throws: LoggingError if the destination cannot be added
    public func addDestination(_ destination: LoggingTypes.LogDestination) async throws {
        let identifier = destination.identifier
        
        // Check for duplicate destination
        if destinations[identifier] != nil {
            throw LoggingTypes.LoggingError.duplicateDestination(identifier: identifier)
        }
        
        destinations[identifier] = destination
    }
    
    /// Remove a log destination by identifier
    /// - Parameter identifier: Unique identifier of the destination to remove
    /// - Returns: true if the destination was removed, false if not found
    public func removeDestination(withIdentifier identifier: String) async -> Bool {
        if destinations[identifier] != nil {
            destinations.removeValue(forKey: identifier)
            return true
        }
        return false
    }
    
    /// Set the global minimum log level
    /// - Parameter level: The minimum log level to record
    public func setMinimumLogLevel(_ level: LoggingTypes.UmbraLogLevel) async {
        minimumLogLevel = level
    }
    
    /// Get the current global minimum log level
    /// - Returns: The current minimum log level
    public func getMinimumLogLevel() async -> LoggingTypes.UmbraLogLevel {
        return minimumLogLevel
    }
    
    /// Flush all destinations, ensuring pending logs are written
    /// - Throws: LoggingError if any destination fails to flush
    public func flushAllDestinations() async throws {
        var errors: [String: Error] = [:]
        
        for (identifier, destination) in destinations {
            do {
                try await destination.flush()
            } catch {
                errors[identifier] = error
            }
        }
        
        if !errors.isEmpty {
            // If any destination failed to flush, throw an error with details
            let errorDetails = errors.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            throw LoggingInterfaces.LoggingError.destinationWriteFailed(
                destination: "multiple",
                reason: "Failed to flush destinations: \(errorDetails)"
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Internal method to log at a specific level
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source component
    private func log(
        level: LoggingTypes.UmbraLogLevel,
        message: String,
        metadata: LoggingTypes.LogMetadata?,
        source: String?
    ) async {
        // Skip if below minimum level
        guard level.rawValue >= minimumLogLevel.rawValue else {
            return
        }
        
        // Create log entry
        let entry = LoggingTypes.LogEntry(
            level: level,
            message: message,
            metadata: metadata,
            source: source
        )
        
        // Distribute to all destinations
        for (identifier, destination) in destinations {
            // Skip if below destination's minimum level
            guard level.rawValue >= destination.minimumLevel.rawValue else {
                continue
            }
            
            do {
                try await destination.write(entry)
            } catch {
                // For now, just print the error
                // In a more comprehensive implementation, we could store errors or notify error handlers
                print("Failed to write to destination \(identifier): \(error)")
            }
        }
    }
}

/// Default implementation of LogFormatterProtocol
public struct DefaultLogFormatter: LoggingInterfaces.LogFormatterProtocol {
    /// Configuration for the formatter
    private let includeTimestamp: Bool
    private let includeLevel: Bool
    private let includeSource: Bool
    private let includeMetadata: Bool
    
    /// Initialise with default configuration
    public init(
        includeTimestamp: Bool = true,
        includeLevel: Bool = true,
        includeSource: Bool = true,
        includeMetadata: Bool = true
    ) {
        self.includeTimestamp = includeTimestamp
        self.includeLevel = includeLevel
        self.includeSource = includeSource
        self.includeMetadata = includeMetadata
    }
    
    /// Format a log entry to a string
    /// - Parameter entry: The log entry to format
    /// - Returns: Formatted string representation of the log entry
    public func format(_ entry: LoggingTypes.LogEntry) -> String {
        var components: [String] = []
        
        if includeTimestamp {
            components.append("[\(formatTimestamp(entry.timestamp))]")
        }
        
        if includeLevel {
            components.append("[\(formatLogLevel(entry.level))]")
        }
        
        if includeSource, let source = entry.source {
            components.append("[\(source)]")
        }
        
        components.append(entry.message)
        
        if includeMetadata, let metadata = entry.metadata, let formattedMetadata = formatMetadata(metadata) {
            components.append(formattedMetadata)
        }
        
        return components.joined(separator: " ")
    }
    
    /// Format metadata to a string
    /// - Parameter metadata: Metadata to format
    /// - Returns: Formatted string representation of the metadata
    public func formatMetadata(_ metadata: LoggingTypes.LogMetadata?) -> String? {
        guard let metadata = metadata, !metadata.asDictionary.isEmpty else {
            return nil
        }
        
        let entries = metadata.asDictionary.map { "\"\($0.key)\": \"\($0.value)\"" }
        return "{ \(entries.joined(separator: ", ")) }"
    }
    
    /// Format a timestamp to a string
    /// - Parameter timestamp: The timestamp to format
    /// - Returns: Formatted string representation of the timestamp
    public func formatTimestamp(_ timestamp: LoggingTypes.TimePointAdapter) -> String {
        return timestamp.description
    }
    
    /// Format a log level to a string
    /// - Parameter level: The log level to format
    /// - Returns: Formatted string representation of the log level
    public func formatLogLevel(_ level: LoggingTypes.UmbraLogLevel) -> String {
        switch level {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        case .critical:
            return "CRITICAL"
        }
    }
    
    /// Customise the format based on configuration
    /// - Parameters:
    ///   - includeTimestamp: Whether to include timestamps in the output
    ///   - includeLevel: Whether to include log levels in the output
    ///   - includeSource: Whether to include source information in the output
    ///   - includeMetadata: Whether to include metadata in the output
    /// - Returns: A new formatter with the specified configuration
    public func withConfiguration(
        includeTimestamp: Bool,
        includeLevel: Bool,
        includeSource: Bool,
        includeMetadata: Bool
    ) -> LoggingInterfaces.LogFormatterProtocol {
        return DefaultLogFormatter(
            includeTimestamp: includeTimestamp,
            includeLevel: includeLevel,
            includeSource: includeSource,
            includeMetadata: includeMetadata
        )
    }
}
