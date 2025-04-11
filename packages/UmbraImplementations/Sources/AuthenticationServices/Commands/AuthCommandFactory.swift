import Foundation
import AuthenticationInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Factory for creating authentication command instances.
 
 This factory centralises the creation of all authentication commands,
 ensuring consistent initialisation and parameter passing.
 */
public class AuthCommandFactory {
    /// Provider for authentication operations
    private let provider: AuthenticationProviderProtocol
    
    /// Logger instance for authentication operations
    private let logger: PrivacyAwareLoggingProtocol
    
    /**
     Initialises a new authentication command factory.
     
     - Parameters:
        - provider: Provider for authentication operations
        - logger: Logger instance for authentication operations
     */
    public init(
        provider: AuthenticationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.provider = provider
        self.logger = logger
    }
    
    /**
     Creates a command for authenticating a user.
     
     - Parameters:
        - credentials: The credentials to use for authentication
     - Returns: A command for authenticating the user
     */
    public func createAuthenticateCommand(
        credentials: AuthCredentialsDTO
    ) -> AuthenticateCommand {
        return AuthenticateCommand(
            credentials: credentials,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for validating an authentication token.
     
     - Parameters:
        - token: The token to validate
     - Returns: A command for validating the token
     */
    public func createValidateTokenCommand(
        token: AuthTokenDTO
    ) -> ValidateTokenCommand {
        return ValidateTokenCommand(
            token: token,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for refreshing an authentication token.
     
     - Parameters:
        - token: The token to refresh
     - Returns: A command for refreshing the token
     */
    public func createRefreshTokenCommand(
        token: AuthTokenDTO
    ) -> RefreshTokenCommand {
        return RefreshTokenCommand(
            token: token,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for revoking an authentication token.
     
     - Parameters:
        - token: The token to revoke
     - Returns: A command for revoking the token
     */
    public func createRevokeTokenCommand(
        token: AuthTokenDTO
    ) -> RevokeTokenCommand {
        return RevokeTokenCommand(
            token: token,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for retrieving the current authentication status.
     
     - Returns: A command for retrieving the status
     */
    public func createGetStatusCommand() -> GetStatusCommand {
        return GetStatusCommand(
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for logging out the currently authenticated user.
     
     - Returns: A command for logging out
     */
    public func createLogoutCommand() -> LogoutCommand {
        return LogoutCommand(
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a command for verifying user credentials.
     
     - Parameters:
        - credentials: The credentials to verify
     - Returns: A command for verifying the credentials
     */
    public func createVerifyCredentialsCommand(
        credentials: AuthCredentialsDTO
    ) -> VerifyCredentialsCommand {
        return VerifyCredentialsCommand(
            credentials: credentials,
            provider: provider,
            logger: logger
        )
    }
}
