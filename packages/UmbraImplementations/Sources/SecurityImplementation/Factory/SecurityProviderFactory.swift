import CryptoServices
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityKeyManagement
import SecurityTypes

/**
 # SecurityProviderFactory

 Factory for creating instances of the SecurityProviderImpl with appropriate dependencies.

 ## Factory Pattern

 The factory pattern allows for easy creation of security providers with either:
 - Default dependencies
 - Custom dependencies for testing or specialised scenarios
 */
public enum SecurityProviderFactory {
  /**
   Creates a SecurityProvider with default implementations of all dependencies.

   - Parameter logger: Optional custom logger (uses default if nil)
   - Returns: A properly configured SecurityProviderProtocol instance
   */
  public static func createSecurityProvider(
    logger: LoggingServiceProtocol? = nil
  ) async -> SecurityProviderProtocol {
    // Get the default implementations
    let cryptoService = createDefaultCryptoService()
    let keyManager = createDefaultKeyManager()
    
    // Use the provided logger or create a default one
    let actualLogger = logger ?? await LoggingServiceFactory.createDefaultLogger(
      minimumLevel: .info,
      identifier: "SecurityProviderDefaultLogger"
    )

    // Create the provider
    let provider = SecurityProviderImpl(
      cryptoService: cryptoService,
      keyManager: keyManager
    )
    
    // Initialise the provider (this handles async setup)
    try? await provider.initialize()
    
    return provider
  }

  /**
   Creates a SecurityProvider with custom dependencies.

   - Parameters:
     - cryptoService: Custom crypto service
     - keyManager: Custom key management service
   - Returns: A configured SecurityProviderProtocol instance
   
   Note: This method creates the provider but does not initialise it.
   You must call `initialize()` on the returned provider before use.
   */
  public static func createSecurityProvider(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) -> SecurityProviderProtocol {
    SecurityProviderImpl(
      cryptoService: cryptoService,
      keyManager: keyManager
    )
  }

  // MARK: - Helper Methods

  /**
   Creates the default crypto service implementation.
   
   - Returns: A properly configured crypto service
   */
  private static func createDefaultCryptoService() -> CryptoServiceProtocol {
    CryptoServiceAdapter(cryptoService: CryptoServices.CryptoServiceFactory.createDefaultService())
  }

  /**
   Creates the default key management service.
   
   - Returns: A properly configured key management service
   */
  private static func createDefaultKeyManager() -> KeyManagementProtocol {
    KeyManagementAdapter(keyManager: SecurityKeyManagement.KeyManagementFactory.createDefaultManager())
  }

  // MARK: - Service Adapters

  /**
   Adapter to make CryptoServices.CryptoService compatible with CryptoServiceProtocol.
   */
  private final class CryptoServiceAdapter: CryptoServiceProtocol, Sendable {
    private let cryptoService: CryptoServices.CryptoService
    
    init(cryptoService: CryptoServices.CryptoService) {
      self.cryptoService = cryptoService
    }
    
    // MARK: - Required protocol methods

    /**
     Encrypts binary data using the provided key.
     */
    func encrypt(data: SecureBytes, using key: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
      do {
        let encryptedData = try cryptoService.encrypt(data: data.extractUnderlyingData(), using: key.extractUnderlyingData())
        return .success(SecureBytes(data: encryptedData))
      } catch {
        return .failure(.encryptionFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Decrypts binary data using the provided key.
     */
    func decrypt(data: SecureBytes, using key: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
      do {
        let decryptedData = try cryptoService.decrypt(data: data.extractUnderlyingData(), using: key.extractUnderlyingData())
        return .success(SecureBytes(data: decryptedData))
      } catch {
        return .failure(.decryptionFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Computes a cryptographic hash of binary data.
     */
    func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
      do {
        let hashedData = try cryptoService.hash(data: data.extractUnderlyingData())
        return .success(SecureBytes(data: hashedData))
      } catch {
        return .failure(.hashingFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Verifies a cryptographic hash against the expected value.
     */
    func verifyHash(data: SecureBytes, expectedHash: SecureBytes) async -> Result<Bool, SecurityProtocolError> {
      do {
        let hashedData = try cryptoService.hash(data: data.extractUnderlyingData())
        let expectedData = expectedHash.extractUnderlyingData()
        return .success(hashedData == expectedData)
      } catch {
        return .failure(.hashingFailed(message: error.localizedDescription))
      }
    }
  }

  /**
   Adapter to make SecurityKeyManagement.KeyManager compatible with KeyManagementProtocol.
   */
  private final class KeyManagementAdapter: KeyManagementProtocol, Sendable {
    private let keyManager: SecurityKeyManagement.KeyManager
    
    init(keyManager: SecurityKeyManagement.KeyManager) {
      self.keyManager = keyManager
    }
    
    // MARK: - Required protocol methods
    
    /**
     Retrieves a security key by its identifier.
     */
    func retrieveKey(withIdentifier identifier: String) async -> Result<SecureBytes, SecurityProtocolError> {
      do {
        let keyData = try keyManager.retrieveKey(withIdentifier: identifier)
        return .success(SecureBytes(data: keyData))
      } catch {
        return .failure(.keyRetrievalFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Stores a security key with the given identifier.
     */
    func storeKey(_ key: SecureBytes, withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
      do {
        try keyManager.storeKey(key.extractUnderlyingData(), withIdentifier: identifier)
        return .success(())
      } catch {
        return .failure(.keyStorageFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Deletes a security key with the given identifier.
     */
    func deleteKey(withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
      do {
        try keyManager.deleteKey(withIdentifier: identifier)
        return .success(())
      } catch {
        return .failure(.keyDeletionFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Rotates a security key, creating a new key and optionally re-encrypting data.
     */
    func rotateKey(
      withIdentifier identifier: String,
      dataToReencrypt: SecureBytes?
    ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), SecurityProtocolError> {
      do {
        let dataToProcess = dataToReencrypt?.extractUnderlyingData()
        let (newKey, reencryptedData) = try keyManager.rotateKey(
          withIdentifier: identifier,
          dataToReencrypt: dataToProcess
        )
        
        let secureNewKey = SecureBytes(data: newKey)
        var secureReencryptedData: SecureBytes?
        
        if let reencryptedData = reencryptedData {
          secureReencryptedData = SecureBytes(data: reencryptedData)
        }
        
        return .success((newKey: secureNewKey, reencryptedData: secureReencryptedData))
      } catch {
        return .failure(.keyRotationFailed(message: error.localizedDescription))
      }
    }
    
    /**
     Lists all available key identifiers.
     */
    func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
      do {
        let identifiers = try keyManager.listKeyIdentifiers()
        return .success(identifiers)
      } catch {
        return .failure(.operationFailed(message: error.localizedDescription))
      }
    }
  }
}
