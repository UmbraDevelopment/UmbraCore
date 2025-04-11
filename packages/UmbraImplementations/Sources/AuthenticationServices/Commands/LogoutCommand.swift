import Foundation
import AuthenticationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for logging out the currently authenticated user.
 
 This command encapsulates the logic for user logout,
 following the command pattern architecture.
 */
public class LogoutCommand: BaseAuthCommand, AuthCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /**
     Initialises a new logout command.
     
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
     Executes the logout command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: True if logout was successful, false otherwise
     - Throws: AuthenticationError if logout fails
     */
    public func execute(context: LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "logout"
        )
        
        // Log operation start
        await logOperationStart(operation: "logout", context: operationContext)
        
        do {
            // Perform logout through provider
            let success = try await provider.performLogout(
                context: operationContext
            )
            
            // Log result
            if success {
                await logOperationSuccess(
                    operation: "logout",
                    context: operationContext
                )
            } else {
                await logger.log(
                    .warning,
                    "Logout operation could not be completed",
                    context: operationContext
                )
            }
            
            return success
            
        } catch let error as AuthenticationError {
            // Log failure
            await logOperationFailure(
                operation: "logout",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to AuthenticationError
            let authError = AuthenticationError.unexpected(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "logout",
                error: authError,
                context: operationContext
            )
            
            throw authError
        }
    }
}
