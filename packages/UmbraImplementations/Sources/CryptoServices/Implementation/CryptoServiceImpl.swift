import CommonCrypto
import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/**
 Default implementation of the CryptoServiceProtocol.
 
 This implementation follows the Alpha Dot Five architecture by:
 1. Using SecureStorage for all sensitive cryptographic material
 2. Providing actor-based concurrency for thread safety
 3. Following privacy-by-design principles
 4. Properly handling errors using Result types
 */
public actor CryptoServiceImpl: CryptoServiceProtocol {
  /// Configuration options for this service instance
  private let options: CryptoServiceOptions
  
  /// The secure storage used for handling sensitive data
  public let secureStorage: SecureStorageProtocol
  
  /// The key size for AES-256 keys in bytes
  private let aes256KeySize = 32
  
  /// Create a new crypto service instance
  /// - Parameters:
  ///   - options: Optional configuration options
  ///   - secureStorage: The secure storage to use (creates a new one if not provided)
  public init(options: CryptoServiceOptions = CryptoServiceOptions(), secureStorage: SecureStorageProtocol? = nil) {
    self.options = options
    self.secureStorage = secureStorage ?? SecureStorage()
  }
  
  /// Encrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
  ///   - keyIdentifier: Identifier of the encryption key in secure storage.
  ///   - options: Optional encryption configuration.
  /// - Returns: Identifier for the encrypted data in secure storage, or an error.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Retrieve data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    
    // Check for errors in retrieving data or key
    switch (dataResult, keyResult) {
    case (.failure(let error), _):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case (_, .failure(let error)):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case (.success(let dataBytes), .success(let keyBytes)):
      // Use encryption options or defaults
      let encryptionOptions = options ?? EncryptionOptions()
      
      // Generate IV for encryption algorithms that require it
      let ivBytes: [UInt8]
      switch encryptionOptions.algorithm {
      case .aes256CBC, .aes256GCM:
        // Generate a random IV
        do {
          ivBytes = try generateRandomBytes(count: 16)
        } catch {
          return .failure(.cryptoOperationFailed(underlyingError: error))
        }
      case .chaCha20Poly1305:
        // Generate a random nonce (12 bytes for ChaCha20Poly1305)
        do {
          ivBytes = try generateRandomBytes(count: 12)
        } catch {
          return .failure(.cryptoOperationFailed(underlyingError: error))
        }
      }
      
      // Perform the encryption based on the algorithm
      do {
        let encryptedBytes: [UInt8]
        
        switch encryptionOptions.algorithm {
        case .aes256CBC:
          encryptedBytes = try encryptAES_CBC(
            data: dataBytes,
            key: keyBytes,
            iv: ivBytes
          )
        case .aes256GCM:
          // Include authenticated data if provided
          let aad = encryptionOptions.authenticatedData
          
          // For a real implementation, this would be implemented with a proper AEAD algorithm
          // This is just a placeholder for now
          encryptedBytes = dataBytes
        case .chaCha20Poly1305:
          // Include authenticated data if provided
          let aad = encryptionOptions.authenticatedData
          
          // For a real implementation, this would be implemented with a proper AEAD algorithm
          // This is just a placeholder for now
          encryptedBytes = dataBytes
        }
        
        // Create a full package that includes the IV with the encrypted data
        // Format: [algorithm (1 byte)][iv length (1 byte)][iv (variable)][encrypted data]
        var resultBytes = [UInt8]()
        resultBytes.append(encryptionOptions.algorithm.rawValue)
        resultBytes.append(UInt8(ivBytes.count))
        resultBytes.append(contentsOf: ivBytes)
        resultBytes.append(contentsOf: encryptedBytes)
        
        // Store in secure storage and return the identifier
        let outputIdentifier = generateRandomIdentifier()
        let storeResult = await secureStorage.storeData(resultBytes, withIdentifier: outputIdentifier)
        
        switch storeResult {
        case .success:
          return .success(outputIdentifier)
        case .failure(let error):
          return .failure(.cryptoOperationFailed(underlyingError: error))
        }
      } catch {
        return .failure(.cryptoOperationFailed(underlyingError: error))
      }
    }
  }
  
  /// Decrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
  ///   - keyIdentifier: Identifier of the decryption key in secure storage.
  ///   - options: Optional decryption configuration.
  /// - Returns: Identifier for the decrypted data in secure storage, or an error.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Retrieve data from secure storage
    let encryptedDataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    
    // Check for errors in retrieving data or key
    switch (encryptedDataResult, keyResult) {
    case (.failure(let error), _):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case (_, .failure(let error)):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case (.success(let encryptedPackage), .success(let keyBytes)):
      // Parse the encrypted package
      // Format: [algorithm (1 byte)][iv length (1 byte)][iv (variable)][encrypted data]
      guard encryptedPackage.count >= 2 else {
        return .failure(.invalidData)
      }
      
      let algorithmValue = encryptedPackage[0]
      let ivLength = Int(encryptedPackage[1])
      
      guard encryptedPackage.count >= 2 + ivLength else {
        return .failure(.invalidData)
      }
      
      let iv = Array(encryptedPackage[2..<(2 + ivLength)])
      let encryptedBytes = Array(encryptedPackage[(2 + ivLength)...])
      
      guard let algorithm = EncryptionAlgorithm(rawValue: algorithmValue) else {
        return .failure(.unsupportedAlgorithm)
      }
      
      // Use decryption options or defaults
      let decryptionOptions = options ?? DecryptionOptions(algorithm: algorithm)
      
      // Perform the decryption based on the algorithm
      do {
        let decryptedBytes: [UInt8]
        
        switch algorithm {
        case .aes256CBC:
          decryptedBytes = try decryptAES_CBC(
            data: encryptedBytes,
            key: keyBytes,
            iv: iv
          )
        case .aes256GCM:
          // Include authenticated data if provided
          let aad = decryptionOptions.authenticatedData
          
          // For a real implementation, this would be implemented with a proper AEAD algorithm
          // This is just a placeholder for now
          decryptedBytes = encryptedBytes
        case .chaCha20Poly1305:
          // Include authenticated data if provided
          let aad = decryptionOptions.authenticatedData
          
          // For a real implementation, this would be implemented with a proper AEAD algorithm
          // This is just a placeholder for now
          decryptedBytes = encryptedBytes
        }
        
        // Store the decrypted data in secure storage and return the identifier
        let outputIdentifier = generateRandomIdentifier()
        let storeResult = await secureStorage.storeData(decryptedBytes, withIdentifier: outputIdentifier)
        
        switch storeResult {
        case .success:
          return .success(outputIdentifier)
        case .failure(let error):
          return .failure(.cryptoOperationFailed(underlyingError: error))
        }
      } catch {
        return .failure(.cryptoOperationFailed(underlyingError: error))
      }
    }
  }
  
  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Retrieve data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
    case .failure(let error):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case .success(let dataBytes):
      // Use hashing options or defaults
      let hashingOptions = options ?? HashingOptions()
      
      do {
        // Compute the hash
        let hashedBytes = try computeHash(data: dataBytes, algorithm: hashingOptions.algorithm)
        
        // Store the hash in secure storage and return the identifier
        let outputIdentifier = generateRandomIdentifier()
        let storeResult = await secureStorage.storeData(hashedBytes, withIdentifier: outputIdentifier)
        
        switch storeResult {
        case .success:
          return .success(outputIdentifier)
        case .failure(let error):
          return .failure(.cryptoOperationFailed(underlyingError: error))
        }
      } catch {
        return .failure(.cryptoOperationFailed(underlyingError: error))
      }
    }
  }
  
  /// Verifies a cryptographic hash against the expected value, both stored securely.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    // Retrieve data and expected hash from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let expectedHashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
    
    // Check for errors in retrieving data or expected hash
    switch (dataResult, expectedHashResult) {
    case (.failure(let error), _):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case (_, .failure(let error)):
      return .failure(.cryptoOperationFailed(underlyingError: error))
    case (.success(let dataBytes), .success(let expectedHashBytes)):
      // Use hashing options or defaults
      let hashingOptions = options ?? HashingOptions()
      
      do {
        // Compute the hash of the data
        let computedHash = try computeHash(data: dataBytes, algorithm: hashingOptions.algorithm)
        
        // Compare the computed hash with the expected hash
        let hashesMatch = computedHash.count == expectedHashBytes.count && 
                          zip(computedHash, expectedHashBytes).allSatisfy { $0 == $1 }
        
        return .success(hashesMatch)
      } catch {
        return .failure(.cryptoOperationFailed(underlyingError: error))
      }
    }
  }
  
  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    do {
      // Generate random bytes for the key
      let keyBytes = try generateRandomBytes(count: length)
      
      // Store the key in secure storage and return the identifier
      let keyIdentifier = generateRandomIdentifier()
      let storeResult = await secureStorage.storeData(keyBytes, withIdentifier: keyIdentifier)
      
      switch storeResult {
      case .success:
        return .success(keyIdentifier)
      case .failure(let error):
        return .failure(.cryptoOperationFailed(underlyingError: error))
      }
    } catch {
      return .failure(.cryptoOperationFailed(underlyingError: error))
    }
  }
  
  /// Imports data into secure storage for use with cryptographic operations.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is generated.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    // Use the provided identifier or generate a random one
    let identifier = customIdentifier ?? generateRandomIdentifier()
    
    // Store the data in secure storage
    let storeResult = await secureStorage.storeData(data, withIdentifier: identifier)
    
    switch storeResult {
    case .success:
      return .success(identifier)
    case .failure(let error):
      return .failure(error)
    }
  }
  
  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  /// - Warning: Use with caution as this exposes sensitive data.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Retrieve the data from secure storage
    return await secureStorage.retrieveData(withIdentifier: identifier)
  }
  
  // MARK: - Private Helper Methods
  
  /// Generates random bytes for cryptographic operations
  /// - Parameter count: Number of random bytes to generate
  /// - Returns: Array of random bytes
  /// - Throws: CryptoServiceError if random generation fails
  private func generateRandomBytes(count: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    
    guard status == errSecSuccess else {
      throw SecurityProtocolError.randomGenerationFailed
    }
    
    return bytes
  }
  
  /// Generates a random identifier for secure storage
  /// - Returns: A random identifier string
  private func generateRandomIdentifier() -> String {
    return "crypto-\(UUID().uuidString.lowercased())"
  }
  
  /// Computes a hash of the data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Hash algorithm to use
  /// - Returns: Computed hash
  /// - Throws: CryptoServiceError if hashing fails
  private func computeHash(data: [UInt8], algorithm: HashAlgorithm) throws -> [UInt8] {
    // Implementation depends on algorithm
    switch algorithm {
    case .sha256:
      var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
      CC_SHA256(data, CC_LONG(data.count), &hash)
      return hash
    case .sha384:
      var hash = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
      CC_SHA384(data, CC_LONG(data.count), &hash)
      return hash
    case .sha512:
      var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
      CC_SHA512(data, CC_LONG(data.count), &hash)
      return hash
    default:
      throw SecurityProtocolError.unsupportedAlgorithm
    }
  }
  
  // MARK: - AES Encryption/Decryption Methods
  
  /// Encrypts data using AES-CBC
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - iv: Initialization vector
  /// - Returns: Encrypted data
  /// - Throws: CryptoServiceError if encryption fails
  private func encryptAES_CBC(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Implementation of AES-CBC encryption
    // This uses CommonCrypto
    var outLength = 0
    var dataOutAvailable = data.count + kCCBlockSizeAES128
    var dataOut = [UInt8](repeating: 0, count: dataOutAvailable)
    
    let status = CCCrypt(
      CCOperation(kCCEncrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      key.count,
      iv,
      data,
      data.count,
      &dataOut,
      dataOutAvailable,
      &outLength
    )
    
    guard status == kCCSuccess else {
      throw SecurityProtocolError.encryptionFailed
    }
    
    return Array(dataOut[0..<outLength])
  }
  
  /// Decrypts data using AES-CBC
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - iv: Initialization vector
  /// - Returns: Decrypted data
  /// - Throws: CryptoServiceError if decryption fails
  private func decryptAES_CBC(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Implementation of AES-CBC decryption
    // This uses CommonCrypto
    var outLength = 0
    var dataOutAvailable = data.count + kCCBlockSizeAES128
    var dataOut = [UInt8](repeating: 0, count: dataOutAvailable)
    
    let status = CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      key.count,
      iv,
      data,
      data.count,
      &dataOut,
      dataOutAvailable,
      &outLength
    )
    
    guard status == kCCSuccess else {
      throw SecurityProtocolError.decryptionFailed
    }
    
    return Array(dataOut[0..<outLength])
  }
}
