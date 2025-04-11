import Foundation
import AuthenticationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Actor implementation of the AuthenticationServiceProtocol.
 
 This actor provides thread-safe authentication operations using the command pattern,
 supporting various authentication methods and providers.
 */
public actor AuthenticationServicesActor: AuthenticationServiceProtocol {
    
    /// Provider for authentication operations
    private let provider: AuthenticationProviderProtocol
    
    /// Command factory for creating authentication commands
    private let commandFactory: AuthCommandFactory
    
    /// Logger instance for authentication operations
    private let logger: PrivacyAwareLoggingProtocol
    
    /**
     Initialises a new authentication services actor.
     
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
        self.commandFactory = AuthCommandFactory(provider: provider, logger: logger)
        
        // Add initial log entry
        Task {
            await self.logger.log(
                .info,
                "AuthenticationServicesActor initialised",
                context: LogContextDTO(
                    operation: "initialisation",
                    category: "Authentication",
                    metadata: LogMetadataDTOCollection.empty
                )
            )
        }
    }
    
    /**
     Authenticates a user with the provided credentials.
     
     - Parameters:
        - credentials: The authentication credentials
     - Returns: Authentication token upon successful authentication
     - Throws: AuthenticationError if authentication fails
     */
    public func authenticate(credentials: AuthCredentialsDTO) async throws -> AuthTokenDTO {
        let baseContext = LogContextDTO(
            operation: "authenticate",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createAuthenticateCommand(credentials: credentials)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Validates an authentication token.
     
     - Parameters:
        - token: The token to validate
     - Returns: True if the token is valid, false otherwise
     - Throws: AuthenticationError if validation fails for reasons other than token validity
     */
    public func validateToken(token: AuthTokenDTO) async throws -> Bool {
        let baseContext = LogContextDTO(
            operation: "validateToken",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createValidateTokenCommand(token: token)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Refreshes an expired or about-to-expire authentication token.
     
     - Parameters:
        - token: The token to refresh
     - Returns: A new authentication token
     - Throws: AuthenticationError if refresh fails
     */
    public func refreshToken(token: AuthTokenDTO) async throws -> AuthTokenDTO {
        let baseContext = LogContextDTO(
            operation: "refreshToken",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createRefreshTokenCommand(token: token)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Revokes an authentication token, making it invalid for future use.
     
     - Parameters:
        - token: The token to revoke
     - Returns: True if revocation was successful, false otherwise
     - Throws: AuthenticationError if revocation fails
     */
    public func revokeToken(token: AuthTokenDTO) async throws -> Bool {
        let baseContext = LogContextDTO(
            operation: "revokeToken",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createRevokeTokenCommand(token: token)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Retrieves the current authentication status.
     
     - Returns: The current authentication status
     */
    public func getAuthenticationStatus() async -> AuthenticationStatus {
        let baseContext = LogContextDTO(
            operation: "getAuthenticationStatus",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createGetStatusCommand()
        
        do {
            return try await command.execute(context: baseContext)
        } catch {
            // Since this method doesn't throw, we need to handle errors internally
            await logger.log(
                .error,
                "Failed to get authentication status: \(error.localizedDescription)",
                context: baseContext
            )
            
            // Return a safe default
            return .notAuthenticated
        }
    }
    
    /**
     Logs out the currently authenticated user.
     
     - Returns: True if logout was successful, false otherwise
     - Throws: AuthenticationError if logout fails
     */
    public func logout() async throws -> Bool {
        let baseContext = LogContextDTO(
            operation: "logout",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createLogoutCommand()
        return try await command.execute(context: baseContext)
    }
    
    /**
     Verifies user credentials without performing a full authentication.
     
     - Parameters:
        - credentials: The credentials to verify
     - Returns: True if credentials are valid, false otherwise
     - Throws: AuthenticationError if verification fails
     */
    public func verifyCredentials(credentials: AuthCredentialsDTO) async throws -> Bool {
        let baseContext = LogContextDTO(
            operation: "verifyCredentials",
            category: "Authentication",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createVerifyCredentialsCommand(credentials: credentials)
        return try await command.execute(context: baseContext)
    }
}
