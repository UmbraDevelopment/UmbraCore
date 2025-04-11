import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Protocol defining the command pattern for cryptographic operations.
 
 This pattern encapsulates each cryptographic operation as a discrete, single-responsibility
 command that can be executed, composed, and tested independently.
 */
public protocol CryptoCommand<ResultType> {
    /// The type of result returned by this command
    associatedtype ResultType
    
    /**
     Executes the cryptographic operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The operation result, wrapped in a Result type
     - Throws: May throw errors from the underlying cryptographic operations
     */
    func execute(
        context: LogContextDTO,
        operationID: String
    ) async -> Result<ResultType, SecurityStorageError>
}

/**
 Base class providing common functionality for cryptographic operation commands.
 
 This abstract class implements common behaviours shared by all cryptographic
 operations, reducing duplication and ensuring consistent operation patterns.
 */
public class BaseCryptoCommand {
    /// The secure storage to use for cryptographic materials
    protected let secureStorage: SecureStorageProtocol
    
    /// Logger for operations
    protected let logger: LoggingProtocol?
    
    /**
     Initialises a new base crypto command.
     
     - Parameters:
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking and auditing
     */
    public init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol? = nil) {
        self.secureStorage = secureStorage
        self.logger = logger
    }
    
    /**
     Creates a log context for cryptographic operations.
     
     - Parameters:
        - operation: The operation being performed
        - algorithm: Optional cryptographic algorithm being used
        - correlationID: Optional correlation ID for tracking related operations
        - additionalMetadata: Additional metadata to include in the context
     - Returns: A configured log context
     */
    protected func createLogContext(
        operation: String,
        algorithm: String? = nil,
        correlationID: String? = nil,
        additionalMetadata: [String: (value: String, privacyLevel: LogPrivacyLevel)] = [:]
    ) -> LogContextDTO {
        // Create base log context
        var context = CryptoLogContext(
            operation: operation,
            algorithm: algorithm,
            correlationID: correlationID ?? UUID().uuidString
        )
        
        // Add any additional metadata with appropriate privacy levels
        for (key, (value, privacyLevel)) in additionalMetadata {
            context = context.adding(
                key: key,
                value: value,
                privacyLevel: privacyLevel
            )
        }
        
        return context
    }
    
    /**
     Logs debug information during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logDebug(_ message: String, context: LogContextDTO) async {
        await logger?.debug(message, context: context)
    }
    
    /**
     Logs information during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logInfo(_ message: String, context: LogContextDTO) async {
        await logger?.info(message, context: context)
    }
    
    /**
     Logs warnings during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logWarning(_ message: String, context: LogContextDTO) async {
        await logger?.warning(message, context: context)
    }
    
    /**
     Logs errors during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logError(_ message: String, context: LogContextDTO) async {
        await logger?.error(message, context: context)
    }
}
