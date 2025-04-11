import Foundation
import LoggingInterfaces
import LoggingTypes
import AuthenticationInterfaces
import CoreDTOs

/**
 Protocol for all authentication commands.
 
 This protocol defines the contract that all authentication commands must adhere to,
 following the command pattern architecture.
 */
public protocol AuthCommand {
    /// The type of result that the command produces
    associatedtype ResultType
    
    /**
     Executes the command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the command execution
     - Throws: Error if the command execution fails
     */
    func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for authentication commands.
 
 This class provides common functionality for all authentication commands,
 such as standardised logging and error handling.
 */
public class BaseAuthCommand {
    /// Logger instance for authentication operations
    let logger: PrivacyAwareLoggingProtocol
    
    /// Authentication provider to perform the actual operations
    let provider: AuthenticationProviderProtocol
    
    /**
     Initialises a new base authentication command.
     
     - Parameters:
        - provider: Provider for authentication operations
        - logger: Logger instance for authentication operations
     */
    init(provider: AuthenticationProviderProtocol, logger: PrivacyAwareLoggingProtocol) {
        self.provider = provider
        self.logger = logger
    }
    
    /**
     Creates a log context for an authentication operation.
     
     - Parameters:
        - operation: The operation being performed
        - userIdentifier: The identifier of the user being authenticated (optional)
        - additionalMetadata: Additional metadata to include in the context
     - Returns: A log context for the operation
     */
    func createLogContext(
        operation: String,
        userIdentifier: String? = nil,
        additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)] = [:]
    ) -> LogContextDTO {
        var metadata = LogMetadataDTOCollection.empty
        
        if let userIdentifier = userIdentifier {
            // User identifier should be protected as it could be personally identifiable
            metadata = metadata.withProtected(key: "userIdentifier", value: userIdentifier)
        }
        
        for (key, value) in additionalMetadata {
            metadata = metadata.with(
                key: key,
                value: value.value,
                privacyLevel: value.privacyLevel
            )
        }
        
        return LogContextDTO(
            operation: operation,
            category: "Authentication",
            metadata: metadata
        )
    }
    
    /**
     Logs the start of an authentication operation.
     
     - Parameters:
        - operation: The name of the operation
        - context: The logging context
     */
    func logOperationStart(operation: String, context: LogContextDTO) async {
        await logger.log(.info, "Starting authentication operation: \(operation)", context: context)
    }
    
    /**
     Logs the successful completion of an authentication operation.
     
     - Parameters:
        - operation: The name of the operation
        - context: The logging context
        - additionalMetadata: Additional metadata to include in the log
     */
    func logOperationSuccess(
        operation: String,
        context: LogContextDTO,
        additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)] = [:]
    ) async {
        var enrichedContext = context
        
        for (key, value) in additionalMetadata {
            enrichedContext = enrichedContext.withMetadata(
                LogMetadataDTOCollection().with(
                    key: key,
                    value: value.value,
                    privacyLevel: value.privacyLevel
                )
            )
        }
        
        await logger.log(.info, "Authentication operation successful: \(operation)", context: enrichedContext)
    }
    
    /**
     Logs the failure of an authentication operation.
     
     - Parameters:
        - operation: The name of the operation
        - error: The error that occurred
        - context: The logging context
     */
    func logOperationFailure(operation: String, error: Error, context: LogContextDTO) async {
        let errorDescription = error.localizedDescription
        
        // Determine the privacy level for the error message
        // Some errors might contain sensitive information
        let enrichedContext = context.withMetadata(
            LogMetadataDTOCollection().withProtected(
                key: "errorDescription",
                value: errorDescription
            )
        )
        
        await logger.log(.error, "Authentication operation failed: \(operation)", context: enrichedContext)
    }
}
