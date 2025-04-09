import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Null Logger
 
 A logger implementation that does nothing. This is useful for cases where
 logging is not required but a logger instance is expected by the API.
 
 This logger conforms to the PrivacyAwareLoggingProtocol and implements all
 required methods, but does not perform any actual logging.
 */
@preconcurrency
public actor NullLogger: PrivacyAwareLoggingProtocol {
    /// The logging actor used by this logger
    public nonisolated let loggingActor: LoggingActor = .init(destinations: [])
    
    /// Initializes a new NullLogger instance
    public init() {}
    
    // MARK: - CoreLoggingProtocol
    
    /// Does nothing
    public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {}
    
    // MARK: - LoggingProtocol Convenience Methods
    
    /// Does nothing
    public func trace(_ message: String, context: LogContextDTO) async {}
    
    /// Does nothing
    public func debug(_ message: String, context: LogContextDTO) async {}
    
    /// Does nothing
    public func info(_ message: String, context: LogContextDTO) async {}
    
    /// Does nothing
    public func warning(_ message: String, context: LogContextDTO) async {}
    
    /// Does nothing
    public func error(_ message: String, context: LogContextDTO) async {}
    
    /// Does nothing
    public func critical(_ message: String, context: LogContextDTO) async {}
    
    // MARK: - PrivacyAwareLoggingProtocol
    
    /// Does nothing
    public func log(_ level: LogLevel, _ message: PrivacyString, context: LogContextDTO) async {}
    
    /// Does nothing
    public func logSensitive(
        _ level: LogLevel,
        _ message: String,
        sensitiveValues: LogMetadata,
        context: LogContextDTO
    ) async {}
    
    /// Does nothing
    public func trace(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {}
    
    /// Does nothing
    public func debug(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {}
    
    /// Does nothing
    public func info(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {}
    
    /// Does nothing
    public func warning(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {}
    
    /// Does nothing
    public func error(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {}
    
    /// Does nothing
    public func critical(_ message: String, metadata: LogMetadataDTOCollection?, source: String) async {}
    
    /// Does nothing
    public func logError(_ error: Error, context: LogContextDTO) async {}
    
    /// Does nothing
    public func logError(
        _ error: Error,
        privacyLevel: LogPrivacyLevel,
        context: LogContextDTO
    ) async {}
}
