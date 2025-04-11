import Foundation
import LoggingTypes

/// Protocol for logging providers that handle the actual writing of log entries
public protocol LoggingProviderProtocol: Sendable {
    /// Write a log entry to a destination
    /// - Parameters:
    ///   - entry: The log entry to write
    ///   - destination: The destination to write to
    /// - Returns: Whether the write was successful
    /// - Throws: Any errors encountered during the write
    func writeLogEntry(_ entry: LogEntryDTO, to destination: LogDestinationDTO) async throws -> Bool
    
    /// Validate a destination configuration
    /// - Parameter destination: The destination configuration to validate
    /// - Returns: Whether the configuration is valid
    func validateDestination(_ destination: LogDestinationDTO) async -> Bool
}

/// Default implementation extension
public extension LoggingProviderProtocol {
    /// Create a default implementation that does nothing except log to console
    static func createDefault() -> LoggingProviderProtocol {
        return DefaultLoggingProvider()
    }
}

/// A simple default implementation that just prints to console
private final class DefaultLoggingProvider: LoggingProviderProtocol {
    func writeLogEntry(_ entry: LogEntryDTO, to destination: LogDestinationDTO) async throws -> Bool {
        print("[\(entry.level)] \(entry.message)")
        return true
    }
    
    func validateDestination(_ destination: LogDestinationDTO) async -> Bool {
        return true
    }
}
