import ErrorCoreTypes
import ErrorDomainsImpl
import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # SecurityProviderImpl
 
 Thread-safe implementation of the SecurityProviderProtocol that follows the Alpha Dot Five architecture.
 
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
public final class SecurityProviderImpl: SecurityProviderProtocol {
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
     - cryptoService: Service providing cryptographic operations
     - keyManager: Service providing key management operations
   */
  public init(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) {
    self.cryptoServiceImpl = cryptoService
    self.keyManagerImpl = keyManager
  }
  
  /**
   Initialises the service with any required asynchronous setup.
   
   This implementation initialises the underlying crypto and key management services.
   
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
  
  // MARK: - SecurityProviderProtocol Implementation
  
  /**
   Provides access to the cryptographic service implementation.
   
   - Returns: The crypto service implementation
   */
  public func cryptoService() async -> CryptoServiceProtocol {
    return cryptoServiceImpl
  }
  
  /**
   Provides access to the key management service implementation.
   
   - Returns: The key management implementation
   */
  public func keyManager() async -> KeyManagementProtocol {
    return keyManagerImpl
  }
  
  /**
   Encrypts data with the specified configuration.
   
   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard let key = try await getKeyForOperation(config: config, operation: .encrypt(data: config.data ?? SecureBytes(), key: nil)) else {
      throw SecurityErrorDomain.invalidKey(
        reason: "Could not retrieve key for encryption operation"
      )
    }
    
    // Convert data from config
    guard let data = config.data else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing data for encryption operation"
      )
    }
    
    // Perform the encryption using the crypto service
    let result = await cryptoServiceImpl.encrypt(data: data, using: key)
    
    // Process result
    switch result {
    case .success(let encryptedData):
      return SecurityResultDTO(
        status: .success,
        data: encryptedData,
        metadata: [
          "algorithm": config.algorithm,
          "operationType": "encrypt"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Decrypts data with the specified configuration.
   
   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard let key = try await getKeyForOperation(config: config, operation: .decrypt(data: config.data ?? SecureBytes(), key: nil)) else {
      throw SecurityErrorDomain.invalidKey(
        reason: "Could not retrieve key for decryption operation"
      )
    }
    
    // Convert data from config
    guard let data = config.data else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing data for decryption operation"
      )
    }
    
    // Perform the decryption using the crypto service
    let result = await cryptoServiceImpl.decrypt(data: data, using: key)
    
    // Process result
    switch result {
    case .success(let decryptedData):
      return SecurityResultDTO(
        status: .success,
        data: decryptedData,
        metadata: [
          "algorithm": config.algorithm,
          "operationType": "decrypt"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Generates a cryptographic key with the specified configuration.
   
   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract key size from config (default to 256 if not specified)
    let keySize = config.keySize ?? 256
    
    // Generate random bytes as the key
    let keyData = try await generateRandomBytes(length: keySize / 8)
    
    // Determine identifier for the key (use provided ID or generate a UUID)
    let keyID = config.identifier ?? UUID().uuidString
    
    // Store the generated key
    let storeResult = await keyManagerImpl.storeKey(keyData, withIdentifier: keyID)
    
    // Process result
    switch storeResult {
    case .success:
      return SecurityResultDTO(
        status: .success,
        identifier: keyID,
        metadata: [
          "keySize": "\(keySize)",
          "algorithm": config.algorithm,
          "operationType": "generateKey"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Computes a cryptographic hash for the provided data.
   
   - Parameter config: Configuration for the hash operation
   - Returns: Result containing hash data or error
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract data from config
    guard let data = config.data else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing data for hash operation"
      )
    }
    
    // Perform hash operation
    let result = await cryptoServiceImpl.hash(data: data)
    
    // Process result
    switch result {
    case .success(let hashData):
      return SecurityResultDTO(
        status: .success,
        data: hashData,
        metadata: [
          "algorithm": config.hashAlgorithm ?? "SHA256",
          "operationType": "hash"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Securely stores data with the specified configuration.
   
   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters from config
    guard let data = config.data else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing data for secure storage operation"
      )
    }
    
    // Ensure we have an identifier
    guard let identifier = config.identifier else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing identifier for secure storage operation"
      )
    }
    
    // We'll use the key manager to store the data as a "key"
    let storeResult = await keyManagerImpl.storeKey(data, withIdentifier: identifier)
    
    // Process result
    switch storeResult {
    case .success:
      return SecurityResultDTO(
        status: .success,
        identifier: identifier,
        metadata: [
          "operation": "secureStore",
          "timestamp": "\(Date().timeIntervalSince1970)"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Retrieves securely stored data with the specified configuration.
   
   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Ensure we have an identifier
    guard let identifier = config.identifier else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing identifier for secure retrieval operation"
      )
    }
    
    // We'll use the key manager to retrieve the data
    let retrieveResult = await keyManagerImpl.retrieveKey(withIdentifier: identifier)
    
    // Process result
    switch retrieveResult {
    case .success(let data):
      return SecurityResultDTO(
        status: .success,
        identifier: identifier,
        data: data,
        metadata: [
          "operation": "secureRetrieve",
          "timestamp": "\(Date().timeIntervalSince1970)"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Deletes securely stored data with the specified configuration.
   
   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Ensure we have an identifier
    guard let identifier = config.identifier else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing identifier for secure deletion operation"
      )
    }
    
    // We'll use the key manager to delete the data
    let deleteResult = await keyManagerImpl.deleteKey(withIdentifier: identifier)
    
    // Process result
    switch deleteResult {
    case .success:
      return SecurityResultDTO(
        status: .success,
        identifier: identifier,
        metadata: [
          "operation": "secureDelete",
          "timestamp": "\(Date().timeIntervalSince1970)"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Creates a digital signature for data with the specified configuration.
   
   - Parameter config: Configuration for the digital signature operation
   - Returns: Result containing signature data or error
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters
    guard let data = config.data else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing data for signing operation"
      )
    }
    
    guard let key = try await getKeyForOperation(config: config, operation: .sign(data: data, key: nil)) else {
      throw SecurityErrorDomain.invalidKey(
        reason: "Could not retrieve key for signing operation"
      )
    }
    
    // This is a placeholder implementation since we don't have direct access to a signing function
    // In a real implementation, you would call the appropriate signing service
    // For now, we'll use the hash function as a simplistic stand-in
    let hashResult = await cryptoServiceImpl.hash(data: data)
    
    // Process result
    switch hashResult {
    case .success(let signatureData):
      return SecurityResultDTO(
        status: .success,
        data: signatureData,
        metadata: [
          "algorithm": config.algorithm,
          "operationType": "sign",
          "note": "This is a placeholder implementation using hashing"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Verifies a digital signature with the specified configuration.
   
   - Parameter config: Configuration for the signature verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract necessary parameters
    guard let data = config.data else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing data for verification operation"
      )
    }
    
    guard let signatureStr = config.options?["signature"], let signature = Data(base64Encoded: signatureStr) else {
      throw SecurityErrorDomain.invalidInput(
        reason: "Missing signature for verification operation"
      )
    }
    
    let secureSignature = SecureBytes(data: signature)
    
    guard let key = try await getKeyForOperation(config: config, operation: .verify(data: data, signature: secureSignature, key: nil)) else {
      throw SecurityErrorDomain.invalidKey(
        reason: "Could not retrieve key for verification operation"
      )
    }
    
    // This is a placeholder implementation since we don't have direct access to a verification function
    // In a real implementation, you would call the appropriate verification service
    // For now, we'll create a simplistic comparison 
    let hashResult = await cryptoServiceImpl.hash(data: data)
    
    // Process result
    switch hashResult {
    case .success(let computedHash):
      // Simple verification by comparing the provided signature with the computed hash
      let verified = computedHash.count == secureSignature.count && 
                     computedHash.withUnsafeBytes { hashPtr in
                       secureSignature.withUnsafeBytes { sigPtr in
                         memcmp(hashPtr.baseAddress, sigPtr.baseAddress, computedHash.count) == 0
                       }
                     }
      
      return SecurityResultDTO(
        status: .success,
        metadata: [
          "algorithm": config.algorithm,
          "operationType": "verify",
          "verified": "\(verified)",
          "note": "This is a placeholder implementation using hashing comparison"
        ]
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Performs a generic secure operation with appropriate error handling.
   
   - Parameters:
     - operation: The security operation to perform
     - config: Configuration options
   - Returns: Result of the operation
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
    case .generateKey:
      return try await generateKey(config: config)
    case .sign:
      return try await sign(config: config)
    case .verify:
      return try await verify(config: config)
    case .store:
      return try await secureStore(config: config)
    case .retrieve:
      return try await secureRetrieve(config: config)
    case .delete:
      return try await secureDelete(config: config)
    case .deriveKey, .custom:
      throw SecurityErrorDomain.unsupportedOperation(
        name: "Operation \(operation) not supported in this implementation"
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
    // Create a basic configuration based on the options
    var config = SecurityConfigDTO(
      algorithm: options.algorithm,
      keySize: options.keySize,
      mode: options.mode,
      hashAlgorithm: options.hashAlgorithm,
      providerType: options.providerType
    )
    
    // Set additional properties from options
    config.data = options.data
    config.key = options.key
    config.identifier = options.identifier
    
    // Convert any additional options to a dictionary
    var optionsDict: [String: String] = [:]
    if let additionalOptions = options.additionalOptions {
      for (key, value) in additionalOptions where value is CustomStringConvertible {
        optionsDict[key] = (value as? CustomStringConvertible)?.description
      }
    }
    
    // Set the options dictionary
    config.options = optionsDict
    
    return config
  }
  
  // MARK: - Helper Methods
  
  /**
   Retrieves a key for the specified operation.
   
   - Parameters:
     - config: The security configuration
     - operation: The operation being performed
   - Returns: The key to use for the operation
   - Throws: A security error if the key cannot be retrieved
   */
  private func getKeyForOperation(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async throws -> SecureBytes? {
    // If a key is provided directly in the config, use it
    if let keyData = config.key {
      return keyData
    }
    
    // If a key ID is provided, retrieve the key
    if let keyID = config.identifier {
      let result = await keyManagerImpl.retrieveKey(withIdentifier: keyID)
      switch result {
      case .success(let key):
        return key
      case .failure(let error):
        throw error
      }
    }
    
    // No key found
    return nil
  }
  
  /**
   Generates random bytes for cryptographic operations.
   
   - Parameter length: The number of bytes to generate
   - Returns: The generated random data
   - Throws: A security error if random generation fails
   */
  private func generateRandomBytes(length: Int) async throws -> SecureBytes {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    
    guard status == errSecSuccess else {
      throw SecurityErrorDomain.operationFailed(
        reason: "Failed to generate random bytes: \(status)"
      )
    }
    
    return SecureBytes(bytes: bytes)
  }
}
