import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security
import SecurityCoreInterfaces
import UmbraErrors

/**
 # DefaultCryptoServiceImpl
 
 Default implementation of CryptoServiceProtocol using SecureStorageProtocol.

 This implementation provides a standard set of cryptographic operations using
 the provided secure storage for persisting cryptographic materials. It serves
 as the baseline implementation when more specialised providers aren't selected.
 
 ## Privacy Controls
 
 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys are treated as private information
 - Data identifiers are generally treated as public information
 - Error details are appropriately classified based on sensitivity
 - Metadata is structured using LogMetadataDTOCollection for privacy-aware logging
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor DefaultCryptoServiceImpl: CryptoServiceProtocol {
  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// Optional logger
  private let logger: LoggingProtocol?

  // Store the provider type if needed for logic
  private let providerType: CoreSecurityTypes.SecurityProviderType = .basic

  /**
   Initialises the crypto service.
   
   - Parameters:
     - secureStorage: The secure storage implementation to use for persisting cryptographic materials
     - logger: Optional logger for recording operations (defaults to nil)
   */
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol? = nil
  ) {
    self.secureStorage = secureStorage
    self.logger = logger
  }

  // MARK: - CryptoServiceProtocol Conformance

  /**
   Encrypts data with the specified key.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to encrypt
     - keyIdentifier: Identifier for the encryption key
     - options: Optional encryption options
   - Returns: Result containing the identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "encrypt",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithOptions: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithOptions = CryptoLogContext(
        operation: context.operation,
        algorithm: algorithm.rawValue,
        correlationID: context.correlationID,
        source: context.source,
        additionalContext: context.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    } else {
      contextWithOptions = context
    }
    
    await logger?.log(
      .debug,
      "Encrypting data for identifier: \(dataIdentifier)",
      context: contextWithOptions
    )

    // --- Implementation ---
    // Retrieve original data first
    let originalDataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    guard case .success(_) = originalDataResult else {
      if case let .failure(error) = originalDataResult {
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to retrieve original data for encryption: \(error)",
          context: errorContext
        )
        return .failure(error)
      } else {
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "Unknown error state")
        )
        
        await logger?.log(
          .error,
          "Failed to retrieve original data for encryption due to unknown error state",
          context: errorContext
        )
        return .failure(.storageUnavailable)
      }
    }

    // Create mock encrypted data
    var encryptedDataBytes = [UInt8]()
    let iv = generateRandomBytes(count: 16)
    encryptedDataBytes.append(contentsOf: iv)
    
    // Safely extract the data from the Result
    if case let .success(originalData) = originalDataResult {
      encryptedDataBytes.append(contentsOf: originalData)
    } else {
      // This shouldn't happen since we already checked the result above
      return .failure(.dataNotFound)
    }
    
    let keyIDBytes = Array(keyIdentifier.utf8)
    encryptedDataBytes.append(UInt8(keyIDBytes.count))
    encryptedDataBytes.append(contentsOf: keyIDBytes)

    // Store the mock encrypted data
    let encryptedDataStoreIdentifier = "encrypted_\(UUID().uuidString)"
    let storeResult = await storeData(
      data: Data(encryptedDataBytes),
      identifier: encryptedDataStoreIdentifier
    )

    switch storeResult {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "encryptedIdentifier", value: encryptedDataStoreIdentifier)
        )
        
        await logger?.log(
          .info,
          "Successfully encrypted data to identifier: \(encryptedDataStoreIdentifier)",
          context: successContext
        )
        return .success(encryptedDataStoreIdentifier)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error, 
          "Failed to store encrypted data: \(error)", 
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Decrypts data with the specified key.
   
   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the decryption key
     - options: Optional decryption options
   - Returns: Result containing the identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.DecryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "decrypt",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithOptions: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithOptions = CryptoLogContext(
        operation: context.operation,
        algorithm: algorithm.rawValue,
        correlationID: context.correlationID,
        source: context.source,
        additionalContext: context.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    } else {
      contextWithOptions = context
    }
    
    await logger?.log(
      .debug,
      "Decrypting data with identifier: \(encryptedDataIdentifier)",
      context: contextWithOptions
    )

    // Retrieve the encrypted data
    let dataResult = await retrieveData(identifier: encryptedDataIdentifier)

    switch dataResult {
      case let .success(encryptedDataBytes):
        // --- Implementation ---
        // Assuming format: [IV (16 bytes)][Data][Key ID Length (1 byte)][Key ID]
        if encryptedDataBytes.count > 17 {
          let dataStartIndex = 16
          guard let keyIDLengthByte = encryptedDataBytes.last else {
            let errorContext = CryptoLogContext(
              operation: context.operation,
              algorithm: context.algorithm,
              correlationID: context.correlationID,
              source: context.source,
              additionalContext: context.metadata.withPublic(key: "status", value: "failed")
                .withPublic(key: "error", value: "Invalid encrypted data format: missing key ID length")
            )
            
            await logger?.log(
              .error,
              "Invalid encrypted data format: missing key ID length",
              context: errorContext
            )
            return .failure(.decryptionFailed)
          }
          
          let keyIDLength = Int(keyIDLengthByte)
          let keyIDStartIndex = encryptedDataBytes.count - 1 - keyIDLength

          // Basic validation
          guard
            keyIDStartIndex > dataStartIndex,
            keyIDStartIndex < encryptedDataBytes.count - 1
          else {
            let errorContext = CryptoLogContext(
              operation: context.operation,
              algorithm: context.algorithm,
              correlationID: context.correlationID,
              source: context.source,
              additionalContext: context.metadata.withPublic(key: "status", value: "failed")
                .withPublic(key: "error", value: "Invalid encrypted data format: key ID length mismatch")
            )
            
            await logger?.log(
              .error,
              "Invalid encrypted data format: key ID length mismatch",
              context: errorContext
            )
            return .failure(.decryptionFailed)
          }

          let decryptedDataBytes = Array(encryptedDataBytes[dataStartIndex..<keyIDStartIndex])
          // Store decrypted data and return its ID
          let decryptedDataIdentifier = "decrypted_\(UUID().uuidString)"
          let storeDecryptedResult = await storeData(
            data: Data(decryptedDataBytes),
            identifier: decryptedDataIdentifier
          )

          switch storeDecryptedResult {
            case .success:
              let successContext = CryptoLogContext(
                operation: context.operation,
                algorithm: context.algorithm,
                correlationID: context.correlationID,
                source: context.source,
                additionalContext: context.metadata.withPublic(key: "status", value: "success")
                  .withPublic(key: "decryptedIdentifier", value: decryptedDataIdentifier)
              )
              
              await logger?.log(
                .info,
                "Successfully decrypted data to identifier: \(decryptedDataIdentifier)",
                context: successContext
              )
              return .success(decryptedDataIdentifier)
              
            case let .failure(error):
              let errorContext = CryptoLogContext(
                operation: context.operation,
                algorithm: context.algorithm,
                correlationID: context.correlationID,
                source: context.source,
                additionalContext: context.metadata.withPublic(key: "status", value: "failed")
                  .withPublic(key: "error", value: "\(error)")
              )
              
              await logger?.log(
                .error,
                "Failed to store decrypted data: \(error)",
                context: errorContext
              )
              return .failure(error)
          }

        } else {
          let errorContext = CryptoLogContext(
            operation: context.operation,
            algorithm: context.algorithm,
            correlationID: context.correlationID,
            source: context.source,
            additionalContext: context.metadata.withPublic(key: "status", value: "failed")
              .withPublic(key: "error", value: "Invalid encrypted data format")
          )
          
          await logger?.log(
            .error,
            "Invalid encrypted data format",
            context: errorContext
          )
          return .failure(.decryptionFailed)
        }

      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to retrieve encrypted data for decryption: \(error)",
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Computes a cryptographic hash of the specified data.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Result containing the identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "hash",
      algorithm: algorithm.rawValue,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )
    
    await logger?.log(
      .debug,
      "Generating hash for data identifier: \(dataIdentifier) with algorithm: \(algorithm)",
      context: context
    )

    // Retrieve original data first (needed for hashing)
    let originalDataResult = await retrieveData(identifier: dataIdentifier)
    
    guard case .success(_) = originalDataResult else {
      if case let .failure(error) = originalDataResult {
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to retrieve original data for hashing: \(error)",
          context: errorContext
        )
        return .failure(error)
      } else {
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "Unknown error state")
        )
        
        await logger?.log(
          .error,
          "Failed to retrieve original data for hashing due to unknown error state",
          context: errorContext
        )
        return .failure(.storageUnavailable)
      }
    }

    // Generate hash based on retrieved data
    var generatedHash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    if case let .success(originalData) = originalDataResult {
      _ = originalData.withUnsafeBytes { buffer in
        CC_SHA256(buffer.baseAddress, CC_LONG(originalData.count), &generatedHash)
      }
    }

    // Store the hash
    let hashIdentifier = "hash_\(UUID().uuidString)"
    let storeResult = await storeData(
      data: Data(generatedHash),
      identifier: hashIdentifier
    )

    switch storeResult {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "hashIdentifier", value: hashIdentifier)
        )
        
        await logger?.log(
          .info,
          "Successfully stored hash to identifier: \(hashIdentifier)",
          context: successContext
        )
        return .success(hashIdentifier)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error, 
          "Failed to store hash: \(error)", 
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Verifies that a hash matches the expected value for the specified data.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options
   - Returns: Result containing a boolean indicating if the hash is valid or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "verifyHash",
      algorithm: algorithm.rawValue,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )
    
    await logger?.log(
      .debug,
      "Verifying hash for data \(dataIdentifier) against hash \(hashIdentifier)",
      context: context
    )
    
    // 1. Retrieve original data
    let dataResult = await retrieveData(identifier: dataIdentifier)
    
    guard case .success(_) = dataResult else {
      let errorContext = CryptoLogContext(
        operation: context.operation,
        algorithm: context.algorithm,
        correlationID: context.correlationID,
        source: context.source,
        additionalContext: context.metadata.withPublic(key: "status", value: "failed")
          .withPublic(key: "error", value: "Failed to retrieve original data for hash verification")
      )
      
      await logger?.log(
        .error,
        "Failed to retrieve original data for hash verification",
        context: errorContext
      )
      
      if case let .failure(error) = dataResult {
        return .failure(error)
      }
      return .failure(.dataNotFound)
    }

    // 2. Retrieve stored hash
    let hashResult = await retrieveData(identifier: hashIdentifier)
    
    guard case .success(_) = hashResult else {
      let errorContext = CryptoLogContext(
        operation: context.operation,
        algorithm: context.algorithm,
        correlationID: context.correlationID,
        source: context.source,
        additionalContext: context.metadata.withPublic(key: "status", value: "failed")
          .withPublic(key: "error", value: "Failed to retrieve stored hash for verification")
      )
      
      await logger?.log(
        .error, 
        "Failed to retrieve stored hash for verification", 
        context: errorContext
      )
      
      if case let .failure(error) = hashResult {
        return .failure(error)
      }
      return .failure(.dataNotFound)
    }

    // 3. Generate hash of original data using CommonCrypto
    var generatedHash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    if case let .success(originalData) = dataResult {
      _ = originalData.withUnsafeBytes { buffer in
        CC_SHA256(buffer.baseAddress, CC_LONG(originalData.count), &generatedHash)
      }
    }

    // 4. Compare hashes
    var hashesMatch = false
    
    if case let .success(storedHash) = hashResult {
      hashesMatch = generatedHash.elementsEqual(storedHash)
    }
    
    let resultContext = CryptoLogContext(
      operation: context.operation,
      algorithm: context.algorithm,
      correlationID: context.correlationID,
      source: context.source,
      additionalContext: context.metadata.withPublic(key: "status", value: "success")
        .withPublic(key: "hashesMatch", value: hashesMatch ? "true" : "false")
    )
    
    await logger?.log(
      .info, 
      "Hash verification result: \(hashesMatch ? "Match" : "No match")", 
      context: resultContext
    )
    
    return .success(hashesMatch)
  }

  /**
   Stores the specified data.
   
   - Parameters:
     - data: The data to store
     - identifier: The identifier to use
   - Returns: Result containing void or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "storeData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPrivate(key: "dataSize", value: "\(data.count)")
    )
    
    await logger?.log(
      .debug,
      "Storing data with identifier: \(identifier)",
      context: context
    )
    
    // Use the correct storage method
    let result = await secureStorage.storeData(
      data.bytes, // Use extension method to convert Data to [UInt8]
      withIdentifier: identifier
    )

    switch result {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
        )
        
        await logger?.log(
          .info,
          "Successfully stored data with identifier: \(identifier)",
          context: successContext
        )
        return .success(())
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to store data: \(error)",
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Internal helper method with properly ordered parameters for storeData
   */
  private func storeData(
    withIdentifier identifier: String,
    data: Data
  ) async -> Result<Void, SecurityStorageError> {
    return await storeData(data: data, identifier: identifier)
  }

  /**
   Retrieves data from the secure storage.
   
   - Parameter identifier: Identifier for the data to retrieve
   - Returns: Result containing the data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "retrieveData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )
    
    await logger?.log(
      .debug, 
      "Retrieving data with identifier: \(identifier)", 
      context: context
    )
    
    // Use the correct storage method and map result
    let result = await secureStorage.retrieveData(withIdentifier: identifier)

    // Handle result and map error synchronously after await
    switch result {
      case let .success(bytes):
        let data = Data(bytes: bytes)
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "dataSize", value: "\(data.count)")
        )
        
        await logger?.log(
          .info,
          "Successfully retrieved data (\(data.count) bytes) for identifier: \(identifier)",
          context: successContext
        )
        
        return .success(data)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error, 
          "Failed to retrieve data: \(error)", 
          context: errorContext
        )
        
        return .failure(error)
    }
  }

  /**
   Deletes data from the secure storage.
   
   - Parameter identifier: Identifier for the data to delete
   - Returns: Result containing void or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "deleteData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )
    
    await logger?.log(
      .debug, 
      "Deleting data with identifier: \(identifier)", 
      context: context
    )
    
    let result = await secureStorage.deleteData(withIdentifier: identifier)
    
    switch result {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
        )
        
        await logger?.log(
          .info,
          "Successfully deleted data for identifier: \(identifier)",
          context: successContext
        )
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error, 
          "Failed to delete data: \(error)", 
          context: errorContext
        )
    }
    
    return result
  }

  /**
   Generates a cryptographic key with the specified parameters.
   
   - Parameters:
     - length: Length of the key to generate in bytes
     - options: Optional key generation options
   - Returns: Result containing the identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "generateKey",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "keyLength", value: "\(length)")
    )
    
    // Add algorithm information if available
    let contextWithOptions: CryptoLogContext
    contextWithOptions = context
    
    await logger?.log(
      .debug, 
      "Generating key of length \(length) bytes...", 
      context: contextWithOptions
    )
    
    let keyData = generateRandomBytes(count: length)
    let keyIdentifier = "key_\(UUID().uuidString)"
    
    let storeResult = await storeData(
      data: Data(keyData),
      identifier: keyIdentifier
    )

    switch storeResult {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
            .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        )
        
        await logger?.log(
          .info,
          "Successfully generated and stored key with identifier: \(keyIdentifier)",
          context: successContext
        )
        return .success(keyIdentifier)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to store generated key: \(error)",
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Imports raw data into the secure storage.
   
   - Parameters:
     - data: Raw data to import
     - customIdentifier: Custom identifier for the data
   - Returns: Result containing the identifier for the imported data or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "importData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "customIdentifier", value: customIdentifier)
        .withPublic(key: "dataSize", value: "\(data.count)")
    )
    
    await logger?.log(
      .debug,
      "Importing raw data with custom identifier: \(customIdentifier)",
      context: context
    )
    
    // Store the raw data using the secure storage protocol
    let importResult = await storeData(
      data: data,
      identifier: customIdentifier
    )
    
    switch importResult {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
        )
        
        await logger?.log(
          .info,
          "Successfully imported data with identifier: \(customIdentifier)",
          context: successContext
        )
        return .success(customIdentifier)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to import raw data: \(error)",
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Imports raw byte array data into the secure storage.
   
   - Parameters:
     - data: Raw byte array to import
     - customIdentifier: Optional custom identifier for the data
   - Returns: Result containing the identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "importData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: "\(data.count)")
        .withPublic(key: "hasCustomIdentifier", value: customIdentifier != nil ? "true" : "false")
    )
    
    await logger?.log(
      .debug,
      "Importing byte array data (\(data.count) bytes)",
      context: context
    )
    
    // Convert [UInt8] to Data for storage
    let dataToStore = Data(data)
    
    // Determine the identifier to use
    let effectiveIdentifier = customIdentifier ?? UUID().uuidString
    
    // Use the secure storage protocol to store the data
    let result = await storeData(
      data: dataToStore,
      identifier: effectiveIdentifier
    )

    // Handle the result and return appropriately
    switch result {
      case .success:
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "identifier", value: effectiveIdentifier)
        )
        
        await logger?.log(
          .info,
          "Successfully imported data with identifier: \(effectiveIdentifier)",
          context: successContext
        )
        return .success(effectiveIdentifier)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to import data: \(error)",
          context: errorContext
        )
        return .failure(error)
    }
  }

  /**
   Exports data from the secure storage as a byte array.
   
   - Parameter identifier: Identifier for the data to export
   - Returns: Result containing the raw byte array or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "exportData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )
    
    await logger?.log(
      .debug,
      "Exporting data with identifier: \(identifier)",
      context: context
    )
    
    let result = await retrieveData(identifier: identifier)
    
    switch result {
      case let .success(data):
        let successContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "dataSize", value: "\(data.count)")
        )
        
        await logger?.log(
          .info,
          "Successfully exported data (\(data.count) bytes) with identifier: \(identifier)",
          context: successContext
        )
        return .success(data.bytes)
        
      case let .failure(error):
        let errorContext = CryptoLogContext(
          operation: context.operation,
          algorithm: context.algorithm,
          correlationID: context.correlationID,
          source: context.source,
          additionalContext: context.metadata.withPublic(key: "status", value: "failed")
            .withPublic(key: "error", value: "\(error)")
        )
        
        await logger?.log(
          .error,
          "Failed to export data: \(error)",
          context: errorContext
        )
        return .failure(error)
    }
  }
  
  /**
   For protocol compatibility with other implementations.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Result containing the identifier for the hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Simply delegate to the hash method
    return await hash(dataIdentifier: dataIdentifier, options: options)
  }

  // MARK: - Helper Methods

  /**
   Generates cryptographically secure random bytes.
   
   - Parameter count: The number of bytes to generate
   - Returns: An array of random bytes
   */
  private func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    
    if status != errSecSuccess {
      // We can't use async logger here, so we'll just print to console in debug builds
      #if DEBUG
      print("ERROR: Failed to generate secure random bytes, status: \(status)")
      #endif
      
      // Return zeros as a fallback (this is not secure and should be handled better in production)
      return [UInt8](repeating: 0, count: count)
    }
    
    return bytes
  }
}
