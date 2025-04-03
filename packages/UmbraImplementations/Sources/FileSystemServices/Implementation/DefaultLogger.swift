import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 A simple default logger implementation that provides basic logging functionality.
 Used as a fallback when no logger is explicitly provided to components.
 */
public struct DefaultLogger: LoggingProtocol {
    /// The underlying logging actor
    public let loggingActor: LoggingActor = LoggingActor()
    
    /// Initialize a new default logger
    public init() {}
    
    /// Log a message with the specified level and context
    /// - Parameters:
    ///   - level: The severity level
    ///   - message: The message to log
    ///   - context: The logging context
    public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
        // In a real implementation, this would write to a log destination
        // For this simple implementation, we just print to the console with the level
        #if DEBUG
        print("[\(level.rawValue.uppercased())] \(message)")
        #endif
    }
}
