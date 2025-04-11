import CommonCrypto
import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces

// MARK: - Basic Encryption Service Adapter

/**
 # BasicEncryptionServiceAdapter

 Provides AES encryption and decryption using CommonCrypto.
 */
actor BasicEncryptionServiceAdapter: EncryptionServiceAdapter {
  /// Logger utility for operation tracking
  private let logger: SecurityServiceLogger

  /// Secure storage for persisting data
  private let secureStorage: SecureStorageProtocol

  /**
   Initialises the adapter with common dependencies.

   - Parameters:
      - secureStorage: The secure storage implementation
      - logger: The logger for operation tracking
   */
  init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
    self.secureStorage=secureStorage
    self.logger=SecurityServiceLogger(logger: logger)
  }

  /**
   Creates a log context with properly classified metadata.

   - Parameters:
      - metadata: Metadata to include in the log context
      - domain: Domain identifier for the log context
      - source: Source identifier for the log context
   - Returns: A log context with properly classified metadata
   */
  public nonisolated func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
    domain: String="SecurityServices",
    source: String="EncryptionService"
  ) -> BaseLogContextDTO {
    logger.createLogContext(metadata, domain: domain, source: source)
  }

  /**
   Encrypts data using the specified configuration.

   - Parameter config: Security configuration with encryption parameters
   - Returns: Result of the encryption operation
   - Throws: If encryption fails
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    await logger.logger.debug(
      "Starting encryption operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.encryptionAlgorithm.rawValue,
                        privacy: .public)
        ],
        source: "BasicEncryptionService"
      )
    )

    // Extract key ID and encrypted data from metadata
    guard
      let metadata=config.options?.metadata,
      let inputDataBase64=metadata["inputData"],
      let keyID=metadata["keyIdentifier"]
    else {
      throw SecurityStorageError.encryptionFailed
    }

    // Decode the input data
    guard let inputData=Data(base64Encoded: inputDataBase64) else {
      throw SecurityStorageError.operationFailed("Invalid input data encoding")
    }

    // Retrieve key from secure storage
    var keyData: Data
    do {
      let retrieveResult=await secureStorage.retrieveData(withIdentifier: keyID)
      switch retrieveResult {
        case let .success(bytes):
          keyData=Data(bytes)
        case .failure:
          throw SecurityStorageError.keyNotFound
      }
    } catch {
      throw SecurityStorageError.keyNotFound
    }

    // Create initialization vector (IV)
    var iv=Data(count: kCCBlockSizeAES128)
    let result=iv.withUnsafeMutableBytes { ivPtr in
      SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivPtr.baseAddress!)
    }

    if result != errSecSuccess {
      throw SecurityStorageError.encryptionFailed
    }

    // Perform encryption
    let algorithm: CCAlgorithm
    let options: CCOptions
    let blockSize: Int

    switch config.encryptionAlgorithm {
      case .aes256CBC:
        algorithm=CCAlgorithm(kCCAlgorithmAES)
        options=CCOptions(kCCOptionPKCS7Padding)
        blockSize=kCCBlockSizeAES128
      case .aes256GCM:
        algorithm=CCAlgorithm(kCCAlgorithmAES)
        options=CCOptions(kCCOptionPKCS7Padding)
        blockSize=kCCBlockSizeAES128
      case .chacha20Poly1305:
        throw SecurityStorageError
          .operationFailed("Unsupported algorithm: \(config.encryptionAlgorithm.rawValue)")
    }

    let dataLength=inputData.count
    var encryptedData=Data(count: dataLength + blockSize)
    var encryptedLength=0

    // Create local copies to avoid overlapping accesses
    let encryptedBufferCount=encryptedData.count

    let cryptStatus=encryptedData.withUnsafeMutableBytes { encryptedPtr in
      inputData.withUnsafeBytes { dataPtr in
        keyData.withUnsafeBytes { keyPtr in
          iv.withUnsafeBytes { ivPtr in
            CCCrypt(
              CCOperation(kCCEncrypt),
              algorithm,
              options,
              keyPtr.baseAddress, keyData.count,
              ivPtr.baseAddress,
              dataPtr.baseAddress, dataLength,
              encryptedPtr.baseAddress, encryptedBufferCount,
              &encryptedLength
            )
          }
        }
      }
    }

    if cryptStatus != kCCSuccess {
      throw SecurityStorageError.encryptionFailed
    }

    // Trim the encrypted data to the actual length
    encryptedData=encryptedData.prefix(encryptedLength)

    // Prepend the IV to the encrypted data for decryption later
    let resultData=iv + encryptedData

    let endTime=Date()
    let duration=endTime.timeIntervalSince(startTime) * 1000

    await logger.logger.debug(
      "Completed encryption operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.encryptionAlgorithm.rawValue,
                        privacy: .public),
          "duration": (value: String(format: "%.2f", duration),
                       privacy: .public),
          "status": (value: "success", privacy: .public)
        ],
        source: "BasicEncryptionService"
      )
    )

    // Create and return the result
    return SecurityResultDTO.success(
      resultData: resultData,
      executionTimeMs: duration,
      metadata: ["algorithm": config.encryptionAlgorithm.rawValue]
    )
  }

  /**
   Decrypts data using the specified configuration.

   - Parameter config: Security configuration with decryption parameters
   - Returns: Result of the decryption operation
   - Throws: If decryption fails
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    await logger.logger.debug(
      "Starting decryption operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.encryptionAlgorithm.rawValue,
                        privacy: .public)
        ],
        source: "BasicEncryptionService"
      )
    )

    // Extract key ID and encrypted data from metadata
    guard
      let metadata=config.options?.metadata,
      let encryptedDataBase64=metadata["inputData"],
      let keyID=metadata["keyIdentifier"]
    else {
      throw SecurityStorageError.decryptionFailed
    }

    // Decode the encrypted data
    guard let encryptedDataWithIV=Data(base64Encoded: encryptedDataBase64) else {
      throw SecurityStorageError.operationFailed("Invalid encrypted data encoding")
    }

    // Extract IV and actual encrypted data
    guard encryptedDataWithIV.count > kCCBlockSizeAES128 else {
      throw SecurityStorageError.decryptionFailed
    }

    let iv=encryptedDataWithIV.prefix(kCCBlockSizeAES128)
    let encryptedData=encryptedDataWithIV.dropFirst(kCCBlockSizeAES128)

    // Retrieve key from secure storage
    var keyData: Data
    do {
      let retrieveResult=await secureStorage.retrieveData(withIdentifier: keyID)
      switch retrieveResult {
        case let .success(bytes):
          keyData=Data(bytes)
        case .failure:
          throw SecurityStorageError.keyNotFound
      }
    } catch {
      throw SecurityStorageError.keyNotFound
    }

    // Perform decryption
    let algorithm: CCAlgorithm
    let options: CCOptions
    let blockSize: Int

    switch config.encryptionAlgorithm {
      case .aes256CBC:
        algorithm=CCAlgorithm(kCCAlgorithmAES)
        options=CCOptions(kCCOptionPKCS7Padding)
        blockSize=kCCBlockSizeAES128
      case .aes256GCM:
        algorithm=CCAlgorithm(kCCAlgorithmAES)
        options=CCOptions(kCCOptionPKCS7Padding)
        blockSize=kCCBlockSizeAES128
      case .chacha20Poly1305:
        throw SecurityStorageError
          .operationFailed("Unsupported algorithm: \(config.encryptionAlgorithm.rawValue)")
    }

    let dataLength=encryptedData.count
    var decryptedData=Data(count: dataLength + blockSize)
    var decryptedLength=0

    // Create a local copy to avoid overlapping accesses
    let decryptedBufferCount=decryptedData.count

    let cryptStatus=decryptedData.withUnsafeMutableBytes { decryptedPtr in
      encryptedData.withUnsafeBytes { dataPtr in
        keyData.withUnsafeBytes { keyPtr in
          iv.withUnsafeBytes { ivPtr in
            CCCrypt(
              CCOperation(kCCDecrypt),
              algorithm,
              options,
              keyPtr.baseAddress, keyData.count,
              ivPtr.baseAddress,
              dataPtr.baseAddress, dataLength,
              decryptedPtr.baseAddress, decryptedBufferCount,
              &decryptedLength
            )
          }
        }
      }
    }

    if cryptStatus != kCCSuccess {
      throw SecurityStorageError.decryptionFailed
    }

    // Trim the decrypted data to the actual length
    decryptedData=decryptedData.prefix(decryptedLength)

    let endTime=Date()
    let duration=endTime.timeIntervalSince(startTime) * 1000

    await logger.logger.debug(
      "Completed decryption operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.encryptionAlgorithm.rawValue,
                        privacy: .public),
          "duration": (value: String(format: "%.2f", duration),
                       privacy: .public),
          "status": (value: "success", privacy: .public)
        ],
        source: "BasicEncryptionService"
      )
    )

    // Create and return the result
    return SecurityResultDTO.success(
      resultData: decryptedData,
      executionTimeMs: duration,
      metadata: ["algorithm": config.encryptionAlgorithm.rawValue]
    )
  }
}

// MARK: - Basic Hashing Service Adapter

/**
 # BasicHashingServiceAdapter

 Provides cryptographic hashing operations using CommonCrypto.
 */
actor BasicHashingServiceAdapter: HashingServiceAdapter {
  /// Logger utility for operation tracking
  private let logger: SecurityServiceLogger

  /// Secure storage for persisting data
  private let secureStorage: SecureStorageProtocol

  /**
   Initialises the adapter with common dependencies.

   - Parameters:
      - secureStorage: The secure storage implementation
      - logger: The logger for operation tracking
   */
  init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
    self.secureStorage=secureStorage
    self.logger=SecurityServiceLogger(logger: logger)
  }

  /**
   Creates a log context with properly classified metadata.

   - Parameters:
      - metadata: Metadata to include in the log context
      - domain: Domain identifier for the log context
      - source: Source identifier for the log context
   - Returns: A log context with properly classified metadata
   */
  public nonisolated func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
    domain: String="SecurityServices",
    source: String="HashingService"
  ) -> BaseLogContextDTO {
    logger.createLogContext(metadata, domain: domain, source: source)
  }

  /**
   Hashes data using the specified configuration.

   - Parameter config: Security configuration with hashing parameters
   - Returns: Result of the hashing operation
   - Throws: If hashing fails
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    await logger.logger.debug(
      "Starting hash operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.hashAlgorithm.rawValue,
                        privacy: .public)
        ],
        source: "BasicHashingService"
      )
    )

    // Extract data from metadata
    guard
      let metadata=config.options?.metadata,
      let inputDataBase64=metadata["inputData"]
    else {
      throw SecurityStorageError.hashingFailed
    }

    // Decode the input data
    guard let inputData=Data(base64Encoded: inputDataBase64) else {
      throw SecurityStorageError.operationFailed("Invalid input data encoding")
    }

    // Perform hashing based on algorithm
    let hashData: Data

    switch config.hashAlgorithm {
      case .sha256:
        var hash=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _=inputData.withUnsafeBytes { dataBytes in
          CC_SHA256(dataBytes.baseAddress, CC_LONG(inputData.count), &hash)
        }
        hashData=Data(hash)

      case .sha512:
        var hash=[UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        _=inputData.withUnsafeBytes { dataBytes in
          CC_SHA512(dataBytes.baseAddress, CC_LONG(inputData.count), &hash)
        }
        hashData=Data(hash)

      case .blake2b:
        throw SecurityStorageError
          .operationFailed("BLAKE2b algorithm not supported in this implementation")
    }

    let endTime=Date()
    let duration=endTime.timeIntervalSince(startTime) * 1000

    await logger.logger.debug(
      "Completed hash operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.hashAlgorithm.rawValue,
                        privacy: .public),
          "duration": (value: String(format: "%.2f", duration),
                       privacy: .public),
          "status": (value: "success", privacy: .public)
        ],
        source: "BasicHashingService"
      )
    )

    // Create and return the result
    return SecurityResultDTO.success(
      resultData: hashData,
      executionTimeMs: duration,
      metadata: ["algorithm": config.hashAlgorithm.rawValue]
    )
  }

  /**
   Verifies a hash against the original data.

   - Parameter config: Security configuration with hash verification parameters
   - Returns: Result of the verification operation
   - Throws: If verification fails
   */
  public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    await logger.logger.debug(
      "Starting hash verification operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.hashAlgorithm.rawValue,
                        privacy: .public)
        ],
        source: "BasicHashingService"
      )
    )

    // Extract data from metadata
    let inputDataBase64=config.options?.metadata?["inputData"] ?? ""
    let expectedHashBase64=config.options?.metadata?["expectedHash"] ?? ""

    // Decode the input data and expected hash
    guard
      let _=Data(base64Encoded: inputDataBase64),
      let expectedHash=Data(base64Encoded: expectedHashBase64)
    else {
      throw SecurityStorageError.operationFailed("Invalid data encoding")
    }

    // Compute the hash of the input data
    let hashConfig=SecurityConfigDTO(
      encryptionAlgorithm: config.encryptionAlgorithm,
      hashAlgorithm: config.hashAlgorithm,
      providerType: config.providerType,
      options: SecurityConfigOptions(
        enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
        keyDerivationIterations: config.options?.keyDerivationIterations ?? 10000,
        memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
        useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
        operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30,
        verifyOperations: config.options?.verifyOperations ?? true,
        metadata: ["inputData": inputDataBase64]
      )
    )

    // Compute hash
    let hashResult=try await hash(config: hashConfig)

    guard let computedHash=hashResult.resultData else {
      throw SecurityStorageError.operationFailed("Failed to compute hash")
    }

    // Compare the computed hash with the expected hash
    let hashesMatch=computedHash == expectedHash

    let endTime=Date()
    let duration=endTime.timeIntervalSince(startTime) * 1000

    await logger.logger.debug(
      "Completed hash verification operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.hashAlgorithm.rawValue,
                        privacy: .public),
          "duration": (value: String(format: "%.2f", duration),
                       privacy: .public),
          "status": (value: hashesMatch ? "match" : "mismatch",
                     privacy: .public)
        ],
        source: "BasicHashingService"
      )
    )

    // Create and return the result
    return SecurityResultDTO.success(
      resultData: Data([UInt8(hashesMatch ? 1 : 0)]),
      executionTimeMs: duration,
      metadata: [
        "algorithm": config.hashAlgorithm.rawValue,
        "verified": hashesMatch ? "true" : "false"
      ]
    )
  }
}

// MARK: - Basic Key Generation Service Adapter

/**
 # BasicKeyGenerationServiceAdapter

 Provides secure key generation operations for cryptographic use.
 */
actor BasicKeyGenerationServiceAdapter: KeyGenerationServiceAdapter {
  /// Logger utility for operation tracking
  private let logger: SecurityServiceLogger

  /// Secure storage for persisting data
  private let secureStorage: SecureStorageProtocol

  /**
   Initialises the adapter with common dependencies.

   - Parameters:
      - secureStorage: The secure storage implementation
      - logger: The logger for operation tracking
   */
  init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
    self.secureStorage=secureStorage
    self.logger=SecurityServiceLogger(logger: logger)
  }

  /**
   Creates a log context with properly classified metadata.

   - Parameters:
      - metadata: Metadata to include in the log context
      - domain: Domain identifier for the log context
      - source: Source identifier for the log context
   - Returns: A log context with properly classified metadata
   */
  public nonisolated func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
    domain: String="SecurityServices",
    source: String="KeyGenerationService"
  ) -> BaseLogContextDTO {
    logger.createLogContext(metadata, domain: domain, source: source)
  }

  /**
   Generates a cryptographic key based on the provided configuration.

   - Parameter config: Security configuration with key generation parameters
   - Returns: Result containing the generated key data
   - Throws: If key generation fails
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    await logger.logger.debug(
      "Starting key generation operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.encryptionAlgorithm.rawValue,
                        privacy: .public)
        ],
        source: "BasicKeyGenerationService"
      )
    )

    // Extract key parameters from metadata
    guard let metadata=config.options?.metadata else {
      throw SecurityStorageError.operationFailed("Missing metadata")
    }

    // Determine key size (default to 256 bits for AES-256)
    let keySizeStr=metadata["keySize"] ?? "256"
    guard let keySize=Int(keySizeStr), keySize > 0 else {
      throw SecurityStorageError.operationFailed("Invalid key size")
    }

    // Convert bits to bytes
    let keySizeBytes=keySize / 8

    // Generate random key data
    var keyData=Data(count: keySizeBytes)
    let result=keyData.withUnsafeMutableBytes { keyPtr in
      SecRandomCopyBytes(kSecRandomDefault, keySizeBytes, keyPtr.baseAddress!)
    }

    if result != errSecSuccess {
      throw SecurityStorageError.keyGenerationFailed
    }

    let endTime=Date()
    let duration=endTime.timeIntervalSince(startTime) * 1000

    await logger.logger.debug(
      "Completed key generation operation",
      context: createLogContext(
        [
          "operationID": (value: operationID, privacy: .public),
          "algorithm": (value: config.encryptionAlgorithm.rawValue,
                        privacy: .public),
          "duration": (value: String(format: "%.2f", duration),
                       privacy: .public),
          "status": (value: "success", privacy: .public),
          "keySize": (value: keySizeStr, privacy: .public)
        ],
        source: "BasicKeyGenerationService"
      )
    )

    // Create and return the result
    return SecurityResultDTO.success(
      resultData: keyData,
      executionTimeMs: duration,
      metadata: [
        "algorithm": config.encryptionAlgorithm.rawValue,
        "keySize": keySizeStr
      ]
    )
  }
}

// MARK: - Basic Configuration Service Adapter

/**
 # BasicConfigurationServiceAdapter

 Provides configuration management for security operations.
 */
actor BasicConfigurationServiceAdapter: ConfigurationServiceAdapter {
  /// Logger utility for operation tracking
  private let logger: SecurityServiceLogger

  /// Secure storage for persisting data
  private let secureStorage: SecureStorageProtocol

  /**
   Initialises the adapter with common dependencies.

   - Parameters:
      - secureStorage: The secure storage implementation
      - logger: The logger for operation tracking
   */
  init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
    self.secureStorage=secureStorage
    self.logger=SecurityServiceLogger(logger: logger)
  }

  /**
   Creates a log context with properly classified metadata.

   - Parameters:
      - metadata: Metadata to include in the log context
      - domain: Domain identifier for the log context
      - source: Source identifier for the log context
   - Returns: A log context with properly classified metadata
   */
  public nonisolated func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
    domain: String="SecurityServices",
    source: String="ConfigurationService"
  ) -> BaseLogContextDTO {
    logger.createLogContext(metadata, domain: domain, source: source)
  }

  /**
   Creates a security configuration with the specified options.

   - Parameter options: The configuration options to use
   - Returns: A security configuration DTO
   */
  public nonisolated func createSecureConfig(options: SecurityConfigOptions) -> SecurityConfigDTO {
    // Create a basic security configuration with sensible defaults
    SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )
  }
}

// NOTE: SecurityError enum is already defined in BasicSecurityProvider.swift
// Moving the file-specific error types to a private enum within each adapter class as needed
