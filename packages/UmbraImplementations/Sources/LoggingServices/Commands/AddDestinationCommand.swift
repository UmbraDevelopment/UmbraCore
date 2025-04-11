import Foundation
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for adding a new log destination.
 
 This command encapsulates the logic for adding and registering a new 
 log destination, following the command pattern architecture.
 */
public class AddDestinationCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The destination to add
    private let destination: LogDestinationDTO
    
    /// Options for adding the destination
    private let options: AddDestinationOptionsDTO
    
    /**
     Initialises a new add destination command.
     
     - Parameters:
        - destination: The destination to add
        - options: Options for adding the destination
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destination: LogDestinationDTO,
        options: AddDestinationOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destination = destination
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the add destination command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "addDestination",
            destinationId: destination.id,
            additionalMetadata: [
                "destinationType": (value: destination.type.rawValue, privacyLevel: .public),
                "destinationName": (value: destination.name, privacyLevel: .public),
                "minimumLevel": (value: destination.minimumLevel.rawValue, privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "addDestination", context: operationContext)
        
        do {
            // Check if destination already exists
            if let existing = getDestination(id: destination.id) {
                if !options.overwriteExisting {
                    throw LoggingError.destinationAlreadyExists(
                        "Destination with ID \(destination.id) already exists"
                    )
                } else {
                    await logger.log(
                        .warning,
                        "Overwriting existing destination with ID: \(destination.id)",
                        context: operationContext
                    )
                }
            }
            
            // Validate destination configuration if requested
            if options.validateConfiguration {
                let validationResult = validateDestination(destination, for: provider)
                
                if !validationResult.isValid {
                    let issues = validationResult.issues.joined(separator: ", ")
                    throw LoggingError.invalidDestinationConfig(
                        "Destination configuration is invalid: \(issues)"
                    )
                }
            }
            
            // Test the destination if requested
            if options.testDestination {
                await logger.log(
                    .debug,
                    "Testing destination before adding",
                    context: operationContext
                )
                
                let testEntry = LogEntryDTO(
                    level: .info,
                    category: "LoggingSystem",
                    message: "Test log entry for destination validation",
                    metadata: LogMetadataDTOCollection.empty
                )
                
                let success = try await provider.writeLog(
                    entry: testEntry,
                    to: destination
                )
                
                if !success {
                    throw LoggingError.writeFailure(
                        "Test write to destination failed"
                    )
                }
            }
            
            // Register the destination
            registerDestination(destination)
            
            // Log success
            await logOperationSuccess(
                operation: "addDestination",
                context: operationContext,
                additionalMetadata: [
                    "totalDestinations": (value: String(Self.registeredDestinations.count), privacyLevel: .public)
                ]
            )
            
            return true
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "addDestination",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.general(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "addDestination",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
}
