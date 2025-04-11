import Foundation
import PersistenceInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Protocol defining the command interface for persistence operations.
 
 This defines the contract for all persistence commands, requiring an execute method
 that performs the operation within a specific context.
 */
public protocol PersistenceCommand {
    /// The type of result returned by this command
    associatedtype ResultType
    
    /**
     Executes the command in the given context.
     
     - Parameters:
        - context: Context for the operation
     - Returns: Result of the operation, type depends on the specific command
     - Throws: PersistenceError if the operation fails
     */
    func execute(context: PersistenceContextDTO) async throws -> ResultType
}

/**
 Base class for persistence commands.
 
 This class provides common functionality for all persistence commands,
 including logging and error handling.
 */
open class BasePersistenceCommand {
    /// Provider for persistence operations
    let provider: PersistenceProviderProtocol
    
    /// Logger for operation logging
    let logger: PrivacyAwareLoggingProtocol
    
    /**
     Initialises a new base persistence command.
     
     - Parameters:
        - provider: Provider for persistence operations
        - logger: Logger for operation logging
     */
    public init(provider: PersistenceProviderProtocol, logger: PrivacyAwareLoggingProtocol) {
        self.provider = provider
        self.logger = logger
    }
    
    // MARK: - Protected Methods
    
    /**
     Creates a log context for an operation.
     
     - Parameters:
        - operation: The operation being performed
        - entityType: The type of entity being operated on
        - entityId: The ID of the entity being operated on
        - additionalMetadata: Additional metadata for the operation
     - Returns: Log context for the operation
     */
    func createLogContext(
        operation: String,
        entityType: String,
        entityId: String? = nil,
        additionalMetadata: [(key: String, value: (value: String, privacyLevel: PrivacyLevel))] = []
    ) -> LogContextDTO {
        var metadata = LogMetadataDTOCollection()
            .withPublic(key: "operation", value: operation)
            .withPublic(key: "entityType", value: entityType)
        
        if let entityId = entityId {
            metadata = metadata.withPublic(key: "entityId", value: entityId)
        }
        
        // Add additional metadata with appropriate privacy levels
        for item in additionalMetadata {
            switch item.value.privacyLevel {
            case .public:
                metadata = metadata.withPublic(key: item.key, value: item.value.value)
            case .protected:
                metadata = metadata.withProtected(key: item.key, value: item.value.value)
            case .private:
                metadata = metadata.withPrivate(key: item.key, value: item.value.value)
            }
        }
        
        return LogContextDTO(
            operation: operation,
            category: "PersistenceService",
            metadata: metadata
        )
    }
    
    /**
     Logs the start of an operation.
     
     - Parameters:
        - operation: The operation being performed
        - context: Log context for the operation
     */
    func logOperationStart(operation: String, context: LogContextDTO) async {
        await logger.log(
            .debug,
            "Starting \(operation) operation",
            context: context
        )
    }
    
    /**
     Logs the successful completion of an operation.
     
     - Parameters:
        - operation: The operation that completed
        - context: Log context for the operation
        - additionalMetadata: Additional metadata about the result
     */
    func logOperationSuccess(
        operation: String,
        context: LogContextDTO,
        additionalMetadata: [(key: String, value: (value: String, privacyLevel: PrivacyLevel))] = []
    ) async {
        var resultContext = context
        
        // Add additional metadata with appropriate privacy levels
        for item in additionalMetadata {
            switch item.value.privacyLevel {
            case .public:
                resultContext = resultContext.withMetadata(
                    LogMetadataDTOCollection().withPublic(key: item.key, value: item.value.value)
                )
            case .protected:
                resultContext = resultContext.withMetadata(
                    LogMetadataDTOCollection().withProtected(key: item.key, value: item.value.value)
                )
            case .private:
                resultContext = resultContext.withMetadata(
                    LogMetadataDTOCollection().withPrivate(key: item.key, value: item.value.value)
                )
            }
        }
        
        await logger.log(
            .info,
            "Successfully completed \(operation) operation",
            context: resultContext
        )
    }
    
    /**
     Logs the failure of an operation.
     
     - Parameters:
        - operation: The operation that failed
        - error: The error that occurred
        - context: Log context for the operation
     */
    func logOperationFailure(
        operation: String,
        error: Error,
        context: LogContextDTO
    ) async {
        var errorContext = context
        
        if let persistenceError = error as? PersistenceError {
            errorContext = errorContext.withMetadata(
                LogMetadataDTOCollection().withProtected(
                    key: "errorType",
                    value: String(describing: type(of: persistenceError))
                )
            )
        }
        
        errorContext = errorContext.withMetadata(
            LogMetadataDTOCollection().withProtected(
                key: "errorMessage",
                value: error.localizedDescription
            )
        )
        
        await logger.log(
            .error,
            "\(operation) operation failed: \(error.localizedDescription)",
            context: errorContext
        )
    }
}
