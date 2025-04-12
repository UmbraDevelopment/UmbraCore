import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for removing a log destination.
 
 This command encapsulates the logic for removing a registered destination,
 ensuring that proper cleanup such as log flushing is performed.
 */
public class RemoveDestinationCommand: BaseCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The ID of the destination to remove
    private let destinationId: String
    
    /// Options for removing the destination
    private let options: LoggingInterfaces.RemoveDestinationOptionsDTO
    
    /// Provider for logging operations
    private let provider: LoggingProviderProtocol
    
    /**
     Initialises a new remove destination command.
     
     - Parameters:
        - destinationId: The ID of the destination to remove
        - options: Options for removing the destination
        - provider: Provider for destination operations
        - loggingServices: The logging services actor
     */
    public init(
        destinationId: String,
        options: LoggingInterfaces.RemoveDestinationOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        loggingServices: LoggingServicesActor
    ) {
        self.destinationId = destinationId
        self.options = options
        self.provider = provider
        
        super.init(loggingServices: loggingServices)
    }
    
    /**
     Executes the remove destination command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LoggingInterfaces.LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = LoggingInterfaces.BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "removeDestination",
            category: "DestinationManagement",
            source: "UmbraCore",
            metadata: LoggingInterfaces.LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withPublic(key: "flushBeforeRemoval", value: String(options.flushBeforeRemoval))
                .withPublic(key: "archiveLogs", value: String(options.archiveLogs))
        )
        
        // Log operation start
        await logInfo("Starting to remove destination with ID '\(destinationId)'")
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingInterfaces.LoggingError.destinationNotFound(
                    "Cannot remove destination with ID \(destinationId): not found"
                )
            }
            
            // Flush pending logs if requested
            if options.flushBeforeRemoval {
                await logInfo(
                    "Flushing logs before removing destination"
                )
                
                try await provider.flushLogs(for: destination)
            }
            
            // Archive logs if requested
            if options.archiveLogs {
                await logInfo(
                    "Archiving logs before removing destination"
                )
                
                if let archivePath = options.archivePath {
                    let archiveOptions = LoggingInterfaces.ArchiveLogsOptionsDTO(
                        destinationPath: archivePath,
                        compress: true,
                        format: .zip,
                        filterCriteria: nil,
                        deleteAfterArchiving: false,
                        encryptionPassword: nil
                    )
                    
                    let success = try await provider.archiveLogs(
                        from: destination,
                        options: archiveOptions
                    )
                    
                    if !success {
                        await logWarning(
                            "Archiving logs failed, but continuing with removal"
                        )
                    } else {
                        await logInfo(
                            "Successfully archived logs to: \(archivePath)"
                        )
                    }
                } else {
                    await logWarning(
                        "Cannot archive logs: no archive path specified"
                    )
                }
            }
            
            // Remove the destination
            let success = try await loggingServices.removeDestination(withId: destinationId)
            
            // Log success
            if success {
                await logInfo("Successfully removed destination with ID '\(destinationId)'")
            } else {
                await logWarning("Failed to remove destination with ID '\(destinationId)'")
            }
            
            return success
            
        } catch {
            // Log failure
            await logError("Failed to remove destination: \(error.localizedDescription)")
            throw error
        }
    }
}
