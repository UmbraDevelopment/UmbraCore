#if canImport(OSLog)
import OSLog
#endif
import LoggingTypes
import LoggingInterfaces

/// Logging backend that uses Apple's OSLog system with privacy annotations.
/// This backend applies the privacy controls defined in LogPrivacyLevel
/// to the OSLog privacy annotations.
public struct OSLogPrivacyBackend: LoggingBackend {
    /// The default log subsystem identifier
    private let defaultSubsystem: String
    
    /// Creates a new OSLog backend with the specified subsystem
    /// - Parameter subsystem: The subsystem identifier to use for logs
    public init(subsystem: String) {
        self.defaultSubsystem = subsystem
    }
    
    /// Writes a log message to OSLog with appropriate privacy annotations
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - context: Contextual information about the log
    ///   - subsystem: The subsystem identifier (defaults to the one provided at initialization)
    public func writeLog(
        level: LogLevel,
        message: String,
        context: LogContext,
        subsystem: String
    ) async {
        #if canImport(OSLog)
        let subsystemToUse = subsystem.isEmpty ? defaultSubsystem : subsystem
        let category = context.source
        
        let logger = Logger(subsystem: subsystemToUse, category: category)
        
        // Map LogLevel to OSLogType
        let osLogType: OSLogType
        switch level {
        case .trace: osLogType = .debug
        case .debug: osLogType = .debug
        case .info: osLogType = .info
        case .warning: osLogType = .default
        case .error: osLogType = .error
        case .critical: osLogType = .fault
        }
        
        // Create metadata string if present
        var logMessage = message
        if let metadata = context.metadata, !metadata.isEmpty {
            let metadataString = formatMetadataWithPrivacy(metadata)
            logMessage += " \(metadataString)"
        }
        
        logger.log(level: osLogType, "\(logMessage) [correlation: \(context.correlationId)]")
        #else
        // Fallback for platforms without OSLog
        print("[\(level)] \(message) [source: \(context.source), correlation: \(context.correlationId)]")
        #endif
    }
    
    /// Formats metadata with appropriate privacy annotations for OSLog
    /// - Parameter metadata: The metadata with privacy annotations
    /// - Returns: A formatted string with OSLog privacy qualifiers
    private func formatMetadataWithPrivacy(_ metadata: LogMetadata) -> String {
        var parts: [String] = []
        
        for (key, value) in metadata {
            let privacyAnnotation: String
            
            #if canImport(OSLog)
            // Apply different OSLog privacy annotations based on our LogPrivacyLevel
            switch value.privacy {
            case .public:
                // Public information: no privacy protection needed
                privacyAnnotation = "\(key): \(value.value)"
                
            case .private:
                // Private information: use OSLog's private qualifier
                privacyAnnotation = "\(key): \(OSLogPrivate: value.value)"
                
            case .sensitive:
                // Sensitive information: use OSLog's private qualifier
                // In DEBUG, we show it with a marker, otherwise completely redacted
                #if DEBUG
                privacyAnnotation = "\(key): 🔐[\(OSLogPrivate: value.value)]"
                #else
                privacyAnnotation = "\(key): 🔐[SENSITIVE]"
                #endif
                
            case .hash:
                // Hashed information: compute a hash for correlation
                if let stringValue = value.value as? String {
                    let hashedValue = simpleHash(stringValue)
                    privacyAnnotation = "\(key): 🔏[\(hashedValue)]"
                } else {
                    privacyAnnotation = "\(key): 🔏[HASHED]"
                }
                
            case .auto:
                // Auto privacy: Use OSLog's default behavior which is smart about PII
                privacyAnnotation = "\(key): \(value.value)"
            }
            #else
            // Fallback for platforms without OSLog
            switch value.privacy {
            case .public:
                privacyAnnotation = "\(key): \(value.value)"
            case .private, .sensitive:
                #if DEBUG
                privacyAnnotation = "\(key): 🔒[\(value.value)]"
                #else
                privacyAnnotation = "\(key): 🔒[REDACTED]"
                #endif
            case .hash:
                if let stringValue = value.value as? String {
                    let hashedValue = simpleHash(stringValue)
                    privacyAnnotation = "\(key): 🔏[\(hashedValue)]"
                } else {
                    privacyAnnotation = "\(key): 🔏[HASHED]"
                }
            case .auto:
                #if DEBUG
                privacyAnnotation = "\(key): \(value.value)"
                #else
                privacyAnnotation = "\(key): [REDACTED]"
                #endif
            }
            #endif
            
            parts.append(privacyAnnotation)
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
