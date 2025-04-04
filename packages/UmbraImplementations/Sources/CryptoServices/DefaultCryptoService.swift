import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/**
 # DefaultCryptoServiceImpl

 Default implementation of the CryptoServiceProtocol following the Alpha Dot Five
 architecture principles. This implementation provides robust cryptographic operations
 with proper error handling and privacy controls.

 ## Security Features

 * Actor-based isolation for thread safety
 * Privacy-aware logging of cryptographic operations
 * Structured error handling with domain-specific errors
 * No plaintext secrets in logs

 ## Usage Example

 ```swift
 let cryptoService = await CryptoServiceFactory.createDefault()

 // Encrypt data
 let result = await cryptoService.encrypt(data: myData, using: myKey)
 switch result {
 case .success(let encryptedData):
     // Process encrypted data
 case .failure(let error):
     // Handle error with proper privacy controls
 }
 ```
 */
public actor DefaultCryptoServiceImpl: CryptoServiceProtocol {
  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol
  
  /// Standard logger for general operations
  private let logger: LoggingProtocol

  /// Secure logger for privacy-aware logging
  private let secureLogger: SecureLoggerActor

  /**
   Initialise a new crypto service with required secure storage and optional loggers.

   - Parameters:
      - secureStorage: The secure storage implementation to use
      - logger: Optional logger for operations (a default will be created if nil)
      - secureLogger: Optional secure logger for privacy-aware operations (will be created if nil)
   */
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil,
    secureLogger: SecureLoggerActor?=nil
  ) {
    self.secureStorage = secureStorage
    self.logger=logger ?? DefaultLogger()
    self.secureLogger=secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.crypto",
      category: "CryptoOperations",
      includeTimestamps: true
    )
  }

  /**
   Encrypts data using the provided key.

   - Parameters:
     - data: Raw data to encrypt as byte array
     - key: Encryption key as byte array
   - Returns: Result containing encrypted data or an error
   */
  public func encrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "encrypt",
      algorithm: "aes",
      metadata: [
        "dataSize": "\(data.count)",
        "keySize": "\(key.count)"
      ]
    )

    await logger.debug("Starting encryption", context: context)

    // Log with secure logger for enhanced privacy
    await secureLogger.securityEvent(
      action: "Encryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "aes", privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    do {
      // Basic validation
      guard !data.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Data to encrypt cannot be empty")
        await logger.error("Encryption failed: empty data", context: context)
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_data", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      guard !key.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Encryption key cannot be empty")
        await logger.error("Encryption failed: empty key", context: context)
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_key", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      // Perform AES encryption (simplified example)
      // In a real implementation, this would use a cryptographic library
      let encryptedData=try performEncryption(data: data, key: key)

      // Log success
      await logger.info("Encryption completed successfully", context: context)
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: encryptedData.count, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
        ]
      )

      return .success(encryptedData)
    } catch {
      let securityError=mapToSecurityError(error)
      await logger.error(
        "Encryption failed: \(securityError.localizedDescription)",
        context: context
      )
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: securityError.localizedDescription,
                                      privacyLevel: .public),
          "errorCode": PrivacyTaggedValue(value: String(describing: securityError),
                                          privacyLevel: .public)
        ]
      )
      return .failure(securityError)
    }
  }

  /**
   Decrypts data using the provided key.

   - Parameters:
     - data: Encrypted data as byte array
     - key: Decryption key as byte array
   - Returns: Result containing decrypted data or an error
   */
  public func decrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "decrypt",
      algorithm: "aes",
      metadata: [
        "dataSize": "\(data.count)",
        "keySize": "\(key.count)"
      ]
    )

    await logger.debug("Starting decryption", context: context)
    await secureLogger.securityEvent(
      action: "Decryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "aes", privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    do {
      // Basic validation
      guard !data.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Data to decrypt cannot be empty")
        await logger.error("Decryption failed: empty data", context: context)
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_data", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      guard !key.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Decryption key cannot be empty")
        await logger.error("Decryption failed: empty key", context: context)
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_key", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      // Perform AES decryption (simplified example)
      // In a real implementation, this would use a cryptographic library
      let decryptedData=try performDecryption(data: data, key: key)

      // Log success
      await logger.info("Decryption completed successfully", context: context)
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: decryptedData.count, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
        ]
      )

      return .success(decryptedData)
    } catch {
      let securityError=mapToSecurityError(error)
      await logger.error(
        "Decryption failed: \(securityError.localizedDescription)",
        context: context
      )
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: securityError.localizedDescription,
                                      privacyLevel: .public),
          "errorCode": PrivacyTaggedValue(value: String(describing: securityError),
                                          privacyLevel: .public)
        ]
      )
      return .failure(securityError)
    }
  }

  /**
   Calculates a cryptographic hash of the provided data.

   - Parameter data: Data to hash
   - Returns: Result containing hash or an error
   */
  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "hash",
      algorithm: "sha256",
      metadata: [
        "dataSize": "\(data.count)"
      ]
    )

    await logger.debug("Starting hash calculation", context: context)
    await secureLogger.securityEvent(
      action: "Hash",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "sha256", privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    // Basic validation
    guard !data.isEmpty else {
      let error=SecurityProtocolError.invalidInput("Data to hash cannot be empty")
      await logger.error("Hashing failed: empty data", context: context)
      await secureLogger.securityEvent(
        action: "Hash",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: "empty_data", privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
        ]
      )
      return .failure(error)
    }

    do {
      // Perform SHA-256 hashing (simplified example)
      // In a real implementation, this would use a cryptographic library
      let hashResult=try performHashing(data: data)

      // Log success
      await logger.info("Hash calculation completed successfully", context: context)
      await secureLogger.securityEvent(
        action: "Hash",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
          "hashSize": PrivacyTaggedValue(value: hashResult.count, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
        ]
      )

      return .success(hashResult)
    } catch {
      let securityError=mapToSecurityError(error)
      await logger.error(
        "Hash calculation failed: \(securityError.localizedDescription)",
        context: context
      )
      await secureLogger.securityEvent(
        action: "Hash",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: securityError.localizedDescription,
                                      privacyLevel: .public),
          "errorCode": PrivacyTaggedValue(value: String(describing: securityError),
                                          privacyLevel: .public)
        ]
      )
      return .failure(securityError)
    }
  }

  /**
   Verifies that a hash matches the expected value for the given data.

   - Parameters:
     - data: Original data
     - expectedHash: Expected hash value
   - Returns: Result with true if verified, false if not matching, or an error
   */
  public func verifyHash(
    data: [UInt8],
    matches expectedHash: [UInt8]
  ) async -> Result<Bool, SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "verifyHash",
      algorithm: "sha256",
      metadata: [
        "dataSize": "\(data.count)",
        "hashSize": "\(expectedHash.count)"
      ]
    )

    await logger.debug("Starting hash verification", context: context)
    await secureLogger.securityEvent(
      action: "HashVerification",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "hashSize": PrivacyTaggedValue(value: expectedHash.count, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    // Calculate hash first
    let hashResult=await hash(data: data)

    switch hashResult {
      case let .success(calculatedHash):
        // Compare hashes
        let verified=(calculatedHash == expectedHash)

        // Log result
        if verified {
          await logger.info("Hash verification succeeded", context: context)
          await secureLogger.securityEvent(
            action: "HashVerification",
            status: .success,
            subject: nil,
            resource: nil,
            additionalMetadata: [
              "result": PrivacyTaggedValue(value: "verified", privacyLevel: .public),
              "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
            ]
          )
        } else {
          await logger.warning("Hash verification failed: hashes don't match", context: context)
          await secureLogger.securityEvent(
            action: "HashVerification",
            status: .failed,
            subject: nil,
            resource: nil,
            additionalMetadata: [
              "result": PrivacyTaggedValue(value: "mismatch", privacyLevel: .public),
              "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
            ]
          )
        }

        return .success(verified)

      case let .failure(error):
        await logger.error(
          "Hash verification failed: \(error.localizedDescription)",
          context: context
        )
        await secureLogger.securityEvent(
          action: "HashVerification",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
            "errorCode": PrivacyTaggedValue(value: String(describing: error), privacyLevel: .public)
          ]
        )
        return .failure(error)
    }
  }

  // MARK: - CryptoServiceProtocol Implementation
  
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
  ) async -> Result<String, SecurityStorageError> {
    // First retrieve the data to encrypt
    let dataResult = await secureStorage.retrieveData(with: dataIdentifier)
    guard case .success(let data) = dataResult else {
      if case .failure(let error) = dataResult {
        return .failure(.storageFailed(reason: "Failed to retrieve data: \(error.localizedDescription)"))
      }
      return .failure(.dataNotFound(identifier: dataIdentifier))
    }
    
    // Retrieve the encryption key
    let keyResult = await secureStorage.retrieveData(with: keyIdentifier)
    guard case .success(let keyData) = keyResult else {
      if case .failure(let error) = keyResult {
        return .failure(.storageFailed(reason: "Failed to retrieve key: \(error.localizedDescription)"))
      }
      return .failure(.keyNotFound(identifier: keyIdentifier))
    }
    
    // Use the existing encryption implementation
    let encryptionResult = await encrypt(data: [UInt8](data), key: [UInt8](keyData))
    
    switch encryptionResult {
    case .success(let encryptedData):
      // Store the encrypted result and return the identifier
      let resultIdentifier = "encrypted_\(UUID().uuidString)"
      let storeResult = await secureStorage.storeData(Data(encryptedData), with: resultIdentifier)
      
      switch storeResult {
      case .success:
        return .success(resultIdentifier)
      case .failure(let error):
        return .failure(.storageFailed(reason: "Failed to store encrypted data: \(error.localizedDescription)"))
      }
      
    case .failure(let error):
      return .failure(.operationFailed(reason: "Encryption failed: \(error.localizedDescription)"))
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
  ) async -> Result<String, SecurityStorageError> {
    // First retrieve the encrypted data
    let dataResult = await secureStorage.retrieveData(with: encryptedDataIdentifier)
    guard case .success(let encryptedData) = dataResult else {
      if case .failure(let error) = dataResult {
        return .failure(.storageFailed(reason: "Failed to retrieve encrypted data: \(error.localizedDescription)"))
      }
      return .failure(.dataNotFound(identifier: encryptedDataIdentifier))
    }
    
    // Retrieve the decryption key
    let keyResult = await secureStorage.retrieveData(with: keyIdentifier)
    guard case .success(let keyData) = keyResult else {
      if case .failure(let error) = keyResult {
        return .failure(.storageFailed(reason: "Failed to retrieve key: \(error.localizedDescription)"))
      }
      return .failure(.keyNotFound(identifier: keyIdentifier))
    }
    
    // Use the existing decryption implementation
    let decryptionResult = await decrypt(data: [UInt8](encryptedData), key: [UInt8](keyData))
    
    switch decryptionResult {
    case .success(let decryptedData):
      // Store the decrypted result and return the identifier
      let resultIdentifier = "decrypted_\(UUID().uuidString)"
      let storeResult = await secureStorage.storeData(Data(decryptedData), with: resultIdentifier)
      
      switch storeResult {
      case .success:
        return .success(resultIdentifier)
      case .failure(let error):
        return .failure(.storageFailed(reason: "Failed to store decrypted data: \(error.localizedDescription)"))
      }
      
    case .failure(let error):
      return .failure(.operationFailed(reason: "Decryption failed: \(error.localizedDescription)"))
    }
  }
  
  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // First retrieve the data to hash
    let dataResult = await secureStorage.retrieveData(with: dataIdentifier)
    guard case .success(let data) = dataResult else {
      if case .failure(let error) = dataResult {
        return .failure(.storageFailed(reason: "Failed to retrieve data: \(error.localizedDescription)"))
      }
      return .failure(.dataNotFound(identifier: dataIdentifier))
    }
    
    // Use the existing hash implementation
    let hashResult = await hash(data: [UInt8](data))
    
    switch hashResult {
    case .success(let hashedData):
      // Store the hashed result and return the identifier
      let resultIdentifier = "hash_\(UUID().uuidString)"
      let storeResult = await secureStorage.storeData(Data(hashedData), with: resultIdentifier)
      
      switch storeResult {
      case .success:
        return .success(resultIdentifier)
      case .failure(let error):
        return .failure(.storageFailed(reason: "Failed to store hash: \(error.localizedDescription)"))
      }
      
    case .failure(let error):
      return .failure(.operationFailed(reason: "Hashing failed: \(error.localizedDescription)"))
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
  ) async -> Result<Bool, SecurityStorageError> {
    // First retrieve the data to verify
    let dataResult = await secureStorage.retrieveData(with: dataIdentifier)
    guard case .success(let data) = dataResult else {
      if case .failure(let error) = dataResult {
        return .failure(.storageFailed(reason: "Failed to retrieve data: \(error.localizedDescription)"))
      }
      return .failure(.dataNotFound(identifier: dataIdentifier))
    }
    
    // Retrieve the expected hash
    let hashResult = await secureStorage.retrieveData(with: hashIdentifier)
    guard case .success(let expectedHash) = hashResult else {
      if case .failure(let error) = hashResult {
        return .failure(.storageFailed(reason: "Failed to retrieve hash: \(error.localizedDescription)"))
      }
      return .failure(.dataNotFound(identifier: hashIdentifier))
    }
    
    // Hash the provided data
    let computedHashResult = await hash(data: [UInt8](data))
    guard case .success(let computedHash) = computedHashResult else {
      if case .failure(let error) = computedHashResult {
        return .failure(.operationFailed(reason: "Hash computation failed: \(error.localizedDescription)"))
      }
      return .failure(.operationFailed(reason: "Unknown hash computation error"))
    }
    
    // Compare the hashes
    let verified = expectedHash == Data(computedHash)
    return .success(verified)
  }
  
  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Generate random bytes for the key
    var keyData = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, keyData.count, &keyData)
    
    if status != errSecSuccess {
      return .failure(.operationFailed(reason: "Failed to generate random key: \(status)"))
    }
    
    // Store the generated key
    let keyIdentifier = "key_\(UUID().uuidString)"
    let storeResult = await secureStorage.storeData(Data(keyData), with: keyIdentifier)
    
    switch storeResult {
    case .success:
      return .success(keyIdentifier)
    case .failure(let error):
      return .failure(.storageFailed(reason: "Failed to store generated key: \(error.localizedDescription)"))
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
  ) async -> Result<String, SecurityStorageError> {
    let identifier = customIdentifier ?? "imported_\(UUID().uuidString)"
    let storeResult = await secureStorage.storeData(Data(data), with: identifier)
    
    switch storeResult {
    case .success:
      return .success(identifier)
    case .failure(let error):
      return .failure(.storageFailed(reason: "Failed to import data: \(error.localizedDescription)"))
    }
  }
  
  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  /// - Warning: Use with caution as this exposes sensitive data.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let retrieveResult = await secureStorage.retrieveData(with: identifier)
    
    switch retrieveResult {
    case .success(let data):
      return .success([UInt8](data))
    case .failure(let error):
      return .failure(.dataNotFound(identifier: identifier))
    }
  }

  // MARK: - Private Helper Methods

  /// Performs the actual encryption operation (simplified implementation)
  private func performEncryption(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    // This is a placeholder implementation. In a real system,
    // this would use a proper cryptographic library

    // Simulate encryption with a simple XOR (NOT secure, just for example)
    var result=[UInt8](repeating: 0, count: data.count)
    let keyLength=key.count

    for i in 0..<data.count {
      result[i]=data[i] ^ key[i % keyLength]
    }

    return result
  }

  /// Performs the actual decryption operation (simplified implementation)
  private func performDecryption(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    // For this simple XOR example, encryption and decryption are the same
    try performEncryption(data: data, key: key)
  }

  /// Performs the actual hashing operation (simplified implementation)
  private func performHashing(data: [UInt8]) throws -> [UInt8] {
    // This is a placeholder. In a real system, this would use a proper
    // cryptographic hashing function like SHA-256

    // Simulate a hash with a simple checksum
    var hash=[UInt8](repeating: 0, count: 32) // SHA-256 is 32 bytes

    for (index, byte) in data.enumerated() {
      hash[index % 32]=hash[index % 32] &+ byte
    }

    return hash
  }

  /// Maps a standard error to a SecurityProtocolError
  private func mapToSecurityError(_ error: Error) -> SecurityProtocolError {
    if let securityError=error as? SecurityProtocolError {
      return securityError
    }

    return SecurityProtocolError.operationFailed(
      reason: error.localizedDescription
    )
  }
}

/**
 * Default logger implementation for when no logger is provided
 */
private final class DefaultLogger: LoggingProtocol, CoreLoggingProtocol {
  let loggingActor: LoggingActor = DefaultLoggingActor()
  
  func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    // Simple console logging with context
    print("[\(level)] \(message) - \(context.domainName)")
  }
  
  // Core logging method implementations
  func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    let context = DefaultLogContext(
      domainName: "CryptoServices",
      source: source,
      correlationID: nil,
      metadata: LogMetadataDTOCollection(),
      parameters: [:]
    )
    await logMessage(level, message, context: context)
  }
  
  func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }
  
  func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }
  
  func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }
  
  func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }
  
  func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }
  
  func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }
}

/**
 Default logging actor implementation
 */
private actor DefaultLoggingActor: LoggingActor {
  func log(_ level: LogLevel, _ message: String, context: LogContext) async {
    print("Actor: [\(level)] \(message) - \(context.domainName)")
  }
}

/**
 Default log context implementation
 */
private struct DefaultLogContext: LogContext {
  var domainName: String
  var source: String?
  var correlationID: String?
  var metadata: LogMetadataDTOCollection
  var parameters: [String: Any]
}

/**
 Context for logging cryptographic operations
 */
private struct CryptoLogContext: LogContextDTO {
  // Required by LogContextDTO
  var domainName: String = "CryptoServices"
  var correlationID: String?
  var source: String?
  var metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
  
  // Implementation specific
  var parameters: [String: Any] = [:]

  init(operation: String, algorithm: String, metadata: [String: String]=[:], source: String? = "CryptoService", correlationID: String? = nil) {
    self.source = source
    self.correlationID = correlationID
    
    // Convert string metadata to proper collection
    var metadataCollection = LogMetadataDTOCollection()
    for (key, value) in metadata {
      metadataCollection.add(key: key, value: LogMetadataDTO(stringValue: value, privacyLevel: .public))
    }
    self.metadata = metadataCollection
    
    // Store operation-specific parameters
    self.parameters["operation"] = operation
    self.parameters["algorithm"] = algorithm
  }
  
  // Implement withUpdatedMetadata for LogContextDTO conformance
  func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> CryptoLogContext {
    var updated = self
    updated.metadata = metadata
    return updated
  }
}
