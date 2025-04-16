import AuthenticationInterfaces
import Foundation
import LoggingInterfaces
import SecurityInterfaces

/**
 Factory for creating AuthenticationService instances.

 This factory centralises the creation of authentication service implementations,
 supporting both Apple native authentication and Ring FFI with Argon2id for
 cross-platform authentication.
 */
public class AuthenticationServiceFactory {

  /**
   Type of authentication provider to use.
   */
  public enum AuthenticationProviderType {
    /// Apple's native authentication frameworks (LocalAuthentication, etc.)
    case apple

    /// Ring FFI with Argon2id for cross-platform authentication
    case ring(RingAuthenticationProvider.Argon2Parameters)
  }

  /**
   Creates a new instance of an AuthenticationService.

   - Parameters:
      - providerType: The type of authentication provider to use
      - securityProvider: The security provider for cryptographic operations
      - logger: The logger to use for authentication operations
   - Returns: An implementation of AuthenticationServiceProtocol
   */
  public static func createAuthenticationService(
    providerType: AuthenticationProviderType,
    securityProvider: SecurityProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) -> AuthenticationServiceProtocol {
    let provider: AuthenticationProviderProtocol=switch providerType {
      case .apple:
        AppleAuthenticationProvider(securityProvider: securityProvider)

      case let .ring(parameters):
        RingAuthenticationProvider(
          securityProvider: securityProvider,
          parameters: parameters
        )
    }

    return AuthenticationServicesActor(
      provider: provider,
      logger: logger
    )
  }

  /**
   Creates a new instance of an AuthenticationService using Ring FFI with recommended
   parameters for the specified target environment.

   - Parameters:
      - targetEnvironment: The target environment (server, mobile, minimal)
      - securityProvider: The security provider for cryptographic operations
      - logger: The logger to use for authentication operations
   - Returns: An implementation of AuthenticationServiceProtocol
   */
  public static func createRingAuthenticationService(
    targetEnvironment: RingAuthenticationEnvironment,
    securityProvider: SecurityProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) -> AuthenticationServiceProtocol {
    let parameters=switch targetEnvironment {
      case .server:
        RingAuthenticationProvider.Argon2Parameters.server
      case .mobile:
        RingAuthenticationProvider.Argon2Parameters.mobile
      case .minimal:
        RingAuthenticationProvider.Argon2Parameters.minimal
    }

    return createAuthenticationService(
      providerType: .ring(parameters),
      securityProvider: securityProvider,
      logger: logger
    )
  }

  /**
   Target environment for Ring authentication service.
   */
  public enum RingAuthenticationEnvironment {
    /// Server environment (high security, more resources)
    case server
    /// Mobile environment (balanced security and performance)
    case mobile
    /// Minimal environment (resource-constrained devices)
    case minimal
  }

  /**
   Private initialiser to prevent instantiation of the factory.
   */
  private init() {
    // This factory should not be instantiated
  }
}
