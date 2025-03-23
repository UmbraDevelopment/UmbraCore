/**
 # UmbraCore Security Provider

 The SecurityProvider acts as a facade for the UmbraCore security subsystem, providing
 a unified interface to cryptographic operations and key management. It implements the
 SecurityProviderProtocol and coordinates between the various security services.

 ## Design Pattern

 This class follows the Facade design pattern, simplifying access to the security
 subsystem by providing a single entry point that coordinates between different
 components:

 * CryptoService: Handles encryption, decryption, hashing, and other cryptographic operations
 * KeyManager: Handles key generation, storage, retrieval, and lifecycle management

 ## Security Considerations

 * **Facade Security**: The provider enforces proper parameter validation and ensures
   that operations are called with appropriate parameters, reducing the chance of
   misusing the underlying services.

 * **Key Management**: The provider automatically handles key lookup by identifier when
   provided in the configuration, simplifying key management for callers.

 * **Error Handling**: The provider normalises error reporting across different security
   components, making it easier to handle errors consistently.

 * **Audit Trail**: In a production implementation, this class would be an appropriate
   place to implement security logging and audit trail features.

 ## Usage Guidelines

 * Use the `performSecureOperation` method for standard cryptographic operations
 * Use the `createSecureConfig` method to build properly formatted configuration objects
 * Access the `cryptoService` and `keyManager` properties directly for more specific operations
 * Always validate the success flag in the returned SecurityResultDTO

 ## Example Usage

 ```swift
 // Create the security provider
 let securityProvider = SecurityProvider()

 // Create a configuration for encryption
 let config = securityProvider.createSecureConfig(options: [
     "algorithm": "AES-GCM",
     "keySize": 256,
     "keyIdentifier": "data-encryption-key"
 ])

 // Perform an encryption operation
 let result = await securityProvider.performSecureOperation(
     operation: .symmetricEncryption,
     config: config
 )

 // Check the result
 if result.status == .success {
     // Use the encrypted data
     let encryptedData = result.data
 }
 ```

 ## Limitations

 * **Foundation Independence**: This implementation avoids Foundation dependencies,
   which means some features (like Base64 encoding/decoding) are placeholders.

 * **Not All Operations Implemented**: Some operations like asymmetric encryption,
   signature generation/verification, and MAC generation are not fully implemented.

 * **Development Stage**: This implementation is designed for development and testing.
   For production use, consider enhancing with:
     - Comprehensive logging and auditing
     - Input sanitization
     - Rate limiting for sensitive operations
     - More robust error handling
 */

import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Implementation of the SecurityProviderProtocol
///
/// SecurityProvider coordinates between cryptographic services and key management
/// to provide a unified interface for security operations.
public final class SecurityProvider: SecurityProviderProtocol {
  // MARK: - Properties

  /// The crypto service for cryptographic operations
  public let cryptoService: CryptoServiceProtocol

  /// The key manager for key management operations
  public let keyManager: KeyManagementProtocol

  /// Core implementation that handles provider functionality
  private let providerCore: SecurityProviderCore

  // MARK: - Initialisation

  /// Creates a new instance with default services
  public init() {
    cryptoService=CryptoService()
    keyManager=KeyManager()
    providerCore=SecurityProviderCore(cryptoService: cryptoService, keyManager: keyManager)
  }

  /// Creates a new instance with the specified services
  /// - Parameters:
  ///   - cryptoService: The crypto service to use
  ///   - keyManager: The key manager to use
  public init(cryptoService: CryptoServiceProtocol, keyManager: KeyManagementProtocol) {
    self.cryptoService=cryptoService
    self.keyManager=keyManager
    providerCore=SecurityProviderCore(cryptoService: cryptoService, keyManager: keyManager)
  }

  // MARK: - SecurityProviderProtocol

  /// Perform a secure operation with appropriate error handling
  /// - Parameters:
  ///   - operation: The security operation to perform
  ///   - config: Configuration options
  /// - Returns: Result of the operation
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await providerCore.performSecureOperation(operation: operation, config: config)
  }

  /**
   Create a secure configuration with appropriate defaults for the security subsystem.

   - Parameter options: Optional dictionary of configuration options
   - Returns: A properly configured SecurityConfigDTO

   ## Available Options

   * `algorithm`: String - The encryption algorithm to use (default: "AES-GCM")
   * `keySize`: Int - The key size in bits (default: 256)
   * `iv`: String - Hex-encoded initialisation vector
   * `keyIdentifier`: String - Identifier for a key in the key manager
   * `inputData`: String - Base64-encoded input data

   ## Default Configuration

   If no options are provided, the method will return a configuration with:
   - Algorithm: AES-GCM
   - Key Size: 256 bits
   - No IV (a random one will be generated by the crypto service)
   - No key identifier (key must be provided separately)
   - No input data

   ## Example

   ```swift
   let config = securityProvider.createSecureConfig(options: [
       "algorithm": "AES-GCM",
       "keySize": 256,
       "keyIdentifier": "my-encryption-key"
   ])
   ```
   */
  public func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO {
    providerCore.createSecureConfig(options: options)
  }
}
