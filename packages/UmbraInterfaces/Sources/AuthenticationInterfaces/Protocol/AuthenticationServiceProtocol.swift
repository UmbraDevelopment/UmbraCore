import CoreDTOs
import Foundation

/**
 Protocol defining the authentication service operations.

 This protocol provides a comprehensive interface for all authentication
 operations, regardless of the underlying authentication provider.
 */
public protocol AuthenticationServiceProtocol {
  /**
   Authenticates a user with the provided credentials.

   - Parameters:
      - credentials: The authentication credentials
   - Returns: Authentication token upon successful authentication
   - Throws: AuthenticationError if authentication fails
   */
  func authenticate(credentials: AuthCredentialsDTO) async throws -> AuthTokenDTO

  /**
   Validates an authentication token.

   - Parameters:
      - token: The token to validate
   - Returns: True if the token is valid, false otherwise
   - Throws: AuthenticationError if validation fails for reasons other than token validity
   */
  func validateToken(token: AuthTokenDTO) async throws -> Bool

  /**
   Refreshes an expired or about-to-expire authentication token.

   - Parameters:
      - token: The token to refresh
   - Returns: A new authentication token
   - Throws: AuthenticationError if refresh fails
   */
  func refreshToken(token: AuthTokenDTO) async throws -> AuthTokenDTO

  /**
   Revokes an authentication token, making it invalid for future use.

   - Parameters:
      - token: The token to revoke
   - Returns: True if revocation was successful, false otherwise
   - Throws: AuthenticationError if revocation fails
   */
  func revokeToken(token: AuthTokenDTO) async throws -> Bool

  /**
   Retrieves the current authentication status.

   - Returns: The current authentication status
   */
  func getAuthenticationStatus() async -> AuthenticationStatus

  /**
   Logs out the currently authenticated user.

   - Returns: True if logout was successful, false otherwise
   - Throws: AuthenticationError if logout fails
   */
  func logout() async throws -> Bool

  /**
   Verifies user credentials without performing a full authentication.

   This is useful for operations like changing passwords where you need
   to verify the current password before accepting a new one.

   - Parameters:
      - credentials: The credentials to verify
   - Returns: True if credentials are valid, false otherwise
   - Throws: AuthenticationError if verification fails
   */
  func verifyCredentials(credentials: AuthCredentialsDTO) async throws -> Bool
}
