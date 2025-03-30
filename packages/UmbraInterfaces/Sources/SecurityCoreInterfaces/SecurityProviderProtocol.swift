import Foundation
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # SecurityProviderProtocol

 Top-level protocol defining a complete security provider following the Alpha Dot Five architecture.

 This protocol consolidates cryptographic operations, key management, and security configuration
 into a cohesive interface for secure operations across the UmbraCore platform.

 ## Responsibilities

 The security provider serves as the primary interface for all security operations,
 coordinating between various security services and ensuring proper error handling,
 logging, and configuration management.
 */
public protocol SecurityProviderProtocol: Sendable, AsyncServiceInitializable {
  // MARK: - Service Access

  /// Access to cryptographic service implementation
  func cryptoService() async -> CryptoServiceProtocol

  /// Access to key management service implementation
  func keyManager() async -> KeyManagementProtocol

  // MARK: - Core Operations

  /**
   Encrypts data with the specified configuration.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Decrypts data with the specified configuration.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Generates a cryptographic key with the specified configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Securely stores data with the specified configuration.

   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   */
  func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Retrieves securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Deletes securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Creates a digital signature for data with the specified configuration.

   - Parameter config: Configuration for the digital signature operation
   - Returns: Result containing signature data or error
   */
  func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Verifies a digital signature with the specified configuration.

   - Parameter config: Configuration for the signature verification operation
   - Returns: Result containing verification status or error
   */
  func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO

  /**
   Performs a generic secure operation with appropriate error handling.

   - Parameters:
     - operation: The security operation to perform
     - config: Configuration options
   - Returns: Result of the operation
   */
  func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO

  /**
   Creates a secure configuration with type-safe, Sendable-compliant options.
   
   This method provides a Swift 6-compatible way to create security configurations
   that can safely cross actor boundaries.
   
   - Parameter options: Type-safe options structure that conforms to Sendable
   - Returns: A properly configured SecurityConfigDTO
   */
  func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO
}
