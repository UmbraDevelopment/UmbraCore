import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for rotating logs in a destination.
 
 This command encapsulates the logic for rotating logs in a destination,
 following the command pattern architecture.
 */
public class RotateLogsCommand: BaseCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The ID of the destination to rotate logs for
    private let destinationId: String
    
    /// Options for rotating logs
    private let options: LoggingInterfaces.RotateLogsOptionsDTO
    
    /// Provider for logging operations
    private let provider: LoggingProviderProtocol
    
    /**
     Initialises a new rotate logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to rotate logs for
        - options: Options for rotating logs
        - provider: Provider for rotation operations
        - loggingServices: The logging services actor
     */
    public init(
        destinationId: String,
        options: LoggingInterfaces.RotateLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        loggingServices: LoggingServicesActor
    ) {
        self.destinationId = destinationId
        self.options = options
        self.provider = provider
        
        super.init(loggingServices: loggingServices)
    }
    
    /**
     Executes the rotate logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LoggingInterfaces.LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = LoggingInterfaces.BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "rotateLogs",
            category: "LogRotation",
            source: "UmbraCore",
            metadata: LoggingInterfaces.LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withPublic(key: "forceRotation", value: String(options.forceRotation))
                .withPublic(key: "maxBackupCount", value: String(options.maxBackupCount))
        )
        
        // Log operation start
        await logInfo("Starting log rotation for destination '\(destinationId)'")
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingTypes.LoggingError.destinationNotFound("Destination with ID \(destinationId) not found")
            }
            
            // Check if the destination type supports rotation
            guard destination.type == .file else {
                throw LoggingTypes.LoggingError.invalidDestinationConfig(
                    "Log rotation is only supported for file destinations"
                )
            }
            
            // Rotate logs using provider
            let success = try await provider.rotateLogs(
                for: destination,
                options: options
            )
            
            // Log success or failure
            if success {
                await logInfo("Successfully rotated logs for destination '\(destinationId)'")
            } else {
                await logWarning("Failed to rotate logs for destination '\(destinationId)'")
            }
            
            return success
            
        } catch {
            // Log failure
            await logError("Log rotation failed: \(error.localizedDescription)")
            throw error
        }
    }
}
