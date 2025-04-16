import AuthenticationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for revoking an authentication token.

 This command encapsulates the logic for invalidating tokens,
 following the command pattern architecture.
 */
public class RevokeTokenCommand: BaseAuthCommand, AuthCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// Token to revoke
  private let token: AuthTokenDTO

  /**
   Initialises a new revoke token command.

   - Parameters:
      - token: The token to revoke
      - provider: Provider for authentication operations
      - logger: Logger instance for authentication operations
   */
  public init(
    token: AuthTokenDTO,
    provider: AuthenticationProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.token=token

    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the revoke token command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: True if revocation was successful, false otherwise
   - Throws: AuthenticationError if revocation fails
   */
  public func execute(context _: LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "revokeToken",
      userIdentifier: token.userIdentifier
    )

    // Log operation start
    await logOperationStart(operation: "revokeToken", context: operationContext)

    do {
      // Revoke token through provider
      let success=try await provider.revokeAuthToken(
        token: token,
        context: operationContext
      )

      // Log result
      if success {
        await logOperationSuccess(
          operation: "revokeToken",
          context: operationContext
        )
      } else {
        await logger.log(
          .warning,
          "Token revocation could not be completed",
          context: operationContext
        )
      }

      return success

    } catch let error as AuthenticationError {
      // Log failure
      await logOperationFailure(
        operation: "revokeToken",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to AuthenticationError
      let authError=AuthenticationError.unexpected(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "revokeToken",
        error: authError,
        context: operationContext
      )

      throw authError
    }
  }
}
