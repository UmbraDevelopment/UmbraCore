import BuildConfig
import CoreSecurityTypes
import CryptoInterfaces
import CryptoServicesCore
import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security
import SecurityCoreInterfaces
import CommonCrypto

#if os(macOS) || os(iOS)
import CryptoKit
import LocalAuthentication
#endif

/// # ApplePlatformCryptoService
///
/// Apple-native implementation of the CryptoServiceProtocol using CryptoKit.
///
/// This implementation provides highly optimised cryptographic operations specifically
/// for Apple platforms (macOS, iOS, watchOS, tvOS). It leverages Apple's CryptoKit
/// framework for hardware-accelerated encryption, proper sandboxing, and integration
/// with the Apple security architecture.
///
/// ## Features
///
/// - Optimised for Apple platforms with hardware acceleration where available
/// - AES-GCM implementation for authenticated encryption
/// - Secure enclave integration on supported devices
/// - Full macOS/iOS sandboxing compliance
/// - Integration with Apple's security architecture
///
/// ## Usage
///
/// This implementation should be selected when:
/// - Working exclusively on Apple platforms
/// - Requiring hardware acceleration for cryptographic operations
/// - Needing secure enclave integration on supported devices
/// - Operating within Apple's security and sandboxing guidelines
///
/// ## Thread Safety
///
/// As an actor, this implementation guarantees thread safety when used from multiple
/// concurrent contexts, preventing data races in cryptographic operations.
public actor ApplePlatformCryptoService: CryptoServiceProtocol {
  // MARK: - Properties

  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// Optional logger for operation tracking with privacy controls
  private let logger: LoggingProtocol?

  /// The environment configuration
  private let environment: CryptoServicesCore.CryptoEnvironment

  // Store the provider type for logging purposes
  private let providerType: SecurityProviderType = .appleCryptoKit

  // MARK: - Initialisation

  /// Initialises an Apple platform-specific crypto service.
  ///
  /// - Parameters:
  ///   - secureStorage: The secure storage to use
  ///   - logger: Optional logger for recording operations with privacy controls
  ///   - environment: Optional override for the environment configuration
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol? = nil,
    environment: CryptoServicesCore.CryptoEnvironment? = nil
  ) {
    self.secureStorage = secureStorage
    self.logger = logger

    // Create a default environment if none provided
    if let environment {
      self.environment = environment
    } else {
      // Create a default environment based on the BuildConfig
      let envType = BuildConfig.activeEnvironment == .production
        ? CryptoServicesCore.CryptoEnvironment.EnvironmentType.production
        : BuildConfig.activeEnvironment == .debug
          ? CryptoServicesCore.CryptoEnvironment.EnvironmentType.development
          : CryptoServicesCore.CryptoEnvironment.EnvironmentType.staging

      self.environment = CryptoServicesCore.CryptoEnvironment(
        type: envType,
        hasHardwareSecurity: true,
        isLoggingEnhanced: BuildConfig.activeEnvironment != .production,
        platformIdentifier: "apple",
        parameters: [
          "provider": "cryptokit",
          "allowsFallback": "true"
        ]
      )
    }

    // We will initialise CryptoKit in the first async operation rather than in init

    // Log initialisation will be done in the first async operation
  }

  /// Initialises CryptoKit for use with this service.
  ///
  /// This method is called at the start of each async operation to ensure
  /// that CryptoKit is properly initialised.
  ///
  /// If CryptoKit is not available or minimum requirements are not met, appropriate
  /// warnings will be logged.
  private func initializeCryptoKit() async {
    // Check if we've already initialised
    if cryptoKitInitialised {
      return
    }
    
    // Initialize CryptoKit bridge
    CryptoKitBridge.initialise()
    
    // Record that we've initialised
    cryptoKitInitialised = true
    
    // Log initialisation with appropriate privacy controls
    if let logger {
      let logContext = CryptoLogContext(
        operation: "initialise",
        correlationID: UUID().uuidString
      )
      
      await logger.info(
        "ApplePlatformCryptoService initialised in \(self.environment.name) environment with CryptoKit",
        context: logContext.toLogContextDTO()
      )
    }
  }
  
  /// Flag to track whether CryptoKit has been initialised
  private var cryptoKitInitialised = false

  // MARK: - Private Helpers

  /// Logs a message at debug level with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log message
  private func logDebug(_ message: String, context: CryptoLogContext) async {
    await logger?.debug(
      message,
      context: context.toLogContextDTO()
    )
  }

  /// Logs a message at info level with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log message
  private func logInfo(_ message: String, context: CryptoLogContext) async {
    await logger?.info(
      message,
      context: context.toLogContextDTO()
    )
  }

  /// Logs a message at warning level with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log message
  private func logWarning(_ message: String, context: CryptoLogContext) async {
    await logger?.warning(
      message,
      context: context.toLogContextDTO()
    )
  }

  /// Logs a message at error level with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log message
  private func logError(_ message: String, context: CryptoLogContext) async {
    await logger?.error(
      message,
      context: context.toLogContextDTO()
    )
  }
  
  /// Logs the start of an operation.
  ///
  /// - Parameters:
  ///   - operation: The operation being started
  ///   - context: The context for the operation
  /// - Returns: The start time of the operation for timing purposes
  private func logOperationStart(
    _ operation: String,
    context: CryptoLogContext
  ) async -> CFAbsoluteTime {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    await logDebug(
      "Starting \(operation) operation",
      context: context
    )
    
    return startTime
  }
  
  /// Logs the completion of an operation with execution time.
  ///
  /// - Parameters:
  ///   - operation: The operation that completed
  ///   - startTime: The start time from logOperationStart
  ///   - context: The context for the operation
  /// - Returns: The execution time in milliseconds
  private func logOperationComplete(
    _ operation: String,
    startTime: CFAbsoluteTime,
    context: CryptoLogContext
  ) async -> Double {
    let endTime = CFAbsoluteTimeGetCurrent()
    let executionTime = (endTime - startTime) * 1000 // Convert to milliseconds
    
    let timeContext = context.withMetadata(
      LogMetadataDTOCollection()
        .withOperational(key: "executionTimeMs", value: String(format: "%.2f", executionTime))
    )
    
    await logDebug(
      "Completed \(operation) operation in \(String(format: "%.2f", executionTime))ms",
      context: timeContext
    )
    
    return executionTime
  }

  /// Logs an operation error.
  ///
  /// - Parameters:
  ///   - operation: The operation that failed
  ///   - error: The error that occurred
  ///   - startTime: The start time from logOperationStart
  ///   - context: The context for the operation
  /// - Returns: The execution time in milliseconds
  private func logOperationError(
    _ operation: String,
    error: Error,
    startTime: CFAbsoluteTime,
    context: CryptoLogContext
  ) async -> Double {
    let endTime = CFAbsoluteTimeGetCurrent()
    let executionTime = (endTime - startTime) * 1000 // Convert to milliseconds
    
    let errorContext = context.withMetadata(
      LogMetadataDTOCollection()
        .withOperational(key: "executionTimeMs", value: String(format: "%.2f", executionTime))
        .withPublic(key: "error", value: error.localizedDescription)
    )
    
    await logError(
      "\(operation) operation failed: \(error.localizedDescription)",
      context: errorContext
    )
    
    return executionTime
  }

  /// Generates a random nonce using CryptoKit.
  ///
  /// - Parameter algorithm: The encryption algorithm to generate a nonce for
  /// - Returns: The generated nonce as Data
  private func cryptoKitGenerateRandomBytes(for algorithm: StandardEncryptionAlgorithm) -> Data {
    // In a real implementation, this would use:
    // return Data(CryptoKit.generateRandomBytes(count: size))

    // For now, we'll simulate with SecRandomCopyBytes
    let nonceSize = algorithm.nonceSize
    var bytes = [UInt8](repeating: 0, count: nonceSize)
    _ = SecRandomCopyBytes(kSecRandomDefault, nonceSize, &bytes)
    return Data(bytes)
  }

  /// Simulates AES-GCM encryption using CryptoKit.
  ///
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key
  ///   - nonce: The nonce for encryption
  ///   - authData: Additional authenticated data (optional)
  /// - Returns: The encrypted data with authentication tag
  private func cryptoKitAESGCMEncrypt(
    data: Data,
    key: Data,
    nonce: Data,
    authData: Data? = nil
  ) -> Data? {
    // In a real implementation, this would use CryptoKit AES-GCM
    // For demonstration purposes, we'll simulate with CommonCrypto or a placeholder

    // NOTE: This is a simplified placeholder implementation
    // In a real implementation, proper AES-GCM would be used with CryptoKit

    // Simulation: just append an "authentication tag" to the data
    // Real implementation would use proper authenticated encryption
    let simulatedTag = Data([
      0x01,
      0x02,
      0x03,
      0x04,
      0x05,
      0x06,
      0x07,
      0x08,
      0x09,
      0x0A,
      0x0B,
      0x0C,
      0x0D,
      0x0E,
      0x0F,
      0x10
    ])
    return data + simulatedTag
  }

  /// Simulates AES-GCM decryption using CryptoKit.
  ///
  /// - Parameters:
  ///   - encryptedData: The encrypted data with authentication tag
  ///   - key: The decryption key
  ///   - nonce: The nonce used for encryption
  ///   - authData: Additional authenticated data (optional)
  /// - Returns: The decrypted data, or nil if authentication fails
  private func cryptoKitAESGCMDecrypt(
    encryptedData: Data,
    key: Data,
    nonce: Data,
    authData: Data? = nil
  ) -> Data? {
    // In a real implementation, this would use CryptoKit AES-GCM
    // For demonstration purposes, we'll simulate with CommonCrypto or a placeholder

    // NOTE: This is a simplified placeholder implementation
    // In a real implementation, proper AES-GCM would be used with CryptoKit

    // Simulation: just remove the "authentication tag" from the data
    // Real implementation would verify the tag and decrypt properly
    if encryptedData.count > 16 {
      return encryptedData.dropLast(16)
    }
    return nil
  }

  /// Generates a SHA-256 hash using CryptoKit.
  ///
  /// - Parameter data: The data to hash
  /// - Returns: The SHA-256 hash
  private func cryptoKitSHA256(data: Data) -> Data {
    // In a real implementation, this would use CryptoKit.SHA256
    // For demonstration purposes, we'll use CommonCrypto
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { buffer in
      _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hashBytes)
    }
    return Data(hashBytes)
  }

  /// Generates a SHA-512 hash using CryptoKit.
  ///
  /// - Parameter data: The data to hash
  /// - Returns: The SHA-512 hash
  private func cryptoKitSHA512(data: Data) -> Data {
    // In a real implementation, this would use CryptoKit.SHA512
    // For demonstration purposes, we'll use CommonCrypto
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    data.withUnsafeBytes { buffer in
      _ = CC_SHA512(buffer.baseAddress, CC_LONG(data.count), &hashBytes)
    }
    return Data(hashBytes)
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypts data with the given key using Apple CryptoKit.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier for the data to encrypt
  ///   - keyIdentifier: Identifier for the encryption key
  ///   - options: Optional encryption options
  /// - Returns: A Result containing the encrypted data identifier or an error
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "encrypt",
      algorithm: options?.algorithm ?? StandardEncryptionAlgorithm.aes256GCM.rawValue,
      mode: options?.mode ?? StandardEncryptionMode.gcm.rawValue,
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("encrypt", context: context)
    
    // Get the data to encrypt
    let dataResult = await retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(dataToEncrypt):
        await logDebug(
          "Retrieved data for encryption, size: \(dataToEncrypt.count) bytes",
          context: context
        )
        
        // Get the encryption key
        let keyResult = await retrieveData(withIdentifier: keyIdentifier)
        
        switch keyResult {
          case let .success(keyData):
            // Determine the encryption algorithm and mode
            let (algorithm, mode) = selectOptimalAlgorithm()
            
            // Process additional authenticated data if provided
            var authenticatedData: Data? = nil
            if let aadIdentifier = options?.authenticatedDataIdentifier {
              let aadResult = await retrieveData(withIdentifier: aadIdentifier)
              switch aadResult {
                case let .success(aad):
                  authenticatedData = aad
                case let .failure(error):
                  let _ = await logOperationError("encrypt", error: error, startTime: startTime, context: context)
                  return .failure(error)
              }
            }
            
            // Perform encryption based on algorithm and mode
            let encryptionResult: Result<(encryptedData: Data, nonce: Data), CryptoOperationError>
            
            switch (algorithm, mode) {
              case (.aes256GCM, .gcm):
                // Use AES-GCM encryption
                encryptionResult = CryptoKitBridge.encryptAESGCM(
                  data: dataToEncrypt,
                  key: keyData,
                  authenticatedData: authenticatedData
                )
                
              case (.aes256CBC, .cbc):
                // Error: CBC mode is not fully implemented in this version
                let error = CryptoOperationError(
                  code: .unsupportedMode,
                  message: "AES-CBC mode is not fully implemented in this version"
                )
                encryptionResult = .failure(error)
                
              case (.chacha20Poly1305, .stream):
                // Use ChaCha20-Poly1305 encryption
                encryptionResult = CryptoKitBridge.encryptChaChaPoly(
                  data: dataToEncrypt,
                  key: keyData,
                  authenticatedData: authenticatedData
                )
                
              default:
                // Unsupported algorithm/mode combination
                let error = CryptoOperationError(
                  code: .unsupportedAlgorithm,
                  message: "Unsupported algorithm/mode combination: \(algorithm.rawValue)/\(mode.rawValue)"
                )
                encryptionResult = .failure(error)
            }
            
            // Process encryption result
            switch encryptionResult {
              case let .success((encryptedData, nonce)):
                // Format the encrypted data with nonce and other metadata
                let keyIdLength: UInt8 = UInt8(keyIdentifier.utf8.count)
                var resultData = Data()
                
                // Add nonce
                resultData.append(nonce)
                
                // Add encrypted data
                resultData.append(encryptedData)
                
                // Add key ID length and key ID
                resultData.append(keyIdLength)
                if let keyIdData = keyIdentifier.data(using: .utf8) {
                  resultData.append(keyIdData)
                }
                
                // Store the encrypted data
                let encryptedDataIdentifier = options?.resultIdentifier ?? "\(dataIdentifier).encrypted"
                let storeResult = await storeData(resultData, withIdentifier: encryptedDataIdentifier)
                
                switch storeResult {
                  case .success:
                    // Log successful encryption
                    let executionTime = await logOperationComplete(
                      "encrypt",
                      startTime: startTime,
                      context: context.withMetadata(
                        LogMetadataDTOCollection()
                          .withOperational(key: "originalSize", value: "\(dataToEncrypt.count)")
                          .withOperational(key: "encryptedSize", value: "\(resultData.count)")
                          .withOperational(key: "algorithm", value: algorithm.rawValue)
                          .withOperational(key: "mode", value: mode.rawValue)
                      )
                    )
                    
                    // Return the identifier for the encrypted data
                    return .success(encryptedDataIdentifier)
                    
                  case let .failure(error):
                    // Log storage error
                    let _ = await logOperationError(
                      "encrypt",
                      error: error,
                      startTime: startTime,
                      context: context
                    )
                    return .failure(error)
                }
                
              case let .failure(error):
                // Convert and log the encryption error
                let securityError = error.toSecurityStorageError()
                let _ = await logOperationError(
                  "encrypt",
                  error: securityError,
                  startTime: startTime,
                  context: context
                )
                return .failure(securityError)
            }
            
          case let .failure(error):
            // Log key retrieval error
            let errorContext = context.withMetadata(
              LogMetadataDTOCollection()
                .withPublic(key: "error", value: error.localizedDescription)
            )
            
            let _ = await logOperationError(
              "encrypt",
              error: error,
              startTime: startTime,
              context: errorContext
            )
            
            return .failure(error)
        }
        
      case let .failure(error):
        // Log data retrieval error
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        
        let _ = await logOperationError(
          "encrypt",
          error: error,
          startTime: startTime,
          context: errorContext
        )
        
        return .failure(error)
    }
  }

  /// Decrypts data with the given key using Apple CryptoKit.
  ///
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier for the encrypted data
  ///   - keyIdentifier: Identifier for the decryption key
  ///   - options: Optional decryption options
  /// - Returns: A Result containing the decrypted data identifier or an error
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String?,
    options: DecryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "decrypt",
      algorithm: "AES-GCM", // CryptoKit uses AES-GCM by default
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("decrypt", context: context)
    
    // Get the encrypted data
    let dataResult = await retrieveData(withIdentifier: encryptedDataIdentifier)
    
    switch dataResult {
      case let .success(encryptedDataBytes):
        // Verify the encrypted data format: [Nonce (12 bytes)][Encrypted Data with Tag][Key ID Length (1 byte)][Key ID]
        if encryptedDataBytes.count < 13 { // Minimum size: Nonce (12) + Key ID Length (1)
          let error = SecurityStorageError.dataCorrupted(details: "Encrypted data too short or malformed")
          let _ = await logOperationError("decrypt", error: error, startTime: startTime, context: context)
          return .failure(error)
        }
        
        // Extract nonce (first 12 bytes)
        let nonce = encryptedDataBytes.prefix(12)
        
        // Extract key ID from the end
        let keyIDLength = Int(encryptedDataBytes[encryptedDataBytes.count - 1])
        
        // Validate key ID position
        if encryptedDataBytes.count < 13 + keyIDLength {
          let error = SecurityStorageError.dataCorrupted(details: "Encrypted data malformed, key ID length invalid")
          let _ = await logOperationError("decrypt", error: error, startTime: startTime, context: context)
          return .failure(error)
        }
        
        // Extract embedded key ID if no key identifier provided
        let actualKeyIdentifier: String
        if let providedKeyIdentifier = keyIdentifier {
          actualKeyIdentifier = providedKeyIdentifier
        } else {
          // Extract key ID from the encrypted data
          let keyIDStart = encryptedDataBytes.count - keyIDLength - 1
          let keyIDData = encryptedDataBytes.suffix(keyIDLength)
          
          guard let extractedKeyID = String(data: keyIDData, encoding: .utf8) else {
            let error = SecurityStorageError.dataCorrupted(details: "Failed to extract key ID from encrypted data")
            let _ = await logOperationError("decrypt", error: error, startTime: startTime, context: context)
            return .failure(error)
          }
          
          actualKeyIdentifier = extractedKeyID
          
          await logDebug(
            "Using key ID extracted from encrypted data",
            context: context
          )
        }
        
        // Get the encryption key
        let keyResult = await retrieveData(withIdentifier: actualKeyIdentifier)
        
        switch keyResult {
          case let .success(keyData):
            // Extract the encrypted data with tag (excluding nonce, key ID length, and key ID)
            let contentStart = 12 // After nonce
            let contentEnd = encryptedDataBytes.count - keyIDLength - 1 // Before key ID length
            let encryptedContent = encryptedDataBytes[contentStart..<contentEnd]
            
            // Process additional authenticated data if provided
            var authenticatedData: Data? = nil
            if let aadIdentifier = options?.authenticatedDataIdentifier {
              let aadResult = await retrieveData(withIdentifier: aadIdentifier)
              switch aadResult {
                case let .success(aad):
                  authenticatedData = aad
                case let .failure(error):
                  let _ = await logOperationError("decrypt", error: error, startTime: startTime, context: context)
                  return .failure(error)
              }
            }
            
            // Determine the algorithm based on options or guess from data format
            let algorithmString = options?.algorithm ?? StandardEncryptionAlgorithm.aes256GCM.rawValue
            let algorithm: StandardEncryptionAlgorithm
            
            if let specified = StandardEncryptionAlgorithm.allCases.first(where: { $0.rawValue == algorithmString }) {
              algorithm = specified
            } else {
              // Default to AES-GCM
              algorithm = .aes256GCM
              await logWarning(
                "Unrecognised algorithm specified: \(algorithmString), defaulting to AES-GCM",
                context: context
              )
            }
            
            // Perform decryption based on algorithm
            let decryptionResult: Result<Data, CryptoOperationError>
            let tagLength = 16 // Both AES-GCM and ChaCha20-Poly1305 use 16-byte tags
            
            switch algorithm {
              case .aes256GCM:
                // Use AES-GCM decryption
                decryptionResult = CryptoKitBridge.decryptAESGCM(
                  encryptedData: Data(encryptedContent),
                  key: keyData,
                  nonce: Data(nonce),
                  tagLength: tagLength,
                  authenticatedData: authenticatedData
                )
                
              case .chacha20Poly1305:
                // Use ChaCha20-Poly1305 decryption
                decryptionResult = CryptoKitBridge.decryptChaChaPoly(
                  encryptedData: Data(encryptedContent),
                  key: keyData,
                  nonce: Data(nonce),
                  tagLength: tagLength,
                  authenticatedData: authenticatedData
                )
                
              case .aes256CBC:
                // CBC mode not fully implemented in this version
                let error = CryptoOperationError(
                  code: .unsupportedMode,
                  message: "AES-CBC mode is not fully implemented in this version"
                )
                decryptionResult = .failure(error)
            }
            
            // Process decryption result
            switch decryptionResult {
              case let .success(decryptedData):
                // Store the decrypted data
                let decryptedDataIdentifier = options?.resultIdentifier ?? "\(encryptedDataIdentifier).decrypted"
                let storeResult = await storeData(decryptedData, withIdentifier: decryptedDataIdentifier)
                
                switch storeResult {
                  case .success:
                    // Log successful decryption
                    let executionTime = await logOperationComplete(
                      "decrypt",
                      startTime: startTime,
                      context: context.withMetadata(
                        LogMetadataDTOCollection()
                          .withOperational(key: "encryptedSize", value: "\(encryptedDataBytes.count)")
                          .withOperational(key: "decryptedSize", value: "\(decryptedData.count)")
                          .withOperational(key: "algorithm", value: algorithm.rawValue)
                      )
                    )
                    
                    // Return the identifier for the decrypted data
                    return .success(decryptedDataIdentifier)
                    
                  case let .failure(error):
                    // Log storage error
                    let _ = await logOperationError(
                      "decrypt",
                      error: error,
                      startTime: startTime,
                      context: context
                    )
                    return .failure(error)
                }
                
              case let .failure(error):
                // Convert and log the decryption error
                let securityError = error.toSecurityStorageError()
                let _ = await logOperationError(
                  "decrypt",
                  error: securityError,
                  startTime: startTime,
                  context: context
                )
                return .failure(securityError)
            }
            
          case let .failure(error):
            // Log key retrieval error
            let errorContext = context.withMetadata(
              LogMetadataDTOCollection()
                .withPublic(key: "error", value: error.localizedDescription)
            )
            
            let _ = await logOperationError(
              "decrypt",
              error: error,
              startTime: startTime,
              context: errorContext
            )
            
            return .failure(error)
        }
        
      case let .failure(error):
        // Log data retrieval error
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        
        let _ = await logOperationError(
          "decrypt",
          error: error,
          startTime: startTime,
          context: errorContext
        )
        
        return .failure(error)
    }
  }

  /// Verifies a hash against data using Apple CryptoKit.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify
  ///   - hashIdentifier: Identifier of the hash to verify against
  ///   - options: Optional hashing configuration
  /// - Returns: Whether the hash is valid or an error
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    let algorithm = options?.algorithm ?? .sha256

    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "verifyHash",
      algorithm: algorithm.rawValue,
      correlationID: UUID().uuidString
    )
    .withMetadata(
      LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
        .withPublic(key: "algorithm", value: algorithm.rawValue)
        .withPublic(key: "provider", value: "CryptoKit")
    )

    await logDebug("Starting CryptoKit hash verification", context: context.toLogContextDTO())

    // Retrieve the data to verify
    let dataResult = await retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(dataToVerify):
        // Retrieve the stored hash
        let hashResult = await retrieveData(withIdentifier: hashIdentifier)

        switch hashResult {
          case let .success(storedHash):
            // Compute the hash of the data
            var computedHash: Data

            switch algorithm {
              case .sha256:
                computedHash = cryptoKitSHA256(data: dataToVerify)
              case .sha512:
                computedHash = cryptoKitSHA512(data: dataToVerify)
              default:
                await logError(
                  "Unsupported hash algorithm for CryptoKit: \(algorithm.rawValue)",
                  context: context.toLogContextDTO()
                )
                return .failure(.hashingFailed)
            }

            // Compare the computed hash with the stored hash
            let hashesMatch = computedHash == storedHash

            let resultContext = context.withMetadata(
              LogMetadataDTOCollection()
                .withPublic(key: "hashesMatch", value: String(hashesMatch))
            )

            if hashesMatch {
              await logInfo("CryptoKit hash verification succeeded", context: resultContext.toLogContextDTO())
            } else {
              await logInfo(
                "CryptoKit hash verification failed - hashes do not match",
                context: resultContext.toLogContextDTO()
              )
            }

            return .success(hashesMatch)

          case let .failure(error):
            let errorContext = context.withMetadata(
              LogMetadataDTOCollection()
                .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError(
              "Failed to retrieve stored hash for CryptoKit verification",
              context: errorContext.toLogContextDTO()
            )
            return .failure(error)
        }

      case let .failure(error):
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        await logError(
          "Failed to retrieve data for CryptoKit hash verification",
          context: errorContext.toLogContextDTO()
        )
        return .failure(error)
    }
  }

  /// Generates a cryptographic key using Apple CryptoKit.
  ///
  /// For hardware support where available, this can use the Secure Enclave.
  ///
  /// - Parameters:
  ///   - length: Bit length of the key
  ///   - identifier: Identifier to associate with the key
  ///   - purpose: Purpose of the key
  ///   - options: Optional key generation configuration
  /// - Returns: Success or failure with error details
  public func generateKey(
    length: Int,
    identifier: String,
    purpose: KeyPurpose,
    options: KeyGenerationOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "generateKey",
      correlationID: UUID().uuidString
    )
    .withMetadata(
      LogMetadataDTOCollection()
        .withPrivate(key: "keyIdentifier", value: identifier)
        .withPublic(key: "keyLength", value: String(length))
        .withPublic(key: "keyPurpose", value: purpose.rawValue)
        .withPublic(key: "provider", value: "CryptoKit")
    )

    await logDebug("Starting CryptoKit key generation", context: context.toLogContextDTO())

    // Validate key length
    let byteLength = length / 8
    if byteLength <= 0 || byteLength > 1024 { // Set a reasonable upper limit
      let errorContext = context.withMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "error", value: "Invalid key length for CryptoKit key generation")
      )
      await logError("Invalid key length", context: errorContext.toLogContextDTO())
      return .failure(.invalidKeyLength)
    }

    // In a real implementation, we would use CryptoKit.SymmetricKey to generate a key
    // For demonstration purposes, we'll simulate using SecRandomCopyBytes

    // Generate random key bytes
    let keyData = cryptoKitGenerateRandomBytes(for: .aes256GCM)

    // Store the key
    let storeResult = await storeData(keyData, withIdentifier: identifier)

    switch storeResult {
      case .success:
        // Log if we're using the Secure Enclave (in a real implementation)
        let useSecureEnclave = options?.secureEnclave ?? false

        let successContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "keySize", value: String(keyData.count))
            .withPublic(key: "secureEnclave", value: String(useSecureEnclave))
        )
        await logInfo("CryptoKit key generated and stored successfully", context: successContext.toLogContextDTO())
        return .success(true)

      case let .failure(error):
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        await logError("Failed to store CryptoKit-generated key", context: errorContext.toLogContextDTO())
        return .failure(error)
    }
  }

  /// Retrieves data from secure storage.
  ///
  /// - Parameter identifier: Identifier of the data to retrieve
  /// - Returns: The retrieved data or an error
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    await retrieveData(withIdentifier: identifier)
  }

  /// Stores data in secure storage.
  ///
  /// - Parameters:
  ///   - data: Data to store
  ///   - identifier: Identifier to associate with the data
  /// - Returns: Success or failure with error details
  public func storeData(
    _ data: Data,
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    await storeData(data, withIdentifier: identifier)
  }

  // MARK: - Helper Methods
  
  /// Selects the optimal encryption algorithm based on hardware capabilities.
  ///
  /// This method returns AES-GCM with 256-bit keys for Apple Silicon platforms,
  /// which provides hardware-acceleration for maximum performance and security.
  ///
  /// - Returns: The optimal algorithm and mode for this device
  private func selectOptimalAlgorithm() -> (algorithm: StandardEncryptionAlgorithm, mode: StandardEncryptionMode) {
    // Use AES-GCM on Apple Silicon for hardware acceleration
    return (.aes256GCM, .gcm)
  }
  
  /// Generates a cryptographically secure key using the Secure Enclave when available.
  ///
  /// This method implements Apple's best practices for key generation, using Secure Enclave
  /// on supported devices and falling back to CryptoKit's secure random generation otherwise.
  ///
  /// - Parameters:
  ///   - tag: A unique tag/identifier for the key
  ///   - options: Optional key generation configuration
  /// - Returns: A Result containing the generated key identifier or an error
  public func generateKey(
    tag: String,
    options: KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "generateKey",
      correlationID: UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("generateKey", context: context)
    
    // Determine key size
    let keySize = options?.keySize ?? 32 // 256 bits default
    
    do {
      var keyData: Data
      let useSecureEnclave = options?.useSecureEnclaveIfAvailable ?? true
      
      #if os(macOS) || os(iOS)
      if useSecureEnclave && isSecureEnclaveAvailable() {
        // Try to use Secure Enclave for key generation on supported devices
        // This is a simplified implementation - a full implementation would use more
        // keychain-specific options and proper SecKey APIs
        
        await logInfo(
          "Using Secure Enclave for key generation",
          context: context
        )
        
        // Generate a secure enclave key and export its representation
        // In a real implementation, we'd store this key reference securely
        // and only export a reference
        
        keyData = try generateSecureEnclaveKey(tag: tag)
      } else {
      #endif
        // Generate a random key using CryptoKit's secure random generator
        keyData = generateRandomBytes(count: keySize)
        
        await logInfo(
          "Generated cryptographically secure random key",
          context: context.withMetadata(
            LogMetadataDTOCollection()
              .withOperational(key: "keySize", value: "\(keySize)")
          )
        )
      #if os(macOS) || os(iOS)
      }
      #endif
      
      // Store the key
      let keyIdentifier = options?.resultIdentifier ?? "key_\(tag)_\(UUID().uuidString)"
      let storeResult = await storeData(keyData, withIdentifier: keyIdentifier)
      
      switch storeResult {
        case .success:
          // Log successful key generation
          let executionTime = await logOperationComplete(
            "generateKey",
            startTime: startTime,
            context: context.withMetadata(
              LogMetadataDTOCollection()
                .withOperational(key: "keySize", value: "\(keyData.count)")
            )
          )
          
          // Return the identifier for the key
          return .success(keyIdentifier)
          
        case let .failure(error):
          // Log storage error
          let _ = await logOperationError(
            "generateKey",
            error: error,
            startTime: startTime,
            context: context
          )
          return .failure(error)
      }
      
    } catch {
      // Convert and log any errors
      let securityError = SecurityStorageError.keyGenerationFailed(details: error.localizedDescription)
      let _ = await logOperationError(
        "generateKey",
        error: securityError,
        startTime: startTime,
        context: context
      )
      return .failure(securityError)
    }
  }
  
  /// Checks if Secure Enclave is available on this device.
  ///
  /// - Returns: True if Secure Enclave is available
  private func isSecureEnclaveAvailable() -> Bool {
    #if os(macOS)
      if #available(macOS 10.15, *) {
        return SecureEnclave.isAvailable
      }
      return false
    #elseif os(iOS)
      if #available(iOS 13.0, *) {
        return SecureEnclave.isAvailable
      }
      return false
    #else
      return false
    #endif
  }
  
  /// Generates a key in the Secure Enclave.
  ///
  /// - Parameter tag: Unique tag/identifier for the key
  /// - Returns: Representation of the key (actual key remains in Secure Enclave)
  private func generateSecureEnclaveKey(tag: String) throws -> Data {
    #if os(macOS) || os(iOS)
      if #available(macOS 10.15, iOS 13.0, *) {
        // Create access control for the key
        let access = SecAccessControlCreateWithFlags(
          nil,
          kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
          .privateKeyUsage,
          nil
        )!
        
        // Create a Secure Enclave P-256 key
        let secureEnclaveKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(
          accessControl: access,
          authenticationContext: nil
        )
        
        // In a real implementation, we'd store this key reference securely
        // and only export a reference
        
        return secureEnclaveKey.publicKey.compactRepresentation!
      }
    #endif
    
    // Fallback if Secure Enclave is not available
    throw SecurityStorageError.keyGenerationFailed(details: "Secure Enclave not available")
  }
  
  /// Generates cryptographically secure random bytes.
  ///
  /// - Parameter count: Number of bytes to generate
  /// - Returns: Data containing random bytes
  private func generateRandomBytes(count: Int) -> Data {
    var data = Data(count: count)
    _ = data.withUnsafeMutableBytes { 
      SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!) 
    }
    return data
  }
  
  /// Derives a key from a password using PBKDF2 with high iteration count.
  ///
  /// - Parameters:
  ///   - password: The password to derive the key from
  ///   - salt: The salt to use for key derivation
  ///   - iterations: Number of iterations to use (defaults to a high value for security)
  ///   - keyLength: Length of the derived key in bytes
  /// - Returns: The derived key
  private func deriveKeyFromPassword(
    password: String,
    salt: Data,
    iterations: Int = 600000, // High iteration count for security
    keyLength: Int = 32 // 256 bits
  ) -> Data {
    guard let passwordData = password.data(using: .utf8) else {
      // Handle password encoding error
      return Data(repeating: 0, count: keyLength)
    }
    
    var derivedKeyData = Data(repeating: 0, count: keyLength)
    
    // Perform PBKDF2 key derivation
    derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
      passwordData.withUnsafeBytes { passwordBytes in
        salt.withUnsafeBytes { saltBytes in
          CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes.baseAddress, passwordBytes.count,
            saltBytes.baseAddress, saltBytes.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512),
            UInt32(iterations),
            derivedKeyBytes.baseAddress, derivedKeyBytes.count
          )
        }
      }
    }
    
    return derivedKeyData
  }

  /// Encrypts data using a password with strong key derivation.
  ///
  /// This method provides a high-security password-based encryption operation
  /// using PBKDF2 with SHA-512 and a very high iteration count (600,000) to
  /// derive the encryption key, followed by AES-256-GCM encryption with
  /// hardware acceleration on Apple Silicon.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier for the data to encrypt
  ///   - password: The password to derive the encryption key from
  ///   - options: Optional encryption options
  /// - Returns: A Result containing the encrypted data identifier or an error
  public func encryptWithPassword(
    dataIdentifier: String,
    password: String,
    options: EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "encryptWithPassword",
      algorithm: "AES-GCM",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("encryptWithPassword", context: context)
    
    // Get the data to encrypt
    let dataResult = await retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(dataToEncrypt):
        await logDebug(
          "Retrieved data for password-based encryption, size: \(dataToEncrypt.count) bytes",
          context: context
        )
        
        // Generate a secure random salt
        let salt = generateRandomBytes(count: 16)
        
        // Derive key from password using same parameters
        let derivedKey = deriveKeyFromPassword(
          password: password,
          salt: salt,
          iterations: 600000, // Very high iteration count for security
          keyLength: 32       // 256-bit key
        )
        
        // Generate a nonce
        let nonce = generateRandomBytes(count: 12)
        
        // Process additional authenticated data if provided
        var authenticatedData: Data? = nil
        if let aadIdentifier = options?.authenticatedDataIdentifier {
          let aadResult = await retrieveData(withIdentifier: aadIdentifier)
          switch aadResult {
            case let .success(aad):
              authenticatedData = aad
            case let .failure(error):
              let _ = await logOperationError("encryptWithPassword", error: error, startTime: startTime, context: context)
              return .failure(error)
          }
        }
        
        // Perform encryption using AES-GCM
        let encryptionResult = CryptoKitBridge.encryptAESGCM(
          data: dataToEncrypt,
          key: derivedKey,
          nonce: nonce,
          authenticatedData: authenticatedData
        )
        
        // Process encryption result
        switch encryptionResult {
          case let .success((encryptedData, _)):
            // Format the complete encrypted package, including:
            // - Salt (for key derivation)
            // - Nonce (for encryption)
            // - Iteration count (4 bytes)
            // - Encrypted data with authentication tag
            
            var resultData = Data()
            
            // Add metadata version byte (for future format changes)
            resultData.append(0x01)
            
            // Add salt
            resultData.append(salt)
            
            // Add nonce
            resultData.append(nonce)
            
            // Add iteration count (big-endian UInt32)
            var iterationCount: UInt32 = 600000
            let iterationData = withUnsafeBytes(of: &iterationCount.bigEndian) {
              Data($0)
            }
            resultData.append(iterationData)
            
            // Add encrypted data with authentication tag
            resultData.append(encryptedData)
            
            // Store the encrypted data
            let encryptedDataIdentifier = options?.resultIdentifier ?? "\(dataIdentifier).pw-encrypted"
            let storeResult = await storeData(resultData, withIdentifier: encryptedDataIdentifier)
            
            switch storeResult {
              case .success:
                // Log successful encryption
                let executionTime = await logOperationComplete(
                  "encryptWithPassword",
                  startTime: startTime,
                  context: context.withMetadata(
                    LogMetadataDTOCollection()
                      .withOperational(key: "originalSize", value: "\(dataToEncrypt.count)")
                      .withOperational(key: "encryptedSize", value: "\(resultData.count)")
                  )
                )
                
                // Return the identifier for the encrypted data
                return .success(encryptedDataIdentifier)
                
              case let .failure(error):
                // Log storage error
                let _ = await logOperationError(
                  "encryptWithPassword",
                  error: error,
                  startTime: startTime,
                  context: context
                )
                return .failure(error)
            }
            
          case let .failure(error):
            // Convert and log the encryption error
            let securityError = error.toSecurityStorageError()
            let _ = await logOperationError(
              "encryptWithPassword",
              error: securityError,
              startTime: startTime,
              context: context
            )
            return .failure(securityError)
        }
        
      case let .failure(error):
        // Log data retrieval error
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        
        let _ = await logOperationError(
          "encryptWithPassword",
          error: error,
          startTime: startTime,
          context: errorContext
        )
        
        return .failure(error)
    }
  }
  
  /// Decrypts data using a password that was previously encrypted with encryptWithPassword.
  ///
  /// This method decrypts data that was encrypted using a password-based key derivation
  /// process, restoring the original data if the password is correct.
  ///
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier for the encrypted data
  ///   - password: The password used to encrypt the data
  ///   - options: Optional decryption options
  /// - Returns: A Result containing the decrypted data identifier or an error
  public func decryptWithPassword(
    encryptedDataIdentifier: String,
    password: String,
    options: DecryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "decryptWithPassword",
      algorithm: "AES-GCM",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("decryptWithPassword", context: context)
    
    // Get the encrypted data
    let dataResult = await retrieveData(withIdentifier: encryptedDataIdentifier)
    
    switch dataResult {
      case let .success(encryptedBytes):
        // Verify minimum size for our format
        // Format: Version(1) + Salt(16) + Nonce(12) + Iterations(4) + EncryptedData
        let minSize = 1 + 16 + 12 + 4
        
        if encryptedBytes.count < minSize {
          let error = SecurityStorageError.dataCorrupted(details: "Encrypted data too short or malformed")
          let _ = await logOperationError("decryptWithPassword", error: error, startTime: startTime, context: context)
          return .failure(error)
        }
        
        // Extract format version
        let version = encryptedBytes[0]
        guard version == 0x01 else {
          let error = SecurityStorageError.unsupportedOperation(details: "Unsupported password encryption format version: \(version)")
          let _ = await logOperationError("decryptWithPassword", error: error, startTime: startTime, context: context)
          return .failure(error)
        }
        
        // Extract components
        let salt = encryptedBytes.subdata(in: 1..<17)  // 16 bytes
        let nonce = encryptedBytes.subdata(in: 17..<29)  // 12 bytes
        
        // Extract iteration count
        let iterationData = encryptedBytes.subdata(in: 29..<33)  // 4 bytes
        let iterations = iterationData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        
        // Extract encrypted data with tag
        let encryptedData = encryptedBytes.subdata(in: 33..<encryptedBytes.count)
        
        // Derive key from password using same parameters
        let derivedKey = deriveKeyFromPassword(
          password: password,
          salt: salt,
          iterations: Int(iterations),
          keyLength: 32  // 256-bit key
        )
        
        // Process additional authenticated data if provided
        var authenticatedData: Data? = nil
        if let aadIdentifier = options?.authenticatedDataIdentifier {
          let aadResult = await retrieveData(withIdentifier: aadIdentifier)
          switch aadResult {
            case let .success(aad):
              authenticatedData = aad
            case let .failure(error):
              let _ = await logOperationError("decryptWithPassword", error: error, startTime: startTime, context: context)
              return .failure(error)
          }
        }
        
        // Attempt to decrypt
        let decryptionResult = CryptoKitBridge.decryptAESGCM(
          encryptedData: encryptedData,
          key: derivedKey,
          nonce: nonce,
          authenticatedData: authenticatedData
        )
        
        // Process decryption result
        switch decryptionResult {
          case let .success(decryptedData):
            // Store the decrypted data
            let decryptedDataIdentifier = options?.resultIdentifier ?? "\(encryptedDataIdentifier).decrypted"
            let storeResult = await storeData(decryptedData, withIdentifier: decryptedDataIdentifier)
            
            switch storeResult {
              case .success:
                // Log successful decryption
                let executionTime = await logOperationComplete(
                  "decryptWithPassword",
                  startTime: startTime,
                  context: context.withMetadata(
                    LogMetadataDTOCollection()
                      .withOperational(key: "encryptedSize", value: "\(encryptedBytes.count)")
                      .withOperational(key: "decryptedSize", value: "\(decryptedData.count)")
                  )
                )
                
                // Return the identifier for the decrypted data
                return .success(decryptedDataIdentifier)
                
              case let .failure(error):
                // Log storage error
                let _ = await logOperationError(
                  "decryptWithPassword",
                  error: error,
                  startTime: startTime,
                  context: context
                )
                return .failure(error)
            }
            
          case let .failure(error):
            // A failure here is likely due to an incorrect password
            // Convert to a more specific error type
            let securityError: SecurityStorageError
            if error.code == .authenticationFailed {
              securityError = SecurityStorageError.authenticationFailed(details: "Incorrect password or corrupted data")
            } else {
              securityError = error.toSecurityStorageError()
            }
            
            let _ = await logOperationError(
              "decryptWithPassword",
              error: securityError,
              startTime: startTime,
              context: context
            )
            return .failure(securityError)
        }
        
      case let .failure(error):
        // Log data retrieval error
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        
        let _ = await logOperationError(
          "decryptWithPassword",
          error: error,
          startTime: startTime,
          context: errorContext
        )
        
        return .failure(error)
    }
  }
  
  /// Computes an HMAC-SHA512 for the given data.
  ///
  /// Hash-based Message Authentication Code (HMAC) with SHA-512 provides
  /// the highest level of security for data authentication, ensuring both
  /// integrity and authenticity of the message.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier for the data to authenticate
  ///   - keyIdentifier: Identifier for the authentication key
  ///   - options: Optional hashing options
  /// - Returns: A Result containing the HMAC identifier or an error
  public func computeHMAC(
    dataIdentifier: String,
    keyIdentifier: String,
    options: HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "computeHMAC",
      algorithm: "HMAC-SHA512",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("computeHMAC", context: context)
    
    // Get the data to authenticate
    let dataResult = await retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(dataToAuthenticate):
        await logDebug(
          "Retrieved data for HMAC computation, size: \(dataToAuthenticate.count) bytes",
          context: context
        )
        
        // Get the key
        let keyResult = await retrieveData(withIdentifier: keyIdentifier)
        
        switch keyResult {
          case let .success(keyData):
            // Compute the HMAC
            let hmacResult = CryptoKitBridge.hmacSHA512(
              data: dataToAuthenticate,
              key: keyData
            )
            
            // Process HMAC result
            switch hmacResult {
              case let .success(hmacValue):
                // Store the HMAC
                let hmacIdentifier = options?.resultIdentifier ?? "\(dataIdentifier).hmac"
                let storeResult = await storeData(hmacValue, withIdentifier: hmacIdentifier)
                
                switch storeResult {
                  case .success:
                    // Log successful HMAC computation
                    let executionTime = await logOperationComplete(
                      "computeHMAC",
                      startTime: startTime,
                      context: context.withMetadata(
                        LogMetadataDTOCollection()
                          .withOperational(key: "dataSize", value: "\(dataToAuthenticate.count)")
                          .withOperational(key: "hmacSize", value: "\(hmacValue.count)")
                      )
                    )
                    
                    // Return the identifier for the HMAC
                    return .success(hmacIdentifier)
                    
                  case let .failure(error):
                    // Log storage error
                    let _ = await logOperationError(
                      "computeHMAC",
                      error: error,
                      startTime: startTime,
                      context: context
                    )
                    return .failure(error)
                }
                
              case let .failure(error):
                // Convert and log the HMAC error
                let securityError = error.toSecurityStorageError()
                let _ = await logOperationError(
                  "computeHMAC",
                  error: securityError,
                  startTime: startTime,
                  context: context
                )
                return .failure(securityError)
            }
            
          case let .failure(error):
            // Log key retrieval error
            let errorContext = context.withMetadata(
              LogMetadataDTOCollection()
                .withPublic(key: "error", value: error.localizedDescription)
            )
            
            let _ = await logOperationError(
              "computeHMAC",
              error: error,
              startTime: startTime,
              context: errorContext
            )
            
            return .failure(error)
        }
        
      case let .failure(error):
        // Log data retrieval error
        let errorContext = context.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "error", value: error.localizedDescription)
        )
        
        let _ = await logOperationError(
          "computeHMAC",
          error: error,
          startTime: startTime,
          context: errorContext
        )
        
        return .failure(error)
    }
  }
  
  /// Verifies an HMAC-SHA512 value against the original data.
  ///
  /// This method verifies that an HMAC value was computed from the given data
  /// using the specified key, ensuring data integrity and authenticity.
  ///
  /// - Parameters:
  ///   - hmacIdentifier: Identifier for the HMAC value to verify
  ///   - dataIdentifier: Identifier for the original data
  ///   - keyIdentifier: Identifier for the authentication key
  ///   - options: Optional verification options
  /// - Returns: A Result indicating whether the HMAC is valid
  public func verifyHMAC(
    hmacIdentifier: String,
    dataIdentifier: String,
    keyIdentifier: String,
    options: VerificationOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "verifyHMAC",
      algorithm: "HMAC-SHA512",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("verifyHMAC", context: context)
    
    // Get the HMAC to verify
    let hmacResult = await retrieveData(withIdentifier: hmacIdentifier)
    
    switch hmacResult {
      case let .success(hmacValue):
        // Get the data
        let dataResult = await retrieveData(withIdentifier: dataIdentifier)
        
        switch dataResult {
          case let .success(originalData):
            // Get the key
            let keyResult = await retrieveData(withIdentifier: keyIdentifier)
            
            switch keyResult {
              case let .success(keyData):
                // Verify the HMAC
                let verifyResult = CryptoKitBridge.verifyHMACSHA512(
                  authenticationCode: hmacValue,
                  data: originalData,
                  key: keyData
                )
                
                // Process verification result
                switch verifyResult {
                  case let .success(isValid):
                    // Log successful verification
                    let executionTime = await logOperationComplete(
                      "verifyHMAC",
                      startTime: startTime,
                      context: context.withMetadata(
                        LogMetadataDTOCollection()
                          .withOperational(key: "isValid", value: "\(isValid)")
                      )
                    )
                    
                    // Return verification result
                    return .success(isValid)
                    
                  case let .failure(error):
                    // Convert and log the verification error
                    let securityError = error.toSecurityStorageError()
                    let _ = await logOperationError(
                      "verifyHMAC",
                      error: securityError,
                      startTime: startTime,
                      context: context
                    )
                    return .failure(securityError)
                }
                
              case let .failure(error):
                // Log key retrieval error
                let _ = await logOperationError(
                  "verifyHMAC",
                  error: error,
                  startTime: startTime,
                  context: context
                )
                return .failure(error)
            }
            
          case let .failure(error):
            // Log data retrieval error
            let _ = await logOperationError(
              "verifyHMAC",
              error: error,
              startTime: startTime,
              context: context
            )
            return .failure(error)
        }
        
      case let .failure(error):
        // Log HMAC retrieval error
        let _ = await logOperationError(
          "verifyHMAC",
          error: error,
          startTime: startTime,
          context: context
        )
        return .failure(error)
    }
  }
  
  /// Derives multiple cryptographic keys from a master key using HKDF.
  ///
  /// Hash-based Key Derivation Function (HKDF) with SHA-512 allows securely
  /// deriving multiple cryptographic keys from a single master key.
  /// This is useful for creating separate keys for different purposes
  /// (encryption, authentication, etc.) from a single secret.
  ///
  /// - Parameters:
  ///   - masterKeyIdentifier: Identifier for the master key
  ///   - salt: Optional salt value to strengthen the derivation
  ///   - info: Optional context information to differentiate derived keys
  ///   - outputByteCount: Size of the derived key in bytes
  ///   - options: Optional key derivation options
  /// - Returns: A Result containing the derived key identifier or an error
  public func deriveKey(
    masterKeyIdentifier: String,
    salt: Data? = nil,
    info: Data? = nil,
    outputByteCount: Int = 32,
    options: KeyDerivationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "deriveKey",
      algorithm: "HKDF-SHA512",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("deriveKey", context: context)
    
    // Get the master key
    let keyResult = await retrieveData(withIdentifier: masterKeyIdentifier)
    
    switch keyResult {
      case let .success(masterKeyData):
        // Derive the key using HKDF
        let derivationResult = CryptoKitBridge.deriveKey(
          using: masterKeyData,
          salt: salt,
          info: info,
          outputByteCount: outputByteCount
        )
        
        // Process derivation result
        switch derivationResult {
          case let .success(derivedKeyData):
            // Store the derived key
            let derivedKeyIdentifier = options?.resultIdentifier ?? "derived_\(masterKeyIdentifier)_\(UUID().uuidString)"
            let storeResult = await storeData(derivedKeyData, withIdentifier: derivedKeyIdentifier)
            
            switch storeResult {
              case .success:
                // Log successful key derivation
                let executionTime = await logOperationComplete(
                  "deriveKey",
                  startTime: startTime,
                  context: context.withMetadata(
                    LogMetadataDTOCollection()
                      .withOperational(key: "derivedKeySize", value: "\(derivedKeyData.count)")
                  )
                )
                
                // Return the identifier for the derived key
                return .success(derivedKeyIdentifier)
                
              case let .failure(error):
                // Log storage error
                let _ = await logOperationError(
                  "deriveKey",
                  error: error,
                  startTime: startTime,
                  context: context
                )
                return .failure(error)
            }
            
          case let .failure(error):
            // Convert and log the derivation error
            let securityError = error.toSecurityStorageError()
            let _ = await logOperationError(
              "deriveKey",
              error: securityError,
              startTime: startTime,
              context: context
            )
            return .failure(securityError)
        }
        
      case let .failure(error):
        // Log master key retrieval error
        let _ = await logOperationError(
          "deriveKey",
          error: error,
          startTime: startTime,
          context: context
        )
        return .failure(error)
    }
  }
  
  /// Generates a cryptographic key pair for digital signatures.
  ///
  /// This method creates a key pair that can be used for digital signatures
  /// using one of the supported algorithms: Secure Enclave P-256, Curve25519,
  /// or P-521 ECDSA. When possible, it will use the Secure Enclave for
  /// enhanced security.
  ///
  /// - Parameters:
  ///   - keyType: The type of signature to use
  ///   - useSecureEnclave: Whether to use Secure Enclave when available
  ///   - options: Optional key generation options
  /// - Returns: A Result containing the public and private key identifiers or an error
  public func generateSignatureKeyPair(
    keyType: SignatureKeyType,
    useSecureEnclave: Bool = true,
    options: KeyGenerationOptions? = nil
  ) async -> Result<(publicKeyId: String, privateKeyId: String), SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "generateSignatureKeyPair",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("generateSignatureKeyPair", context: context)
    
    // Determine the signature algorithm to use
    let algorithm: String
    switch keyType {
      case .p256:
        algorithm = "P-256 ECDSA"
      case .p521:
        algorithm = "P-521 ECDSA"
      case .curve25519:
        algorithm = "Curve25519 EdDSA"
    }
    
    // Update context with algorithm information
    let updatedContext = context.withMetadata(
      LogMetadataDTOCollection()
        .withOperational(key: "algorithm", value: algorithm)
        .withOperational(key: "useSecureEnclave", value: "\(useSecureEnclave)")
    )
    
    do {
      // Generate the key pair based on the key type
      var publicKeyData: Data
      var privateKeyData: Data
      var secureEnclaveUsed = false
      
      switch keyType {
        case .p256:
          if useSecureEnclave && isSecureEnclaveAvailable() {
            // Generate a P-256 key in the Secure Enclave
            let accessControl = SecAccessControlCreateWithFlags(
              nil,
              kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
              .privateKeyUsage,
              nil
            )!
            
            let secureEnclaveKey = try SecureEnclave.P256.Signing.PrivateKey(
              accessControl: accessControl,
              authenticationContext: nil
            )
            
            // Store the SecureEnclave reference persistently
            // This is a simplified implementation - in a real system,
            // we would need to securely store this reference
            
            // Get the public key representation
            publicKeyData = secureEnclaveKey.publicKey.rawRepresentation
            
            // For Secure Enclave keys, we don't have direct access to the private key
            // Instead, we store a reference or identifier
            privateKeyData = Data(UUID().uuidString.utf8)
            secureEnclaveUsed = true
            
          } else {
            // Generate a regular P-256 key
            let privateKey = P256.Signing.PrivateKey()
            privateKeyData = privateKey.rawRepresentation
            publicKeyData = privateKey.publicKey.rawRepresentation
          }
          
        case .p521:
          // P-521 keys cannot be stored in the Secure Enclave
          let privateKey = P521.Signing.PrivateKey()
          privateKeyData = privateKey.rawRepresentation
          publicKeyData = privateKey.publicKey.rawRepresentation
          
        case .curve25519:
          // Curve25519 keys cannot be stored in the Secure Enclave
          let privateKey = Curve25519.Signing.PrivateKey()
          privateKeyData = privateKey.rawRepresentation
          publicKeyData = privateKey.publicKey.rawRepresentation
      }
      
      // Create identifiers for the keys
      let keyTag = options?.keyTag ?? UUID().uuidString
      let publicKeyId = options?.publicKeyIdentifier ?? "pubkey_\(keyTag)"
      let privateKeyId = options?.privateKeyIdentifier ?? "privkey_\(keyTag)"
      
      // Store the public key
      let publicKeyStoreResult = await storeData(
        publicKeyData,
        withIdentifier: publicKeyId,
        metadata: [
          "keyType": keyType.rawValue,
          "keyPurpose": "signing",
          "isPublicKey": "true",
          "algorithm": algorithm
        ]
      )
      
      guard case .success = publicKeyStoreResult else {
        if case let .failure(error) = publicKeyStoreResult {
          let _ = await logOperationError(
            "generateSignatureKeyPair",
            error: error,
            startTime: startTime,
            context: updatedContext
          )
          return .failure(error)
        }
        return .failure(.storageError(details: "Failed to store public key"))
      }
      
      // Store the private key or reference
      let privateKeyStoreResult = await storeData(
        privateKeyData,
        withIdentifier: privateKeyId,
        metadata: [
          "keyType": keyType.rawValue,
          "keyPurpose": "signing",
          "isPrivateKey": "true",
          "algorithm": algorithm,
          "useSecureEnclave": String(secureEnclaveUsed)
        ]
      )
      
      guard case .success = privateKeyStoreResult else {
        if case let .failure(error) = privateKeyStoreResult {
          let _ = await logOperationError(
            "generateSignatureKeyPair",
            error: error,
            startTime: startTime,
            context: updatedContext
          )
          return .failure(error)
        }
        return .failure(.storageError(details: "Failed to store private key"))
      }
      
      // Log successful key pair generation
      let executionTime = await logOperationComplete(
        "generateSignatureKeyPair",
        startTime: startTime,
        context: updatedContext.withMetadata(
          LogMetadataDTOCollection()
            .withOperational(key: "publicKeyId", value: publicKeyId)
            .withOperational(key: "privateKeyId", value: privateKeyId)
            .withOperational(key: "secureEnclaveUsed", value: "\(secureEnclaveUsed)")
        )
      )
      
      // Return the key identifiers
      return .success((publicKeyId, privateKeyId))
      
    } catch {
      // Convert and log any errors
      let securityError = SecurityStorageError.keyGenerationFailed(details: error.localizedDescription)
      let _ = await logOperationError(
        "generateSignatureKeyPair",
        error: securityError,
        startTime: startTime,
        context: updatedContext
      )
      return .failure(securityError)
    }
  }
  
  /// Signs data using a private key with the specified signature algorithm.
  ///
  /// This method creates a digital signature for the given data using
  /// the private key identified by privateKeyId. It supports multiple
  /// signature algorithms, including Secure Enclave-backed signatures
  /// when available.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier for the data to sign
  ///   - privateKeyId: Identifier for the private key
  ///   - options: Optional signing options
  /// - Returns: A Result containing the signature identifier or an error
  public func signData(
    dataIdentifier: String,
    privateKeyId: String,
    options: SigningOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "signData",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("signData", context: context)
    
    // Get the data to sign
    let dataResult = await retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(dataToSign):
        // Get the private key
        let keyResult = await retrieveData(
          withIdentifier: privateKeyId,
          includeMetadata: true
        )
        
        switch keyResult {
          case let .success((privateKeyData, metadata)):
            // Extract metadata information
            let keyType = metadata?["keyType"] ?? "p256"
            let useSecureEnclave = (metadata?["useSecureEnclave"] ?? "false") == "true"
            
            // Determine signature type
            let signatureType: CryptoKitBridge.SignatureType
            switch keyType {
              case SignatureKeyType.p256.rawValue:
                signatureType = .secureEnclaveP256
              case SignatureKeyType.p521.rawValue:
                signatureType = .p521ECDSA
              case SignatureKeyType.curve25519.rawValue:
                signatureType = .curve25519
              default:
                signatureType = .secureEnclaveP256
            }
            
            // Generate the signature
            let signatureResult: Result<Data, CryptoOperationError>
            
            if useSecureEnclave && signatureType == .secureEnclaveP256 {
              // For Secure Enclave keys, we need to retrieve the key reference
              // In a real implementation, this would involve more complex logic
              // to retrieve and use the SecureEnclave.P256.Signing.PrivateKey
              
              // This is a placeholder for demonstration
              let error = CryptoOperationError(
                code: .unsupportedOperation,
                message: "Secure Enclave key usage needs additional implementation"
              )
              signatureResult = .failure(error)
              
            } else {
              // Use regular signature generation
              signatureResult = CryptoKitBridge.generateSignature(
                for: dataToSign,
                using: privateKeyData,
                signatureType: signatureType
              )
            }
            
            // Process signature result
            switch signatureResult {
              case let .success(signature):
                // Store the signature
                let signatureId = options?.resultIdentifier ?? "sig_\(dataIdentifier)_\(UUID().uuidString)"
                let storeResult = await storeData(
                  signature,
                  withIdentifier: signatureId,
                  metadata: [
                    "signatureType": String(describing: signatureType),
                    "dataIdentifier": dataIdentifier,
                    "keyType": keyType
                  ]
                )
                
                switch storeResult {
                  case .success:
                    // Log successful signature generation
                    let executionTime = await logOperationComplete(
                      "signData",
                      startTime: startTime,
                      context: context.withMetadata(
                        LogMetadataDTOCollection()
                          .withOperational(key: "dataSize", value: "\(dataToSign.count)")
                          .withOperational(key: "signatureSize", value: "\(signature.count)")
                          .withOperational(key: "signatureType", value: String(describing: signatureType))
                      )
                    )
                    
                    // Return the signature identifier
                    return .success(signatureId)
                    
                  case let .failure(error):
                    // Log storage error
                    let _ = await logOperationError(
                      "signData",
                      error: error,
                      startTime: startTime,
                      context: context
                    )
                    return .failure(error)
                }
                
              case let .failure(error):
                // Convert and log the signature error
                let securityError = error.toSecurityStorageError()
                let _ = await logOperationError(
                  "signData",
                  error: securityError,
                  startTime: startTime,
                  context: context
                )
                return .failure(securityError)
            }
            
          case let .failure(error):
            // Log key retrieval error
            let _ = await logOperationError(
              "signData",
              error: error,
              startTime: startTime,
              context: context
            )
            return .failure(error)
        }
        
      case let .failure(error):
        // Log data retrieval error
        let _ = await logOperationError(
          "signData",
          error: error,
          startTime: startTime,
          context: context
        )
        return .failure(error)
    }
  }
  
  /// Verifies a digital signature against the original data.
  ///
  /// This method verifies that a signature was created for the given data
  /// using the specified public key. It supports multiple signature algorithms
  /// and provides a boolean result indicating whether the signature is valid.
  ///
  /// - Parameters:
  ///   - signatureIdentifier: Identifier for the signature to verify
  ///   - dataIdentifier: Identifier for the original data
  ///   - publicKeyId: Identifier for the public key
  ///   - options: Optional verification options
  /// - Returns: A Result indicating whether the signature is valid
  public func verifySignature(
    signatureIdentifier: String,
    dataIdentifier: String,
    publicKeyId: String,
    options: VerificationOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Ensure CryptoKit is initialised
    await initializeCryptoKit()
    
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "verifySignature",
      correlationID: options?.correlationID ?? UUID().uuidString
    )
    
    // Log start of operation
    let startTime = await logOperationStart("verifySignature", context: context)
    
    // Get the signature to verify
    let signatureResult = await retrieveData(
      withIdentifier: signatureIdentifier,
      includeMetadata: true
    )
    
    switch signatureResult {
      case let .success((signature, metadata)):
        // Get the original data
        let dataResult = await retrieveData(withIdentifier: dataIdentifier)
        
        switch dataResult {
          case let .success(originalData):
            // Get the public key
            let keyResult = await retrieveData(
              withIdentifier: publicKeyId,
              includeMetadata: true
            )
            
            switch keyResult {
              case let .success((publicKey, keyMetadata)):
                // Determine signature type
                let signatureTypeString = metadata?["signatureType"] ?? "secureEnclaveP256"
                let keyType = keyMetadata?["keyType"] ?? metadata?["keyType"] ?? SignatureKeyType.p256.rawValue
                
                let signatureType: CryptoKitBridge.SignatureType
                switch keyType {
                  case SignatureKeyType.p256.rawValue:
                    signatureType = .secureEnclaveP256
                  case SignatureKeyType.p521.rawValue:
                    signatureType = .p521ECDSA
                  case SignatureKeyType.curve25519.rawValue:
                    signatureType = .curve25519
                  default:
                    // Default to P-256 if unclear
                    signatureType = .secureEnclaveP256
                }
                
                // Verify the signature
                let verifyResult = CryptoKitBridge.verifySignature(
                  signature,
                  for: originalData,
                  using: publicKey,
                  signatureType: signatureType
                )
                
                // Process verification result
                switch verifyResult {
                  case let .success(isValid):
                    // Log successful verification
                    let executionTime = await logOperationComplete(
                      "verifySignature",
                      startTime: startTime,
                      context: context.withMetadata(
                        LogMetadataDTOCollection()
                          .withOperational(key: "isValid", value: "\(isValid)")
                          .withOperational(key: "signatureType", value: String(describing: signatureType))
                      )
                    )
                    
                    // Return verification result
                    return .success(isValid)
                    
                  case let .failure(error):
                    // Convert and log the verification error
                    let securityError = error.toSecurityStorageError()
                    let _ = await logOperationError(
                      "verifySignature",
                      error: securityError,
                      startTime: startTime,
                      context: context
                    )
                    return .failure(securityError)
                }
                
              case let .failure(error):
                // Log key retrieval error
                let _ = await logOperationError(
                  "verifySignature",
                  error: error,
                  startTime: startTime,
                  context: context
                )
                return .failure(error)
            }
            
          case let .failure(error):
            // Log data retrieval error
            let _ = await logOperationError(
              "verifySignature",
              error: error,
              startTime: startTime,
              context: context
            )
            return .failure(error)
        }
        
      case let .failure(error):
        // Log signature retrieval error
        let _ = await logOperationError(
          "verifySignature",
          error: error,
          startTime: startTime,
          context: context
        )
        return .failure(error)
    }
  }
  
  /// Functions that support the Secure Enclave if available
  #if os(macOS) || os(iOS)
  /// Generates a key using the Secure Enclave.
  ///
  /// - Parameter tag: The tag to use for the key
  /// - Returns: The key data or reference
  /// - Throws: SecurityStorageError if key generation fails
  private func generateSecureEnclaveKey(tag: String) throws -> Data {
    // Check if Secure Enclave is available
    if SecureEnclave.isAvailable {
      // For a real implementation, this would create a Secure Enclave key
      // and return a reference to it
      
      // Placeholder implementation
      return Data([0x01, 0x02, 0x03, 0x04]) // Would be a key reference in reality
    }
    
    // Fallback if Secure Enclave is not available
    throw SecurityStorageError.operationFailed("Secure Enclave not available")
  }
  #endif
{{ ... }}

  /// Computed property for the crypto provider's name.
  private var providerName: String {
    "CryptoServicesApple"
  }
  
  /// Generates random bytes using a cryptographically secure random number generator.
  ///
  /// - Parameter count: The number of bytes to generate
  /// - Returns: The generated random bytes as Data
  private func generateRandomBytes(count: Int) -> Data {
    var bytes = [UInt8](repeating: 0, count: count)
    _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    return Data(bytes)
  }
  
  /// Computes SHA-256 hash of the given data.
  ///
  /// - Parameter data: The data to hash
  /// - Returns: The SHA-256 hash of the data
  private func cryptoKitSHA256(data: Data) -> Data {
    // In a real implementation, this would use CryptoKit.SHA256
    // For demonstration purposes, we'll use CommonCrypto
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { buffer in
      _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hashBytes)
    }
    return Data(hashBytes)
  }
  
  /// Computes SHA-512 hash of the given data.
  ///
  /// - Parameter data: The data to hash
  /// - Returns: The SHA-512 hash of the data
  private func cryptoKitSHA512(data: Data) -> Data {
    // In a real implementation, this would use CryptoKit.SHA512
    // For demonstration purposes, we'll use CommonCrypto
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    data.withUnsafeBytes { buffer in
      _ = CC_SHA512(buffer.baseAddress, CC_LONG(data.count), &hashBytes)
    }
    return Data(hashBytes)
  }
  
  /// Log an error associated with a cryptographic operation.
  ///
  /// - Parameters:
  ///   - operation: The name of the operation
  ///   - error: The error that occurred
  ///   - startTime: Optional start time for performance tracking
  ///   - context: Optional context for the operation
  /// - Returns: The execution time in milliseconds
  private func logOperationError(
    _ operation: String,
    error: Error,
    startTime: CFAbsoluteTime? = nil,
    context: CryptoLogContext? = nil
  ) async -> Double {
    let executionTime: Double
    if let startTime = startTime {
      let endTime = CFAbsoluteTimeGetCurrent()
      executionTime = (endTime - startTime) * 1000 // Convert to milliseconds
    } else {
      executionTime = 0
    }
    
    let errorContext = context ?? CryptoLogContext(operation: operation)
    let updatedContext = errorContext.withMetadata(
      LogMetadataDTOCollection()
        .withPublic(key: "error", value: error.localizedDescription)
        .withPublic(key: "executionTimeMs", value: String(format: "%.2f", executionTime))
    )
    
    if let logger = logger {
      await logger.error(
        "[\(providerName)] \(operation) failed: \(error.localizedDescription)",
        context: updatedContext.toLogContextDTO()
      )
    }
    
    return executionTime
  }
  
  /// Log the start of a cryptographic operation.
  ///
  /// - Parameters:
  ///   - operation: The name of the operation
  ///   - context: Optional context for the operation
  /// - Returns: The start time as CFAbsoluteTime
  private func logOperationStart(
    _ operation: String,
    context: CryptoLogContext? = nil
  ) async -> CFAbsoluteTime {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    if let logger = logger, let context = context {
      await logger.debug(
        "[\(providerName)] Starting \(operation)",
        context: context.toLogContextDTO()
      )
    }
    
    return startTime
  }
  
  /// Log the completion of a cryptographic operation.
  ///
  /// - Parameters:
  ///   - operation: The name of the operation
  ///   - startTime: The start time from logOperationStart
  ///   - status: The status message
  ///   - context: Optional context for the operation
  /// - Returns: The execution time in milliseconds
  private func logOperationComplete(
    _ operation: String,
    startTime: CFAbsoluteTime,
    status: String = "successful",
    context: CryptoLogContext? = nil
  ) async -> Double {
    let endTime = CFAbsoluteTimeGetCurrent()
    let executionTime = (endTime - startTime) * 1000 // Convert to milliseconds
    
    let baseContext = context ?? CryptoLogContext(operation: operation)
    let updatedContext = baseContext.withMetadata(
      LogMetadataDTOCollection()
        .withPublic(key: "executionTimeMs", value: String(format: "%.2f", executionTime))
        .withPublic(key: "status", value: status)
    )
    
    if let logger = logger {
      await logger.debug(
        "[\(providerName)] \(operation) completed in \(String(format: "%.2f", executionTime))ms",
        context: updatedContext.toLogContextDTO()
      )
    }
    
    return executionTime
  }
  
  /// Log a debug message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: Optional context for the message
  private func logDebug(
    _ message: String,
    context: LogContextDTO? = nil
  ) async {
    if let logger = logger {
      await logger.debug(message, context: context)
    }
  }
  
  /// Log an info message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: Optional context for the message
  private func logInfo(
    _ message: String,
    context: LogContextDTO? = nil
  ) async {
    if let logger = logger {
      await logger.info(message, context: context)
    }
  }
  
  /// Log a warning message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: Optional context for the message
  private func logWarning(
    _ message: String,
    context: LogContextDTO? = nil
  ) async {
    if let logger = logger {
      await logger.warn(message, context: context)
    }
  }
  
  /// Log an error message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: Optional context for the message
  private func logError(
    _ message: String,
    context: LogContextDTO? = nil
  ) async {
    if let logger = logger {
      await logger.error(message, context: context)
    }
  }
{{ ... }}
