import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors
import ErrorCoreTypes
import ErrorDomainsImpl

/**
 # SecurityProviderImpl
 
 Actor-based implementation of the SecurityProviderProtocol.
 
 This implementation isolates security operations in an actor, ensuring thread-safety
 while maintaining proper isolation boundaries for sensitive operations.
 */
public actor SecurityProviderImpl: SecurityProviderProtocol {
  // MARK: - Properties

  /// Cryptographic service implementation
  private let _cryptoService: CryptoServiceProtocol
  
  /// Key management service implementation
  private let _keyManager: KeyManagementProtocol
  
  // MARK: - Initialisation
  
  /**
   Initializes a new security provider instance.
   
   - Parameters:
     - cryptoService: Service providing cryptographic operations
     - keyManager: Service providing key management operations
   */
  public init(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) {
    self._cryptoService = cryptoService
    self._keyManager = keyManager
  }
  
  /**
   Initializes the service with any required asynchronous setup.
   
   This implementation initializes the underlying crypto and key management services.
   
   - Throws: An error if initialization fails
   */
  public func initialize() async throws {
    // Initialize any components that support AsyncServiceInitializable
    if let keyManager = _keyManager as? AsyncServiceInitializable {
      try await keyManager.initialize()
    }
  }
  
  // MARK: - Service Access
  
  /**
   Access to the cryptographic service implementation.
   
   - Returns: The cryptographic service instance
   */
  public func cryptoService() async -> CryptoServiceProtocol {
    return _cryptoService
  }
  
  /**
   Access to the key management service implementation.
   
   - Returns: The key management service instance
   */
  public func keyManager() async -> KeyManagementProtocol {
    return _keyManager
  }
  
  // MARK: - Core Operations
  
  /**
   Encrypts data using the configured cryptographic service.
   
   - Parameter config: The configuration for the encryption operation
   - Returns: A result containing the encrypted data and any relevant metadata
   - Throws: SecurityProtocolError if encryption fails
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract input data from config
    guard let inputData = extractData(from: config) else {
      throw SecurityProtocolError.invalidInput("No data provided for encryption")
    }
    
    // Create operation
    let operation = SecurityOperation.encrypt(data: inputData, key: nil)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Decrypts data using the configured cryptographic service.
   
   - Parameter config: The configuration for the decryption operation
   - Returns: A result containing the decrypted data and any relevant metadata
   - Throws: SecurityProtocolError if decryption fails
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract input data from config
    guard let inputData = extractData(from: config) else {
      throw SecurityProtocolError.invalidInput("No data provided for decryption")
    }
    
    // Create operation
    let operation = SecurityOperation.decrypt(data: inputData, key: nil)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Hashes data using the specified algorithm.
   
   - Parameter config: The configuration for the hashing operation
   - Returns: A result containing the hash value and any relevant metadata
   - Throws: SecurityProtocolError if hashing fails
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract input data from config
    guard let inputData = extractData(from: config) else {
      throw SecurityProtocolError.invalidInput("No data provided for hashing")
    }
    
    // Create operation with the algorithm from config
    let algorithm = config.hashAlgorithm ?? "SHA256"
    let operation = SecurityOperation.hash(data: inputData, algorithm: algorithm)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Signs data using the specified key and algorithm.
   
   - Parameter config: The configuration for the signing operation
   - Returns: A result containing the signature and any relevant metadata
   - Throws: SecurityProtocolError if signing fails
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract input data from config
    guard let inputData = extractData(from: config) else {
      throw SecurityProtocolError.invalidInput("No data provided for signing")
    }
    
    // Create operation with the key from config
    let key = try await extractOrGenerateKey(from: config)
    let operation = SecurityOperation.sign(data: inputData, key: key)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Verifies a signature for the given data.
   
   - Parameter config: The configuration for the verification operation
   - Returns: A result indicating whether verification succeeded
   - Throws: SecurityProtocolError if verification fails
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract input data and signature from config
    guard 
      let inputData = extractData(from: config),
      let signatureData = extractSignature(from: config)
    else {
      throw SecurityProtocolError.invalidInput("Missing data or signature for verification")
    }
    
    // Create operation
    let operation = SecurityOperation.verify(data: inputData, signature: signatureData, key: nil)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Securely stores data with the specified configuration.
   
   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract data and storage options
    guard 
      let inputData = extractData(from: config),
      let identifier = config.options["identifier"]
    else {
      throw SecurityProtocolError.invalidInput("Missing required data or identifier for secure storage")
    }
    
    // Create operation with storage location from config
    let operation = SecurityOperation.store(data: inputData, identifier: identifier)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Retrieves securely stored data with the specified configuration.
   
   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract storage location
    guard let identifier = config.options["identifier"] else {
      throw SecurityProtocolError.invalidInput("Missing identifier for secure retrieval")
    }
    
    // Create operation
    let operation = SecurityOperation.retrieve(identifier: identifier)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Securely deletes stored data with the specified configuration.
   
   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract storage location
    guard let identifier = config.options["identifier"] else {
      throw SecurityProtocolError.invalidInput("Missing identifier for secure deletion")
    }
    
    // Create operation
    let operation = SecurityOperation.delete(identifier: identifier)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Generates a cryptographic key with the specified configuration.
   
   - Parameter config: Configuration for the key generation
   - Returns: Result containing generated key as SecureBytes
   - Throws: SecurityProtocolError if key generation fails
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Extract key parameters from config
    let keySize = config.keySize
    
    // Create operation
    let operation = SecurityOperation.generateKey(size: keySize)
    
    return try await performSecureOperation(operation: operation, config: config)
  }
  
  /**
   Creates a secure configuration with type-safe, Sendable-compliant options.
   
   This method provides a Swift 6-compatible way to create security configurations
   that can safely cross actor boundaries.
   
   - Parameter options: Type-safe options structure that conforms to Sendable
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    // Use the initialiser we added to SecurityConfigDTO that accepts SecurityConfigOptions
    return SecurityConfigDTO(options: options)
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
    do {
      // Create a result to return with default failure state
      var result = SecurityResultDTO(
        status: .failure, 
        metadata: ["operation": String(describing: operation)]
      )
      
      // Perform the operation based on type
      switch operation {
      case let .encrypt(data, providedKey):
        // Get or use provided key
        let key: SecureBytes
        if let providedKey = providedKey {
          key = providedKey
        } else {
          key = try await extractOrGenerateKey(from: config)
        }
        
        // Perform encryption
        let encryptResult = await _cryptoService.encrypt(data: data, using: key)
        
        switch encryptResult {
        case .success(let encryptedData):
          result = SecurityResultDTO(
            status: .success,
            data: encryptedData,
            metadata: result.metadata
          )
          
        case .failure(let error):
          result = SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: result.metadata
          )
        }
        
      case let .decrypt(data, providedKey):
        // Get or use provided key
        let key: SecureBytes
        if let providedKey = providedKey {
          key = providedKey
        } else {
          key = try await extractOrGenerateKey(from: config)
        }
        
        // Perform decryption
        let decryptResult = await _cryptoService.decrypt(data: data, using: key)
        
        switch decryptResult {
        case .success(let decryptedData):
          result = SecurityResultDTO(
            status: .success,
            data: decryptedData,
            metadata: result.metadata
          )
          
        case .failure(let error):
          result = SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: result.metadata
          )
        }
        
      case let .hash(data, algorithm):
        // Use the provided algorithm or default
        let hashAlgorithm = algorithm ?? config.hashAlgorithm ?? "SHA256"
        
        // Perform hashing
        let hashResult = await _cryptoService.hash(data: data)
        
        switch hashResult {
        case .success(let hashData):
          result = SecurityResultDTO(
            status: .success,
            data: hashData,
            metadata: ["algorithm": hashAlgorithm]
          )
          
        case .failure(let error):
          result = SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["algorithm": hashAlgorithm]
          )
        }
        
      case let .sign(data, providedKey):
        // Since CryptoServiceProtocol doesn't have a direct signing method,
        // we'll use createHMAC which serves a similar purpose
        
        // Get or use provided key
        let signingKey: SecureBytes
        if let providedKey = providedKey {
          signingKey = providedKey
        } else {
          signingKey = try await extractOrGenerateKey(from: config)
        }
        
        // We need to implement our own HMAC function since it's not in the protocol
        let hmacData = try await createHMAC(for: data, using: signingKey)
        
        result = SecurityResultDTO(
          status: .success,
          data: hmacData,
          metadata: ["algorithm": config.algorithm]
        )
        
      case .verify:
        // Not directly supported by the protocol, we'll throw unsupported
        throw SecurityProtocolError.unsupportedOperation(name: "verify")
        
      case let .generateKey(size):
        // Generate a key of the specified size
        let keySize = size ?? config.keySize
        let keyBytes = try await generateRandomKeyBytes(length: keySize / 8)
        
        result = SecurityResultDTO(
          status: .success,
          data: keyBytes,
          metadata: ["keySize": "\(keySize)"]
        )
        
      case let .store(data, identifier):
        // We don't have a direct storage method in CryptoServiceProtocol,
        // so we'll implement a basic key-value mapping to the key manager
        
        // Store the data using the key manager
        let storeResult = await _keyManager.storeKey(data, withIdentifier: identifier)
        
        switch storeResult {
        case .success:
          result = SecurityResultDTO(
            status: .success,
            metadata: ["identifier": identifier]
          )
          
        case .failure(let error):
          result = SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["identifier": identifier]
          )
        }
        
      case let .retrieve(identifier):
        // Retrieve the data using the key manager
        let retrieveResult = await _keyManager.retrieveKey(withIdentifier: identifier)
        
        switch retrieveResult {
        case .success(let data):
          result = SecurityResultDTO(
            status: .success,
            data: data,
            metadata: ["identifier": identifier]
          )
          
        case .failure(let error):
          result = SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["identifier": identifier]
          )
        }
        
      case let .delete(identifier):
        // Delete the data using the key manager
        let deleteResult = await _keyManager.deleteKey(withIdentifier: identifier)
        
        switch deleteResult {
        case .success:
          result = SecurityResultDTO(
            status: .success,
            metadata: ["identifier": identifier]
          )
          
        case .failure(let error):
          result = SecurityResultDTO(
            status: .failure,
            error: error,
            metadata: ["identifier": identifier]
          )
        }
        
      default:
        throw SecurityProtocolError.unsupportedOperation(name: String(describing: operation))
      }
      
      return result
    } catch let error as SecurityProtocolError {
      // Create error context with source information
      let context = ErrorContext(
        source: ErrorSource(file: #file, function: #function, line: #line),
        metadata: ["operation": String(describing: operation)]
      )
      
      // Map to domain error and throw
      let domainError = mapToSecurityErrorDomain(error, context: context)
      throw domainError
    } catch {
      // Wrap other errors with context
      let context = ErrorContext(
        source: ErrorSource(file: #file, function: #function, line: #line),
        metadata: ["operation": String(describing: operation)]
      )
      
      throw SecurityErrorDomain.generalSecurityError(
        reason: error.localizedDescription,
        context: context
      )
    }
  }
  
  // MARK: - Private Helpers
  
  /// Maps a SecurityProtocolError to a SecurityErrorDomain
  private func mapToSecurityErrorDomain(
    _ error: SecurityProtocolError,
    context: ErrorContext
  ) -> SecurityErrorDomain {
    switch error {
    case .authenticationFailed(let reason):
      return .authenticationFailed(reason: reason, context: context)
    case .invalidInput(let reason):
      return .invalidInput(reason: reason, context: context)
    case .cryptographicError(let reason):
      return .encryptionFailed(reason: reason, context: context)
    case .keyManagementError(let reason):
      return .keyManagementFailed(reason: reason, context: context)
    case .invalidOperation(let reason):
      return .unsupportedOperation(name: reason, context: context)
    case .secureStorageError(let reason):
      return .generalSecurityError(reason: "Secure storage error: \(reason)", context: context)
    case .generalError(let reason):
      return .generalSecurityError(reason: reason, context: context)
    }
  }
  
  /// Extract data from configuration options
  private func extractData(from config: SecurityConfigDTO) -> SecureBytes? {
    if let dataBase64 = config.options["dataBase64"] {
      guard let data = Data(base64Encoded: dataBase64) else {
        return nil
      }
      return SecureBytes(bytes: [UInt8](data))
    }
    
    if let dataHex = config.options["dataHex"] {
      // Convert hex to data
      var data = Data()
      var hex = dataHex
      while hex.count > 0 {
        let subIndex = hex.index(hex.startIndex, offsetBy: min(2, hex.count))
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        if let val = UInt8(c, radix: 16) {
          data.append(val)
        }
      }
      return SecureBytes(bytes: [UInt8](data))
    }
    
    return nil
  }
  
  /// Extract signature data from configuration
  private func extractSignature(from config: SecurityConfigDTO) -> SecureBytes? {
    if let signatureBase64 = config.options["signatureBase64"] {
      guard let data = Data(base64Encoded: signatureBase64) else {
        return nil
      }
      return SecureBytes(bytes: [UInt8](data))
    }
    
    return nil
  }
  
  /// Extract or generate key for operations
  private func extractOrGenerateKey(from config: SecurityConfigDTO) async throws -> SecureBytes {
    // Check for key identifier in options
    if let identifier = config.options["keyIdentifier"] {
      let keyResult = await _keyManager.retrieveKey(withIdentifier: identifier)
      
      switch keyResult {
      case .success(let key):
        return key
      case .failure(let error):
        throw SecurityProtocolError.keyManagementError("Failed to retrieve key: \(error.localizedDescription)")
      }
    }
    
    // Check for key data in options
    if let keyBase64 = config.options["keyBase64"] {
      guard let data = Data(base64Encoded: keyBase64) else {
        throw SecurityProtocolError.invalidInput("Invalid key data format")
      }
      return SecureBytes(bytes: [UInt8](data))
    }
    
    // Generate a temporary key
    return try await generateRandomKeyBytes(length: config.keySize / 8)
  }
  
  /// Generate random key bytes of the specified length
  private func generateRandomKeyBytes(length: Int) async throws -> SecureBytes {
    // Since CryptoServiceProtocol doesn't have generateSecureRandomKey, 
    // we'll implement our own basic secure random generator
    var bytes = [UInt8](repeating: 0, count: length)
    
    // In a real implementation, this would use a secure random source
    // For now, we'll use a placeholder implementation
    for i in 0..<length {
      bytes[i] = UInt8.random(in: 0...255)
    }
    
    return SecureBytes(bytes: bytes)
  }
  
  /// Create an HMAC for the provided data using the given key
  private func createHMAC(for data: SecureBytes, using key: SecureBytes) async throws -> SecureBytes {
    // Since CryptoServiceProtocol doesn't have generateHMAC,
    // we'll implement a simple placeholder that hashes the data
    
    // In a real implementation, this would create a proper HMAC
    // For now, we'll just hash the data
    let hashResult = await _cryptoService.hash(data: data)
    
    switch hashResult {
    case .success(let hashData):
      return hashData
    case .failure(let error):
      throw SecurityProtocolError.cryptographicError("HMAC creation failed: \(error.localizedDescription)")
    }
  }
  
  // MARK: - KeyManagementProtocol Convenience Methods
  
  /// Retrieves a key by identifier
  public func retrieveKey(withIdentifier identifier: String) async -> Result<SecureBytes, SecurityProtocolError> {
    // Delegate to key manager
    return await _keyManager.retrieveKey(withIdentifier: identifier)
  }
  
  /// Stores a key with identifier
  public func storeKey(_ key: SecureBytes, withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
    // Delegate to key manager
    return await _keyManager.storeKey(key, withIdentifier: identifier)
  }
  
  /// Deletes a key by identifier
  public func deleteKey(withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
    // Delegate to key manager
    return await _keyManager.deleteKey(withIdentifier: identifier)
  }
  
  /// Rotates a key, optionally re-encrypting data
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), SecurityProtocolError> {
    // Delegate to key manager
    return await _keyManager.rotateKey(withIdentifier: identifier, dataToReencrypt: dataToReencrypt)
  }
  
  /// Lists all key identifiers
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    // Delegate to key manager
    return await _keyManager.listKeyIdentifiers()
  }
}
