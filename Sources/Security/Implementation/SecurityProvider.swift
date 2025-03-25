/**
 # UmbraCore Security Provider

 The SecurityProvider acts as a facade for the UmbraCore security subsystem, providing
 a unified interface to cryptographic operations and key management. It implements the
 SecurityProviderProtocol defined in the SecurityProtocolsCore module.

 ## Design Pattern

 This class follows the Facade design pattern, simplifying access to the security
 subsystem by providing a single entry point that coordinates between different
 components:

 * CryptoServiceCore: Handles encryption, decryption, hashing, and other cryptographic operations
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
 * Always validate the success flag in the returned SecurityResultDto

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
     - Input sanitisation
     - Rate limiting for sensitive operations
     - More robust error handling
 */

import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import UmbraErrors

// Import specific protocols and types
import Types
import Protocols
import Utils

// Import implementation modules
import Provider
import CryptoServices
import KeyManagement

/// Implementation of the SecurityProviderProtocol
///
/// SecurityProvider coordinates between cryptographic services and key management
/// to provide a unified interface for security operations.
public final class SecurityProvider: SecurityProviderProtocol {
  // MARK: - Properties

  /// The crypto service for cryptographic operations
  public let cryptoService: CryptoServiceProtocol

  /// The key manager for key operations
  public let keyManager: KeyManagementProtocol

  /// Core implementation that handles provider functionality
  private let providerCore: SecurityProviderCore

  // MARK: - Initialisation

  /// Creates a new instance with default services
  public init() {
    // Use simplified approach with CryptoServiceAdapter to avoid circular dependencies
    let cryptoServiceImpl = CryptoServiceAdapter(dto: CryptoServiceDto(
      encrypt: { data, key in .success(data) },  // Placeholder implementations
      decrypt: { data, key in .success(data) },
      hash: { data in .success(data) },
      verifyHash: { data, hash in .success(true) }
    ))
    
    self.cryptoService = cryptoServiceImpl
    self.keyManager = KeyManagementAdapter()
    self.providerCore = SecurityProviderCore(
      cryptoService: cryptoServiceImpl,
      keyManager: keyManager
    )
  }

  /// Creates a new instance with the specified services
  /// - Parameters:
  ///   - cryptoService: Crypto service to use
  ///   - keyManager: Key manager to use
  public init(cryptoService: CryptoServiceProtocol, keyManager: KeyManagementProtocol) {
    self.cryptoService = cryptoService
    self.keyManager = keyManager
    self.providerCore = SecurityProviderCore(
      cryptoService: cryptoService,
      keyManager: keyManager
    )
  }

  // MARK: - SecurityProviderProtocol Implementation

  /// Perform a secure operation with the specified configuration
  /// - Parameters:
  ///   - operation: The secure operation to perform
  ///   - config: Configuration for the operation
  /// - Returns: Result of the operation
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDto
  ) async -> SecurityResultDto {
    await providerCore.performSecureOperation(operation: operation, config: config)
  }

  /// Create a security configuration with the specified options
  /// - Parameter options: Optional dictionary of configuration options
  /// - Returns: A security configuration object
  ///
  /// Example:
  /// ```swift
  /// let config = provider.createSecureConfig(options: [
  ///   "algorithm": "AES256",
  ///   "mode": "GCM"
  /// ])
  /// ```
  public func createSecureConfig(options: [String: Any]?) -> SecurityConfigDto {
    providerCore.createSecureConfig(options: options)
  }

  /// Get the current status of the security system
  /// - Returns: A status DTO with information about the security system
  public func getStatus() async -> ServiceStatusDto {
    await providerCore.getStatus()
  }

  /// Encrypts data using the specified key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data or error
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Core> {
    let operation = SecurityOperation.encrypt(data: data, key: key)
    let result = await providerCore.performSecureOperation(
      operation: operation,
      config: SecurityConfigDto.default
    )
    
    return result.convertToEncryptionResult()
  }

  /// Decrypts data using the specified key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data or error
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Core> {
    let operation = SecurityOperation.decrypt(data: data, key: key)
    let result = await providerCore.performSecureOperation(
      operation: operation,
      config: SecurityConfigDto.default
    )
    
    return result.convertToDecryptionResult()
  }
}
