import CryptoInterfaces
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # CryptoXPCServiceFactory

 Factory for creating CryptoXPCService actors.

 This factory provides methods to create properly configured
 CryptoXPCServiceActor instances with appropriate dependencies
 for different usage scenarios.

 Following the Alpha Dot Five architecture, this factory encapsulates
 the creation logic and dependency injection for the service.
 */
public enum CryptoXPCServiceFactory {
  /**
   Creates a CryptoXPCService with the default configuration.

   - Parameters:
      - logger: Logger for recording operations and errors

   - Returns: A new CryptoXPCServiceActor instance
   */
  public static func createDefault(
    logger: LoggingProtocol
  ) async -> CryptoXPCServiceActor {
    // Create dependencies
    let cryptoProvider=await CryptoProviderFactory.createDefault(logger: logger)
    let keyStore=await KeyStoreFactory.createDefault(logger: logger)

    // Create and return service actor
    return CryptoXPCServiceActor(
      cryptoProvider: cryptoProvider,
      keyStore: keyStore,
      logger: logger
    )
  }

  /**
   Creates a CryptoXPCService with custom dependencies.

   This method is marked as async to maintain consistency with the
   other factory methods and follow Alpha Dot Five architecture patterns.

   - Parameters:
      - cryptoProvider: Custom provider for cryptographic operations
      - keyStore: Custom storage for cryptographic keys
      - logger: Logger for recording operations and errors

   - Returns: A new CryptoXPCServiceActor instance
   */
  public static func create(
    cryptoProvider: CryptoProviderProtocol,
    keyStore: KeyStoreProtocol,
    logger: LoggingProtocol
  ) async -> CryptoXPCServiceActor {
    CryptoXPCServiceActor(
      cryptoProvider: cryptoProvider,
      keyStore: keyStore,
      logger: logger
    )
  }

  /**
   Creates a CryptoXPCService for testing purposes.

   This factory method creates a service with in-memory implementations
   suitable for unit testing.

   - Parameters:
      - logger: Logger for recording operations and errors

   - Returns: A new CryptoXPCServiceActor instance
   */
  public static func createForTesting(
    logger: LoggingProtocol
  ) async -> CryptoXPCServiceActor {
    // Create test dependencies
    let cryptoProvider=await CryptoProviderFactory.createForTesting(logger: logger)
    let keyStore=await KeyStoreFactory.createInMemory(logger: logger)

    // Create and return service actor
    return CryptoXPCServiceActor(
      cryptoProvider: cryptoProvider,
      keyStore: keyStore,
      logger: logger
    )
  }
}
