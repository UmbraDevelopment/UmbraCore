import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 A basic console logger implementation that can be used as a fallback when no other logging service is available.
 
 This implementation writes logs to the standard output with minimal formatting and privacy controls.
 It should only be used for development or as a last resort when the primary logging system is unavailable.
 */
public actor ConsoleLogger: LoggingProtocol {
    // MARK: - Properties
    
    /// Whether logging is enabled
    public var isEnabled: Bool = true
    
    /// The minimum log level to record
    public var minimumLogLevel: LogLevel = .debug
    
    /// The underlying logging actor (self in this case since we're already an actor)
    public var loggingActor: LoggingActor {
        self
    }
    
    // MARK: - Initialization
    
    /// Creates a new console logger
    public init() {}
    
    // MARK: - LoggingProtocol Implementation
    
    /// Log a message at the specified level with context
    public func log(level: LogLevel, message: String, context: LogContextDTO) async {
        guard isEnabled && level >= minimumLogLevel else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let contextString = "[\(context.operation)][\(context.category)]"
        let levelString = levelToString(level)
        
        print("[\(timestamp)][\(levelString)]\(contextString) \(message)")
        
        // Print metadata if available (limited for privacy)
        let safeMetadata = formatMetadata(context.metadata)
        if !safeMetadata.isEmpty {
            print("  Metadata: \(safeMetadata)")
        }
    }
    
    /// Log at debug level with context
    public func debug(_ message: String, context: LogContextDTO) async {
        await log(level: .debug, message: message, context: context)
    }
    
    /// Log at info level with context
    public func info(_ message: String, context: LogContextDTO) async {
        await log(level: .info, message: message, context: context)
    }
    
    /// Log at notice level with context
    public func notice(_ message: String, context: LogContextDTO) async {
        await log(level: .notice, message: message, context: context)
    }
    
    /// Log at warning level with context
    public func warning(_ message: String, context: LogContextDTO) async {
        await log(level: .warning, message: message, context: context)
    }
    
    /// Log at error level with context
    public func error(_ message: String, context: LogContextDTO) async {
        await log(level: .error, message: message, context: context)
    }
    
    /// Log at critical level with context
    public func critical(_ message: String, context: LogContextDTO) async {
        await log(level: .critical, message: message, context: context)
    }
    
    /// Log at debug level with simple context
    public func debug(_ message: String) async {
        await log(level: .debug, message: message, context: NullLogContext())
    }
    
    /// Log at info level with simple context
    public func info(_ message: String) async {
        await log(level: .info, message: message, context: NullLogContext())
    }
    
    /// Log at warning level with simple context
    public func warning(_ message: String) async {
        await log(level: .warning, message: message, context: NullLogContext())
    }
    
    /// Log at error level with simple context
    public func error(_ message: String) async {
        await log(level: .error, message: message, context: NullLogContext())
    }
    
    /// Helper to convert a log level to a string
    private func levelToString(_ level: LogLevel) -> String {
        switch level {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .notice: return "NOTICE"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            case .critical: return "CRITICAL"
            @unknown default: return "UNKNOWN"
        }
    }
    
    /// Format metadata for display, taking privacy into account
    private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
        var result: [String] = []
        
        for entry in metadata.entries {
            let valueDisplay: String
            
            // Apply basic privacy rules
            switch entry.privacyLevel {
                case .public:
                    valueDisplay = entry.value
                case .private:
                    valueDisplay = "[PRIVATE]"
                case .sensitive:
                    valueDisplay = "[SENSITIVE]"
                case .hash:
                    valueDisplay = "[HASH]"
                case .auto:
                    valueDisplay = "[AUTO]"
                @unknown default:
                    valueDisplay = "[UNKNOWN]"
            }
            
            result.append("\(entry.key)=\(valueDisplay)")
        }
        
        return result.joined(separator: ", ")
    }
}

/// A minimal log context used as a fallback
private struct NullLogContext: LogContextDTO {
    public let domainName: String = "console"
    public let operation: String = "console"
    public let category: String = "log"
    public let source: String? = nil
    public let correlationID: String? = nil
    public let metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
    
    public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
        // For simplicity, we don't support additional metadata in the null context
        return self
    }
}
