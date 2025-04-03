import CoreInterfaces
import Foundation
import SecurityCoreInterfaces
import CoreSecurityTypes

/**
 # Security Provider Adapter

 This actor implements the adapter pattern to bridge between the CoreSecurityProviderProtocol
 and the full SecurityProviderProtocol implementation.

 ## Purpose

 - Provides a simplified interface for core modules to access security functionality
 - Delegates operations to the actual security implementation
 - Converts between data types as necessary
 - Ensures thread safety through the actor concurrency model

 ## Design Pattern

 This adapter follows the classic adapter design pattern, where it implements
 one interface (CoreSecurityProviderProtocol) while wrapping an instance of another
 interface (SecurityProviderProtocol).
 */
public actor SecurityProviderAdapter: CoreSecurityProviderProtocol {
  // MARK: - Properties

  /**
   The underlying security provider implementation

   This is the actual implementation that performs the security operations.
   */
  private let securityProvider: SecurityCoreInterfaces.SecurityProviderProtocol

  // MARK: - Initialisation

  /**
   Initialises a new adapter with the provided security provider

   - Parameter securityProvider: The security provider implementation to adapt
   */
  public init(securityProvider: SecurityCoreInterfaces.SecurityProviderProtocol) {
    self.securityProvider=securityProvider
  }

  // MARK: - CoreSecurityProviderProtocol Implementation

  /**
   Initialises the security provider

   This method ensures the underlying security provider is properly initialised.
   With actor-based implementations, this may redirect to the underlying provider's
   initialize() method.

   - Throws: SecurityError if initialisation fails
   */
  public func initialise() async throws {
    try await securityProvider.initialize()
  }

  /**
   Encrypts data with the provided key

   Delegates to the underlying security provider implementation.

   - Parameters:
     - data: The data to encrypt
     - key: The encryption key
   - Returns: The encrypted data
   - Throws: SecurityError if encryption fails
   */
  public func encrypt(data: Data, key: Data) async throws -> Data {
    // Create the secure bytes from data
    let secureData=SecureBytes(data: data)
    let secureKey=SecureBytes(data: key)

    // Create the configuration for encryption
    let config=SecurityConfigDTO(
      operation: .encrypt,
      key: secureKey,
      data: secureData,
      algorithm: "AES",
      mode: "GCM"
    )

    // Perform encryption
    let result=try await securityProvider.encrypt(config: config)

    // Return the encrypted data
    return result.processedData.extractUnderlyingData()
  }

  /**
   Decrypts data with the provided key

   Delegates to the underlying security provider implementation.

   - Parameters:
     - data: The data to decrypt
     - key: The decryption key
   - Returns: The decrypted data
   - Throws: SecurityError if decryption fails
   */
  public func decrypt(data: Data, key: Data) async throws -> Data {
    // Create the secure bytes from data
    let secureData=SecureBytes(data: data)
    let secureKey=SecureBytes(data: key)

    // Create the configuration for decryption
    let config=SecurityConfigDTO(
      operation: .decrypt,
      key: secureKey,
      data: secureData,
      algorithm: "AES",
      mode: "GCM"
    )

    // Perform decryption
    let result=try await securityProvider.decrypt(config: config)

    // Return the decrypted data
    return result.processedData.extractUnderlyingData()
  }

  /**
   Generates a secure random key of the specified length

   Delegates to the underlying security provider implementation.

   - Parameter length: The length of the key in bytes
   - Returns: A secure random key
   - Throws: SecurityError if key generation fails
   */
  public func generateKey(length: Int) async throws -> Data {
    let result=try await securityProvider.generateEncryptionKey(keySize: length * 8)
    return result.processedData.extractUnderlyingData()
  }

  /**
   Stores a key securely

   Delegates to the underlying security provider implementation.

   - Parameters:
     - key: The key to store
     - identifier: The identifier for retrieving the key
   - Throws: SecurityError if key storage fails
   */
  public func storeKey(_ key: Data, identifier: String) async throws {
    let secureKey=SecureBytes(data: key)
    let result=await securityProvider.storeKey(secureKey, withIdentifier: identifier)

    if case let .failure(error)=result {
      throw SecurityError.keyStorageFailed(message: error.localizedDescription)
    }
  }

  /**
   Retrieves a stored key by its identifier

   Delegates to the underlying security provider implementation.

   - Parameter identifier: The identifier of the key to retrieve
   - Returns: The retrieved key
   - Throws: SecurityError if key retrieval fails
   */
  public func retrieveKey(identifier: String) async throws -> Data {
    let result=await securityProvider.retrieveKey(withIdentifier: identifier)

    switch result {
      case let .success(key):
        return key.extractUnderlyingData()
      case let .failure(error):
        throw SecurityError.keyRetrievalFailed(message: error.localizedDescription)
    }
  }

  /**
   Authenticates a user using the provided identifier and credentials

   Delegates to the underlying security provider implementation.

   - Parameters:
       - identifier: User identifier
       - credentials: Authentication credentials
   - Returns: True if authentication is successful, false otherwise
   - Throws: SecurityError if authentication fails
   */
  public func authenticate(identifier: String, credentials: Data) async throws -> Bool {
    try await securityProvider.authenticate(identifier: identifier, credentials: credentials)
  }

  /**
   Authorises access to a resource at the specified access level

   Delegates to the underlying security provider implementation.

   - Parameters:
       - resource: The resource identifier
       - accessLevel: The requested access level
   - Returns: True if authorisation is granted, false otherwise
   - Throws: SecurityError if authorisation check fails
   */
  public func authorise(resource: String, accessLevel: String) async throws -> Bool {
    try await securityProvider.authorise(resource: resource, accessLevel: accessLevel)
  }

  /**
   Verifies the integrity of data using the provided signature

   Delegates to the underlying security provider implementation.

   - Parameters:
       - data: Data to verify
       - signature: Digital signature
   - Returns: True if verification is successful, false otherwise
   - Throws: SecurityError if verification process fails
   */
  public func verifySignature(data: Data, signature: Data) async throws -> Bool {
    try await securityProvider.verify(data: data, signature: signature)
  }
}

/**
 # Security Error

 Error type for security operations through the adapter.
 */
public enum SecurityError: Error, Sendable {
  case encryptionFailed(message: String)
  case decryptionFailed(message: String)
  case keyGenerationFailed(message: String)
  case keyStorageFailed(message: String)
  case keyRetrievalFailed(message: String)
  case initialisation(message: String)
  case invalidInput(message: String)
}
