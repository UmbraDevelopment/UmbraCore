import Foundation
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Factory for creating logging service instances.
 
 This factory simplifies the creation of logging service instances
 with appropriate provider implementations.
 */
public class LoggingServicesFactory {
    
    /**
     Creates a new instance of the logging service.
     
     - Parameters:
        - providers: Map of providers by destination type
        - minimumLogLevel: Minimum log level to record
     - Returns: A new logging service instance
     */
    public static func createLoggingService(
        providers: [LogDestinationType: LoggingProviderProtocol],
        minimumLogLevel: LogLevel = .info
    ) -> PrivacyAwareLoggingProtocol {
        // Create a bootstrap logger for the factory
        let bootstrapLogger = BootstrapLogger()
        
        // Create command factory with providers and bootstrap logger
        let commandFactory = LogCommandFactory(
            providers: providers,
            logger: bootstrapLogger
        )
        
        // Create and return the logging service actor
        return LoggingServicesActor(
            commandFactory: commandFactory,
            minimumLogLevel: minimumLogLevel
        )
    }
    
    /**
     Creates a new logging service with default providers.
     
     - Parameters:
        - minimumLogLevel: Minimum log level to record
     - Returns: A new logging service instance
     */
    public static func createDefaultLoggingService(
        minimumLogLevel: LogLevel = .info
    ) -> PrivacyAwareLoggingProtocol {
        // Create default providers
        let consoleProvider = ConsoleLoggingProvider()
        let fileProvider = FileLoggingProvider()
        
        // Map providers by destination type
        let providers: [LogDestinationType: LoggingProviderProtocol] = [
            .console: consoleProvider,
            .file: fileProvider
        ]
        
        return createLoggingService(
            providers: providers,
            minimumLogLevel: minimumLogLevel
        )
    }
}

/**
 A simple bootstrap logger used during initialization.
 
 This provides basic logging functionality until the real logging system
 is fully initialized and operational.
 */
private class BootstrapLogger: PrivacyAwareLoggingProtocol {
    func log(
        _ level: LogLevel,
        _ message: String,
        context: LogContextDTO,
        file: String,
        function: String,
        line: Int
    ) async {
        // Simple console output during bootstrap
        print("[\(level.rawValue)] \(message)")
    }
    
    // Minimal implementation to satisfy protocol requirements
    func addDestination(
        _ destination: LogDestinationDTO,
        options: AddDestinationOptionsDTO
    ) async throws -> Bool {
        // Do nothing in bootstrap logger
        return true
    }
    
    func removeDestination(
        withId destinationId: String,
        options: RemoveDestinationOptionsDTO
    ) async throws -> Bool {
        // Do nothing in bootstrap logger
        return true
    }
    
    func setMinimumLogLevel(_ level: LogLevel) async {
        // Do nothing in bootstrap logger
    }
    
    func getMinimumLogLevel() async -> LogLevel {
        return .info
    }
    
    func setDefaultDestinations(_ destinationIds: [String]) async {
        // Do nothing in bootstrap logger
    }
    
    func getDefaultDestinations() async -> [String] {
        return []
    }
    
    func getActiveDestinations() async -> [LogDestinationDTO] {
        return []
    }
    
    func rotateLogs(
        forDestination destinationId: String,
        options: RotateLogsOptionsDTO
    ) async throws -> LogRotationResultDTO {
        // Do nothing in bootstrap logger
        return LogRotationResultDTO(success: false)
    }
    
    func exportLogs(
        fromDestination destinationId: String,
        options: ExportLogsOptionsDTO
    ) async throws -> Data {
        // Do nothing in bootstrap logger
        return Data()
    }
    
    func queryLogs(
        fromDestination destinationId: String,
        options: QueryLogsOptionsDTO
    ) async throws -> [LogEntryDTO] {
        // Do nothing in bootstrap logger
        return []
    }
    
    func archiveLogs(
        fromDestination destinationId: String,
        options: ArchiveLogsOptionsDTO
    ) async throws -> LogArchiveResultDTO {
        // Do nothing in bootstrap logger
        return LogArchiveResultDTO(success: false)
    }
    
    func purgeLogs(
        fromDestination destinationId: String?,
        options: PurgeLogsOptionsDTO
    ) async throws -> LogPurgeResultDTO {
        // Do nothing in bootstrap logger
        return LogPurgeResultDTO(success: false)
    }
}
