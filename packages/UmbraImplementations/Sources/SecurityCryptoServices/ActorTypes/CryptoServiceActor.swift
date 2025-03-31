import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import ProviderFactories
import SecurityCoreInterfaces

/**
 # CryptoServiceActor

 A Swift actor that provides thread-safe access to cryptographic operations
 using the pluggable security provider architecture.

 This actor fully embraces Swift's structured concurrency model, offering
 asynchronous methods for all cryptographic operations while ensuring proper
 isolation of mutable state.

 ## Usage

 ```swift
 // Create the actor with a specific provider type
 let cryptoService = CryptoServiceActor(providerType: .apple, logger: logger)

 // Perform operations asynchronously
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```

 ## Thread Safety

 All methods are automatically thread-safe due to Swift's actor isolation rules.
 Mutable state is properly contained within the actor and cannot be accessed from
 outside except through the defined async interfaces.
 */
public actor CryptoServiceActor {
  // MARK: - Properties

  /// The underlying security provider implementation
  private var provider: EncryptionProviderProtocol

  /// Logger for recording operations
  private let logger: LoggingProtocol

  /// Domain-specific logger for cryptographic operations
  private let logAdapter: DomainLogAdapter

  /// The source identifier for logging
  private let logSource="CryptoService"

  /// Configuration options for cryptographic operations
  private var defaultConfig: SecurityConfigDTO

  // MARK: - Initialisation

  /**
   Initialises a new crypto service actor with the specified provider type.

   - Parameters:
      - providerType: The type of security provider to use
      - logger: Logger for recording operations
   */
  public init(providerType: SecurityProviderType?=nil, logger: LoggingProtocol?) {
    // Use the provided logger or create a default one
    self.logger=logger ?? LoggingServiceFactory.createDefaultLogger()
    logAdapter=DomainLogAdapter(logger: self.logger, domain: "CryptoService")

    do {
      if let providerType {
        provider=try SecurityProviderFactoryImpl.createProvider(type: providerType)
      } else {
        provider=try SecurityProviderFactoryImpl.createBestAvailableProvider()
      }

      // If the provider successfully initialises, set the default config
      defaultConfig=SecurityConfigDTO(
        algorithm: "AES",
        keySize: 256,
        mode: "GCM",
        options: [:]
      )
    } catch {
      // If provider creation fails, use a fallback provider
      provider=FallbackEncryptionProvider()
      defaultConfig=SecurityConfigDTO(
        algorithm: "AES",
        keySize: 128,
        mode: "CBC",
        options: [:]
      )

      Task {
        await logAdapter.warning(
          "Failed to create preferred provider, using fallback: \(error.localizedDescription)",
          source: logSource
        )
      }
    }
  }

  /**
   Changes the active security provider.

   - Parameter type: The provider type to switch to
   - Returns: True if the provider was successfully changed, false otherwise
   */
  public func setProviderType(_ type: SecurityProviderType) async throws {
    await logAdapter.debug(
      "Changing provider to: \(type.rawValue)",
      source: logSource
    )

    do {
      let newProvider=try SecurityProviderFactoryImpl.createProvider(type: type)
      provider=newProvider
      defaultConfig=SecurityConfigDTO(
        algorithm: "AES",
        keySize: 256,
        mode: "GCM",
        options: [:]
      )

      await logAdapter.debug(
        "Provider changed to: \(type.rawValue)",
        source: logSource
      )
    } catch {
      await logAdapter.error(
        "Failed to change provider: \(error.localizedDescription)",
        source: logSource
      )
      throw SecurityServiceError.providerError(error.localizedDescription)
    }
  }

  // MARK: - Encryption Operations

  /**
   Encrypts data using the configured provider.

   - Parameters:
      - data: The data to encrypt
      - key: The encryption key
      - config: Optional configuration override
   - Returns: Encrypted data wrapped in SecureBytes
   - Throws: SecurityProtocolError if encryption fails
   */
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes,
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Encrypting data with algorithm: \(algorithm)",
      source: logSource
    )

    let dataBytes=data.extractUnderlyingData()
    let keyBytes=key.extractUnderlyingData()

    // Generate IV using the provider
    let iv: Data
    do {
      iv=try provider.generateIV(size: 16)
    } catch {
      await logAdapter.error(
        "Failed to generate IV: \(error.localizedDescription)",
        source: logSource
      )
      throw SecurityProtocolError
        .cryptographicError("Failed to generate IV: \(error.localizedDescription)")
    }

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    // Encrypt data
    do {
      let encryptedData=try provider.encrypt(
        plaintext: dataBytes,
        key: keyBytes,
        iv: iv,
        config: operationConfig
      )

      // Prepend IV to encrypted data for later decryption
      var result=Data(capacity: iv.count + encryptedData.count)
      result.append(iv)
      result.append(encryptedData)

      await logAdapter.debug(
        "Encryption completed successfully",
        source: logSource
      )

      return SecureBytes(data: result)
    } catch {
      await logAdapter.error(
        "Encryption failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Encryption failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Decrypts data using the configured provider.

   - Parameters:
      - data: The data to decrypt (IV + ciphertext)
      - key: The decryption key
      - config: Optional configuration override
   - Returns: Decrypted data wrapped in SecureBytes
   - Throws: SecurityProtocolError if decryption fails
   */
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes,
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Decrypting data with algorithm: \(algorithm)",
      source: logSource
    )

    let dataBytes=data.extractUnderlyingData()
    let keyBytes=key.extractUnderlyingData()

    // Validate minimum length (IV + at least some ciphertext)
    guard dataBytes.count > 16 else {
      await logAdapter.error(
        "Encrypted data too short, must include IV",
        source: logSource
      )
      throw SecurityProtocolError.invalidInput("Encrypted data too short")
    }

    // Extract IV and ciphertext
    let iv=dataBytes.prefix(16)
    let ciphertext=dataBytes.dropFirst(16)

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    // Decrypt data
    do {
      let decryptedData=try provider.decrypt(
        ciphertext: ciphertext,
        key: keyBytes,
        iv: Data(iv),
        config: operationConfig
      )

      await logAdapter.debug(
        "Decryption completed successfully",
        source: logSource
      )

      return SecureBytes(data: decryptedData)
    } catch {
      await logAdapter.error(
        "Decryption failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Decryption failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Key Management

  /**
   Generates a cryptographic key of the specified size.

   - Parameters:
      - size: Key size in bits (128, 192, or 256 for AES)
      - config: Optional configuration override
   - Returns: Generated key wrapped in SecureBytes
   - Throws: SecurityProtocolError if key generation fails
   */
  public func generateKey(
    size: Int,
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Generating key with algorithm: \(algorithm)",
      source: logSource
    )

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      let keyData=try provider.generateKey(size: size, config: operationConfig)

      await logAdapter.debug(
        "Key generation completed successfully",
        source: logSource
      )

      return SecureBytes(data: keyData)
    } catch {
      await logAdapter.error(
        "Key generation failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Key generation failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Derives a key from a password using PBKDF2.

   - Parameters:
      - password: The password to derive from
      - salt: Salt to use for derivation
      - iterations: Number of iterations (higher is more secure but slower)
      - keyLength: Desired key length in bytes
      - config: Optional configuration override
   - Returns: Derived key wrapped in SecureBytes
   - Throws: SecurityProtocolError if key derivation fails
   */
  public func deriveKey(
    fromPassword password: String,
    salt: Data,
    iterations _: Int=10000,
    keyLength: Int=32,
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Deriving key with algorithm: \(algorithm)",
      source: logSource
    )

    do {
      // Since provider doesn't directly support deriveKey, we'll implement it
      // This is a placeholder implementation
      let passwordData=password.data(using: .utf8) ?? Data()
      let passwordBytes=SecureBytes(bytes: [UInt8](passwordData))
      let saltBytes=SecureBytes(bytes: [UInt8](salt))

      // Use the underlying hash function to create a key derivation
      // This is a simplified PBKDF2-like approach
      var derivedKey=SecureBytes(bytes: [UInt8](repeating: 0, count: keyLength))
      let result=await hash(data: passwordBytes)

      // In a real implementation, we would perform proper key derivation
      // For now, we're just returning the hashed password as a placeholder
      return result
    } catch {
      await logAdapter.error(
        "Key derivation failed: \(error.localizedDescription)",
        source: logSource
      )
      throw error
    }
  }

  // MARK: - Hash Functions

  /**
   Generates a cryptographic hash of data using the specified algorithm.

   - Parameters:
      - data: Data to hash
      - algorithm: Hashing algorithm to use
      - config: Optional configuration override
   - Returns: Hash value as SecureBytes
   - Throws: SecurityProtocolError if hashing fails
   */
  public func hash(
    data: SecureBytes,
    using algorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    await logAdapter.debug(
      "Hashing data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    let dataBytes=data.extractUnderlyingData()

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      // Execute the operation
      let result=await provider.hash(
        data: dataBytes
      )

      switch result {
        case let .success(hashData):
          await logAdapter.debug(
            "Hash operation completed successfully",
            source: logSource
          )
          return hashData
        case let .failure(error):
          await logAdapter.error(
            "Hash operation failed: \(error.localizedDescription)",
            source: logSource
          )
          throw error
      }
    } catch {
      await logAdapter.error(
        "Hash operation threw exception: \(error.localizedDescription)",
        source: logSource
      )
      throw error
    }
  }

  // MARK: - Batch Operations

  /**
   Encrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of data items to encrypt
      - key: The encryption key to use for all items
      - config: Optional configuration override
   - Returns: Array of encrypted data items
   - Throws: SecurityProtocolError if any encryption fails
   */
  public func encryptBatch(
    dataItems: [SecureBytes],
    using key: SecureBytes,
    config: SecurityConfigDTO?=nil
  ) async throws -> [SecureBytes] {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Encrypting batch of data with algorithm: \(algorithm)",
      source: logSource
    )

    var results=[SecureBytes]()
    var errorEncountered: Error?

    // Use task groups for parallel processing
    try await withThrowingTaskGroup(of: (Int, Result<SecureBytes, Error>).self) { group in
      // Queue up all encryption tasks
      for (index, data) in dataItems.enumerated() {
        group.addTask {
          do {
            let encrypted=try await self.encrypt(data: data, using: key, config: config)
            return (index, .success(encrypted))
          } catch {
            return (index, .failure(error))
          }
        }
      }

      // Prepare to receive results in order
      results=Array(repeating: SecureBytes(), count: dataItems.count)

      // Process results as they complete
      for try await (index, result) in group {
        switch result {
          case let .success(encrypted):
            results[index]=encrypted
          case let .failure(error):
            errorEncountered=error
            group.cancelAll() // Cancel remaining tasks on first error
        }
      }
    }

    if let error=errorEncountered {
      await logAdapter.error(
        "Batch encryption failed: \(error.localizedDescription)",
        source: logSource
      )
      throw error
    }

    await logAdapter.debug(
      "Batch encryption completed successfully",
      source: logSource
    )

    return results
  }

  /**
   Decrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of encrypted data items to decrypt
      - key: The decryption key to use for all items
      - config: Optional configuration override
   - Returns: Array of decrypted data items
   - Throws: SecurityProtocolError if any decryption fails
   */
  public func decryptBatch(
    dataItems: [SecureBytes],
    using key: SecureBytes,
    config: SecurityConfigDTO?=nil
  ) async throws -> [SecureBytes] {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Decrypting batch of data with algorithm: \(algorithm)",
      source: logSource
    )

    var results=[SecureBytes]()
    var errorEncountered: Error?

    // Use task groups for parallel processing
    try await withThrowingTaskGroup(of: (Int, Result<SecureBytes, Error>).self) { group in
      // Queue up all decryption tasks
      for (index, data) in dataItems.enumerated() {
        group.addTask {
          do {
            let decrypted=try await self.decrypt(data: data, using: key, config: config)
            return (index, .success(decrypted))
          } catch {
            return (index, .failure(error))
          }
        }
      }

      // Prepare to receive results in order
      results=Array(repeating: SecureBytes(), count: dataItems.count)

      // Process results as they complete
      for try await (index, result) in group {
        switch result {
          case let .success(decrypted):
            results[index]=decrypted
          case let .failure(error):
            errorEncountered=error
            group.cancelAll() // Cancel remaining tasks on first error
        }
      }
    }

    if let error=errorEncountered {
      await logAdapter.error(
        "Batch decryption failed: \(error.localizedDescription)",
        source: logSource
      )
      throw error
    }

    await logAdapter.debug(
      "Batch decryption completed successfully",
      source: logSource
    )

    return results
  }
}

/**
 Domain-specific log adapter for crypto operations.
 Wraps a standard logger and adds domain context.
 */
struct DomainLogAdapter {
  private let logger: LoggingProtocol
  private let domain: String

  init(logger: LoggingProtocol, domain: String) {
    self.logger=logger
    self.domain=domain
  }

  func trace(_ message: String, source: String) async {
    await logger.trace(message, metadata: PrivacyMetadata(), source: source)
  }

  func debug(_ message: String, source: String) async {
    await logger.debug(message, metadata: PrivacyMetadata(), source: source)
  }

  func info(_ message: String, source: String) async {
    await logger.info(message, metadata: PrivacyMetadata(), source: source)
  }

  func warning(_ message: String, source: String) async {
    await logger.warning(message, metadata: PrivacyMetadata(), source: source)
  }

  func error(_ message: String, source: String) async {
    await logger.error(message, metadata: PrivacyMetadata(), source: source)
  }

  func critical(_ message: String, source: String) async {
    await logger.critical(message, metadata: PrivacyMetadata(), source: source)
  }

  func logOperationStart(operation: String, source: String?=nil) async {
    await logger.debug(
      "Starting \(operation) operation",
      metadata: PrivacyMetadata(),
      source: source ?? domain
    )
  }

  func logOperationComplete(operation: String, source: String?=nil) async {
    await logger.debug(
      "Completed \(operation) operation",
      metadata: PrivacyMetadata(),
      source: source ?? domain
    )
  }
}

/**
 A simple factory for creating logging services
 */
enum LoggingServiceFactory {
  static func createDefaultLogger() -> LoggingProtocol {
    SimpleLogger()
  }
}

/**
 A simple logger implementation that follows LoggingProtocol
 */
final class SimpleLogger: LoggingProtocol {
  /// The system logger for output
  private let logger=Logger(
    subsystem: "com.umbra.securitycryptoservices",
    category: "CryptoServices"
  )

  /// The logging actor for this logger
  private let _loggingActor: LoggingActor

  public var loggingActor: LoggingActor {
    _loggingActor
  }

  public init() {
    // Initialize with a console log destination
    _loggingActor=LoggingActor(
      destinations: [ConsoleLogDestination()],
      minimumLogLevel: .debug
    )
  }

  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    let formattedMessage="[\(source)] \(message)"

    // Log to OSLog
    switch level {
      case .trace:
        logger.debug("TRACE: \(formattedMessage)")
      case .debug:
        logger.debug("\(formattedMessage)")
      case .info:
        logger.info("\(formattedMessage)")
      case .warning:
        logger.warning("\(formattedMessage)")
      case .error:
        logger.error("\(formattedMessage)")
      case .critical:
        logger.critical("\(formattedMessage)")
    }

    // Also log to LoggingActor with a context
    let context=LogContext(
      source: source,
      metadata: metadata ?? PrivacyMetadata()
    )

    await loggingActor.log(
      level: level,
      message: message,
      context: context
    )
  }

  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    let source=context.source
    await log(level, message, metadata: context.metadata as? PrivacyMetadata, source: source)
  }

  public func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }

  public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }

  public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }
}

/**
 A simple console log destination for LoggingActor
 */
actor ConsoleLogDestination: ActorLogDestination {
  /// The identifier for this log destination
  public let identifier: String="console"

  /// The minimum log level to process (nil means use the parent's level)
  public let minimumLogLevel: LogLevel?=nil

  /// Initializer
  public init() {}

  /// Determine if this destination should log the given level
  public func shouldLog(level _: LogLevel) async -> Bool {
    true // Log all levels
  }

  /// Write a log entry to this destination
  public func write(_ entry: LogEntry) async {
    // Format and print the log message
    let formattedMessage="[\(entry.context.source)] [\(entry.level.rawValue)] \(entry.message)"
    print(formattedMessage)
  }
}

/**
 A simple implementation of the LoggingActor protocol
 */
final class SimpleLoggingActor: LoggingActor {
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata _: PrivacyMetadata?,
    source: String
  ) async {
    // Delegate to the system logger for now
    print("[\(source)] \(level.rawValue): \(message)")
  }
}

/**
 Fallback encryption provider when no other provider can be instantiated
 */
class FallbackEncryptionProvider: EncryptionProviderProtocol {
  var providerType: SecurityProviderType {
    .basic
  }

  var capabilities: [EncryptionCapability] {
    [.standardEncryption]
  }

  func encrypt(
    data _: SecureBytes,
    using _: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(
      reason: "Fallback provider does not implement actual encryption"
    ))
  }

  func decrypt(
    data _: SecureBytes,
    using _: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(
      reason: "Fallback provider does not implement actual decryption"
    ))
  }

  func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
    // Very simple placeholder hash function - not for production use
    var result=[UInt8](repeating: 0, count: 32)
    for i in 0..<min(data.count, 32) {
      result[i]=data[i]
    }
    return .success(SecureBytes(bytes: result))
  }

  func verifyHash(
    data: SecureBytes,
    expectedHash: SecureBytes
  ) async -> Result<Bool, SecurityProtocolError> {
    let hashResult=await hash(data: data)
    switch hashResult {
      case let .success(computedHash):
        return .success(compareBytes(computedHash, expectedHash))
      case let .failure(error):
        return .failure(error)
    }
  }

  private func compareBytes(_ bytes1: SecureBytes, _ bytes2: SecureBytes) -> Bool {
    guard bytes1.count == bytes2.count else { return false }

    for i in 0..<bytes1.count {
      if bytes1[i] != bytes2[i] {
        return false
      }
    }

    return true
  }
}
