import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityInterfaces
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

 // Create a logging implementation
 let loggingService = await CryptoServiceFactory.createLogging(
   wrapped: cryptoService,
   logger: myLogger
 )
 ```
 */
public enum CryptoServiceFactory {
  /**
   Creates a default implementation of CryptoServiceProtocol.

   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault() async -> CryptoServiceProtocol {
    DefaultCryptoServiceImpl()
  }

  /**
   Creates a mock implementation of CryptoServiceProtocol.

   - Parameter configuration: Configuration for the mock implementation
   - Returns: A CryptoServiceProtocol implementation that mocks cryptographic operations
   */
  public static func createMock(
    configuration: MockCryptoServiceImpl.Configuration = .init()
  ) async -> CryptoServiceProtocol {
    MockCryptoServiceImpl(configuration: configuration)
  }

  /**
   Creates a logging decorator for a CryptoServiceProtocol implementation.

   - Parameters:
     - wrapped: The implementation to wrap with logging
     - logger: Optional logger to use, a default will be created if nil

   - Returns: A CryptoServiceProtocol implementation with logging capabilities
   */
  public static func createLogging(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    // Use provided logger or create a default one with appropriate identifier
    let actualLogger=logger ?? DefaultLogger()

    return LoggingCryptoServiceImpl(wrapped: wrapped, logger: actualLogger)
  }

  /**
   Creates a secure implementation of CryptoServiceProtocol that utilises actor-based
   SecureStorageProtocol for handling sensitive cryptographic material.

   - Parameter secureStorage: The secure storage implementation to use
   - Returns: A CryptoServiceProtocol implementation with enhanced security
   */
  public static func createSecure(
    secureStorage: any SecureStorageProtocol
  ) async -> CryptoServiceProtocol {
    let defaultService = await createDefault()
    return SecureCryptoServiceImpl(
      wrapped: defaultService,
      secureStorage: secureStorage
    )
  }
  
  /**
   Creates an enhanced secure implementation of CryptoServiceProtocol that fully integrates
   with the Alpha Dot Five architecture's actor-based SecureStorage system.
   
   This implementation provides advanced security features:
   - Key material is stored securely rather than returned directly
   - Key identifiers are returned instead of raw key material
   - Full actor isolation for thread safety
   - Comprehensive privacy-aware logging
   
   - Parameters:
      - secureStorage: The secure storage implementation to use
      - logger: Logger for recording operations with privacy controls
   
   - Returns: A CryptoServiceProtocol implementation with advanced security features
   */
  public static func createEnhancedSecure(
    secureStorage: any SecureStorageProtocol,
    logger: any LoggingProtocol
  ) async -> CryptoServiceProtocol {
    let defaultService = await createDefault()
    let secureCryptoStorage = SecureCryptoStorage(
      secureStorage: secureStorage,
      logger: logger
    )
    
    return EnhancedSecureCryptoServiceImpl(
      wrapped: defaultService,
      secureStorage: secureCryptoStorage,
      logger: logger
    )
  }

  /// Default logger implementation used when no logger is provided
  private struct DefaultLogger: LoggingProtocol {
    // Add loggingActor property required by LoggingProtocol
    var loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

    // Core method required by CoreLoggingProtocol
    func logMessage(_: LoggingTypes.LogLevel, _: String, context _: LoggingTypes.LogContext) async {
      // Empty implementation for this stub
    }

    // Implement all required methods with proper parameter types
    func debug(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
    func info(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
    func notice(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
    func warning(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
    func error(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
    func critical(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
    func trace(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
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

    /// Whether key derivation should succeed
    public let keyDerivationShouldSucceed: Bool

    /// Whether random generation should succeed
    public let randomGenerationShouldSucceed: Bool

    /// Whether HMAC generation should succeed
    public let hmacGenerationShouldSucceed: Bool

    /// Whether signature generation should succeed
    public let signatureShouldSucceed: Bool

    /// Initializes mock configuration with default values
    public init(
      encryptionShouldSucceed: Bool = true,
      decryptionShouldSucceed: Bool = true,
      keyDerivationShouldSucceed: Bool = true,
      randomGenerationShouldSucceed: Bool = true,
      hmacGenerationShouldSucceed: Bool = true,
      signatureShouldSucceed: Bool = true
    ) {
      self.encryptionShouldSucceed = encryptionShouldSucceed
      self.decryptionShouldSucceed = decryptionShouldSucceed
      self.keyDerivationShouldSucceed = keyDerivationShouldSucceed
      self.randomGenerationShouldSucceed = randomGenerationShouldSucceed
      self.hmacGenerationShouldSucceed = hmacGenerationShouldSucceed
      self.signatureShouldSucceed = signatureShouldSucceed
    }
  }

  /// Mock configuration
  private let configuration: Configuration

  /// Initializes a new mock crypto service
  public init(configuration: Configuration) {
    self.configuration = configuration
  }

  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    guard configuration.encryptionShouldSucceed else {
      throw CryptoError.encryptionFailed(reason: "Mock encryption configured to fail")
    }

    // Just return the original data as "encrypted"
    return data
  }

  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    guard configuration.decryptionShouldSucceed else {
      throw CryptoError.decryptionFailed(reason: "Mock decryption configured to fail")
    }

    // Just return the original data as "decrypted"
    return data
  }

  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    guard configuration.keyDerivationShouldSucceed else {
      throw CryptoError.keyDerivationFailed(reason: "Mock key derivation configured to fail")
    }

    // Generate a deterministic "key" based on the input
    let length = 32 // Default key length
    let mockData = Data([UInt8](repeating: 0x42, count: length))
    
    // Create contextual data for logging
    _ = "derived_key_\(password.hashValue)_\(salt.hashValue)_\(iterations)"
    _ = SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: [
        "operation": "key_derivation",
        "iterations": "\(iterations)",
        "algorithm": derivationOptions?.function.rawValue ?? "default"
      ]
    )
    
    return mockData
  }

  public func generateKey(
    length: Int,
    keyOptions: KeyGenerationOptions?
  ) async throws -> Data {
    guard configuration.randomGenerationShouldSucceed else {
      throw CryptoError.keyGenerationFailed(reason: "Mock key generation configured to fail")
    }

    let mockData = Data([UInt8](repeating: 0x41, count: length))

    // Store with a unique identifier
    _ = "generated_key_\(UUID().uuidString)"
    _ = SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: [
        "operation": "key_generation",
        "length": "\(length)",
        "purpose": keyOptions?.purpose.rawValue ?? "encryption"
      ]
    )

    return mockData
  }

  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    guard configuration.hmacGenerationShouldSucceed else {
      throw CryptoError.operationFailed(reason: "Mock HMAC generation configured to fail")
    }

    // Generate a mock HMAC value
    let mockHmac = Data([UInt8](repeating: 0x44, count: 32))

    // Store with a unique identifier
    _ = "hmac_\(data.hashValue)_\(key.hashValue)"
    _ = SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: [
        "operation": "hmac_generation",
        "algorithm": hmacOptions?.algorithm.rawValue ?? "sha256"
      ]
    )

    return mockHmac
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

  /**
   Initialise a new logging decorator.

   - Parameters:
     - wrapped: The implementation to wrap
     - logger: The logger to use
   */
  public init(wrapped: CryptoServiceProtocol, logger: LoggingProtocol) {
    self.wrapped = wrapped
    self.logger = logger
  }

  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting encryption operation", metadata: metadata, source: "CryptoService")

    do {
      let result = try await wrapped.encrypt(data, using: key, iv: iv, cryptoOptions: cryptoOptions)
      await logger.debug(
        "Encryption completed successfully",
        metadata: metadata,
        source: "CryptoService"
      )
      return result
    } catch {
      await logger.error(
        "Encryption failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "CryptoService"
      )
      throw error
    }
  }

  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting decryption operation", metadata: metadata, source: "CryptoService")

    do {
      let result = try await wrapped.decrypt(data, using: key, iv: iv, cryptoOptions: cryptoOptions)
      await logger.debug(
        "Decryption completed successfully",
        metadata: metadata,
        source: "CryptoService"
      )
      return result
    } catch {
      await logger.error(
        "Decryption failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "CryptoService"
      )
      throw error
    }
  }

  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["iterations"] = LoggingTypes
      .PrivacyMetadataValue(value: "\(iterations)", privacy: .public)

    await logger.debug("Starting key derivation", metadata: metadata, source: "CryptoService")

    do {
      let result = try await wrapped.deriveKey(
        from: password,
        salt: salt,
        iterations: iterations,
        derivationOptions: derivationOptions
      )

      await logger.debug(
        "Key derivation completed successfully",
        metadata: metadata,
        source: "CryptoService"
      )
      return result
    } catch {
      await logger.error(
        "Key derivation failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "CryptoService"
      )
      throw error
    }
  }

  public func generateKey(
    length: Int,
    keyOptions: KeyGenerationOptions?
  ) async throws -> Data {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["length"] = LoggingTypes.PrivacyMetadataValue(value: "\(length)", privacy: .public)

    await logger.debug("Generating secure random key", metadata: metadata, source: "CryptoService")

    do {
      let result = try await wrapped.generateKey(length: length, keyOptions: keyOptions)
      await logger.debug(
        "Secure random key generated successfully",
        metadata: metadata,
        source: "CryptoService"
      )
      return result
    } catch {
      await logger.error(
        "Secure random key generation failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "CryptoService"
      )
      throw error
    }
  }

  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Generating HMAC", metadata: metadata, source: "CryptoService")

    do {
      let result = try await wrapped.generateHMAC(for: data, using: key, hmacOptions: hmacOptions)
      await logger.debug("HMAC generated successfully", metadata: metadata, source: "CryptoService")
      return result
    } catch {
      await logger.error(
        "HMAC generation failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "CryptoService"
      )
      throw error
    }
  }
}

/**
 # SecureCryptoServiceImpl
 
 A CryptoServiceProtocol implementation that follows the Alpha Dot Five architecture
 by storing sensitive cryptographic material using the SecureStorageProtocol.
 
 This implementation wraps another CryptoServiceProtocol and enhances it with
 secure storage capabilities. It follows privacy-by-design principles by ensuring
 sensitive data is properly stored and retrieved through secure channels.
 */
public actor SecureCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped crypto service implementation
  private let wrapped: CryptoServiceProtocol
  
  /// The secure storage provider
  private let secureStorage: any SecureStorageProtocol
  
  /// Initialises a new secure crypto service
  public init(
    wrapped: CryptoServiceProtocol,
    secureStorage: any SecureStorageProtocol
  ) {
    self.wrapped = wrapped
    self.secureStorage = secureStorage
  }
  
  /// Generates a unique identifier for a key based on derivation parameters
  private func keyIdentifier(
    from password: String,
    salt: Data,
    iterations: Int
  ) -> String {
    "derived_key_\(password.hashValue)_\(salt.count)_\(iterations)"
  }
  
  /// Securely stores cryptographic data
  private func securelyStore(
    _ data: Data,
    withIdentifier identifier: String,
    context: [String: String]
  ) async throws -> Data {
    let config = SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: context
    )
    
    // Store securely and return the data itself
    let result = try await secureStorage.storeSecurely(
      data: data,
      identifier: identifier,
      config: config
    )
    
    if !result.success {
      throw CryptoError.operationFailed(reason: "Failed to store data securely")
    }
    
    return data
  }
  
  // MARK: - CryptoServiceProtocol Methods
  
  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    // Use the wrapped implementation for encryption
    return try await wrapped.encrypt(
      data,
      using: key,
      iv: iv,
      cryptoOptions: cryptoOptions
    )
  }
  
  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    // Use the wrapped implementation for decryption
    return try await wrapped.decrypt(
      data,
      using: key,
      iv: iv,
      cryptoOptions: cryptoOptions
    )
  }
  
  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    // Generate the key using the wrapped implementation
    let derivedKey = try await wrapped.deriveKey(
      from: password,
      salt: salt,
      iterations: iterations,
      derivationOptions: derivationOptions
    )
    
    // Store the key securely
    let identifier = keyIdentifier(from: password, salt: salt, iterations: iterations)
    let context: [String: String] = [
      "operation": "key_derivation",
      "iterations": "\(iterations)",
      "algorithm": derivationOptions?.function.rawValue ?? "pbkdf2"
    ]
    
    // Return after secure storage
    return try await securelyStore(derivedKey, withIdentifier: identifier, context: context)
  }
  
  public func generateKey(
    length: Int,
    keyOptions: KeyGenerationOptions?
  ) async throws -> Data {
    // Generate the key using the wrapped implementation
    let generatedKey = try await wrapped.generateKey(
      length: length,
      keyOptions: keyOptions
    )
    
    // Store the key securely
    let identifier = "generated_key_\(UUID().uuidString)"
    let context: [String: String] = [
      "operation": "key_generation",
      "length": "\(length)",
      "purpose": keyOptions?.purpose.rawValue ?? "encryption"
    ]
    
    // Return after secure storage
    return try await securelyStore(generatedKey, withIdentifier: identifier, context: context)
  }
  
  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    // Generate the HMAC using the wrapped implementation
    let hmac = try await wrapped.generateHMAC(
      for: data,
      using: key,
      hmacOptions: hmacOptions
    )
    
    // Store the HMAC securely
    let identifier = "hmac_\(data.hashValue)_\(key.hashValue)_\(UUID().uuidString)"
    let context: [String: String] = [
      "operation": "hmac_generation",
      "algorithm": hmacOptions?.algorithm.rawValue ?? "sha256"
    ]
    
    // Return after secure storage
    return try await securelyStore(hmac, withIdentifier: identifier, context: context)
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
