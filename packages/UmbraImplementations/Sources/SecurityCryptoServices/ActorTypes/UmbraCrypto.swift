import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors
import LoggingInterfaces
import ProviderFactories

/**
 # UmbraCrypto
 
 Global access point for cryptographic operations using the configured security provider.
 
 This actor provides a concurrent-safe way to access the current
 security provider implementation throughout the application.
 
 ## Thread Safety
 
 All provider access and configuration is automatically thread-safe due to Swift's
 actor isolation rules. Multiple tasks can safely read and update the provider
 without race conditions.
 
 ## Usage
 
 ```swift
 // Get the current provider
 let provider = await UmbraCrypto.shared.provider()
 
 // Set a new provider
 await UmbraCrypto.shared.setProvider(newProvider)
 
 // Use with CryptoServiceActor
 let cryptoService = CryptoServiceActor(provider: provider, logger: logger)
 ```
 */
@globalActor
public actor UmbraCrypto {
    /// Shared singleton instance
    public static let shared = UmbraCrypto()
    
    /// The current security provider implementation
    private var _provider: EncryptionProviderProtocol
    
    /// Private initialiser that sets up the default provider
    private init() {
        _provider = SecurityProviderFactoryImpl.createDefaultProvider()
    }
    
    /**
     Returns the current security provider in a concurrent-safe manner.
     
     - Returns: The currently configured EncryptionProviderProtocol implementation
     */
    public func provider() -> EncryptionProviderProtocol {
        return _provider
    }
    
    /**
     Sets a new security provider in a concurrent-safe manner.
     
     - Parameter newProvider: The provider implementation to use
     */
    public func setProvider(_ newProvider: EncryptionProviderProtocol) {
        _provider = newProvider
    }
    
    /**
     Attempts to set a provider by type in a concurrent-safe manner.
     
     - Parameter type: The type of provider to set
     - Returns: True if the provider was successfully set, false otherwise
     */
    public func setProviderType(_ type: SecurityProviderType) -> Bool {
        do {
            let newProvider = try SecurityProviderFactoryImpl.createProvider(type: type)
            _provider = newProvider
            return true
        } catch {
            return false
        }
    }
    
    /**
     Resets the provider to the default implementation.
     */
    public func resetToDefaultProvider() {
        _provider = SecurityProviderFactoryImpl.createDefaultProvider()
    }
}
