import Foundation
import AuthenticationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for refreshing an authentication token.
 
 This command encapsulates the logic for refreshing expired or near-expiry tokens,
 following the command pattern architecture.
 */
public class RefreshTokenCommand: BaseAuthCommand, AuthCommand {
    /// The result type for this command
    public typealias ResultType = AuthTokenDTO
    
    /// Token to refresh
    private let token: AuthTokenDTO
    
    /**
     Initialises a new refresh token command.
     
     - Parameters:
        - token: The token to refresh
        - provider: Provider for authentication operations
        - logger: Logger instance for authentication operations
     */
    public init(
        token: AuthTokenDTO,
        provider: AuthenticationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.token = token
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the refresh token command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: A new authentication token
     - Throws: AuthenticationError if refresh fails
     */
    public func execute(context: LogContextDTO) async throws -> AuthTokenDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "refreshToken",
            userIdentifier: token.userIdentifier,
            additionalMetadata: [
                "tokenExpiresAt": (value: token.expiresAt.description, privacyLevel: .public),
                "tokenIsExpired": (value: String(!token.isValid()), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "refreshToken", context: operationContext)
        
        do {
            // Check if token is eligible for refresh
            // Tokens can be refreshed if:
            // 1. They are still valid but will expire soon, or
            // 2. They have expired but are within the refresh window
            
            // Refresh token through provider
            let refreshedToken = try await provider.refreshAuthToken(
                token: token,
                context: operationContext
            )
            
            // Log success
            await logOperationSuccess(
                operation: "refreshToken",
                context: operationContext,
                additionalMetadata: [
                    "newTokenExpiresAt": (value: refreshedToken.expiresAt.description, privacyLevel: .public)
                ]
            )
            
            return refreshedToken
            
        } catch let error as AuthenticationError {
            // Log failure
            await logOperationFailure(
                operation: "refreshToken",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to AuthenticationError
            let authError = AuthenticationError.unexpected(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "refreshToken",
                error: authError,
                context: operationContext
            )
            
            throw authError
        }
    }
}
