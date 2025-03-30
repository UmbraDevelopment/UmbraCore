import ErrorCoreTypes
import ErrorDomainsImpl
import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # ApplicationSecurityProviderService
 
 Actor-based implementation of the ApplicationSecurityProviderProtocol.
 
 This implementation isolates security operations in an actor, ensuring thread-safety
 while maintaining proper isolation boundaries for sensitive operations at the application level.
 */
public actor ApplicationSecurityProviderService: ApplicationSecurityProviderProtocol {
  // MARK: - Properties
  
  /// Cryptographic service implementation
  private let _cryptoService: ApplicationCryptoServiceProtocol
  
  /// Key management service implementation
  private let _keyManager: KeyManagementProtocol
  
  // MARK: - Initialisation
  
  /**
   Initialises a new application security provider instance.
   
   - Parameters:
     - cryptoService: Service providing cryptographic operations
     - keyManager: Service providing key management operations
   */
  public init(
    cryptoService: ApplicationCryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) {
    _cryptoService = cryptoService
    _keyManager = keyManager
  }
  
  /**
   Initialises the service with any required asynchronous setup.
   
   This implementation initialises the underlying crypto and key management services.
   
   - Throws: An error if initialisation fails
   */
  public func initialize() async throws {
    // Initialize any components that support AsyncServiceInitializable
    if let initialisable = _cryptoService as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }
    
    if let initialisable = _keyManager as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }
  }
  
  // MARK: - ApplicationSecurityProviderProtocol
  
  /// Access to the cryptographic service implementation
  public var cryptoService: any ApplicationCryptoServiceProtocol {
    return _cryptoService
  }
  
  /// Access to the key management service implementation
  public var keyManager: any KeyManagementProtocol {
    return _keyManager
  }
  
  /// Access to the secure storage service implementation
  public var secureStorage: any SecureStorageProtocol {
    return _cryptoService as! SecureStorageProtocol
  }
  
  /**
   Encrypts data using the specified configuration.
   
   - Parameters:
     - data: The data to encrypt
     - config: Configuration for the encryption operation
   - Returns: Result containing the encrypted data or an error
   */
  public func encrypt(data: Data, with config: EncryptionConfig) async throws -> EncryptionResult {
    return try await withSecurityOperation(.encrypt) { [self] in
      let result = try await _cryptoService.encrypt(
        data: data,
        using: KeyIdentifier(config.keyID),
        algorithm: config.algorithm
      )
      
      return EncryptionResult(
        encryptedData: result,
        metadata: ["algorithm": config.algorithm.description]
      )
    }
  }
  
  /**
   Decrypts data using the specified configuration.
   
   - Parameters:
     - data: The encrypted data to decrypt
     - config: Configuration for the decryption operation
   - Returns: Result containing the decrypted data or an error
   */
  public func decrypt(data: Data, with config: EncryptionConfig) async throws -> DecryptionResult {
    return try await withSecurityOperation(.decrypt) { [self] in
      let result = try await _cryptoService.decrypt(
        data: data,
        using: KeyIdentifier(config.keyID),
        algorithm: config.algorithm
      )
      
      return DecryptionResult(
        decryptedData: result,
        metadata: ["algorithm": config.algorithm.description]
      )
    }
  }
  
  /**
   Generates a cryptographic key with the specified parameters.
   
   - Parameter config: Configuration for the key generation
   - Returns: Result containing the generated key identifier
   */
  public func generateKey(with config: KeyGenerationConfig) async throws -> KeyGenerationResult {
    return try await withSecurityOperation(.generateKey) { [self] in
      let key = try await _keyManager.generateKey(
        type: config.keyType,
        size: config.keySize,
        metadata: config.metadata ?? [:]
      )
      
      return KeyGenerationResult(
        keyID: key.identifier,
        keyType: config.keyType.rawValue,
        metadata: ["keySize": String(config.keySize)]
      )
    }
  }
  
  /**
   Computes a cryptographic hash of the input data.
   
   - Parameters:
     - data: The data to hash
     - algorithm: The hashing algorithm to use
   - Returns: The computed hash value
   */
  public func hash(data: Data, using algorithm: HashAlgorithm) async throws -> HashResult {
    return try await withSecurityOperation(.hash) { [self] in
      let result = try await _cryptoService.hash(
        data: data,
        using: algorithm
      )
      
      return HashResult(
        hashedData: result,
        algorithm: algorithm.rawValue
      )
    }
  }
  
  /**
   Signs data with the specified key.
   
   - Parameters:
     - data: The data to sign
     - keyID: Identifier of the key to use for signing
     - algorithm: The signing algorithm to use
   - Returns: The digital signature
   */
  public func sign(data: Data, with keyID: String, using algorithm: SignatureAlgorithm) async throws -> SignatureResult {
    return try await withSecurityOperation(.sign) { [self] in
      let signature = try await _cryptoService.sign(
        data: data,
        using: KeyIdentifier(keyID),
        algorithm: algorithm
      )
      
      return SignatureResult(
        signature: signature,
        algorithm: algorithm.rawValue,
        keyID: keyID
      )
    }
  }
  
  /**
   Verifies a digital signature.
   
   - Parameters:
     - signature: The signature to verify
     - data: The original data that was signed
     - keyID: Identifier of the key to use for verification
     - algorithm: The signing algorithm used
   - Returns: True if the signature is valid, false otherwise
   */
  public func verify(signature: Data, for data: Data, with keyID: String, using algorithm: SignatureAlgorithm) async throws -> Bool {
    return try await withSecurityOperation(.verify) { [self] in
      try await _cryptoService.verify(
        signature: signature,
        for: data,
        using: KeyIdentifier(keyID),
        algorithm: algorithm
      )
    }
  }
  
  /**
   Stores data securely.
   
   - Parameters:
     - data: The data to store
     - identifier: A unique identifier for later retrieval
     - options: Storage options and metadata
   */
  public func storeSecurely(data: Data, withIdentifier identifier: String, options: SecureStorageOptions) async throws {
    try await withSecurityOperation(.store) { [self] in
      try await secureStorage.store(
        data: data,
        withIdentifier: identifier,
        options: options
      )
    }
  }
  
  /**
   Retrieves securely stored data.
   
   - Parameter identifier: The identifier used when storing the data
   - Returns: The retrieved data
   */
  public func retrieveSecureData(withIdentifier identifier: String) async throws -> Data {
    return try await withSecurityOperation(.retrieve) { [self] in
      try await secureStorage.retrieve(withIdentifier: identifier)
    }
  }
  
  /**
   Deletes securely stored data.
   
   - Parameter identifier: The identifier of the data to delete
   */
  public func deleteSecureData(withIdentifier identifier: String) async throws {
    try await withSecurityOperation(.delete) { [self] in
      try await secureStorage.delete(withIdentifier: identifier)
    }
  }
  
  /**
   Validates the security configuration of the system.
   
   - Returns: A validation result indicating the security status
   */
  public func validateSecurityConfiguration() async throws -> SecurityValidationResult {
    let result = SecurityValidationResult(
      status: .valid,
      details: [
        "cryptoService": "available",
        "keyManager": "available", 
        "secureStorage": "available"
      ]
    )
    
    return result
  }
  
  // MARK: - Private Methods
  
  /**
   Executes a security operation with standard error handling and logging.
   
   - Parameters:
     - operation: The security operation being performed
     - body: The operation execution closure
   - Returns: The result of the operation
   - Throws: Security errors converted to appropriate domain errors
   */
  private func withSecurityOperation<T>(_ operation: SecurityOperation, _ body: () async throws -> T) async throws -> T {
    do {
      return try await body()
    } catch let error as SecurityProtocolError {
      // Create error context with source information
      let context = ErrorContext(
        source: ErrorSource(file: #file, function: #function, line: #line),
        metadata: ["operation": String(describing: operation)]
      )
      
      throw SecurityErrorDomain.mapError(error, context: context)
    } catch {
      // Create error context with source information
      let context = ErrorContext(
        source: ErrorSource(file: #file, function: #function, line: #line),
        metadata: ["operation": String(describing: operation), 
                   "error": error.localizedDescription]
      )
      
      throw SecurityErrorDomain.unexpectedError(context: context)
    }
  }
  
  /**
   Processes a complete security operation from start to finish.
   
   This method handles operation logging, execution, error handling, and result formatting.
   
   - Parameters:
     - operation: The security operation to execute
     - metadata: Additional operation metadata
     - body: The operation execution closure
   - Returns: Result containing operation data or error information
   */
  private func processSecurityOperation<T, R>(
    _ operation: SecurityOperationType,
    input: T,
    result: @escaping (R) -> SecurityResultDTO,
    body: (T) async throws -> R
  ) async throws -> SecurityResultDTO {
    do {
      // Create a result to return with default failure state
      var result = SecurityResultDTO(
        status: .failure,
        metadata: ["operation": String(describing: operation)]
      )
      
      // Execute the operation based on type
      switch operation {
        case let .encrypt(data, providedKey):
          // Get or use provided key
          let key: SecureBytes = if let providedKey {
            providedKey
          } else {
            // Use default key if none provided
            try await getDefaultKey(for: .encryption)
          }
          
          // Process encryption
          let encrypted = try await _cryptoService.encrypt(
            bytes: SecureBytes(data: data),
            key: key
          )
          
          // Set success result
          result.status = .success
          result.data = encrypted.data
          result.metadata["keyType"] = "encryption"
          
        case let .decrypt(data, providedKey):
          // Get or use provided key
          let key: SecureBytes = if let providedKey {
            providedKey
          } else {
            // Use default key if none provided
            try await getDefaultKey(for: .encryption)
          }
          
          // Process decryption
          let decrypted = try await _cryptoService.decrypt(
            bytes: SecureBytes(data: data),
            key: key
          )
          
          // Set success result
          result.status = .success
          result.data = decrypted.data
          result.metadata["keyType"] = "encryption"
          
        case let .sign(data, providedKey):
          // Get or use provided key
          let key: SecureBytes = if let providedKey {
            providedKey
          } else {
            // Use default key if none provided
            try await getDefaultKey(for: .signing)
          }
          
          // Process signing
          let signature = try await _cryptoService.sign(
            bytes: SecureBytes(data: data),
            key: key
          )
          
          // Set success result
          result.status = .success
          result.data = signature.data
          result.metadata["keyType"] = "signing"
          
        case let .verify(data, signature, providedKey):
          // Get or use provided key
          let key: SecureBytes = if let providedKey {
            providedKey
          } else {
            // Use default key if none provided
            try await getDefaultKey(for: .signing)
          }
          
          // Process verification
          let verified = try await _cryptoService.verify(
            signature: SecureBytes(data: signature),
            data: SecureBytes(data: data),
            key: key
          )
          
          // Set success result
          result.status = .success
          result.metadata["verified"] = String(verified)
          result.metadata["keyType"] = "signing"
          
        case let .store(data, identifier):
          // Store data securely
          try await _keyManager.storeKey(
            SecureBytes(data: data),
            withIdentifier: identifier
          )
          
          // Set success result
          result.status = .success
          result.metadata["identifier"] = identifier
          
        case let .retrieve(identifier):
          // Retrieve the data using the key manager
          let retrieveResult = await _keyManager.retrieveKey(withIdentifier: identifier)
          
          switch retrieveResult {
            case let .success(key):
              // Set success result
              result.status = .success
              result.data = key.data
              result.metadata["identifier"] = identifier
              
            case let .failure(error):
              // Set failure result
              result.status = .failure
              result.error = error.localizedDescription
              result.metadata["identifier"] = identifier
          }
          
        case let .delete(identifier):
          // Delete data securely
          try await _keyManager.deleteKey(withIdentifier: identifier)
          
          // Set success result
          result.status = .success
          result.metadata["identifier"] = identifier
          
        case let .generateKey(type, size):
          // Generate key with specified parameters
          let generateResult = try await _keyManager.generateKey(
            type: type,
            size: size,
            metadata: [:]
          )
          
          // Set success result
          result.status = .success
          result.data = Data(generateResult.identifier.utf8)
          result.metadata["keyType"] = type.rawValue
          result.metadata["keySize"] = String(size)
      }
      
      return result
    } catch let error as SecurityProtocolError {
      // Create error context with source information
      let context = ErrorContext(
        source: ErrorSource(file: #file, function: #function, line: #line),
        metadata: ["operation": String(describing: operation)]
      )
      
      let convertedError = SecurityErrorDomain.mapError(error, context: context)
      
      // Return a failure result
      return SecurityResultDTO(
        status: .failure,
        error: convertedError.localizedDescription,
        metadata: ["operation": String(describing: operation)]
      )
    } catch {
      // Create error context with source information
      let context = ErrorContext(
        source: ErrorSource(file: #file, function: #function, line: #line),
        metadata: ["operation": String(describing: operation), 
                   "error": error.localizedDescription]
      )
      
      let wrappedError = SecurityErrorDomain.unexpectedError(context: context)
      
      // Return a failure result
      return SecurityResultDTO(
        status: .failure,
        error: wrappedError.localizedDescription,
        metadata: ["operation": String(describing: operation)]
      )
    }
  }
  
  /**
   Gets a default key for the specified operation type.
   
   - Parameter operationType: The operation requiring a key
   - Returns: A secure bytes representation of the key
   - Throws: SecurityProtocolError if the key isn't found
   */
  private func getDefaultKey(for operationType: KeyType) async throws -> SecureBytes {
    let keyResult = await _keyManager.retrieveKey(withIdentifier: "default.\(operationType.rawValue)")
    
    switch keyResult {
      case let .success(key):
        return key
        
      case .failure:
        // Generate a new default key if one doesn't exist
        let newKey = try await _keyManager.generateKey(
          type: operationType,
          size: operationType == .encryption ? 256 : 2048,
          metadata: ["purpose": "default"]
        )
        
        let retrieveResult = await _keyManager.retrieveKey(withIdentifier: newKey.identifier)
        
        guard case let .success(key) = retrieveResult else {
          throw SecurityProtocolError.keyNotFound("Could not create default key")
        }
        
        return key
    }
  }
}
