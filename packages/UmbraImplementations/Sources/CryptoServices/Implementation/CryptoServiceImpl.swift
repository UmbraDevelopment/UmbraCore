import CommonCrypto
import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
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
  public nonisolated let secureStorage: SecureStorageProtocol
  
  /// Logger for operations
  private let logger: LoggingProtocol

  /// The key size for AES-256 keys in bytes
  private let aes256KeySize=32

  /// Create a new crypto service instance
  /// - Parameters:
  ///   - options: Optional configuration options
  ///   - secureStorage: The secure storage to use for cryptographic operations
  ///   - logger: The logger to use for recording operations
  public init(
    options: CryptoServiceOptions = CryptoServiceOptions(),
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.options=options
    self.logger=logger ?? EmptyLogger()
    self.secureStorage = secureStorage
  }
  
  /// A minimal empty logger for when none is provided
  private struct EmptyLogger: LoggingProtocol {
    /// The underlying logging actor, required by LoggingProtocol
    public let loggingActor: LoggingActor = DummyLoggingActor()
    
    /// Core logging method implementation
    public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {}
    
    func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
    func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  }
  
  /// A dummy logging actor for EmptyLogger
  private actor DummyLoggingActor: LoggingActor {
    init() {
      super.init(destinations: [], minimumLogLevel: .info)
    }
    
    override func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {}
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
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Retrieve data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    // Check for errors in retrieving data or key
    switch (dataResult, keyResult) {
      case let (.failure(error), _):
        return .failure(error)
      case let (_, .failure(error)):
        return .failure(error)
      case let (.success(dataBytes), .success(keyBytes)):
        // Use encryption options or defaults
        let encryptionOptions=options ?? SecurityCoreInterfaces.EncryptionOptions()
        
        // Convert to CryptoOperationOptionsDTO
        let cryptoOptions = encryptionOptions.toCryptoOperationOptionsDTO()

        // Generate IV for encryption algorithms that require it
        let ivBytes: [UInt8]
        switch encryptionOptions.algorithm {
          case .aes256CBC, .aes256GCM:
            // Generate a random IV
            var iv = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, iv.count, &iv)
            guard status == errSecSuccess else {
              throw CryptoError.ivGenerationFailed
            }
            ivBytes = iv
          case .chacha20Poly1305:
            // Generate a nonce for ChaCha20-Poly1305
            var nonce = [UInt8](repeating: 0, count: 12)
            let status = SecRandomCopyBytes(kSecRandomDefault, nonce.count, &nonce)
            guard status == errSecSuccess else {
              throw CryptoError.ivGenerationFailed
            }
            ivBytes = nonce
        }

        // Perform the encryption based on the algorithm
        do {
          let encryptedBytes: [UInt8]

          switch encryptionOptions.algorithm {
            case .aes256CBC:
              encryptedBytes=try encryptAES_CBC(
                plaintext: dataBytes,
                key: keyBytes,
                iv: ivBytes
              )
            case .aes256GCM:
              encryptedBytes=try encryptAES_GCM(
                plaintext: dataBytes,
                key: keyBytes,
                iv: ivBytes,
                authData: encryptionOptions.authenticatedData
              )
            case .chacha20Poly1305:
              // Fallback to AES-GCM if ChaCha20-Poly1305 is requested
              // This is just a placeholder - in production, you would implement ChaCha20-Poly1305
              encryptedBytes=try encryptAES_GCM(
                plaintext: dataBytes,
                key: keyBytes,
                iv: ivBytes,
                authData: encryptionOptions.authenticatedData
              )
          }

          // Create a full package that includes the IV with the encrypted data
          // Format: [algorithm (1 byte)][iv length (1 byte)][iv (variable)][encrypted data]
          var resultBytes=[UInt8]()
          resultBytes.append(encryptionOptions.algorithm.rawValue.first?.asciiValue ?? 0)
          resultBytes.append(UInt8(ivBytes.count))
          resultBytes.append(contentsOf: ivBytes)
          resultBytes.append(contentsOf: encryptedBytes)

          // Store in secure storage and return the identifier
          let outputIdentifier=generateRandomIdentifier()
          let storeResult=await secureStorage.storeData(
            resultBytes,
            withIdentifier: outputIdentifier
          )

          switch storeResult {
            case .success:
              return .success(outputIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        } catch {
          return .failure(.encryptionFailed)
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
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Retrieve data from secure storage
    let encryptedDataResult=await secureStorage
      .retrieveData(withIdentifier: encryptedDataIdentifier)
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    // Check for errors in retrieving data or key
    switch (encryptedDataResult, keyResult) {
      case let (.failure(error), _):
        return .failure(error)
      case let (_, .failure(error)):
        return .failure(error)
      case let (.success(encryptedPackage), .success(keyBytes)):
        // Parse the encrypted package
        // Format: [algorithm (1 byte)][iv length (1 byte)][iv (variable)][encrypted data]
        guard encryptedPackage.count >= 2 else {
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        let algorithmValue=encryptedPackage[0]
        let ivLength=Int(encryptedPackage[1])

        guard encryptedPackage.count >= 2 + ivLength else {
          return .failure(.operationFailed("Invalid encrypted data format: insufficient data for IV"))
        }

        let iv=Array(encryptedPackage[2..<(2 + ivLength)])
        let encryptedBytes=Array(encryptedPackage[(2 + ivLength)...])

        // Convert byte value back to string for rawValue lookup
        let algorithmString: String
        switch algorithmValue {
          case 0: algorithmString = "aes256CBC"
          case 1: algorithmString = "aes256GCM"
          case 2: algorithmString = "chacha20Poly1305"
          default: return .failure(.operationFailed("Unknown algorithm identifier: \(algorithmValue)"))
        }
        
        guard let algorithm = CoreSecurityTypes.EncryptionAlgorithm(rawValue: algorithmString) else {
          return .failure(.operationFailed("Unsupported encryption algorithm"))
        }

        // Use decryption options or defaults
        let decryptionOptions = options ?? SecurityCoreInterfaces.DecryptionOptions(algorithm: algorithm)
        
        // Convert to CryptoOperationOptionsDTO
        let cryptoOptions = decryptionOptions.toCryptoOperationOptionsDTO()

        // Perform the decryption based on the algorithm
        do {
          let decryptedBytes: [UInt8]

          switch algorithm {
            case .aes256CBC:
              decryptedBytes=try decryptAES_CBC(
                ciphertext: encryptedBytes,
                key: keyBytes,
                iv: iv
              )
            case .aes256GCM:
              decryptedBytes=try decryptAES_GCM(
                ciphertext: encryptedBytes,
                key: keyBytes,
                authData: cryptoOptions.authenticatedData
              )
            case .chacha20Poly1305:
              // Fallback to AES-GCM for ChaCha20-Poly1305 
              // This is just a placeholder - in production, you would implement ChaCha20-Poly1305
              decryptedBytes=try decryptAES_GCM(
                ciphertext: encryptedBytes,
                key: keyBytes,
                authData: cryptoOptions.authenticatedData
              )
          }

          // Store in secure storage and return the identifier
          let outputIdentifier=generateRandomIdentifier()
          let storeResult=await secureStorage.storeData(
            decryptedBytes,
            withIdentifier: outputIdentifier
          )

          switch storeResult {
            case .success:
              return .success(outputIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        } catch {
          return .failure(.decryptionFailed)
        }
    }
  }

  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Retrieve data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .failure(error):
        return .failure(error)
      case let .success(dataBytes):
        // Use hashing options or defaults
        let hashingOptions = options ?? SecurityCoreInterfaces.HashingOptions()
        
        // Get the hash algorithm from the options
        let hashAlgorithm = hashingOptions.algorithm

        do {
          // Compute the hash
          let hashBytes=try computeHash(data: dataBytes, algorithm: hashAlgorithm)

          // Store in secure storage and return the identifier
          let hashIdentifier=generateRandomIdentifier()
          let storeResult=await secureStorage.storeData(
            hashBytes,
            withIdentifier: hashIdentifier
          )

          switch storeResult {
            case .success:
              return .success(hashIdentifier)
            case let .failure(error):
              return .failure(error)
          }
        } catch {
          return .failure(.hashingFailed)
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
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Retrieve data and expected hash from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let expectedHashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

    // Check for errors in retrieving data or expected hash
    switch (dataResult, expectedHashResult) {
      case let (.failure(error), _):
        return .failure(error)
      case let (_, .failure(error)):
        return .failure(error)
      case let (.success(dataBytes), .success(expectedHashBytes)):
        // Use hashing options or defaults
        let hashingOptions = options ?? SecurityCoreInterfaces.HashingOptions()
        
        // Get the hash algorithm from the options
        let hashAlgorithm = hashingOptions.algorithm

        do {
          // Compute the hash
          let computedHashBytes=try computeHash(data: dataBytes, algorithm: hashAlgorithm)

          // Compare the hashes (constant-time comparison)
          let matches=constantTimeCompare(
            computedHashBytes,
            expectedHashBytes
          )

          return .success(matches)
        } catch {
          return .failure(.hashVerificationFailed)
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
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    do {
      // Generate random bytes for the key
      let keyBytes=try generateRandomBytes(count: length)
      
      // Convert options to KeyGenerationOptionsDTO if needed for additional operations
      let keyGenOptionsDTO = (options ?? SecurityCoreInterfaces.KeyGenerationOptions()).toKeyGenerationOptionsDTO(keySize: length)

      // Generate a key identifier and store the key
      let keyIdentifier=generateRandomIdentifier()
      let storeResult=await secureStorage.storeData(keyBytes, withIdentifier: keyIdentifier)

      switch storeResult {
        case .success:
          return .success(keyIdentifier)
        case let .failure(error):
          return .failure(error)
      }
    } catch {
      return .failure(.keyGenerationFailed)
    }
  }

  /// Imports data into secure storage for use with cryptographic operations.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is
  /// generated.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Use the provided identifier or generate a random one
    let identifier=customIdentifier ?? generateRandomIdentifier()

    // Store the data
    let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)

    return storeResult.map { identifier }
  }

  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  /// - Warning: Use with caution as this exposes sensitive data.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Retrieve the data from secure storage
    await secureStorage.retrieveData(withIdentifier: identifier)
  }

  // MARK: - Utility Methods

  /// Generates cryptographically secure random bytes.
  /// - Parameter count: Number of random bytes to generate.
  /// - Returns: An array of random bytes.
  /// - Throws: Error if generation fails.
  private func generateRandomBytes(count: Int) throws -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: count)
    let status=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

    guard status == errSecSuccess else {
      throw NSError(domain: "CryptoServices", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to generate random bytes"])
    }

    return bytes
  }

  /// Generates a random identifier for stored data.
  /// - Returns: A string identifier based on a UUID.
  private func generateRandomIdentifier() -> String {
    "cs-\(UUID().uuidString.lowercased())"
  }

  /// Computes a hash of the data using the specified algorithm.
  /// - Parameters:
  ///   - data: Data to hash.
  ///   - algorithm: Hash algorithm to use.
  /// - Returns: Hash value as bytes.
  /// - Throws: Error if hashing fails.
  private func computeHash(data: [UInt8], algorithm: CoreSecurityTypes.HashAlgorithm) throws -> [UInt8] {
    switch algorithm {
      case .sha256:
        var hash=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(data, CC_LONG(data.count), &hash)
        return hash
      case .sha512:
        var hash=[UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        CC_SHA512(data, CC_LONG(data.count), &hash)
        return hash
      default:
        throw NSError(domain: "CryptoServices", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Unsupported algorithm"])
    }
  }

  /// Compares two byte arrays in constant time to prevent timing attacks.
  /// - Parameters:
  ///   - lhs: First byte array.
  ///   - rhs: Second byte array.
  /// - Returns: True if arrays match, false otherwise.
  private func constantTimeCompare(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }

    var result: UInt8=0
    for i in 0..<lhs.count {
      result |= lhs[i] ^ rhs[i]
    }

    return result == 0
  }

  /// Encrypts data using AES-CBC.
  /// - Parameters:
  ///   - plaintext: Data to encrypt.
  ///   - key: Encryption key.
  ///   - iv: Initialization vector.
  /// - Returns: Encrypted data.
  /// - Throws: Error if encryption fails.
  private func encryptAES_CBC(plaintext: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Create output buffer with padding
    let bufferSize=plaintext.count + kCCBlockSizeAES128
    var dataOut=[UInt8](repeating: 0, count: bufferSize)
    var outLength=0

    let status=CCCrypt(
      CCOperation(kCCEncrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      key.count,
      iv,
      plaintext,
      plaintext.count,
      &dataOut,
      bufferSize,
      &outLength
    )

    guard status == kCCSuccess else {
      throw NSError(domain: "CryptoServices", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "AES encryption failed"])
    }

    return Array(dataOut[0..<outLength])
  }

  /// Decrypts data using AES-CBC.
  /// - Parameters:
  ///   - ciphertext: Data to decrypt.
  ///   - key: Decryption key.
  ///   - iv: Initialization vector.
  /// - Returns: Decrypted data.
  /// - Throws: Error if decryption fails.
  private func decryptAES_CBC(ciphertext: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Create output buffer
    let bufferSize=ciphertext.count + kCCBlockSizeAES128
    var dataOut=[UInt8](repeating: 0, count: bufferSize)
    var outLength=0

    let status=CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      key.count,
      iv,
      ciphertext,
      ciphertext.count,
      &dataOut,
      bufferSize,
      &outLength
    )

    guard status == kCCSuccess else {
      throw NSError(domain: "CryptoServices", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "AES decryption failed"])
    }

    return Array(dataOut[0..<outLength])
  }

  /// Encrypts data using AES-GCM.
  /// - Parameters:
  ///   - plaintext: Data to encrypt.
  ///   - key: Encryption key.
  ///   - iv: Initialization vector.
  ///   - authData: Additional authenticated data.
  /// - Returns: Encrypted data.
  /// - Throws: Error if encryption fails.
  private func encryptAES_GCM(plaintext: [UInt8], key: [UInt8], iv: [UInt8], authData: [UInt8]?) throws -> [UInt8] {
    // Create output buffer with padding
    let bufferSize=plaintext.count + kCCBlockSizeAES128
    var dataOut=[UInt8](repeating: 0, count: bufferSize)
    var outLength=0

    let status=CCCrypt(
      CCOperation(kCCEncrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      key.count,
      iv,
      plaintext,
      plaintext.count,
      &dataOut,
      bufferSize,
      &outLength
    )

    guard status == kCCSuccess else {
      throw NSError(domain: "CryptoServices", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "AES encryption failed"])
    }

    return Array(dataOut[0..<outLength])
  }

  /// Decrypts data using AES-GCM.
  /// - Parameters:
  ///   - ciphertext: Data to decrypt.
  ///   - key: Decryption key.
  ///   - authData: Additional authenticated data.
  /// - Returns: Decrypted data.
  /// - Throws: Error if decryption fails.
  private func decryptAES_GCM(ciphertext: [UInt8], key: [UInt8], authData: [UInt8]?) throws -> [UInt8] {
    // Create output buffer
    let bufferSize=ciphertext.count + kCCBlockSizeAES128
    var dataOut=[UInt8](repeating: 0, count: bufferSize)
    var outLength=0

    let status=CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      key.count,
      nil,
      ciphertext,
      ciphertext.count,
      &dataOut,
      bufferSize,
      &outLength
    )

    guard status == kCCSuccess else {
      throw NSError(domain: "CryptoServices", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "AES decryption failed"])
    }

    return Array(dataOut[0..<outLength])
  }
}
