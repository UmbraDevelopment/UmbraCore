import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/**
 SecurityProviderImpl actor implementation.

 This implementation coordinates between cryptographic services and key management systems,
 providing a unified interface for all security operations while ensuring proper isolation
 and error handling.

 ## Design Philosophy

 This implementation follows these core principles:

 1. **Actor-Based Concurrency**: Implemented as a Swift actor to ensure thread safety
    through Swift's structured concurrency model.

 2. **Provider Abstraction**: Supports multiple cryptographic implementations:
    - Basic/fallback provider (AES-CBC implementation)
    - Ring FFI for cross-platform environments
    - CryptoKit for native Apple platforms

 3. **Privacy-By-Design**: Incorporates privacy-aware error handling and logging that
    prevents leakage of sensitive information.

 4. **Type Safety**: Uses strongly-typed interfaces that make illegal states unrepresentable.
 */
public actor SecurityProviderImpl: SecurityProviderProtocol, AsyncServiceInitializable {
  // MARK: - Private Properties

  /// The crypto service for cryptographic operations
  private let cryptoServiceImpl: CryptoServiceProtocol

  /// The key manager for key operations
  private let keyManagerImpl: KeyManagementProtocol

  // MARK: - Initialisation

  /**
   Initialises a new security provider instance.

   - Parameters:
     - cryptoService: The crypto service implementation
     - keyManager: The key management implementation
   */
  public init(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) {
    cryptoServiceImpl=cryptoService
    keyManagerImpl=keyManager
  }

  /**
   Initializes the service with any required asynchronous setup.

   - Throws: An error if initialisation fails
   */
  public func initialize() async throws {
    // Initialize any components that support AsyncServiceInitializable
    if let initialisable=cryptoServiceImpl as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }

    if let initialisable=keyManagerImpl as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }
  }

  // MARK: - Service Access

  /// Access to cryptographic service implementation
  public func cryptoService() async -> CryptoServiceProtocol {
    cryptoServiceImpl
  }

  /// Access to key management service implementation
  public func keyManager() async -> KeyManagementProtocol {
    keyManagerImpl
  }

  // MARK: - Private Helpers

  /**
   Helper to get or create a key for the current operation.

   - Parameters:
     - config: The security configuration
     - operation: The security operation requiring a key
   - Returns: Byte array key if available
   - Throws: Error if key retrieval fails
   */
  private func getKeyForOperation(
    config: SecurityConfigDTO,
    operation _: SecurityOperation
  ) async throws -> [UInt8]? {
    // Check if the key is directly provided in the options
    if let keyB64=config.options?.metadata?["key"], let keyData=Data(base64Encoded: keyB64) {
      return [UInt8](keyData)
    }

    // Check if a key identifier is provided to load from key manager
    if let keyID=config.options?.metadata?["keyIdentifier"] {
      let result=await keyManagerImpl.retrieveKey(withIdentifier: keyID)
      switch result {
        case let .success(key):
          return key
        case let .failure(error):
          throw SecurityProtocolError.inputError("Failed to retrieve key with identifier \(keyID): \(error.localizedDescription)")
      }
    }

    // TODO: Implement more advanced key retrieval based on operation type
    return nil
  }

  // MARK: - SecurityProviderProtocol Core Implementation

  /**
   Encrypts binary data with the provided key.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
   - Returns: Encrypted data
   - Throws: Security protocol errors if encryption fails
   */
  public func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let dataIdentifier=await storeDataForOperation(data)
    let keyIdentifier=await storeDataForOperation(key)
    let result=await cryptoServiceImpl.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: EncryptionOptions(algorithm: .aes256CBC)
    )

    switch result {
      case let .success(encryptedDataIdentifier):
        // Retrieve the encrypted data using the identifier
        if let encryptedData = await retrieveDataForOperation(withIdentifier: encryptedDataIdentifier) {
            return encryptedData
        } else {
            throw SecurityProtocolError.inputError("Failed to retrieve encrypted data")
        }
      case let .failure(error):
        throw error
    }
  }

  /**
   Decrypts binary data with the provided key.

   - Parameters:
     - data: Encrypted data to decrypt
     - key: Decryption key
   - Returns: Decrypted data
   - Throws: Security protocol errors if decryption fails
   */
  public func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let encryptedDataIdentifier=await storeDataForOperation(data)
    let keyIdentifier=await storeDataForOperation(key)
    let result=await cryptoServiceImpl.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: DecryptionOptions(algorithm: .aes256CBC)
    )

    switch result {
      case let .success(decryptedDataIdentifier):
        // Retrieve the decrypted data using the identifier
        if let decryptedData = await retrieveDataForOperation(withIdentifier: decryptedDataIdentifier) {
            return decryptedData
        } else {
            throw SecurityProtocolError.inputError("Failed to retrieve decrypted data")
        }
      case let .failure(error):
        throw error
    }
  }

  /**
   Handles implementation of the hash function required by SecurityProviderProtocol.
   
   - Parameter config: Configuration for the hash operation
   - Returns: Result DTO with the computed hash
   - Throws: Security errors if hashing fails
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operation = SecurityOperation.hash
    let handler = OperationsHandler(cryptoService: cryptoServiceImpl, keyManager: keyManagerImpl)
    return await handler.handleOperation(operation: operation, config: config)
  }

  /**
   Signs data with the provided key.

   - Parameters:
     - data: Data to sign
     - key: Signing key
   - Returns: Signature
   - Throws: Security protocol errors if signing fails
   */
  public func sign(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // This is a placeholder implementation
    // For now, we'll just concatenate the data and key and hash them to create a signature
    let dataIdentifier = await storeDataForOperation(data + key)
    let result = await cryptoServiceImpl.hash(
      dataIdentifier: dataIdentifier,
      options: HashingOptions(algorithm: .sha256)
    )

    switch result {
      case let .success(signatureIdentifier):
        // Retrieve the signature using the identifier
        if let signatureData = await retrieveDataForOperation(withIdentifier: signatureIdentifier) {
            return signatureData
        } else {
            throw SecurityProtocolError.inputError("Failed to retrieve signature data")
        }
      case let .failure(error):
        throw error
    }
  }

  /**
   Handles a security operation with the appropriate handler.

   - Parameters:
     - operation: The security operation to perform
     - config: Configuration for the operation
   - Returns: Result DTO with operation results
   - Throws: Security errors if the operation fails
   */
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    switch operation {
      case .encrypt:
        return try await encrypt(config: config)
      case .decrypt:
        return try await decrypt(config: config)
      case .hash:
        return try await hash(config: config)
      case .generateRandom:
        return try await generateKey(config: config)
      case .sign:
        return try await sign(config: config)
      case .verify:
        return try await verify(config: config)
      case .storeKey:
        return try await secureStore(config: config)
      case .retrieveKey:
        return try await secureRetrieve(config: config)
      case .deleteKey:
        return try await secureDelete(config: config)
      case .deriveKey:
        throw SecurityProtocolError.inputError("Operation \(operation) not supported in this implementation")
    }
  }

  /**
   Creates a secure configuration based on the provided options
   - Parameter options: Configuration options for secure operations
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    // Map security options to the appropriate enum values

    // Determine the encryption algorithm based on the hardware acceleration setting
    let encryption: CoreSecurityTypes.EncryptionAlgorithm=if options.useHardwareAcceleration {
      .aes256GCM // Hardware-accelerated GCM is often available
    } else {
      .aes256CBC // CBC as fallback for software implementations
    }

    // Determine the hash algorithm based on the key derivation iterations
    let hash: CoreSecurityTypes.HashAlgorithm=if options.keyDerivationIterations > 200_000 {
      .sha512 // Use stronger hash for high-security settings
    } else {
      .sha256 // Default hash
    }

    // Determine provider type based on hardware acceleration
    let provider: SecurityProviderType=if options.useHardwareAcceleration {
      .cryptoKit // CryptoKit supports hardware acceleration on Apple platforms
    } else {
      .basic // Basic provider for software-only implementations
    }

    // Create a new SecurityConfigOptions instance with the same settings but ensure metadata is
    // preserved
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: options.enableDetailedLogging,
      keyDerivationIterations: options.keyDerivationIterations,
      memoryLimitBytes: options.memoryLimitBytes,
      useHardwareAcceleration: options.useHardwareAcceleration,
      operationTimeoutSeconds: options.operationTimeoutSeconds,
      verifyOperations: options.verifyOperations,
      metadata: options.metadata
    )

    // Create the DTO with the proper enum values
    return SecurityConfigDTO(
      encryptionAlgorithm: encryption,
      hashAlgorithm: hash,
      providerType: provider,
      options: configOptions
    )
  }

  /**
   Generates cryptographically secure random bytes.

   - Parameter count: Number of random bytes to generate
   - Returns: Array of random bytes
   - Throws: Error if random generation fails
   */
  private func generateRandomBytes(count: Int) async throws -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: count)
    let status=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityProtocolError.inputError("Failed to generate random bytes: \(status)")
    }

    return bytes
  }

  /**
   Helper method to compare two byte arrays.

   - Parameters:
     - bytes1: First byte array
     - bytes2: Second byte array
   - Returns: True if the bytes are identical, false otherwise
   */
  private func compareBytes(_ bytes1: [UInt8], _ bytes2: [UInt8]) -> Bool {
    guard bytes1.count == bytes2.count else { return false }

    // Using a constant-time comparison to prevent timing attacks
    var result: UInt8=0
    for i in 0..<bytes1.count {
      result |= bytes1[i] ^ bytes2[i]
    }

    return result == 0
  }

  private func storeDataForOperation(_ data: [UInt8]) async -> String {
    // Generate a unique identifier
    let identifier = UUID().uuidString
    
    // Store the data using the crypto service's secure storage
    let result = await cryptoServiceImpl.secureStorage.storeData(data, withIdentifier: identifier)
    
    // Handle the result
    switch result {
    case .success:
        return identifier
    case .failure(let error):
        // Log error if possible, but return the identifier anyway
        // as it may be needed for the calling function's signature
        print("Warning: Failed to store data: \(error.localizedDescription)")
        return identifier
    }
  }
  
  /// Retrieves data securely using an identifier
  /// - Parameter identifier: The identifier for the stored data
  /// - Returns: The retrieved binary data or nil if retrieval failed
  private func retrieveDataForOperation(withIdentifier identifier: String) async -> [UInt8]? {
    let result = await cryptoServiceImpl.secureStorage.retrieveData(withIdentifier: identifier)
    
    switch result {
    case .success(let data):
        return data
    case .failure(let error):
        // Log error if possible
        print("Warning: Failed to retrieve data: \(error.localizedDescription)")
        return nil
    }
  }

  /**
   Handles a security operation with OperationsHandler.

   - Parameter config: Security configuration for the operation
   - Returns: Security result DTO
   */
  private func handleSecurityOperation(with config: SecurityConfigDTO, operation: SecurityOperation) async -> SecurityResultDTO {
    let handler = OperationsHandler(cryptoService: cryptoServiceImpl, keyManager: keyManagerImpl)
    return await handler.handleOperation(operation: operation, config: config)
  }

  /**
   Verifies a cryptographic signature against the provided data.

   - Parameter config: Configuration for the verification operation
   - Returns: Result DTO with verification result
   - Throws: Security errors if verification fails
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operation = SecurityOperation.verify
    let handler = OperationsHandler(cryptoService: cryptoServiceImpl, keyManager: keyManagerImpl)
    return await handler.handleOperation(operation: operation, config: config)
  }

  /**
   Performs encryption using the provided configuration.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result DTO with encrypted data and metadata
   - Throws: Security errors if encryption fails
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operation = SecurityOperation.encrypt
    let handler = OperationsHandler(cryptoService: cryptoServiceImpl, keyManager: keyManagerImpl)
    return await handler.handleOperation(operation: operation, config: config)
  }

  /**
   Performs decryption using the provided configuration.

   - Parameter config: Configuration parameters for the decryption operation
   - Returns: SecurityResultDTO with the decryption result
   - Throws: Protocol violation errors
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operation = SecurityOperation.decrypt
    let handler = OperationsHandler(cryptoService: cryptoServiceImpl, keyManager: keyManagerImpl)
    return await handler.handleOperation(operation: operation, config: config)
  }

  /**
   Generates a new cryptographic key based on configuration parameters.

   - Parameter config: Configuration for key generation
   - Returns: Result DTO with the generated key
   - Throws: Security errors if key generation fails
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract key size from config (default to 256 if not explicitly set)
    let keySize=config.options?.metadata?["keySize"].flatMap { Int($0) } ?? 256

    // Generate random bytes as the key
    let keyBytes=try await generateRandomBytes(count: keySize / 8)

    // Store the key if needed
    let keyID=UUID().uuidString
    let storeResult=await keyManagerImpl.storeKey(keyBytes, withIdentifier: keyID)

    switch storeResult {
      case .success:
        // Create metadata for the operation
        let metadata: [String: String]=[
          "keySize": "\(keySize)",
          "keyID": keyID,
          "operation": "generateRandom"
        ]

        // Use the success factory method
        return .success(
          resultData: Data(keyBytes),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: metadata
        )
      case let .failure(error):
        // Use the failure factory method
        return .failure(
          errorDetails: "Key generation failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
        )
    }
  }

  /**
   Generate a cryptographically secure random key.

   - Parameter length: Length of the key in bytes
   - Returns: Generated key
   - Throws: SecurityProtocolError if key generation fails
   */
  public func generateKey(length: Int) async throws -> [UInt8] {
    try await generateRandomBytes(count: length)
  }

  /**
   Stores data securely using the provided configuration.

   - Parameter config: Configuration for the secure storage operation
   - Returns: Result DTO with operation status
   - Throws: Security errors if storage fails
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard config.options != nil else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing configuration options",
        executionTimeMs: 0,
        metadata: ["operation": "secureStore"]
      )
    }

    guard
      let dataString=config.options?.metadata?["data"],
      let inputData=Data(base64Encoded: dataString)
    else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing or invalid data for secure storage operation",
        executionTimeMs: 0,
        metadata: ["operation": "secureStore"]
      )
    }

    guard let identifier=config.options?.metadata?["identifier"] else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing identifier for secure storage operation",
        executionTimeMs: 0,
        metadata: ["operation": "secureStore"]
      )
    }

    // Store the data
    let storeResult=await keyManagerImpl.storeKey([UInt8](inputData), withIdentifier: identifier)

    switch storeResult {
      case .success:
        return SecurityResultDTO.success(
          resultData: nil,
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "storeKey",
            "identifier": identifier
          ]
        )
      case let .failure(error):
        return SecurityResultDTO.failure(
          errorDetails: "Secure storage failed: \(error.localizedDescription)",
          executionTimeMs: 0,
          metadata: ["operation": "secureStore"]
        )
    }
  }

  /**
   Retrieves securely stored data using the provided configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result DTO with retrieved data
   - Throws: Security errors if retrieval fails
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard config.options != nil else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing configuration options",
        executionTimeMs: 0,
        metadata: ["operation": "secureRetrieve"]
      )
    }

    guard let identifier=config.options?.metadata?["identifier"] else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing identifier for secure retrieval operation",
        executionTimeMs: 0,
        metadata: ["operation": "secureRetrieve"]
      )
    }

    // Retrieve the data
    let retrieveResult=await keyManagerImpl.retrieveKey(withIdentifier: identifier)

    switch retrieveResult {
      case let .success(data):
        return SecurityResultDTO.success(
          resultData: Data(data),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "retrieveKey",
            "identifier": identifier
          ]
        )
      case let .failure(error):
        return SecurityResultDTO.failure(
          errorDetails: "Secure retrieval failed: \(error.localizedDescription)",
          executionTimeMs: 0,
          metadata: ["operation": "secureRetrieve"]
        )
    }
  }

  /**
   Deletes securely stored data using the provided configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result DTO with operation status
   - Throws: Security errors if deletion fails
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard config.options != nil else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing configuration options",
        executionTimeMs: 0,
        metadata: ["operation": "secureDelete"]
      )
    }

    guard let identifier=config.options?.metadata?["identifier"] else {
      return SecurityResultDTO.failure(
        errorDetails: "Missing identifier for secure deletion operation",
        executionTimeMs: 0,
        metadata: ["operation": "secureDelete"]
      )
    }

    // Delete the data
    let deleteResult=await keyManagerImpl.deleteKey(withIdentifier: identifier)

    switch deleteResult {
      case .success:
        return SecurityResultDTO.success(
          resultData: nil,
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "deleteKey",
            "identifier": identifier
          ]
        )
      case let .failure(error):
        return SecurityResultDTO.failure(
          errorDetails: "Secure deletion failed: \(error.localizedDescription)",
          executionTimeMs: 0,
          metadata: ["operation": "secureDelete"]
        )
    }
  }

  /**
   Performs digital signature operations using the provided configuration.

   - Parameter config: Configuration for the signing operation
   - Returns: Result DTO with signature data
   - Throws: Protocol violation errors
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operation = SecurityOperation.sign
    let handler = OperationsHandler(cryptoService: cryptoServiceImpl, keyManager: keyManagerImpl)
    return await handler.handleOperation(operation: operation, config: config)
  }
}
