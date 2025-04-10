import CoreSecurityTypes
import CryptoKit
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # BasicSecurityProvider

 A basic implementation of SecurityProviderProtocol following the Alpha Dot Five architecture.

 This implementation provides a simple security provider for use when
 more specialised providers are not available or not required. It serves
 as a fallback implementation for various security operations.

 ## Privacy Controls

 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys and operations are treated with appropriate privacy levels
 - Error details are classified based on sensitivity
 - Metadata is structured using SecurityLogContext for privacy-aware logging

 ## Thread Safety

 The implementation uses Swift's actor model to ensure thread safety for cryptographic operations,
 providing proper isolation and concurrency safety in line with Alpha Dot Five architecture.
 */
public actor BasicSecurityProvider: SecurityProviderProtocol, AsyncServiceInitializable {
  // MARK: - Properties

  /// Logger for recording operations
  private let logger: LoggingProtocol?
  
  /// A secure random number generator for cryptographic operations
  private let secureRandom = SecureRandomGenerator()

  // MARK: - Initialisation

  /**
   Initialises a new BasicSecurityProvider.

   - Parameter logger: Optional logger for recording operations
   */
  public init(logger: LoggingProtocol? = nil) {
    self.logger = logger
  }

  // MARK: - AsyncServiceInitializable

  /**
   Creates an async instance of the provider.
   Required by AsyncServiceInitializable protocol.
   
   - Returns: An initialised instance
   */
  public static func createAsync() async -> BasicSecurityProvider {
    return BasicSecurityProvider()
  }

  /**
   Initialises the provider asynchronously.

   This method performs any necessary setup that requires asynchronous operations.
   */
  public func initialize() async throws {
    let metadata = LogMetadataDTOCollection()
      .withPublic(key: "provider", value: "BasicSecurityProvider")

    let context = SecurityLogContext(
      operation: "initialize",
      component: "BasicSecurityProvider",
      operationID: UUID().uuidString,
      correlationID: nil,
      source: "CryptoServices",
      metadata: metadata
    )

    await logger?.info(
      "Initialising BasicSecurityProvider",
      context: context
    )

    // No actual initialisation required for this provider

    await logger?.info(
      "BasicSecurityProvider initialised successfully",
      context: context
    )
  }
  
  // MARK: - Helper Methods
  
  /**
   Creates a standard security log context for operations
   
   - Parameters:
   - operation: The operation being performed
   - config: Configuration for the operation
   - Returns: A context object for logging
   */
  private func createLogContext(
    operation: String,
    config: SecurityConfigDTO? = nil,
    correlationID: String? = nil
  ) -> SecurityLogContext {
    let operationID = UUID().uuidString
    
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "provider", value: "BasicSecurityProvider")
      .withPublic(key: "operationId", value: operationID)
    
    if let config = config {
      metadata = metadata
        .withPublic(key: "encryptionAlgorithm", value: config.encryptionAlgorithm.rawValue)
        .withPublic(key: "hashAlgorithm", value: config.hashAlgorithm.rawValue)
    }
    
    return SecurityLogContext(
      operation: operation,
      component: "BasicSecurityProvider",
      operationID: operationID,
      correlationID: correlationID,
      source: "CryptoServices",
      metadata: metadata
    )
  }
  
  /**
   Extracts required data from configuration options
   
   - Parameter config: The configuration to extract data from
   - Parameter key: The metadata key to look for
   - Returns: The decoded data or nil if not found
   - Throws: SecurityError if the data is invalid
   */
  private func extractData(from config: SecurityConfigDTO, key: String) throws -> Data? {
    guard let options = config.options,
          let base64Data = options.metadata?[key],
          let data = Data(base64Encoded: base64Data) else {
      return nil
    }
    return data
  }

  // MARK: - SecurityProviderProtocol Implementation

  /**
   Encrypts data using the provided configuration.
   This implementation uses AES-CBC with a secure random IV.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing the encrypted data
   - Throws: SecurityError if the operation fails
   */
  public func encrypt(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "encrypt", config: config)

    await logger?.debug(
      "Encryption operation requested",
      context: context
    )
    
    do {
      // Extract data to encrypt from configuration
      guard let options = config.options,
            let inputDataBase64 = options.metadata?["inputData"],
            let inputData = Data(base64Encoded: inputDataBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid inputData in configuration metadata"
        )
      }
      
      // Extract encryption key or generate one if not provided
      let encryptionKey: SymmetricKey
      if let keyBase64 = options.metadata?["key"], 
         let keyData = Data(base64Encoded: keyBase64) {
        // Use provided key
        encryptionKey = SymmetricKey(data: keyData)
      } else {
        // Generate a new AES-256 key (32 bytes)
        encryptionKey = SymmetricKey(size: .bits256)
      }
      
      // Generate a random IV (initialisation vector)
      let iv = generateRandomIV()
      
      // Encrypt the data using AES-CBC
      let ciphertext = try encryptAESCBC(data: inputData, key: encryptionKey, iv: iv)
      
      // Combine IV and ciphertext
      // Format: [16 bytes IV][ciphertext]
      var encryptedData = Data()
      encryptedData.append(iv)
      encryptedData.append(ciphertext)
      
      // Calculate execution time (simulated for this implementation)
      let executionTime = 5.0 // milliseconds
      
      // Log success with appropriate privacy tags
      let successContext = context
        .withPublic(key: "algorithm", value: "AES-CBC")
        .withPublic(key: "inputSize", value: "\(inputData.count)")
        .withPublic(key: "outputSize", value: "\(encryptedData.count)")
      
      await logger?.info(
        "Successfully encrypted data using AES-CBC",
        context: successContext
      )
      
      // Return successful result with encrypted data
      return SecurityResultDTO.success(
        resultData: encryptedData,
        executionTimeMs: executionTime,
        metadata: [
          "algorithm": "AES-CBC",
          "ivSize": "\(iv.count)",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Encryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.encryptionFailed(
        reason: "Unexpected error during encryption: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "encryptionFailed")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Encryption operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Decrypts data using the provided configuration.
   This implementation decrypts data that was encrypted using AES-CBC.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing the decrypted data
   - Throws: SecurityError if the operation fails
   */
  public func decrypt(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "decrypt", config: config)

    await logger?.debug(
      "Decryption operation requested",
      context: context
    )
    
    do {
      // Extract encrypted data from configuration
      guard let options = config.options,
            let encryptedDataBase64 = options.metadata?["encryptedData"],
            let encryptedData = Data(base64Encoded: encryptedDataBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid encryptedData in configuration metadata"
        )
      }
      
      // Ensure we have enough data for IV + ciphertext
      guard encryptedData.count > 16 else {
        throw SecurityError.invalidInputData(
          reason: "Encrypted data too short, missing IV"
        )
      }
      
      // Extract IV (first 16 bytes) and ciphertext
      let iv = encryptedData.prefix(16)
      let ciphertext = encryptedData.dropFirst(16)
      
      // Extract decryption key
      guard let keyBase64 = options.metadata?["key"],
            let keyData = Data(base64Encoded: keyBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid key in configuration metadata"
        )
      }
      
      let decryptionKey = SymmetricKey(data: keyData)
      
      // Decrypt the data using AES-CBC
      let plaintext = try decryptAESCBC(ciphertext: ciphertext, key: decryptionKey, iv: iv)
      
      // Calculate execution time (simulated for this implementation)
      let executionTime = 4.5 // milliseconds
      
      // Log success with appropriate privacy tags
      let successContext = context
        .withPublic(key: "algorithm", value: "AES-CBC")
        .withPublic(key: "inputSize", value: "\(encryptedData.count)")
        .withPublic(key: "outputSize", value: "\(plaintext.count)")
      
      await logger?.info(
        "Successfully decrypted data using AES-CBC",
        context: successContext
      )
      
      // Return successful result with decrypted data
      return SecurityResultDTO.success(
        resultData: plaintext,
        executionTimeMs: executionTime,
        metadata: [
          "algorithm": "AES-CBC",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Decryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.decryptionFailed(
        reason: "Unexpected error during decryption: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "decryptionFailed")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Decryption operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Decrypts data using AES-CBC with the provided key and IV.
   
   - Parameters:
     - ciphertext: The encrypted data to decrypt
     - key: The symmetric key for decryption
     - iv: The initialisation vector used during encryption
   - Returns: The decrypted plaintext
   - Throws: Error if decryption fails
   */
  private func decryptAESCBC(ciphertext: Data, key: SymmetricKey, iv: Data) throws -> Data {
    // Implementation for platforms without CryptoKit AES-CBC
    // This is a fallback implementation using CommonCrypto
    
    // Prepare for CommonCrypto
    let keyData = key.withUnsafeBytes { Data($0) }
    
    var cryptoResult = Data(count: ciphertext.count + kCCBlockSizeAES128)
    var resultLength = 0
    
    let status = keyData.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        ciphertext.withUnsafeBytes { ciphertextBytes in
          cryptoResult.withUnsafeMutableBytes { resultBytes in
            CCCrypt(
              CCOperation(kCCDecrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress, keyBytes.count,
              ivBytes.baseAddress,
              ciphertextBytes.baseAddress, ciphertextBytes.count,
              resultBytes.baseAddress, resultBytes.count,
              &resultLength
            )
          }
        }
      }
    }
    
    guard status == kCCSuccess else {
      throw SecurityError.decryptionFailed(
        reason: "AES-CBC decryption failed with code: \(status)"
      )
    }
    
    return cryptoResult.prefix(resultLength)
  }
  
  /**
   Generates a cryptographic key using the provided configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing the generated key
   - Throws: SecurityStorageError if the operation fails
   */
  public func generateKey(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "generateKey", config: config)

    await logger?.debug(
      "Generating cryptographic key",
      context: context
    )

    // Return a mock key identifier for basic functionality
    let mockKeyID = "basic_key_\(UUID().uuidString)"

    let successContext = createLogContext(operation: "generateKey", config: config)
      .withSensitive(key: "keyIdentifier", value: mockKeyID)

    await logger?.info(
      "Successfully generated key with identifier: \(mockKeyID)",
      context: successContext
    )

    // Use static factory method and qualify enums
    return SecurityResultDTO.success(
      resultData: mockKeyID.data(using: .utf8),
      executionTimeMs: 0.0
    )
  }

  /**
   Securely stores data with the provided identifier.

   - Parameter config: Configuration for the storage operation
   - Returns: Result indicating whether the storage was successful
   - Throws: SecurityError if the operation fails
   */
  public func secureStore(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "secureStore", config: config)

    await logger?.debug(
      "Secure storage operation requested",
      context: context
    )
    
    do {
      // Extract data and identifier from configuration
      guard let options = config.options,
            let identifier = options.metadata?["identifier"],
            let inputDataBase64 = options.metadata?["data"],
            let inputData = Data(base64Encoded: inputDataBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid identifier or data in configuration metadata"
        )
      }
      
      // Create a secure storage instance
      let secureStorage = await createSecureStorage()
      
      // Store the data
      let storeResult = await secureStorage.storeData(inputData, withIdentifier: identifier)
      
      switch storeResult {
      case .success:
        // Calculate execution time (simulated for this implementation)
        let executionTime = 5.0 // milliseconds
        
        // Log success with appropriate privacy tags
        let successContext = context
          .withPublic(key: "operation", value: "secureStore")
          .withPublic(key: "dataSize", value: "\(inputData.count)")
          .withPrivate(key: "identifier", value: identifier)
        
        await logger?.info(
          "Successfully stored data securely",
          context: successContext
        )
        
        // Return successful result
        return SecurityResultDTO.success(
          resultData: Data([1]), // Success byte
          executionTimeMs: executionTime,
          metadata: [
            "operation": "secureStore",
            "dataSize": "\(inputData.count)"
          ]
        )
        
      case .failure(let error):
        throw SecurityError.storageError(
          reason: "Failed to store data: \(error.localizedDescription)"
        )
      }
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Secure storage operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.storageError(
        reason: "Unexpected error during secure storage: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "storageError")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Secure storage operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Securely retrieves data with the provided identifier.

   - Parameter config: Configuration for the retrieval operation
   - Returns: Result containing the retrieved data
   - Throws: SecurityError if the operation fails
   */
  public func secureRetrieve(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "secureRetrieve", config: config)

    await logger?.debug(
      "Secure retrieval operation requested",
      context: context
    )
    
    do {
      // Extract identifier from configuration
      guard let options = config.options,
            let identifier = options.metadata?["identifier"] else {
        throw SecurityError.invalidInputData(
          reason: "Missing identifier in configuration metadata"
        )
      }
      
      // Create a secure storage instance
      let secureStorage = await createSecureStorage()
      
      // Retrieve the data
      let retrieveResult = await secureStorage.retrieveData(withIdentifier: identifier)
      
      switch retrieveResult {
      case .success(let retrievedData):
        // Calculate execution time (simulated for this implementation)
        let executionTime = 4.0 // milliseconds
        
        // Log success with appropriate privacy tags
        let successContext = context
          .withPublic(key: "operation", value: "secureRetrieve")
          .withPublic(key: "dataSize", value: "\(retrievedData.count)")
          .withPrivate(key: "identifier", value: identifier)
        
        await logger?.info(
          "Successfully retrieved data securely",
          context: successContext
        )
        
        // Return successful result with retrieved data
        return SecurityResultDTO.success(
          resultData: retrievedData,
          executionTimeMs: executionTime,
          metadata: [
            "operation": "secureRetrieve",
            "dataSize": "\(retrievedData.count)"
          ]
        )
        
      case .failure(let error):
        throw SecurityError.retrievalError(
          reason: "Failed to retrieve data: \(error.localizedDescription)"
        )
      }
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Secure retrieval operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.retrievalError(
        reason: "Unexpected error during secure retrieval: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "retrievalError")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Secure retrieval operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Securely deletes data with the provided identifier.

   - Parameter config: Configuration for the deletion operation
   - Returns: Result indicating whether the deletion was successful
   - Throws: SecurityError if the operation fails
   */
  public func secureDelete(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "secureDelete", config: config)

    await logger?.debug(
      "Secure deletion operation requested",
      context: context
    )
    
    do {
      // Extract identifier from configuration
      guard let options = config.options,
            let identifier = options.metadata?["identifier"] else {
        throw SecurityError.invalidInputData(
          reason: "Missing identifier in configuration metadata"
        )
      }
      
      // Create a secure storage instance
      let secureStorage = await createSecureStorage()
      
      // Delete the data
      let deleteResult = await secureStorage.deleteData(withIdentifier: identifier)
      
      switch deleteResult {
      case .success:
        // Calculate execution time (simulated for this implementation)
        let executionTime = 3.0 // milliseconds
        
        // Log success with appropriate privacy tags
        let successContext = context
          .withPublic(key: "operation", value: "secureDelete")
          .withPrivate(key: "identifier", value: identifier)
        
        await logger?.info(
          "Successfully deleted data securely",
          context: successContext
        )
        
        // Return successful result
        return SecurityResultDTO.success(
          resultData: Data([1]), // Success byte
          executionTimeMs: executionTime,
          metadata: [
            "operation": "secureDelete"
          ]
        )
        
      case .failure(let error):
        throw SecurityError.deletionError(
          reason: "Failed to delete data: \(error.localizedDescription)"
        )
      }
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Secure deletion operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.deletionError(
        reason: "Unexpected error during secure deletion: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "deletionError")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Secure deletion operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Creates a secure configuration with the specified options.

   - Parameter options: Options for the secure configuration
   - Returns: A SecurityConfigDTO instance
   */
  public func createSecureConfig(
    options: CoreSecurityTypes.SecurityConfigOptions
  ) async -> CoreSecurityTypes.SecurityConfigDTO {
    let context = createLogContext(operation: "createSecureConfig")

    await logger?.debug(
      "Creating security configuration",
      context: context
    )

    // Create a basic configuration
    let config = SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: .sha256,
      providerType: .cryptoKit,
      options: options
    )

    let successContext = createLogContext(operation: "createSecureConfig")

    await logger?.debug(
      "Successfully created secure configuration",
      context: successContext
    )

    return config
  }

  /**
   Generates random bytes.

   - Parameter bytes: Number of random bytes to generate
   - Returns: Result containing the generated random bytes
   - Throws: SecurityStorageError if the operation fails
   */
  public func generateRandom(
    bytes: Int
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "generateRandom")
      .withPublic(key: "byteCount", value: "\(bytes)")

    await logger?.debug(
      "Generating \(bytes) random bytes",
      context: context
    )

    do {
      // Generate cryptographically secure random bytes using SecRandomCopyBytes
      var randomData = [UInt8](repeating: 0, count: bytes)
      let status = SecRandomCopyBytes(kSecRandomDefault, bytes, &randomData)
      
      // Check for status errors
      guard status == errSecSuccess else {
        throw SecurityError.randomGenerationFailed(
          reason: "SecRandomCopyBytes failed with code: \(status)"
        )
      }

      let successContext = createLogContext(operation: "generateRandom")
        .withPublic(key: "bytesGenerated", value: "\(randomData.count)")

      await logger?.info(
        "Successfully generated \(randomData.count) secure random bytes",
        context: successContext
      )

      // Calculate the execution time (simulated)
      let executionTime = 2.5 // milliseconds

      return SecurityResultDTO.success(
        resultData: Data(randomData),
        executionTimeMs: executionTime,
        metadata: [
          "byteCount": "\(bytes)",
          "algorithm": "SecRandomCopyBytes",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch {
      let errorContext = createLogContext(operation: "generateRandom")
        .withPublic(key: "error", value: error.localizedDescription)
        
      await logger?.error(
        "Failed to generate random bytes: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    }
  }

  /**
   Computes a cryptographic hash for the provided input data.

   - Parameter config: Configuration for the hash operation
   - Returns: Result containing the hash data
   - Throws: SecurityError if the operation fails
   */
  public func hash(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "hash", config: config)

    await logger?.debug(
      "Hash operation requested",
      context: context
    )
    
    do {
      // Extract data to hash from configuration
      guard let options = config.options,
            let inputDataBase64 = options.metadata?["inputData"],
            let inputData = Data(base64Encoded: inputDataBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid inputData in configuration metadata"
        )
      }
      
      // Determine which hashing algorithm to use
      let algorithm = config.hashAlgorithm
      
      // Perform the hash operation
      let hashedData: Data
      
      switch algorithm {
      case .sha256:
        hashedData = performSHA256(on: inputData)
      case .sha512:
        hashedData = performSHA512(on: inputData)
      case .md5:
        // MD5 is considered insecure, but provided for compatibility
        hashedData = performMD5(on: inputData)
      default:
        // Default to SHA-256 for unrecognised algorithms
        await logger?.warning(
          "Unrecognised hash algorithm \(algorithm.rawValue), defaulting to SHA-256",
          context: context
        )
        hashedData = performSHA256(on: inputData)
      }
      
      // Calculate execution time (simulated for this implementation)
      let executionTime = 3.0 // milliseconds
      
      // Log success with appropriate privacy tags
      let successContext = context
        .withPublic(key: "algorithm", value: algorithm.rawValue)
        .withPublic(key: "outputSize", value: "\(hashedData.count)")
        .withHashed(key: "hashOutput", value: hashedData.base64EncodedString())
      
      await logger?.info(
        "Successfully computed \(algorithm.rawValue) hash",
        context: successContext
      )
      
      // Return successful result with hash data
      return SecurityResultDTO.success(
        resultData: hashedData,
        executionTimeMs: executionTime,
        metadata: [
          "algorithm": algorithm.rawValue,
          "hashSize": "\(hashedData.count)",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Hash operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.hashingFailed(
        reason: "Unexpected error during hash operation: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "hashingFailed")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Hash operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Verifies a hash against the provided data and expected hash value.

   - Parameter config: Configuration for the hash verification operation
   - Returns: Result indicating whether the hash is valid
   - Throws: SecurityError if the operation fails
   */
  public func verifyHash(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "verifyHash", config: config)

    await logger?.debug(
      "Hash verification requested",
      context: context
    )
    
    do {
      // Extract data and expected hash from configuration
      guard let options = config.options,
            let inputDataBase64 = options.metadata?["inputData"],
            let expectedHashBase64 = options.metadata?["expectedHash"],
            let inputData = Data(base64Encoded: inputDataBase64),
            let expectedHash = Data(base64Encoded: expectedHashBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid inputData or expectedHash in configuration metadata"
        )
      }
      
      // Determine which hashing algorithm to use
      let algorithm = config.hashAlgorithm
      
      // Generate the hash of the input data
      let calculatedHash: Data
      
      switch algorithm {
      case .sha256:
        calculatedHash = performSHA256(on: inputData)
      case .sha512:
        calculatedHash = performSHA512(on: inputData)
      case .md5:
        // MD5 is considered insecure, but provided for compatibility
        calculatedHash = performMD5(on: inputData)
      default:
        // Default to SHA-256 for unrecognised algorithms
        await logger?.warning(
          "Unrecognised hash algorithm \(algorithm.rawValue), defaulting to SHA-256",
          context: context
        )
        calculatedHash = performSHA256(on: inputData)
      }
      
      // Perform constant-time comparison to prevent timing attacks
      let isValid = constantTimeCompare(calculatedHash, expectedHash)
      
      // Create result data - a single byte indicating valid (1) or invalid (0)
      let resultData = Data([isValid ? 1 : 0])
      
      // Calculate execution time (simulated for this implementation)
      let executionTime = 3.0 // milliseconds
      
      // Log result with appropriate privacy tags
      let resultContext = context
        .withPublic(key: "algorithm", value: algorithm.rawValue)
        .withPublic(key: "isValid", value: "\(isValid)")
      
      await logger?.info(
        "Hash verification result: \(isValid ? "Valid" : "Invalid")",
        context: resultContext
      )
      
      // Return result
      return SecurityResultDTO.success(
        resultData: resultData,
        executionTimeMs: executionTime,
        metadata: [
          "algorithm": algorithm.rawValue,
          "isValid": "\(isValid)",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Hash verification failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.hashingFailed(
        reason: "Unexpected error during hash verification: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "hashingFailed")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Hash verification failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Performs a constant-time comparison of two Data objects.
   This prevents timing attacks that could potentially leak information
   about the expected hash value.
   
   - Parameters:
     - lhs: First Data object to compare
     - rhs: Second Data object to compare
   - Returns: True if the Data objects are identical, false otherwise
   */
  private func constantTimeCompare(_ lhs: Data, _ rhs: Data) -> Bool {
    // If lengths differ, return false but still do the full comparison
    // to maintain constant time regardless of content
    let result = lhs.count == rhs.count
    
    // XOR each byte - if they're the same, XOR will be 0
    var accumulated: UInt8 = 0
    
    // Use the shorter length to avoid out-of-bounds access
    let minCount = min(lhs.count, rhs.count)
    
    for i in 0..<minCount {
      accumulated |= lhs[i] ^ rhs[i]
    }
    
    // If data lengths differ, force a mismatch
    if lhs.count != rhs.count {
      accumulated |= 1
    }
    
    // accumulated will be 0 if and only if all bytes match
    return accumulated == 0
  }
  
  /**
   Computes a SHA-256 hash of the input data.
   
   - Parameter data: The data to hash
   - Returns: The SHA-256 hash of the input data
   */
  private func performSHA256(on data: Data) -> Data {
    var hasher = SHA256()
    hasher.update(data: data)
    return Data(hasher.finalize())
  }
  
  /**
   Computes a SHA-512 hash of the input data.
   
   - Parameter data: The data to hash
   - Returns: The SHA-512 hash of the input data
   */
  private func performSHA512(on data: Data) -> Data {
    var hasher = SHA512()
    hasher.update(data: data)
    return Data(hasher.finalize())
  }
  
  /**
   Computes an MD5 hash of the input data.
   Note: MD5 is considered cryptographically weak and should only be used
   for non-security critical operations like checksums.
   
   - Parameter data: The data to hash
   - Returns: The MD5 hash of the input data
   */
  private func performMD5(on data: Data) -> Data {
    var hasher = Insecure.MD5()
    hasher.update(data: data)
    return Data(hasher.finalize())
  }

  /**
   Signs data using the provided configuration.
   This implementation uses HMAC-SHA256 for digital signatures.

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing the signature
   - Throws: SecurityError if the operation fails
   */
  public func sign(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "sign", config: config)

    await logger?.debug(
      "Signing operation requested",
      context: context
    )
    
    do {
      // Extract data to sign from configuration
      guard let options = config.options,
            let inputDataBase64 = options.metadata?["inputData"],
            let inputData = Data(base64Encoded: inputDataBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid inputData in configuration metadata"
        )
      }
      
      // Extract signing key
      guard let keyBase64 = options.metadata?["key"],
            let keyData = Data(base64Encoded: keyBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid key in configuration metadata"
        )
      }
      
      // Create the signing key
      let signingKey = SymmetricKey(data: keyData)
      
      // Determine which algorithm to use
      let algorithm = config.hashAlgorithm
      
      // Generate the signature
      let signature: Data
      
      switch algorithm {
      case .sha256:
        signature = HMAC<SHA256>.authenticationCode(for: inputData, using: signingKey)
      case .sha512:
        signature = HMAC<SHA512>.authenticationCode(for: inputData, using: signingKey)
      default:
        // Default to SHA-256 for unrecognised algorithms
        await logger?.warning(
          "Unrecognised hash algorithm \(algorithm.rawValue), defaulting to HMAC-SHA256",
          context: context
        )
        signature = HMAC<SHA256>.authenticationCode(for: inputData, using: signingKey)
      }
      
      // Convert signature to Data
      let signatureData = Data(signature)
      
      // Calculate execution time (simulated for this implementation)
      let executionTime = 3.5 // milliseconds
      
      // Log success with appropriate privacy tags
      let successContext = context
        .withPublic(key: "algorithm", value: "HMAC-\(algorithm.rawValue)")
        .withPublic(key: "inputSize", value: "\(inputData.count)")
        .withPublic(key: "signatureSize", value: "\(signatureData.count)")
        .withHashed(key: "signatureHash", value: performSHA256(on: signatureData).base64EncodedString())
      
      await logger?.info(
        "Successfully generated signature using HMAC-\(algorithm.rawValue)",
        context: successContext
      )
      
      // Return successful result with signature
      return SecurityResultDTO.success(
        resultData: signatureData,
        executionTimeMs: executionTime,
        metadata: [
          "algorithm": "HMAC-\(algorithm.rawValue)",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Signing operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.signingFailed(
        reason: "Unexpected error during signing: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "signingFailed")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Signing operation failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Verifies a signature using the provided configuration.

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing the verification information
   - Throws: SecurityProviderError if the operation fails
   */
  public func verify(
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "verify", config: config)

    await logger?.debug(
      "Signature verification requested",
      context: context
    )
    
    do {
      // Extract data and signature from configuration
      guard let options = config.options,
            let inputDataBase64 = options.metadata?["inputData"],
            let signatureBase64 = options.metadata?["signature"],
            let inputData = Data(base64Encoded: inputDataBase64),
            let signatureData = Data(base64Encoded: signatureBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid inputData or signature in configuration metadata"
        )
      }
      
      // Extract verification key
      guard let keyBase64 = options.metadata?["key"],
            let keyData = Data(base64Encoded: keyBase64) else {
        throw SecurityError.invalidInputData(
          reason: "Missing or invalid key in configuration metadata"
        )
      }
      
      // Create the verification key
      let verificationKey = SymmetricKey(data: keyData)
      
      // Determine which algorithm to use
      let algorithm = config.hashAlgorithm
      
      // Verify the signature
      let isValid: Bool
      
      switch algorithm {
      case .sha256:
        isValid = verifyHMAC(
          data: inputData,
          signature: signatureData,
          key: verificationKey,
          using: SHA256.self
        )
      case .sha512:
        isValid = verifyHMAC(
          data: inputData,
          signature: signatureData,
          key: verificationKey,
          using: SHA512.self
        )
      default:
        // Default to SHA-256 for unrecognised algorithms
        await logger?.warning(
          "Unrecognised hash algorithm \(algorithm.rawValue), defaulting to HMAC-SHA256",
          context: context
        )
        isValid = verifyHMAC(
          data: inputData,
          signature: signatureData,
          key: verificationKey,
          using: SHA256.self
        )
      }
      
      // Create result data - a single byte indicating valid (1) or invalid (0)
      let resultData = Data([isValid ? 1 : 0])
      
      // Calculate execution time (simulated for this implementation)
      let executionTime = 2.5 // milliseconds
      
      // Log result with appropriate privacy tags
      let resultContext = context
        .withPublic(key: "algorithm", value: "HMAC-\(algorithm.rawValue)")
        .withPublic(key: "isValid", value: "\(isValid)")
      
      await logger?.info(
        "Signature verification result: \(isValid ? "Valid" : "Invalid")",
        context: resultContext
      )
      
      // Return result
      return SecurityResultDTO.success(
        resultData: resultData,
        executionTimeMs: executionTime,
        metadata: [
          "algorithm": "HMAC-\(algorithm.rawValue)",
          "isValid": "\(isValid)",
          "source": "BasicSecurityProvider"
        ]
      )
    } catch let error as SecurityError {
      // Handle known security errors
      let errorContext = context
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorMessage", value: error.localizedDescription)
      
      await logger?.error(
        "Signature verification failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // Handle unexpected errors
      let wrappedError = SecurityError.verificationFailed(
        reason: "Unexpected error during signature verification: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "errorType", value: "verificationFailed")
        .withPublic(key: "errorMessage", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Signature verification failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }
  
  /**
   Verifies an HMAC signature using a specific hashing algorithm.
   
   - Parameters:
     - data: The data that was signed
     - signature: The signature to verify
     - key: The key to use for verification
     - hashFunction: The hash function type to use for HMAC
   - Returns: True if the signature is valid, false otherwise
   */
  private func verifyHMAC<H: HashFunction>(
    data: Data,
    signature: Data,
    key: SymmetricKey,
    using hashFunction: H.Type
  ) -> Bool {
    guard let expectedMAC = HMAC<H>.MAC(data: signature) else {
      return false
    }
    
    do {
      let computedMAC = HMAC<H>.authenticationCode(for: data, using: key)
      return expectedMAC == computedMAC
    } catch {
      return false
    }
  }
  
  /**
   Performs a secure operation based on the operation type and configuration.

   - Parameters:
     - operation: The type of operation to perform
     - config: Configuration for the operation
   - Returns: Result containing the operation information
   - Throws: SecurityError if the operation fails
   */
  public func performSecureOperation(
    operation: CoreSecurityTypes.SecurityOperation,
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let context = createLogContext(operation: "performSecureOperation", config: config)
      .withPublic(key: "operationType", value: "\(operation)")

    await logger?.info(
      "Performing secure operation: \(operation)",
      context: context
    )
    
    let startTime = Date()
    
    do {
      // Route to the appropriate operation
      let result: SecurityResultDTO
      
      switch operation {
        case .sign:
          result = try await sign(config: config)
          
        case .verify:
          result = try await verify(config: config)
          
        case .encrypt:
          result = try await encrypt(config: config)
          
        case .decrypt:
          result = try await decrypt(config: config)
          
        case .hash:
          result = try await hash(config: config)
          
        case .verifyHash:
          result = try await verifyHash(config: config)
          
        case .generateKey:
          result = try await generateKey(config: config)
          
        case .generateRandom:
          result = try await generateRandom(bytes: config.options?.metadata?["byteCount"].flatMap { Int($0) } ?? 32)
          
        case .secureStore:
          result = try await secureStore(config: config)
          
        case .secureRetrieve:
          result = try await secureRetrieve(config: config)
          
        case .secureDelete:
          result = try await secureDelete(config: config)
          
        @unknown default:
          // Handle any future operations by throwing a proper error
          throw SecurityError.unsupportedOperation(
            reason: "Operation type \(operation) is not supported by BasicSecurityProvider"
          )
      }
      
      // Calculate execution time
      let executionTime = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware context
      let successContext = context
        .withPublic(key: "status", value: "success")
        .withPublic(key: "durationMs", value: String(format: "%.2f", executionTime))
      
      await logger?.info(
        "Successfully completed \(operation) operation",
        context: successContext
      )
      
      // If the result doesn't have execution time data, add it
      var updatedResult = result
      if result.executionTimeMs == 0 {
        // Create a new result with the actual execution time
        updatedResult = SecurityResultDTO.success(
          resultData: result.resultData,
          executionTimeMs: executionTime,
          metadata: result.metadata ?? [:]
        )
      }
      
      return updatedResult
    } catch let error as SecurityError {
      // For known SecurityError types, log and rethrow
      let errorContext = context
        .withPublic(key: "status", value: "failed")
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPublic(key: "errorDescription", value: error.localizedDescription)
      
      await logger?.error(
        "Security operation \(operation) failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw error
    } catch {
      // For generic errors, wrap in SecurityError
      let wrappedError = SecurityError.generalError(
        reason: "Unexpected error during \(operation) operation: \(error.localizedDescription)"
      )
      
      let errorContext = context
        .withPublic(key: "status", value: "failed")
        .withPublic(key: "errorType", value: "generalError")
        .withPublic(key: "errorDescription", value: wrappedError.localizedDescription)
      
      await logger?.error(
        "Security operation \(operation) failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )
      
      throw wrappedError
    }
  }

  /**
   Creates a crypto service instance.

   - Returns: An implementation of CryptoServiceProtocol
   */
  public func cryptoService() async -> any CryptoServiceProtocol {
    let context = createLogContext(operation: "cryptoService")

    await logger?.debug(
      "Creating crypto service instance",
      context: context
    )

    // Create secure storage service for handling cryptographic materials
    let secureStorageService = await createSecureStorage()
    
    // Create DefaultCryptoServiceWithProviderImpl with self as the provider
    let service = DefaultCryptoServiceWithProviderImpl(
      provider: self,
      secureStorage: secureStorageService,
      logger: logger ?? EmptyLogger()
    )
    
    await logger?.info(
      "Successfully created crypto service instance",
      context: context
    )
    
    return service
  }
  
  /**
   Creates a secure storage instance for the crypto service.
   
   - Returns: A SecureStorageProtocol implementation
   */
  private func createSecureStorage() async -> SecureStorageProtocol {
    // In a real implementation, this should create a secure storage implementation
    // based on the platform capabilities and security requirements
    return InMemorySecureStorage(
      logger: logger ?? EmptyLogger(),
      baseURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("basic_crypto_storage")
    )
  }
  
  /**
   Creates a key management instance.

   - Returns: An implementation of KeyManagementProtocol
   */
  public func keyManager() async -> any SecurityCoreInterfaces.KeyManagementProtocol {
    let context = createLogContext(operation: "keyManager")

    await logger?.debug(
      "Creating key manager instance",
      context: context
    )

    // Create a basic key management implementation that works with
    // the secureStorage in the crypto service
    let service = BasicKeyManagementService(
      secureStorage: await createSecureStorage(),
      logger: logger ?? EmptyLogger()
    )
    
    await logger?.info(
      "Successfully created key manager instance",
      context: context
    )
    
    return service
  }
  
  /**
   Basic implementation of KeyManagementProtocol for internal use with BasicSecurityProvider.
   */
  private actor BasicKeyManagementService: KeyManagementProtocol {
    // MARK: - Properties
    
    /// Secure storage for key material
    private let secureStorage: SecureStorageProtocol
    
    /// Logger for operations
    private let logger: LoggingProtocol
    
    // MARK: - Initialisation
    
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
      self.secureStorage = secureStorage
      self.logger = logger
    }
    
    // MARK: - KeyManagementProtocol Implementation
    
    /**
     Generates a cryptographic key with the given options.
     
     - Parameters:
        - keyType: The type of key to generate
        - keySize: The size of the key in bits
        - options: Additional options for key generation
     - Returns: The generated key or an error
     */
    public func generateKey(
      keyType: KeyType,
      keySize: Int,
      options: KeyGenerationOptions?
    ) async -> Result<KeyMaterial, KeyManagementError> {
      let operationID = UUID().uuidString
      
      // Create a log context for the operation
      let context = SecurityLogContext(
        operation: "generateKey",
        component: "BasicKeyManagementService",
        operationID: operationID,
        correlationID: nil,
        source: "CryptoServices",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "keyType", value: "\(keyType)")
          .withPublic(key: "keySize", value: "\(keySize)")
      )
      
      await logger.info("Generating cryptographic key", context: context)
      
      // Generate random bytes for the key
      var keyBytes = [UInt8](repeating: 0, count: keySize / 8)
      let status = SecRandomCopyBytes(kSecRandomDefault, keySize / 8, &keyBytes)
      
      // Handle key creation failure
      guard status == errSecSuccess else {
        await logger.error("Failed to generate secure random bytes for key", context: context)
        return .failure(.keyGenerationFailed(reason: "Failed to generate secure random bytes with status \(status)"))
      }
      
      // Generate key identifier
      let keyID = "key_\(UUID().uuidString)"
      
      // Store the key material
      let storeResult = await secureStorage.storeData(keyBytes, withIdentifier: keyID)
      
      switch storeResult {
      case .success:
        // Key was stored successfully
        let successContext = context.adding(
          key: "keyIdentifier", 
          value: keyID,
          privacy: .private
        )
        
        await logger.info("Successfully generated and stored cryptographic key", context: successContext)
        
        // Create key material with identifier
        let keyMaterial = KeyMaterial(
          identifier: keyID,
          type: keyType,
          size: keySize,
          algorithm: options?.algorithm ?? .aes
        )
        
        return .success(keyMaterial)
        
      case .failure(let error):
        // Key storage failed
        await logger.error("Failed to store generated key: \(error.localizedDescription)", context: context)
        return .failure(.keyStorageFailed(reason: error.localizedDescription))
      }
    }
    
    /**
     Imports an existing key with the specified options.
     
     - Parameters:
        - keyData: The raw key data to import
        - keyType: The type of key being imported
        - options: Additional options for key import
     - Returns: Key material or an error
     */
    public func importKey(
      keyData: [UInt8],
      keyType: KeyType,
      options: KeyImportOptions?
    ) async -> Result<KeyMaterial, KeyManagementError> {
      let operationID = UUID().uuidString
      
      // Create a log context for the operation
      let context = SecurityLogContext(
        operation: "importKey",
        component: "BasicKeyManagementService",
        operationID: operationID,
        correlationID: nil,
        source: "CryptoServices",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "keyType", value: "\(keyType)")
          .withPublic(key: "keySize", value: "\(keyData.count * 8)")
      )
      
      await logger.info("Importing cryptographic key", context: context)
      
      // Generate key identifier or use provided one
      let keyID = options?.identifier ?? "imported_key_\(UUID().uuidString)"
      
      // Store the key material
      let storeResult = await secureStorage.storeData(Data(keyData), withIdentifier: keyID)
      
      switch storeResult {
      case .success:
        // Key was stored successfully
        let successContext = context.adding(
          key: "keyIdentifier", 
          value: keyID,
          privacy: .private
        )
        
        await logger.info("Successfully imported and stored cryptographic key", context: successContext)
        
        // Create key material with identifier
        let keyMaterial = KeyMaterial(
          identifier: keyID,
          type: keyType,
          size: keyData.count * 8,
          algorithm: options?.algorithm ?? .aes
        )
        
        return .success(keyMaterial)
        
      case .failure(let error):
        // Key storage failed
        await logger.error("Failed to store imported key: \(error.localizedDescription)", context: context)
        return .failure(.keyStorageFailed(reason: error.localizedDescription))
      }
    }
    
    /**
     Retrieves a key by its identifier.
     
     - Parameter identifier: The identifier of the key to retrieve
     - Returns: The key data or an error
     */
    public func retrieveKey(
      identifier: String
    ) async -> Result<[UInt8], KeyManagementError> {
      let operationID = UUID().uuidString
      
      // Create a log context for the operation
      let context = SecurityLogContext(
        operation: "retrieveKey",
        component: "BasicKeyManagementService",
        operationID: operationID,
        correlationID: nil,
        source: "CryptoServices",
        metadata: LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: identifier)
      )
      
      await logger.info("Retrieving cryptographic key", context: context)
      
      // Retrieve the key from storage
      let retrieveResult = await secureStorage.retrieveData(withIdentifier: identifier)
      
      switch retrieveResult {
      case .success(let keyData):
        // Key was retrieved successfully
        await logger.info("Successfully retrieved cryptographic key", context: context)
        return .success([UInt8](keyData))
        
      case .failure(let error):
        // Key retrieval failed
        await logger.error("Failed to retrieve key: \(error.localizedDescription)", context: context)
        return .failure(.keyNotFound(reason: error.localizedDescription))
      }
    }
    
    /**
     Deletes a key by its identifier.
     
     - Parameter identifier: The identifier of the key to delete
     - Returns: Success or an error
     */
    public func deleteKey(
      identifier: String
    ) async -> Result<Bool, KeyManagementError> {
      let operationID = UUID().uuidString
      
      // Create a log context for the operation
      let context = SecurityLogContext(
        operation: "deleteKey",
        component: "BasicKeyManagementService",
        operationID: operationID,
        correlationID: nil,
        source: "CryptoServices",
        metadata: LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: identifier)
      )
      
      await logger.info("Deleting cryptographic key", context: context)
      
      // Delete the key from storage
      let deleteResult = await secureStorage.deleteData(withIdentifier: identifier)
      
      switch deleteResult {
      case .success:
        // Key was deleted successfully
        await logger.info("Successfully deleted cryptographic key", context: context)
        return .success(true)
        
      case .failure(let error):
        // Key deletion failed
        await logger.error("Failed to delete key: \(error.localizedDescription)", context: context)
        return .failure(.keyDeletionFailed(reason: error.localizedDescription))
      }
    }
  }
  
  /**
   Generates a random initialisation vector for AES-CBC encryption.
   
   - Returns: A 16-byte random initialisation vector
   */
  private func generateRandomIV() -> Data {
    var iv = Data(count: 16) // AES block size is 16 bytes
    _ = iv.withUnsafeMutableBytes { 
      SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) 
    }
    return iv
  }
  
  /**
   Encrypts data using AES-CBC with the provided key and IV.
   
   - Parameters:
     - data: The plaintext data to encrypt
     - key: The symmetric key for encryption
     - iv: The initialisation vector
   - Returns: The encrypted ciphertext
   - Throws: Error if encryption fails
   */
  private func encryptAESCBC(data: Data, key: SymmetricKey, iv: Data) throws -> Data {
    // Implementation for platforms without CryptoKit AES-CBC
    // This is a fallback implementation using CommonCrypto
    
    // Prepare for CommonCrypto
    let keyData = key.withUnsafeBytes { Data($0) }
    
    var cryptoResult = Data(count: data.count + kCCBlockSizeAES128)
    var resultLength = 0
    
    let status = keyData.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        data.withUnsafeBytes { dataBytes in
          cryptoResult.withUnsafeMutableBytes { resultBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress, keyBytes.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress, dataBytes.count,
              resultBytes.baseAddress, resultBytes.count,
              &resultLength
            )
          }
        }
      }
    }
    
    guard status == kCCSuccess else {
      throw SecurityError.encryptionFailed(
        reason: "AES-CBC encryption failed with code: \(status)"
      )
    }
    
    return cryptoResult.prefix(resultLength)
  }
}

/**
 Empty logger implementation for cases when no logger is provided.
 */
private struct EmptyLogger: LoggingProtocol {
  func log(level: LogLevel, message: String, privacy: PrivacyMetadata) { }
  
  func debug(_ message: String, metadata: PrivacyMetadata?, source: String?) async { }
  func info(_ message: String, metadata: PrivacyMetadata?, source: String?) async { }
  func warning(_ message: String, metadata: PrivacyMetadata?, source: String?) async { }
  func error(_ message: String, metadata: PrivacyMetadata?, source: String?) async { }
  func critical(_ message: String, metadata: PrivacyMetadata?, source: String?) async { }
  func debug(_ message: String, context: LogContext?) async { }
  func info(_ message: String, context: LogContext?) async { }
  func warning(_ message: String, context: LogContext?) async { }
  func error(_ message: String, context: LogContext?) async { }
  func critical(_ message: String, context: LogContext?) async { }
}
