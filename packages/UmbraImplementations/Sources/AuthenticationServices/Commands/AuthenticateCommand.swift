import AuthenticationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for authenticating a user.

 This command encapsulates the logic for user authentication,
 following the command pattern architecture.
 */
public class AuthenticateCommand: BaseAuthCommand, AuthCommand {
  /// The result type for this command
  public typealias ResultType=AuthTokenDTO

  /// Credentials to use for authentication
  private let credentials: AuthCredentialsDTO

  /**
   Initialises a new authenticate command.

   - Parameters:
      - credentials: The credentials to use for authentication
      - provider: Provider for authentication operations
      - logger: Logger instance for authentication operations
   */
  public init(
    credentials: AuthCredentialsDTO,
    provider: AuthenticationProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.credentials=credentials

    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the authenticate command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: An authentication token on successful authentication
   - Throws: AuthenticationError if authentication fails
   */
  public func execute(context _: LogContextDTO) async throws -> AuthTokenDTO {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "authenticate",
      userIdentifier: credentials.identifier,
      additionalMetadata: [
        "authMethod": (value: credentials.methodType.rawValue, privacyLevel: .public)
      ]
    )

    // Log operation start
    await logOperationStart(operation: "authenticate", context: operationContext)

    do {
      // Validate input
      if credentials.identifier.isEmpty {
        throw AuthenticationError.invalidCredentials("User identifier cannot be empty")
      }

      if credentials.methodType == .password && credentials.secret.isEmpty {
        throw AuthenticationError.invalidCredentials("Password cannot be empty")
      }

      // Perform authentication through provider
      let token=try await provider.performAuthentication(
        credentials: credentials,
        context: operationContext
      )

      // Log success
      await logOperationSuccess(
        operation: "authenticate",
        context: operationContext,
        additionalMetadata: [
          "tokenExpiresAt": (value: token.expiresAt.description, privacyLevel: .public)
        ]
      )

      return token

    } catch let error as AuthenticationError {
      // Log failure
      await logOperationFailure(
        operation: "authenticate",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to AuthenticationError
      let authError=AuthenticationError.unexpected(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "authenticate",
        error: authError,
        context: operationContext
      )

      throw authError
    }
  }
}
