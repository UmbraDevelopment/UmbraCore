import Foundation
import AuthenticationInterfaces
import CoreDTOs
import LoggingInterfaces

/**
 Protocol defining the authentication provider operations.
 
 This protocol serves as the internal interface for different authentication
 implementations (Apple native, Ring FFI with Argon2id, etc.)
 */
public protocol AuthenticationProviderProtocol {
    /**
     Performs authentication with the provided credentials.
     
     - Parameters:
        - credentials: The authentication credentials
        - context: The logging context for the operation
     - Returns: Authentication token upon successful authentication
     - Throws: AuthenticationError if authentication fails
     */
    func performAuthentication(
        credentials: AuthCredentialsDTO,
        context: LogContextDTO
    ) async throws -> AuthTokenDTO
    
    /**
     Validates an authentication token.
     
     - Parameters:
        - token: The token to validate
        - context: The logging context for the operation
     - Returns: True if the token is valid, false otherwise
     - Throws: AuthenticationError if validation fails for reasons other than token validity
     */
    func validateAuthToken(
        token: AuthTokenDTO,
        context: LogContextDTO
    ) async throws -> Bool
    
    /**
     Refreshes an expired or about-to-expire authentication token.
     
     - Parameters:
        - token: The token to refresh
        - context: The logging context for the operation
     - Returns: A new authentication token
     - Throws: AuthenticationError if refresh fails
     */
    func refreshAuthToken(
        token: AuthTokenDTO,
        context: LogContextDTO
    ) async throws -> AuthTokenDTO
    
    /**
     Revokes an authentication token, making it invalid for future use.
     
     - Parameters:
        - token: The token to revoke
        - context: The logging context for the operation
     - Returns: True if revocation was successful, false otherwise
     - Throws: AuthenticationError if revocation fails
     */
    func revokeAuthToken(
        token: AuthTokenDTO,
        context: LogContextDTO
    ) async throws -> Bool
    
    /**
     Retrieves the current authentication status.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The current authentication status
     */
    func checkStatus(
        context: LogContextDTO
    ) async -> AuthenticationStatus
    
    /**
     Logs out the currently authenticated user.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: True if logout was successful, false otherwise
     - Throws: AuthenticationError if logout fails
     */
    func performLogout(
        context: LogContextDTO
    ) async throws -> Bool
    
    /**
     Verifies user credentials without performing a full authentication.
     
     - Parameters:
        - credentials: The credentials to verify
        - context: The logging context for the operation
     - Returns: True if credentials are valid, false otherwise
     - Throws: AuthenticationError if verification fails
     */
    func verifyUserCredentials(
        credentials: AuthCredentialsDTO,
        context: LogContextDTO
    ) async throws -> Bool
    
    /**
     Securely hashes a user password for storage.
     
     - Parameters:
        - password: The password to hash
        - context: The logging context for the operation
     - Returns: The securely hashed password
     - Throws: AuthenticationError if hashing fails
     */
    func hashPassword(
        password: String,
        context: LogContextDTO
    ) async throws -> String
    
    /**
     Verifies a password against a stored hash.
     
     - Parameters:
        - password: The password to verify
        - hash: The stored hash to verify against
        - context: The logging context for the operation
     - Returns: True if the password matches the hash, false otherwise
     - Throws: AuthenticationError if verification fails
     */
    func verifyPassword(
        password: String,
        hash: String,
        context: LogContextDTO
    ) async throws -> Bool
}
