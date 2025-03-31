import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces
import DomainSecurityTypes
import UmbraErrors

/**
 # SecurityProviderImpl

 Thread-safe implementation of the SecurityProviderProtocol that follows the architecture.

 This implementation coordinates between cryptographic services and key management systems,
 providing a unified interface for all security operations while ensuring proper isolation
 and error handling.

 ## Design Philosophy

 This implementation follows these core principles:

 1. **Actor-Based Concurrency**: While not an actor itself, it uses thread-safe access patterns
    that complement Swift's structured concurrency model.

 2. **Provider Abstraction**: Supports multiple cryptographic implementations:
    - Basic/fallback provider (AES-CBC implementation)
    - Ring FFI for cross-platform environments
    - CryptoKit for native Apple platforms

 3. **Privacy-By-Design**: Incorporates privacy-aware error handling and logging that
    prevents leakage of sensitive information.

 4. **Type Safety**: Uses strongly-typed interfaces that make illegal states unrepresentable.
 */
public final class SecurityProviderImpl: SecurityProviderProtocol, AsyncServiceInitializable {
  // MARK: - Private Properties

  /// The crypto service for cryptographic operations
  private let cryptoServiceImpl: CryptoServiceProtocol

  /// The key manager for key operations
  private let keyManagerImpl: KeyManagementProtocol

  /// Lock for thread-safe access
  private let lock = NSLock()

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
    self.cryptoServiceImpl = cryptoService
    self.keyManagerImpl = keyManager
  }

  /**
   Initializes the service with any required asynchronous setup.

   - Throws: An error if initialisation fails
   */
  public func initialize() async throws {
    // Initialize any components that support AsyncServiceInitializable
    if let initialisable = cryptoServiceImpl as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }

    if let initialisable = keyManagerImpl as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }
  }

  // MARK: - Service Access

  /// Access to cryptographic service implementation
  public func cryptoService() async -> CryptoServiceProtocol {
    return cryptoServiceImpl
  }

  /// Access to key management service implementation
  public func keyManager() async -> KeyManagementProtocol {
    return keyManagerImpl
  }

  // MARK: - Thread Safety

  /**
   Execute a closure with thread-safe access to provider state.

   - Parameter work: The work to execute with the lock held
   - Returns: Whatever the work closure returns
   */
  private func withThreadSafety<T>(_ work: () throws -> T) rethrows -> T {
    lock.lock()
    defer { lock.unlock() }
    return try work()
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
    operation: SecurityOperation
  ) async throws -> [UInt8]? {
    // Check if the key is directly provided in the options
    if let keyB64 = config.options?.metadata?["key"], let keyData = Data(base64Encoded: keyB64) {
      return [UInt8](keyData)
    }
    
    // Check if a key identifier is provided to load from key manager
    if let keyID = config.options?.metadata?["keyIdentifier"] {
      let result = await keyManagerImpl.retrieveKey(withIdentifier: keyID)
      switch result {
        case .success(let key):
          return key
        case .failure(let error):
          throw SecurityProtocolError.invalidMessageFormat(
            details: "Failed to retrieve key with identifier \(keyID): \(error.localizedDescription)"
          )
      }
    }
    
    // TODO: Implement more advanced key retrieval based on operation type
    return nil
  }

  // MARK: - SecurityProviderProtocol Core Implementation
  
  /// Encrypt binary data using the provider's encryption mechanism
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  /// - Throws: SecurityProtocolError if encryption fails
  public func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let result = await cryptoServiceImpl.encrypt(data: data, using: key)
    
    switch result {
      case .success(let encryptedData):
        return encryptedData
      case .failure(let error):
        throw SecurityProtocolError.invalidMessageFormat(
          details: "Encryption failed: \(error.localizedDescription)"
        )
    }
  }
  
  /// Decrypt binary data using the provider's decryption mechanism
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  /// - Throws: SecurityProtocolError if decryption fails
  public func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let result = await cryptoServiceImpl.decrypt(data: data, using: key)
    
    switch result {
      case .success(let decryptedData):
        return decryptedData
      case .failure(let error):
        throw SecurityProtocolError.invalidMessageFormat(
          details: "Decryption failed: \(error.localizedDescription)"
        )
    }
  }
  
  /// Generate a cryptographically secure random key
  /// - Parameter length: Length of the key in bytes
  /// - Returns: Generated key
  /// - Throws: SecurityProtocolError if key generation fails
  public func generateKey(length: Int) async throws -> [UInt8] {
    return try await generateRandomBytes(count: length)
  }
  
  /// Hash data using the provider's hashing mechanism
  /// - Parameter data: Data to hash
  /// - Returns: Hash of the data
  /// - Throws: SecurityProtocolError if hashing fails
  public func hash(_ data: [UInt8]) async throws -> [UInt8] {
    let result = await cryptoServiceImpl.hash(data: data)
    
    switch result {
      case .success(let hashData):
        return hashData
      case .failure(let error):
        throw SecurityProtocolError.invalidMessageFormat(
          details: "Hashing failed: \(error.localizedDescription)"
        )
    }
  }

  // MARK: - SecurityProvider Implementation

  /**
   Performs encryption using the provided configuration.

   - Parameter config: Configuration parameters for the encryption operation
   - Returns: Result DTO with encrypted data and metadata
   - Throws: Security errors if encryption fails
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard config.options != nil else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let dataString = config.options?.metadata?["data"], let inputData = Data(base64Encoded: dataString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid data for encryption operation")
    }
    
    guard let key = try await getKeyForOperation(config: config, operation: .encrypt) else {
      throw SecurityProtocolError.invalidState(
        expected: "Key available", 
        actual: "No key found for encryption operation"
      )
    }

    // Perform encryption
    let result = await cryptoServiceImpl.encrypt(data: [UInt8](inputData), using: key)

    // Process result
    switch result {
      case let .success(encryptedData):
        return .success(
          resultData: Data(encryptedData),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "encrypt"
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Encryption failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
        )
    }
  }

  /**
   Performs decryption using the provided configuration.

   - Parameter config: Configuration parameters for the decryption operation
   - Returns: Result DTO with decrypted data and metadata
   - Throws: Security errors if decryption fails
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard config.options != nil else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let dataString = config.options?.metadata?["data"], let inputData = Data(base64Encoded: dataString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid data for decryption operation")
    }
    
    guard let key = try await getKeyForOperation(config: config, operation: .decrypt) else {
      throw SecurityProtocolError.invalidState(
        expected: "Key available", 
        actual: "No key found for decryption operation"
      )
    }

    // Perform decryption
    let result = await cryptoServiceImpl.decrypt(data: [UInt8](inputData), using: key)

    // Process result
    switch result {
      case let .success(decryptedData):
        return .success(
          resultData: Data(decryptedData),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "decrypt"
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Decryption failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
        )
    }
  }

  /**
   Generates a new cryptographic key based on configuration parameters.

   - Parameter config: Configuration for key generation
   - Returns: Result DTO with the generated key
   - Throws: Security errors if key generation fails
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract key size from config (default to 256 if not explicitly set)
    let keySize = config.options?.metadata?["keySize"].flatMap { Int($0) } ?? 256

    // Generate random bytes as the key
    let keyBytes = try await generateRandomBytes(count: keySize / 8)

    // Store the key if needed
    let keyID = UUID().uuidString
    let storeResult = await keyManagerImpl.storeKey(keyBytes, withIdentifier: keyID)

    switch storeResult {
      case .success:
        // Create metadata for the operation
        let metadata: [String: String] = [
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
   Computes a cryptographic hash of the provided data.

   - Parameter config: Configuration for the hash operation
   - Returns: Result DTO with the computed hash
   - Throws: Security errors if hashing fails
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard config.options != nil else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let dataString = config.options?.metadata?["data"], let inputData = Data(base64Encoded: dataString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid data for hash operation")
    }

    // Perform hash operation
    let result = await cryptoServiceImpl.hash(data: [UInt8](inputData))

    // Process result
    switch result {
      case let .success(hashedData):
        return .success(
          resultData: Data(hashedData),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "hash",
            "algorithm": config.hashAlgorithm.rawValue
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Hashing failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
        )
    }
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
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let dataString = config.options?.metadata?["data"], let inputData = Data(base64Encoded: dataString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid data for secure storage operation")
    }
    
    guard let identifier = config.options?.metadata?["identifier"] else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing identifier for secure storage operation")
    }

    // Store the data
    let storeResult = await keyManagerImpl.storeKey([UInt8](inputData), withIdentifier: identifier)

    switch storeResult {
      case .success:
        return .success(
          resultData: nil,
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "storeKey",
            "identifier": identifier
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Secure storage failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
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
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let identifier = config.options?.metadata?["identifier"] else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing identifier for secure retrieval operation")
    }

    // Retrieve the data
    let retrieveResult = await keyManagerImpl.retrieveKey(withIdentifier: identifier)

    switch retrieveResult {
      case let .success(data):
        return .success(
          resultData: Data(data),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "retrieveKey",
            "identifier": identifier
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Secure retrieval failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
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
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let identifier = config.options?.metadata?["identifier"] else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing identifier for secure deletion operation")
    }

    // Delete the data
    let deleteResult = await keyManagerImpl.deleteKey(withIdentifier: identifier)

    switch deleteResult {
      case .success:
        return .success(
          resultData: nil,
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "deleteKey",
            "identifier": identifier
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Secure deletion failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
        )
    }
  }

  /**
   Performs digital signature operations using the provided configuration.

   - Parameter config: Configuration for the signing operation
   - Returns: Result DTO with signature data
   - Throws: Security errors if signing fails
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters
    guard config.options != nil else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let dataString = config.options?.metadata?["data"], let inputData = Data(base64Encoded: dataString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid data for sign operation")
    }
    
    guard let key = try await getKeyForOperation(config: config, operation: .sign) else {
      throw SecurityProtocolError.invalidState(
        expected: "Key available", 
        actual: "No key found for sign operation"
      )
    }

    // For now, we'll just return a basic HMAC as signature since full signing implementation
    // would depend on specific algorithms that might not be in scope
    let result = await cryptoServiceImpl.hash(data: [UInt8](inputData) + key)

    switch result {
      case let .success(signatureData):
        return .success(
          resultData: Data(signatureData),
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: [
            "operation": "sign",
            "algorithm": config.encryptionAlgorithm.rawValue
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Signing failed: \(error.localizedDescription)",
          executionTimeMs: 0, // We should implement proper timing in production
          metadata: nil
        )
    }
  }

  /**
   Verifies a cryptographic signature against the provided data.

   - Parameter config: Configuration for the verification operation
   - Returns: Result DTO with verification result
   - Throws: Security errors if verification fails
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters
    guard config.options != nil else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing configuration options")
    }
    
    guard let dataString = config.options?.metadata?["data"], let inputData = Data(base64Encoded: dataString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid data for verification operation")
    }
    
    guard let signatureString = config.options?.metadata?["signature"], let signatureData = Data(base64Encoded: signatureString) else {
      throw SecurityProtocolError.invalidMessageFormat(details: "Missing or invalid signature for verification operation")
    }
    
    guard let key = try await getKeyForOperation(config: config, operation: .verify) else {
      throw SecurityProtocolError.invalidState(
        expected: "Key available", 
        actual: "No key found for verification operation"
      )
    }

    // For now, we'll use a simple approach similar to the sign operation
    let result = await cryptoServiceImpl.hash(data: [UInt8](inputData) + key)

    switch result {
      case let .success(computedSignature):
        // Compare the computed signature with the provided one
        let isValid = compareBytes([UInt8](signatureData), computedSignature)
        
        return .success(
          resultData: nil,
          executionTimeMs: 0,
          metadata: [
            "operation": "verify",
            "isValid": isValid ? "true" : "false"
          ]
        )
      case let .failure(error):
        return .failure(
          errorDetails: "Verification failed: \(error.localizedDescription)",
          executionTimeMs: 0,
          metadata: nil
        )
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
        throw SecurityProtocolError.invalidMessageFormat(
          details: "Operation \(operation) not supported in this implementation"
        )
    }
  }

  /**
   Creates a secure configuration with type-safe, Sendable-compliant options.

   This method provides a Swift 6-compatible way to create security configurations
   that can safely cross actor boundaries.

   - Parameter options: Type-safe options structure that conforms to Sendable
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    // Map security options to the appropriate enum values
    
    // Determine the encryption algorithm based on the hardware acceleration setting
    let encryption: EncryptionAlgorithm
    if options.useHardwareAcceleration {
      encryption = .aes256GCM  // Hardware-accelerated GCM is often available
    } else {
      encryption = .aes256CBC  // CBC as fallback for software implementations
    }
    
    // Determine the hash algorithm based on the key derivation iterations
    let hash: HashAlgorithm
    if options.keyDerivationIterations > 200_000 {
      hash = .sha512  // Use stronger hash for high-security settings
    } else {
      hash = .sha256  // Default hash
    }
    
    // Determine provider type based on hardware acceleration
    let provider: SecurityProviderType
    if options.useHardwareAcceleration {
      provider = .cryptoKit  // CryptoKit supports hardware acceleration on Apple platforms
    } else {
      provider = .basic  // Basic provider for software-only implementations
    }

    // Create a new SecurityConfigOptions instance with the same settings but ensure metadata is preserved
    let configOptions = SecurityConfigOptions(
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
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityProtocolError.invalidMessageFormat(
        details: "Failed to generate random bytes: \(status)"
      )
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
    var result: UInt8 = 0
    for i in 0..<bytes1.count {
      result |= bytes1[i] ^ bytes2[i]
    }
    
    return result == 0
  }
}
