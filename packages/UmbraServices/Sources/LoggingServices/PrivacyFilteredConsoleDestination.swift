import Foundation
import LoggingTypes
import LoggingInterfaces

/// A privacy-aware console log destination that applies privacy controls to sensitive data
/// Implementation is thread-safe via the actor model
public actor PrivacyFilteredConsoleDestination: ActorLogDestination {
    /// Unique identifier for this destination
    public let identifier: String
    
    /// The minimum log level this destination will process
    public let minimumLogLevel: LogLevel?
    
    /// Whether to include timestamps in log output
    private let includeTimestamp: Bool
    
    /// Whether to include the log source in output
    private let includeSource: Bool
    
    /// Whether to include metadata in output
    private let includeMetadata: Bool
    
    /// Controls how private values are filtered
    private let privacyMode: PrivacyFilterMode
    
    /// Initialise a new privacy-filtered console log destination
    /// - Parameters:
    ///   - identifier: Unique identifier for this destination
    ///   - minimumLogLevel: Optional minimum log level to process
    ///   - includeTimestamp: Whether to include timestamps in log output
    ///   - includeSource: Whether to include the log source in output
    ///   - includeMetadata: Whether to include metadata in output
    ///   - privacyMode: How to filter private values
    public init(
        identifier: String = "privacy-console",
        minimumLogLevel: LogLevel? = nil,
        includeTimestamp: Bool = true,
        includeSource: Bool = true,
        includeMetadata: Bool = true,
        privacyMode: PrivacyFilterMode = .debugModeDefault
    ) {
        self.identifier = identifier
        self.minimumLogLevel = minimumLogLevel
        self.includeTimestamp = includeTimestamp
        self.includeSource = includeSource
        self.includeMetadata = includeMetadata
        self.privacyMode = privacyMode
    }
    
    /// Write a privacy-filtered log entry to the console
    /// - Parameter entry: The log entry to write
    public func write(_ entry: LogEntry) async {
        // Since this method runs on the actor, it's already thread-safe
        print(formatEntry(entry))
    }
    
    /// Format a log entry as a string for console output with privacy filtering
    /// - Parameter entry: The log entry to format
    /// - Returns: A formatted string representation of the log entry
    private func formatEntry(_ entry: LogEntry) -> String {
        var components: [String] = []
        
        // Add log level
        components.append("[\(entry.level.rawValue.uppercased())]")
        
        // Add timestamp if enabled
        if includeTimestamp {
            components.append("[\(formatTimestamp(entry.timestamp))]")
        }
        
        // Add source if enabled
        if includeSource && !entry.source.isEmpty {
            components.append("[\(entry.source)]")
        }
        
        // Add privacy-filtered message
        components.append(applyPrivacyFiltering(to: entry.message))
        
        // Add filtered metadata if enabled and present
        if includeMetadata, let metadata = entry.metadata, !metadata.isEmpty {
            components.append("- Metadata: \(formatPrivacyFilteredMetadata(metadata))")
        }
        
        return components.joined(separator: " ")
    }
    
    /// Format a timestamp for console output
    /// - Parameter timestamp: The timestamp to format
    /// - Returns: A formatted timestamp string
    private func formatTimestamp(_ timestamp: LogTimestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let date = Date(timeIntervalSince1970: timestamp.secondsSinceEpoch)
        return formatter.string(from: date)
    }
    
    /// Apply privacy filtering to a message string
    /// - Parameter message: The message to filter
    /// - Returns: A privacy-filtered message
    private func applyPrivacyFiltering(to message: String) -> String {
        // In a real implementation, this would parse the message for privacy markers
        // and apply appropriate filtering based on the privacy mode.
        // This is a simplified version that just returns the original message.
        return message
    }
    
    /// Format metadata for console output with privacy filtering
    /// - Parameter metadata: The metadata to format
    /// - Returns: A formatted metadata string with privacy filtering applied
    private func formatPrivacyFilteredMetadata(_ metadata: PrivacyMetadata) -> String {
        let pairs = metadata.entriesDict().map { key, value in
            let filteredValue = applyPrivacyFiltering(to: value.valueString, withLevel: value.privacy)
            return "\(key): \(filteredValue)"
        }
        return "{" + pairs.joined(separator: ", ") + "}"
    }
    
    /// Apply privacy filtering to a metadata value
    /// - Parameters:
    ///   - value: The value to filter
    ///   - level: The privacy level to apply
    /// - Returns: A filtered value based on privacy level
    private func applyPrivacyFiltering(to value: String, withLevel level: LogPrivacyLevel) -> String {
        switch (level, privacyMode) {
        case (.public, _):
            // Public values are never filtered
            return value
            
        case (.private, .debugModeDefault), (.sensitive, .debugModeDefault):
            // In debug mode, private and sensitive values are shown by default
            return value
            
        case (.private, .releaseMode), (.sensitive, .releaseMode):
            // In release mode, private and sensitive values are redacted
            return level == .private ? "<private>" : "<sensitive>"
            
        case (.hash, _):
            // Hashed values are always hashed
            return String(value.hash)
            
        case (.auto, _):
            // Auto values use context-dependent filtering
            #if DEBUG
            return value
            #else
            return "<redacted>"
            #endif
            
        default:
            // Default to redacting unknown privacy levels
            return "<redacted>"
        }
    }
}

/// Defines how privacy filtering should be applied
public enum PrivacyFilterMode {
    /// Debug mode default - show most private data for debugging
    case debugModeDefault
    
    /// Release mode - redact all private data
    case releaseMode
    
    /// Custom filtering rules
    case custom(redactPrivate: Bool, redactSensitive: Bool, hashSensitive: Bool)
}
