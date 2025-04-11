import Foundation
import AuthenticationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for retrieving the current authentication status.
 
 This command encapsulates the logic for checking authentication status,
 following the command pattern architecture.
 */
public class GetStatusCommand: BaseAuthCommand, AuthCommand {
    /// The result type for this command
    public typealias ResultType = AuthenticationStatus
    
    /**
     Initialises a new get status command.
     
     - Parameters:
        - provider: Provider for authentication operations
        - logger: Logger instance for authentication operations
     */
    public init(
        provider: AuthenticationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the get status command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The current authentication status
     */
    public func execute(context: LogContextDTO) async throws -> AuthenticationStatus {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "getAuthenticationStatus"
        )
        
        // Log operation start (at debug level since this is a frequent, non-critical operation)
        await logger.log(.debug, "Checking authentication status", context: operationContext)
        
        // Get status through provider
        let status = await provider.checkStatus(context: operationContext)
        
        // Log result
        await logger.log(
            .debug,
            "Authentication status: \(status.rawValue)",
            context: operationContext
        )
        
        return status
    }
}
