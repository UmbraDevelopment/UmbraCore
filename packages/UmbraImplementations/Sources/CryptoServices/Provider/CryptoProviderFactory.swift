/**
 # CryptoProviderFactory

 A factory for creating and providing instances of CryptoProviderProtocol.
 Following Alpha Dot Five architecture, this factory centralises the creation logic
 for cryptographic providers and allows for dependency injection and testing.
 */

import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingServices

/**
 Factory for creating crypto providers
 */
public enum CryptoProviderFactory {
  /**
   Creates a default crypto provider.

   - Parameter logger: Logger instance for operation logging
   - Returns: A crypto provider instance
   */
  public static func createDefaultProvider(
    logger: LoggingProtocol
  ) -> CryptoProviderProtocol {
    DefaultCryptoProvider(logger: logger)
  }

  /**
   Creates the appropriate crypto provider based on the platform and available implementations.
   For Apple platforms, this might select CryptoKit, while for cross-platform it may use the Ring implementation.

   - Parameters:
      - logger: Logger instance for operation logging
      - preferNative: Whether to prefer native platform implementations if available
   - Returns: The most suitable crypto provider for the platform
   */
  public static func createProvider(
    logger: LoggingProtocol,
    preferNative _: Bool=true
  ) -> CryptoProviderProtocol {
    // Implementation would select the appropriate provider based on platform
    // This is a simple implementation that just returns the default provider
    createDefaultProvider(logger: logger)
  }
}
