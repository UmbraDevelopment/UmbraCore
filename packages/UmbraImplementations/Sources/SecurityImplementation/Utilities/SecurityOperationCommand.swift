import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Protocol defining the command pattern for security operations.
 
 This protocol enables the encapsulation of security operations as discrete,
 single-responsibility commands that can be executed, composed, and tested
 independently.
 */
public protocol SecurityOperationCommand {
    /**
     Executes the security operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The security operation result
     - Throws: Any error that might occur during execution
     */
    func execute(context: LogContextDTO, operationID: String) async throws -> SecurityResultDTO
}

/**
 Base class providing common functionality for security operation commands.
 
 This abstract class implements common behaviours shared by all security
 operations, reducing duplication and ensuring consistent operation patterns.
 */
public class BaseSecurityCommand {
    /// Logger for operations
    protected let logger: LoggingProtocol
    
    /// Security configuration
    protected let config: SecurityConfigDTO
    
    /**
     Initialises a new base security command.
     
     - Parameters:
        - config: Security configuration for the operation
        - logger: Logger for operation tracking and auditing
     */
    public init(config: SecurityConfigDTO, logger: LoggingProtocol) {
        self.config = config
        self.logger = logger
    }
    
    /**
     Creates a successful result DTO.
     
     - Parameters:
        - data: Result data to include
        - duration: Operation execution time in milliseconds
        - metadata: Additional result metadata
     - Returns: A configured SecurityResultDTO
     */
    protected func createSuccessResult(
        data: Data?,
        duration: TimeInterval,
        metadata: [String: String] = [:]
    ) -> SecurityResultDTO {
        return SecurityResultDTO.success(
            resultData: data,
            executionTimeMs: duration,
            metadata: metadata
        )
    }
    
    /**
     Extracts metadata safely from the security configuration.
     
     - Returns: A metadata extractor for the current configuration
     */
    protected func metadataExtractor() -> SecurityMetadataExtractor {
        return SecurityMetadataExtractor(config: config)
    }
    
    /**
     Logs debug information during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logDebug(_ message: String, context: LogContextDTO) async {
        await logger.debug(message, context: context)
    }
    
    /**
     Logs information during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logInfo(_ message: String, context: LogContextDTO) async {
        await logger.info(message, context: context)
    }
    
    /**
     Logs warnings during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logWarning(_ message: String, context: LogContextDTO) async {
        await logger.warning(message, context: context)
    }
    
    /**
     Logs errors during command execution.
     
     - Parameters:
        - message: The log message
        - context: The logging context
     */
    protected func logError(_ message: String, context: LogContextDTO) async {
        await logger.error(message, context: context)
    }
}
