import LoggingTypes
import LoggingInterfaces

/// A simple console-based logging backend implementation that writes logs to standard output.
/// Useful for development and testing purposes.
public struct ConsoleLoggingBackend: LoggingBackend {
    /// Initialises a new console logging backend
    public init() {}
    
    /// Writes a log message to the console with formatting based on the log level
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
        // Format timestamp
        let timestamp = formatTimestamp(context.timestamp)
        
        // Create colour and emoji prefix based on log level
        let (emoji, colourCode) = formatForLevel(level)
        
        // Format metadata if present
        var metadataString = ""
        if let metadata = context.metadata, !metadata.isEmpty {
            metadataString = " " + formatMetadata(metadata)
        }
        
        // Format and print the log message
        let formattedMessage = "\(colourCode)\(timestamp) \(emoji) [\(level)] [\(subsystem):\(context.source)] \(message)\(metadataString) [correlation: \(context.correlationId)]\u{001B}[0m"
        print(formattedMessage)
    }
    
    /// Formats a timestamp for display
    /// - Parameter timestamp: The timestamp to format
    /// - Returns: A formatted timestamp string
    private func formatTimestamp(_ timestamp: LogTimestamp) -> String {
        let date = Date(timeIntervalSince1970: timestamp.secondsSinceEpoch)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    /// Provides formatting information for each log level
    /// - Parameter level: The log level to format
    /// - Returns: A tuple containing an emoji and ANSI colour code for the log level
    private func formatForLevel(_ level: LogLevel) -> (emoji: String, colourCode: String) {
        switch level {
        case .trace:
            return ("🔍", "\u{001B}[90m") // Dark gray
        case .debug:
            return ("🐞", "\u{001B}[36m") // Cyan
        case .info:
            return ("ℹ️", "\u{001B}[32m") // Green
        case .warning:
            return ("⚠️", "\u{001B}[33m") // Yellow
        case .error:
            return ("❌", "\u{001B}[31m") // Red
        case .critical:
            return ("🚨", "\u{001B}[41m\u{001B}[37m") // White on red background
        }
    }
    
    /// Formats metadata for display
    /// - Parameter metadata: The metadata to format
    /// - Returns: A formatted metadata string
    private func formatMetadata(_ metadata: LogMetadata) -> String {
        var parts: [String] = []
        
        for (key, value) in metadata {
            let formattedValue: String
            
            switch value.privacy {
            case .public:
                formattedValue = "\(value.value)"
            case .private:
                #if DEBUG
                formattedValue = "🔒[\(value.value)]"
                #else
                formattedValue = "🔒[REDACTED]"
                #endif
            case .sensitive:
                formattedValue = "🔐[SENSITIVE]"
            case .hash:
                if let stringValue = value.value as? String {
                    let hashedValue = simpleHash(stringValue)
                    formattedValue = "🔏[\(hashedValue)]"
                } else {
                    formattedValue = "🔏[HASHED]"
                }
            case .auto:
                #if DEBUG
                formattedValue = "🔍[\(value.value)]"
                #else
                formattedValue = "🔍[AUTO-REDACTED]"
                #endif
            }
            
            parts.append("\(key): \(formattedValue)")
        }
        
        return "{" + parts.joined(separator: ", ") + "}"
    }
    
    /// Creates a simple hash representation of a string
    /// - Parameter value: The string to hash
    /// - Returns: A simple hash string
    private func simpleHash(_ value: String) -> String {
        // This is a placeholder for a real hashing algorithm
        // In a real implementation, this would use a cryptographic hash function
        let chars = Array(value)
        var hashValue = 0
        
        for char in chars {
            hashValue = ((hashValue << 5) &+ hashValue) &+ Int(char.asciiValue ?? 0)
        }
        
        return String(format: "%08x", abs(hashValue))
    }
}
