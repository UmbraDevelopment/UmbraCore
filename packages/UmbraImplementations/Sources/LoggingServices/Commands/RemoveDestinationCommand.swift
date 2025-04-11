import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for removing a log destination.
 
 This command encapsulates the logic for removing a log destination,
 following the command pattern architecture.
 */
public class RemoveDestinationCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The ID of the destination to remove
    private let destinationId: String
    
    /// Options for removing the destination
    private let options: RemoveDestinationOptionsDTO
    
    /**
     Initialises a new remove destination command.
     
     - Parameters:
        - destinationId: The ID of the destination to remove
        - options: Options for removing the destination
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destinationId: String,
        options: RemoveDestinationOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destinationId = destinationId
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the remove destination command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "removeDestination",
            destinationId: destinationId,
            additionalMetadata: [
                "flushBeforeRemoval": (value: String(options.flushBeforeRemoval), privacyLevel: .public),
                "archiveLogs": (value: String(options.archiveLogs), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "removeDestination", context: operationContext)
        
        do {
            // Check if destination exists
            guard let destination = getDestination(id: destinationId) else {
                throw LoggingError.destinationNotFound(
                    "Cannot remove destination with ID \(destinationId): not found"
                )
            }
            
            // Flush pending logs if requested
            if options.flushBeforeRemoval {
                await logger.log(
                    .debug,
                    "Flushing logs before removing destination",
                    context: operationContext
                )
                
                try await provider.flushLogs(for: destination)
            }
            
            // Archive logs if requested
            if options.archiveLogs {
                await logger.log(
                    .debug,
                    "Archiving logs before removing destination",
                    context: operationContext
                )
                
                if let archivePath = options.archivePath {
                    let archiveOptions = ArchiveLogsOptionsDTO(
                        destinationPath: archivePath,
                        compress: true,
                        format: .zip,
                        deleteAfterArchiving: false
                    )
                    
                    let archiveResult = try await provider.archiveLogs(
                        from: destination,
                        options: archiveOptions
                    )
                    
                    if !archiveResult.success {
                        await logger.log(
                            .warning,
                            "Archiving logs failed, but continuing with removal",
                            context: operationContext
                        )
                    } else {
                        await logger.log(
                            .info,
                            "Successfully archived logs to: \(archiveResult.archivePath ?? "unknown")",
                            context: operationContext
                        )
                    }
                } else {
                    await logger.log(
                        .warning,
                        "Cannot archive logs: no archive path specified",
                        context: operationContext
                    )
                }
            }
            
            // Unregister the destination
            unregisterDestination(id: destinationId)
            
            // Log success
            await logOperationSuccess(
                operation: "removeDestination",
                context: operationContext,
                additionalMetadata: [
                    "remainingDestinations": (value: String(Self.registeredDestinations.count), privacyLevel: .public)
                ]
            )
            
            return true
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "removeDestination",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.initialisationFailed(reason: error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "removeDestination",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
}
