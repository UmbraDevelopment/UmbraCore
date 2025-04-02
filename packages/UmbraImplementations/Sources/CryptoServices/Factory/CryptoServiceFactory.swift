import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import SecurityInterfaces // Temporary, until we fully migrate SecureStorageConfig
import UmbraErrors

/**
 # CryptoServiceFactory

 Factory for creating CryptoServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 of providing asynchronous factory methods that return actor-based
 implementations.

 ## Usage Example

 ```swift
 // Create a default implementation
 let cryptoService = await CryptoServiceFactory.createDefault()

 // Create a service with custom secure logger
 let customService = await CryptoServiceFactory.createDefaultService(
   secureLogger: mySecureLogger
 )

 // Create a logging implementation
 let loggingService = await CryptoServiceFactory.createLoggingDecorator(
   wrapped: cryptoService,
   logger: myLogger,
   secureLogger: mySecureLogger
 )
 ```
 */
public enum CryptoServiceFactory {
  /**
   Creates a default implementation of CryptoServiceProtocol.

   This implementation uses the Alpha Dot Five architecture principles,
   providing robust security capabilities with proper isolation and privacy-aware logging.

   - Returns: A CryptoServiceProtocol implementation with secure logging enabled
   */
  public static func createDefault() async -> CryptoServiceProtocol {
    await createDefaultService()
  }

  /**
   Creates a default implementation of CryptoServiceProtocol with optional custom loggers.

   This implementation provides full cryptographic capabilities following
   the Alpha Dot Five architecture with proper privacy controls for logging.

   - Parameters:
     - logger: Optional logger for standard logging (a default will be created if nil)
     - secureLogger: Optional secure logger for privacy-aware logging (a default will be created if nil)
   - Returns: A DefaultCryptoServiceImpl instance with configured loggers
   */
  public static func createDefaultService(
    logger: LoggingProtocol?=nil,
    secureLogger: SecureLoggerActor?=nil
  ) async -> CryptoServiceProtocol {
    // Create a secure logger if not provided
    let actualSecureLogger=secureLogger ?? await LoggingServices.createSecureLogger(
      category: "CryptoOperations"
    )

    return await DefaultCryptoServiceImpl(
      logger: logger,
      secureLogger: actualSecureLogger
    )
  }

  /**
   Creates a mock implementation of CryptoServiceProtocol.

   This implementation is useful for testing and does not perform
   actual cryptographic operations.

   - Parameter configuration: Configuration options for the mock
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock(
    configuration: MockCryptoServiceImpl.Configuration = .init()
  ) async -> CryptoServiceProtocol {
    await MockCryptoServiceImpl(configuration: configuration)
  }

  /**
   Creates a secure implementation that stores sensitive data in secure storage.

   This implementation enhances security by storing sensitive data in secure storage
   rather than keeping it in memory, reducing exposure to memory-based attacks.

   - Parameters:
     - wrapped: Optional base implementation (a default will be created if nil)
     - secureStorage: Secure storage implementation
     - secureLogger: Optional secure logger for privacy-aware logging
   - Returns: A secure CryptoServiceProtocol implementation
   */
  public static func createSecureService(
    wrapped: CryptoServiceProtocol?=nil,
    secureStorage: SecureStorageProtocol,
    secureLogger: SecureLoggerActor?=nil
  ) async -> CryptoServiceProtocol {
    let baseImplementation=wrapped ?? await createDefaultService()
    let actualSecureLogger=secureLogger ?? await LoggingServices.createSecureLogger(
      category: "SecureCryptoService"
    )

    // Pass secure logger to SecureCryptoServiceImpl when it supports it
    return await SecureCryptoServiceImpl(
      wrapped: baseImplementation,
      secureStorage: secureStorage
    )
  }

  /**
   Creates a logging decorator for any CryptoServiceProtocol implementation.

   This logs all cryptographic operations before delegating to the wrapped implementation.
   When a secure logger is provided, it uses privacy-aware logging for sensitive operations.

   - Parameters:
     - wrapped: The implementation to wrap
     - logger: The logger to use for standard logging
     - secureLogger: Optional secure logger for privacy-aware logging
   - Returns: A logging decorator for the wrapped implementation
   */
  public static func createLoggingDecorator(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol,
    secureLogger: SecureLoggerActor?=nil
  ) async -> CryptoServiceProtocol {
    // If secure logger is provided, create enhanced logging implementation
    if let secureLogger {
      return await EnhancedLoggingCryptoServiceImpl(
        wrapped: wrapped,
        logger: logger,
        secureLogger: secureLogger
      )
    }

    // Fall back to standard logging implementation
    return await LoggingCryptoServiceImpl(wrapped: wrapped, logger: logger)
  }
}

/**
 # MockCryptoServiceImpl

 A mock implementation of CryptoServiceProtocol for testing purposes.
 This implementation simulates cryptographic operations without actually
 performing encryption, allowing for controlled testing environments.
 */
public actor MockCryptoServiceImpl: CryptoServiceProtocol {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption should succeed
    public let encryptionShouldSucceed: Bool
    /// Whether decryption should succeed
    public let decryptionShouldSucceed: Bool
    /// Whether hashing should succeed
    public let hashingShouldSucceed: Bool
    /// Whether hash verification should succeed
    public let hashVerificationShouldSucceed: Bool
    /// Whether key derivation should succeed
    public let keyDerivationShouldSucceed: Bool
    /// Whether random generation should succeed
    public let randomGenerationShouldSucceed: Bool
    /// Whether HMAC generation should succeed
    public let hmacGenerationShouldSucceed: Bool

    /// Initialize with default values or customize behavior
    public init(
      encryptionShouldSucceed: Bool=true,
      decryptionShouldSucceed: Bool=true,
      hashingShouldSucceed: Bool=true,
      hashVerificationShouldSucceed: Bool=true,
      keyDerivationShouldSucceed: Bool=true,
      randomGenerationShouldSucceed: Bool=true,
      hmacGenerationShouldSucceed: Bool=true
    ) {
      self.encryptionShouldSucceed=encryptionShouldSucceed
      self.decryptionShouldSucceed=decryptionShouldSucceed
      self.hashingShouldSucceed=hashingShouldSucceed
      self.hashVerificationShouldSucceed=hashVerificationShouldSucceed
      self.keyDerivationShouldSucceed=keyDerivationShouldSucceed
      self.randomGenerationShouldSucceed=randomGenerationShouldSucceed
      self.hmacGenerationShouldSucceed=hmacGenerationShouldSucceed
    }
  }

  /// The mock configuration
  private let configuration: Configuration

  /// Initialize with specific configuration
  public init(configuration: Configuration=Configuration()) {
    self.configuration=configuration
  }

  public func encrypt(
    data: [UInt8],
    using _: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    guard configuration.encryptionShouldSucceed else {
      return .failure(.operationFailed("Mock encryption configured to fail"))
    }

    // Create a mock encrypted result
    let encryptedData=[UInt8](
      repeating: 0x42,
      count: data.count + 16
    ) // Add 16 bytes for mock IV/padding

    return .success(encryptedData)
  }

  public func decrypt(
    data: [UInt8],
    using _: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    guard configuration.decryptionShouldSucceed else {
      return .failure(.operationFailed("Mock decryption configured to fail"))
    }

    // Create a mock decrypted result
    let decryptedData=[UInt8](repeating: 0x41, count: max(
      0,
      data.count - 16
    )) // Remove 16 bytes for mock IV/padding

    return .success(decryptedData)
  }

  public func hash(data _: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    guard configuration.hashingShouldSucceed else {
      return .failure(.operationFailed("Mock hashing configured to fail"))
    }

    // Create a mock hash (fixed length of 32 bytes for SHA-256)
    let hash=[UInt8](repeating: 0x43, count: 32)

    return .success(hash)
  }

  public func verifyHash(
    data _: [UInt8],
    expectedHash _: [UInt8]
  ) async -> Result<Bool, SecurityProtocolError> {
    guard configuration.hashVerificationShouldSucceed else {
      return .failure(.operationFailed("Mock hash verification configured to fail"))
    }

    // Always return true for successful verification in mock
    return .success(true)
  }
}

/**
 # LoggingCryptoServiceImpl

 A decorator for CryptoServiceProtocol that adds logging capabilities.
 This implementation logs all cryptographic operations while delegating
 the actual work to a wrapped implementation.
 */
public actor LoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// The logger to use
  private let logger: LoggingProtocol

  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }

  /**
   Initialises a new logging-enhanced crypto service.

   - Parameters:
     - wrapped: The underlying crypto service to wrap
     - logger: The logger to use
   */
  public init(wrapped: CryptoServiceProtocol, logger: LoggingProtocol) {
    self.wrapped=wrapped
    self.logger=logger
  }

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["dataId"]=LoggingTypes.PrivacyMetadataValue(value: dataIdentifier, privacy: .hash)
    metadata["keyId"]=LoggingTypes.PrivacyMetadataValue(value: keyIdentifier, privacy: .hash)

    await logger.debug("Starting encryption operation", metadata: metadata, source: "CryptoService")

    let result=await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case .success:
        await logger.debug(
          "Encryption completed successfully",
          metadata: metadata,
          source: "CryptoService"
        )
      case let .failure(error):
        await logger.error(
          "Encryption failed: \(error.localizedDescription)",
          metadata: metadata,
          source: "CryptoService"
        )
    }

    return result
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Starting decryption operation for data identifier: \(encryptedDataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Decryption completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Decryption failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Starting hash operation for data identifier: \(dataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Hashing completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Hashing failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Verifying hash for data identifier: \(dataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(matches):
        await logger.debug(
          "LoggingCryptoService: Hash verification completed (matches: \(matches)) in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(matches)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Hash verification failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Generating key of length \(length) bits",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.generateKey(
      length: length,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Key generation completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Key generation failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Importing data with\(customIdentifier != nil ? " custom identifier: \(customIdentifier!)" : "out custom identifier")",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Data import completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data import failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Exporting data for identifier: \(identifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.exportData(
      identifier: identifier
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(data):
        await logger.debug(
          "LoggingCryptoService: Data export completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(data)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data export failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }
}

/**
 # EnhancedLoggingCryptoServiceImpl

 A decorator for CryptoServiceProtocol that adds privacy-aware logging capabilities.
 This implementation uses SecureLoggerActor to ensure that sensitive information
 is properly tagged with privacy levels when logged.
 */
public actor EnhancedLoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// The standard logger
  private let logger: LoggingProtocol

  /// The secure logger for privacy-aware logging
  private let secureLogger: SecureLoggerActor

  /**
   Initialises a new enhanced logging crypto service.

   - Parameters:
     - wrapped: The implementation to wrap
     - logger: The standard logger
     - secureLogger: The secure logger for privacy-aware logging
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol,
    secureLogger: SecureLoggerActor
  ) {
    self.wrapped=wrapped
    self.logger=logger
    self.secureLogger=secureLogger
  }

  public func encrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await logger.debug(
      "EnhancedLoggingCryptoService: Encrypting data of size \(data.count) with key of size \(key.count)",
      metadata: nil,
      source: "EnhancedLoggingCryptoService"
    )

    // Log with privacy tagging
    await secureLogger.securityEvent(
      action: "Encryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    let startTime=Date()
    let result=await wrapped.encrypt(data: data, using: key)
    let duration=Date().timeIntervalSince(startTime)

    switch result {
      case let .success(encryptedData):
        await logger.info(
          "EnhancedLoggingCryptoService: Encryption succeeded in \(duration) seconds",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log success with privacy tagging
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .success,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
            "resultSize": PrivacyTaggedValue(value: encryptedData.count, privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
          ]
        )

      case let .failure(error):
        await logger.error(
          "EnhancedLoggingCryptoService: Encryption failed in \(duration) seconds: \(error.localizedDescription)",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log failure with privacy tagging
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
            "errorCode": PrivacyTaggedValue(value: String(describing: error),
                                            privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public)
          ]
        )
    }

    return result
  }

  public func decrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await logger.debug(
      "EnhancedLoggingCryptoService: Decrypting data of size \(data.count) with key of size \(key.count)",
      metadata: nil,
      source: "EnhancedLoggingCryptoService"
    )

    // Log with privacy tagging
    await secureLogger.securityEvent(
      action: "Decryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    let startTime=Date()
    let result=await wrapped.decrypt(data: data, using: key)
    let duration=Date().timeIntervalSince(startTime)

    switch result {
      case let .success(decryptedData):
        await logger.info(
          "EnhancedLoggingCryptoService: Decryption succeeded in \(duration) seconds",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log success with privacy tagging
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .success,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
            "resultSize": PrivacyTaggedValue(value: decryptedData.count, privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
          ]
        )

      case let .failure(error):
        await logger.error(
          "EnhancedLoggingCryptoService: Decryption failed in \(duration) seconds: \(error.localizedDescription)",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log failure with privacy tagging
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
            "errorCode": PrivacyTaggedValue(value: String(describing: error),
                                            privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public)
          ]
        )
    }

    return result
  }

  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    await logger.debug(
      "EnhancedLoggingCryptoService: Hashing data of size \(data.count)",
      metadata: nil,
      source: "EnhancedLoggingCryptoService"
    )

    // Log with privacy tagging
    await secureLogger.securityEvent(
      action: "Hash",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    let startTime=Date()
    let result=await wrapped.hash(data: data)
    let duration=Date().timeIntervalSince(startTime)

    switch result {
      case let .success(hash):
        await logger.info(
          "EnhancedLoggingCryptoService: Hashing succeeded in \(duration) seconds",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log success with privacy tagging
        await secureLogger.securityEvent(
          action: "Hash",
          status: .success,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
            "hashSize": PrivacyTaggedValue(value: hash.count, privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
          ]
        )

      case let .failure(error):
        await logger.error(
          "EnhancedLoggingCryptoService: Hashing failed in \(duration) seconds: \(error.localizedDescription)",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log failure with privacy tagging
        await secureLogger.securityEvent(
          action: "Hash",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
            "errorCode": PrivacyTaggedValue(value: String(describing: error),
                                            privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public)
          ]
        )
    }

    return result
  }

  public func verifyHash(
    data: [UInt8],
    matches expectedHash: [UInt8]
  ) async -> Result<Bool, SecurityProtocolError> {
    await logger.debug(
      "EnhancedLoggingCryptoService: Verifying hash for data of size \(data.count)",
      metadata: nil,
      source: "EnhancedLoggingCryptoService"
    )

    // Log with privacy tagging
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

    let startTime=Date()
    let result=await wrapped.verifyHash(data: data, matches: expectedHash)
    let duration=Date().timeIntervalSince(startTime)

    switch result {
      case let .success(verified):
        await logger.info(
          "EnhancedLoggingCryptoService: Hash verification succeeded in \(duration) seconds, result: \(verified)",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log success with privacy tagging
        await secureLogger.securityEvent(
          action: "HashVerification",
          status: .success,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "result": PrivacyTaggedValue(value: verified ? "verified" : "mismatch",
                                         privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
          ]
        )

      case let .failure(error):
        await logger.error(
          "EnhancedLoggingCryptoService: Hash verification failed in \(duration) seconds: \(error.localizedDescription)",
          metadata: nil,
          source: "EnhancedLoggingCryptoService"
        )

        // Log failure with privacy tagging
        await secureLogger.securityEvent(
          action: "HashVerification",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
            "errorCode": PrivacyTaggedValue(value: String(describing: error),
                                            privacyLevel: .public),
            "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public)
          ]
        )
    }

    return result
  }
}

/**
 # SecureCryptoServiceImpl

 A CryptoServiceProtocol implementation that follows the Alpha Dot Five architecture
 by storing sensitive cryptographic material using the SecureStorageProtocol.
 */
public actor SecureCryptoServiceImpl: CryptoServiceProtocol {

  /// The wrapped implementation that does the actual cryptographic work
  private let wrapped: CryptoServiceProtocol

  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }

  /**
   Initialises a new secure crypto service with an optional wrapped implementation.

   - Parameter wrapped: The underlying implementation to use (defaults to a standard one)
   */
  public init(wrapped: CryptoServiceProtocol?=nil) async {
    if let wrapped {
      self.wrapped=wrapped
    } else {
      self.wrapped=await MockCryptoServiceImpl()
    }
  }

  // MARK: - Protocol Implementation

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await wrapped.generateKey(
      length: length,
      options: options
    )
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await wrapped.exportData(
      identifier: identifier
    )
  }

  // MARK: - Legacy Methods

  public func encrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Convert legacy call to new protocol format
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Store data and key
    let dataImport=await importData(data, customIdentifier: dataID)
    guard case .success=dataImport else {
      return .failure(.storageError("Failed to store data for encryption"))
    }

    let keyImport=await importData(key, customIdentifier: keyID)
    guard case .success=keyImport else {
      return .failure(.storageError("Failed to store key for encryption"))
    }

    // Perform encryption
    let encryptResult=await encrypt(
      dataIdentifier: dataID,
      keyIdentifier: keyID,
      options: nil
    )

    // Return result
    switch encryptResult {
      case let .success(encryptedID):
        return await exportData(identifier: encryptedID)
      case let .failure(error):
        return .failure(error)
    }
  }

  public func decrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Convert legacy call to new protocol format
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Store data and key
    let dataImport=await importData(data, customIdentifier: dataID)
    guard case .success=dataImport else {
      return .failure(.storageError("Failed to store data for decryption"))
    }

    let keyImport=await importData(key, customIdentifier: keyID)
    guard case .success=keyImport else {
      return .failure(.storageError("Failed to store key for decryption"))
    }

    // Perform decryption
    let decryptResult=await decrypt(
      encryptedDataIdentifier: dataID,
      keyIdentifier: keyID,
      options: nil
    )

    // Return result
    switch decryptResult {
      case let .success(decryptedID):
        return await exportData(identifier: decryptedID)
      case let .failure(error):
        return .failure(error)
    }
  }

  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    // Convert legacy call to new protocol format
    let dataID=UUID().uuidString

    // Store data
    let dataImport=await importData(data, customIdentifier: dataID)
    guard case .success=dataImport else {
      return .failure(.storageError("Failed to store data for hashing"))
    }

    // Perform hashing
    let hashResult=await hash(
      dataIdentifier: dataID,
      options: nil
    )

    // Return result
    switch hashResult {
      case let .success(hashID):
        return await exportData(identifier: hashID)
      case let .failure(error):
        return .failure(error)
    }
  }

  public func verifyHash(
    data: [UInt8],
    expectedHash: [UInt8]
  ) async -> Result<Bool, SecurityProtocolError> {
    // Convert legacy call to new protocol format
    let dataID=UUID().uuidString
    let hashID=UUID().uuidString

    // Store data and hash
    let dataImport=await importData(data, customIdentifier: dataID)
    guard case .success=dataImport else {
      return .failure(.storageError("Failed to store data for hash verification"))
    }

    let hashImport=await importData(expectedHash, customIdentifier: hashID)
    guard case .success=hashImport else {
      return .failure(.storageError("Failed to store hash for verification"))
    }

    // Perform verification
    return await verifyHash(
      dataIdentifier: dataID,
      hashIdentifier: hashID,
      options: nil
    )
  }
}

/**
 Configuration options for the CryptoService implementation.

 These options control the behaviour of the cryptographic operations,
 allowing customisation of security parameters and algorithm choices.
 */
public struct CryptoServiceOptions: Sendable {
  /// Default iteration count for PBKDF2 key derivation
  public let defaultIterations: Int

  /// Preferred key size for AES encryption in bytes
  public let preferredKeySize: Int

  /// Size of initialisation vector in bytes
  public let ivSize: Int

  /// Creates a new CryptoServiceOptions instance with the specified parameters
  ///
  /// - Parameters:
  ///   - defaultIterations: Iteration count for PBKDF2 (default: 10000)
  ///   - preferredKeySize: Preferred key size in bytes (default: 32 for AES-256)
  ///   - ivSize: Size of initialisation vector in bytes (default: 12)
  public init(
    defaultIterations: Int=10000,
    preferredKeySize: Int=32,
    ivSize: Int=12
  ) {
    self.defaultIterations=defaultIterations
    self.preferredKeySize=preferredKeySize
    self.ivSize=ivSize
  }

  /// Default options suitable for most applications
  public static let `default`=CryptoServiceOptions()

  /// High security options with increased iteration count
  public static let highSecurity=CryptoServiceOptions(
    defaultIterations: 100_000,
    preferredKeySize: 32,
    ivSize: 16
  )
}
