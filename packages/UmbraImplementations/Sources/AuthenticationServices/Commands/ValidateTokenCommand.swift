import AuthenticationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for validating an authentication token.

 This command encapsulates the logic for token validation,
 following the command pattern architecture.
 */
public class ValidateTokenCommand: BaseAuthCommand, AuthCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// Token to validate
  private let token: AuthTokenDTO

  /**
   Initialises a new validate token command.

   - Parameters:
      - token: The token to validate
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
   Executes the validate token command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: True if the token is valid, false otherwise
   - Throws: AuthenticationError if validation fails for reasons other than token validity
   */
  public func execute(context _: LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "validateToken",
      userIdentifier: token.userIdentifier,
      additionalMetadata: [
        "tokenType": (value: token.tokenType, privacyLevel: .public),
        "tokenIssuedAt": (value: token.issuedAt.description, privacyLevel: .public),
        "tokenExpiresAt": (value: token.expiresAt.description, privacyLevel: .public)
      ]
    )

    // Log operation start
    await logOperationStart(operation: "validateToken", context: operationContext)

    do {
      // Perform quick check for expiration before calling provider
      if !token.isValid() {
        // Log that token has expired
        await logger.log(
          .debug,
          "Token has expired",
          context: operationContext
        )

        // Return false rather than throwing an error for expected expiration
        return false
      }

      // Validate token through provider
      let isValid=try await provider.validateAuthToken(
        token: token,
        context: operationContext
      )

      // Log result
      if isValid {
        await logOperationSuccess(
          operation: "validateToken",
          context: operationContext
        )
      } else {
        await logger.log(
          .info,
          "Token validation failed: token is invalid",
          context: operationContext
        )
      }

      return isValid

    } catch let error as AuthenticationError {
      // Log failure
      await logOperationFailure(
        operation: "validateToken",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to AuthenticationError
      let authError=AuthenticationError.unexpected(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "validateToken",
        error: authError,
        context: operationContext
      )

      throw authError
    }
  }
}
