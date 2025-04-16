import AuthenticationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for verifying user credentials without performing a full authentication.

 This command encapsulates the logic for credentials verification,
 following the command pattern architecture.
 */
public class VerifyCredentialsCommand: BaseAuthCommand, AuthCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// Credentials to verify
  private let credentials: AuthCredentialsDTO

  /**
   Initialises a new verify credentials command.

   - Parameters:
      - credentials: The credentials to verify
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
   Executes the verify credentials command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: True if credentials are valid, false otherwise
   - Throws: AuthenticationError if verification fails
   */
  public func execute(context _: LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "verifyCredentials",
      userIdentifier: credentials.identifier,
      additionalMetadata: [
        "authMethod": (value: credentials.methodType.rawValue, privacyLevel: .public)
      ]
    )

    // Log operation start
    await logOperationStart(operation: "verifyCredentials", context: operationContext)

    do {
      // Validate input
      if credentials.identifier.isEmpty {
        throw AuthenticationError.invalidCredentials("User identifier cannot be empty")
      }

      if credentials.methodType == .password && credentials.secret.isEmpty {
        throw AuthenticationError.invalidCredentials("Password cannot be empty")
      }

      // Verify credentials through provider
      let isValid=try await provider.verifyUserCredentials(
        credentials: credentials,
        context: operationContext
      )

      // Log result
      if isValid {
        await logOperationSuccess(
          operation: "verifyCredentials",
          context: operationContext
        )
      } else {
        await logger.log(
          .info,
          "Credentials verification failed: invalid credentials",
          context: operationContext
        )
      }

      return isValid

    } catch let error as AuthenticationError {
      // Log failure
      await logOperationFailure(
        operation: "verifyCredentials",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to AuthenticationError
      let authError=AuthenticationError.unexpected(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "verifyCredentials",
        error: authError,
        context: operationContext
      )

      throw authError
    }
  }
}
