import Foundation
import LoggingInterfaces
import LoggingTypes
import os.log

/**
 * Factory for creating loggers with consistent configuration.
 * 
 * This implementation follows the Alpha Dot Five architecture principles:
 * - Type-safe interfaces
 * - Privacy-by-design logging
 * - Consistent error handling
 */
public enum LoggerFactory {
    /**
     * Creates a logger with the specified configuration.
     *
     * - Parameters:
     *   - subsystem: The subsystem for the logger (typically reverse-DNS notation)
     *   - category: The category for the logger
     *   - privacyLevel: The default privacy level
     * - Returns: A configured logger
     */
    public static func createLogger(
        subsystem: String,
        category: String,
        privacyLevel: LogPrivacyLevel = .private
    ) -> LoggingProtocol {
        APIServicesLogger(
            subsystem: subsystem,
            category: category,
            privacyLevel: privacyLevel
        )
    }
}

/**
 * Concrete implementation of LoggingProtocol for API Services
 * 
 * This logger uses os_log internally but provides a consistent
 * interface for the API Services module.
 */
private class APIServicesLogger: LoggingProtocol {
    /// The underlying system logger
    private let logger: OSLog
    
    /// Default privacy level for this logger
    private let defaultPrivacyLevel: LogPrivacyLevel
    
    /**
     * Initialises a new API services logger.
     *
     * - Parameters:
     *   - subsystem: The subsystem for the logger
     *   - category: The category for the logger
     *   - privacyLevel: The default privacy level
     */
    init(
        subsystem: String,
        category: String,
        privacyLevel: LogPrivacyLevel
    ) {
        self.logger = OSLog(subsystem: subsystem, category: category)
        self.defaultPrivacyLevel = privacyLevel
    }
    
    // MARK: - LoggingProtocol Methods
    
    func debug(_ message: String, context: LogContextDTO?) async {
        log(message, type: .debug, context: context)
    }
    
    func info(_ message: String, context: LogContextDTO?) async {
        log(message, type: .info, context: context)
    }
    
    func warning(_ message: String, context: LogContextDTO?) async {
        log(message, type: .default, context: context)
    }
    
    func error(_ message: String, context: LogContextDTO?) async {
        log(message, type: .error, context: context)
    }
    
    func critical(_ message: String, context: LogContextDTO?) async {
        log(message, type: .fault, context: context)
    }
    
    func trace(_ message: String, context: LogContextDTO?) async {
        // For trace, we use debug level but add additional context
        log("TRACE: \(message)", type: .debug, context: context)
    }
    
    // MARK: - Private Helper Methods
    
    private func log(_ message: String, type: OSLogType, context: LogContextDTO?) {
        let contextInfo = formatContext(context)
        os_log("%{public}s %{private}s", log: logger, type: type, message, contextInfo)
    }
    
    private func formatContext(_ context: LogContextDTO?) -> String {
        guard let context = context else {
            return ""
        }
        
        var parts: [String] = []
        
        if let source = context.source {
            parts.append("src=\(source)")
        }
        
        if let correlationID = context.correlationID {
            parts.append("corr=\(correlationID)")
        }
        
        // Format metadata as key-value pairs
        let metadataString = formatMetadata(context.metadata)
        if !metadataString.isEmpty {
            parts.append(metadataString)
        }
        
        return parts.isEmpty ? "" : "[\(parts.joined(separator: ", "))]"
    }
    
    private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
        // This is a simplified implementation that doesn't handle complex metadata fully
        // In a real implementation, you would need to handle different value types
        var parts: [String] = []
        
        // Add public keys
        for (key, value) in metadata.publicKeyValues {
            parts.append("\(key)=\(value)")
        }
        
        // Add private keys in a privacy-conscious way
        for key in metadata.privateKeys {
            parts.append("\(key)=<private>")
        }
        
        return parts.joined(separator: ", ")
    }
}
