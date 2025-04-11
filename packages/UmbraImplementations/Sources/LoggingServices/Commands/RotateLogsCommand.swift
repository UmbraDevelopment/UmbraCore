import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for rotating logs.
 
 This command encapsulates the logic for log rotation operations,
 following the command pattern architecture.
 */
public class RotateLogsCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = LogRotationResultDTO
    
    /// The ID of the destination to rotate logs for
    private let destinationId: String
    
    /// Options for rotating logs
    private let options: RotateLogsOptionsDTO
    
    /**
     Initialises a new rotate logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to rotate logs for
        - options: Options for rotating logs
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destinationId: String,
        options: RotateLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destinationId = destinationId
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the rotate logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the rotation operation
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> LogRotationResultDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "rotateLogs",
            destinationId: destinationId,
            additionalMetadata: [
                "forceRotation": (value: String(options.forceRotation), privacyLevel: .public),
                "compressRotatedLogs": (value: String(options.compressRotatedLogs), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "rotateLogs", context: operationContext)
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingError.destinationNotFound(
                    "Cannot rotate logs for destination with ID \(destinationId): not found"
                )
            }
            
            // Check if the destination type supports rotation
            if destination.type != LogDestinationType.file {
                throw LoggingError.invalidDestinationConfig(
                    "Log rotation is only supported for file destinations"
                )
            }
            
            // Rotate logs using provider
            let rotationResult = try await provider.rotateLogs(
                for: destination,
                options: options
            )
            
            // Log success or failure based on rotation result
            if rotationResult.success {
                await logOperationSuccess(
                    operation: "rotateLogs",
                    context: operationContext,
                    additionalMetadata: [
                        "rotatedFilePath": (value: rotationResult.rotatedFilePath ?? "unknown", privacyLevel: .protected),
                        "rotatedSizeBytes": (value: String(rotationResult.rotatedSizeBytes ?? 0), privacyLevel: .public),
                        "rotatedEntryCount": (value: String(rotationResult.rotatedEntryCount ?? 0), privacyLevel: .public)
                    ]
                )
            } else {
                await logger.log(
                    .warning,
                    "Log rotation completed with issues",
                    context: operationContext.withMetadata(
                        LogMetadataDTOCollection().withProtected(
                            key: "rotationError",
                            value: rotationResult.metadata["error"] ?? "Unknown error"
                        )
                    )
                )
            }
            
            return rotationResult
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "rotateLogs",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.writeFailure(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "rotateLogs",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
}
