import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # LoggingAdapter
 
 This adapter class wraps a LoggingServiceProtocol instance and adapts it to
 the LoggingProtocol interface. This allows components that expect a LoggingProtocol
 to work with services that implement LoggingServiceProtocol.
 
 The adapter follows the Adapter design pattern, providing a compatibility layer
 between two incompatible interfaces.
 */
public final class LoggingAdapter: LoggingProtocol {
    /// The wrapped logging service
    private let loggingService: LoggingServiceProtocol
    
    /**
     Initialise a new logging adapter.
     
     - Parameter wrapping: The logging service to adapt
     */
    public init(wrapping loggingService: LoggingServiceProtocol) {
        self.loggingService = loggingService
    }
    
    /// Log trace message
    public func trace(_ message: String, metadata: LogMetadata?, source: String?) async {
        await loggingService.trace(message, metadata: metadata, source: source)
    }
    
    /// Log debug message
    public func debug(_ message: String, metadata: LogMetadata?, source: String?) async {
        await loggingService.debug(message, metadata: metadata, source: source)
    }
    
    /// Log info message
    public func info(_ message: String, metadata: LogMetadata?, source: String?) async {
        await loggingService.info(message, metadata: metadata, source: source)
    }
    
    /// Log warning message
    public func warning(_ message: String, metadata: LogMetadata?, source: String?) async {
        await loggingService.warning(message, metadata: metadata, source: source)
    }
    
    /// Log error message
    public func error(_ message: String, metadata: LogMetadata?, source: String?) async {
        await loggingService.error(message, metadata: metadata, source: source)
    }
}
