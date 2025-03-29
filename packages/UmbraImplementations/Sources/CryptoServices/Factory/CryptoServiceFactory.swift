import CryptoInterfaces
import Foundation
import LoggingInterfaces
import CryptoTypes
import SecurityTypes
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
    return DefaultCryptoServiceImpl()
  }
  
  /**
   Creates a mock implementation of CryptoServiceProtocol.
   
   - Parameter configuration: Configuration for the mock implementation
   - Returns: A CryptoServiceProtocol implementation that mocks cryptographic operations
   */
  public static func createMock(
    configuration: MockCryptoServiceImpl.Configuration = .init()
  ) async -> CryptoServiceProtocol {
    return MockCryptoServiceImpl(configuration: configuration)
  }
  
  /**
   Creates a logging wrapper for a CryptoServiceProtocol implementation.
   
   - Parameters:
     - wrapped: The CryptoServiceProtocol implementation to wrap
     - logger: The logger to use for logging
   - Returns: A CryptoServiceProtocol implementation that logs operations
   */
  public static func createLogging(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) async -> CryptoServiceProtocol {
    return LoggingCryptoServiceImpl(wrapped: wrapped, logger: logger)
  }
}

/**
 # MockCryptoServiceImpl
 
 Mock implementation of CryptoServiceProtocol for testing purposes.
 Allows controlling the success or failure of cryptographic operations.
 */
public actor MockCryptoServiceImpl: CryptoServiceProtocol, Sendable {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption should succeed
    public let encryptionShouldSucceed: Bool
    
    /// Whether decryption should succeed
    public let decryptionShouldSucceed: Bool
    
    /// Whether key derivation should succeed
    public let keyDerivationShouldSucceed: Bool
    
    /// Whether key generation should succeed
    public let keyGenerationShouldSucceed: Bool
    
    /// Whether HMAC generation should succeed
    public let hmacGenerationShouldSucceed: Bool
    
    /**
     Initialises a new Configuration.
     
     - Parameters:
       - encryptionShouldSucceed: Whether encryption should succeed
       - decryptionShouldSucceed: Whether decryption should succeed
       - keyDerivationShouldSucceed: Whether key derivation should succeed
       - keyGenerationShouldSucceed: Whether key generation should succeed
       - hmacGenerationShouldSucceed: Whether HMAC generation should succeed
     */
    public init(
      encryptionShouldSucceed: Bool = true,
      decryptionShouldSucceed: Bool = true,
      keyDerivationShouldSucceed: Bool = true,
      keyGenerationShouldSucceed: Bool = true,
      hmacGenerationShouldSucceed: Bool = true
    ) {
      self.encryptionShouldSucceed = encryptionShouldSucceed
      self.decryptionShouldSucceed = decryptionShouldSucceed
      self.keyDerivationShouldSucceed = keyDerivationShouldSucceed
      self.keyGenerationShouldSucceed = keyGenerationShouldSucceed
      self.hmacGenerationShouldSucceed = hmacGenerationShouldSucceed
    }
  }
  
  /// The configuration for this mock
  private let configuration: Configuration
  
  /**
   Initialises a new MockCryptoServiceImpl.
   
   - Parameter configuration: The configuration for this mock
   */
  public init(configuration: Configuration = .init()) {
    self.configuration = configuration
  }
  
  public func encrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws -> SecureBytes {
    if configuration.encryptionShouldSucceed {
      return SecureBytes(bytes: [UInt8](repeating: 0, count: data.count))
    } else {
      throw CryptoError.encryptionFailed(reason: "Mock encryption configured to fail")
    }
  }
  
  public func decrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws -> SecureBytes {
    if configuration.decryptionShouldSucceed {
      return SecureBytes(bytes: [UInt8](repeating: 0, count: data.count))
    } else {
      throw CryptoError.decryptionFailed(reason: "Mock decryption configured to fail")
    }
  }
  
  public func deriveKey(
    from password: String,
    salt: SecureBytes,
    iterations: Int
  ) async throws -> SecureBytes {
    if configuration.keyDerivationShouldSucceed {
      // Return zeroed bytes of reasonable key length
      return SecureBytes(bytes: [UInt8](repeating: 0, count: 32))
    } else {
      throw CryptoError.keyDerivationFailed(reason: "Mock key derivation configured to fail")
    }
  }
  
  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    if configuration.keyGenerationShouldSucceed {
      return SecureBytes(bytes: [UInt8](repeating: 0, count: length))
    } else {
      throw CryptoError.keyGenerationFailed(reason: "Mock key generation configured to fail")
    }
  }
  
  public func generateHMAC(for data: SecureBytes, using key: SecureBytes) async throws -> SecureBytes {
    if configuration.hmacGenerationShouldSucceed {
      // Return zeroed bytes of SHA-256 output size
      return SecureBytes(bytes: [UInt8](repeating: 0, count: 32))
    } else {
      throw CryptoError.operationFailed(reason: "Mock HMAC generation configured to fail")
    }
  }
}

/**
 # LoggingCryptoServiceImpl
 
 Logging wrapper for CryptoServiceProtocol implementations.
 Logs all cryptographic operations for debugging and audit purposes.
 */
public actor LoggingCryptoServiceImpl: CryptoServiceProtocol, Sendable {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  
  /// The logger to use
  private let logger: LoggingProtocol
  
  /**
   Initialises a new LoggingCryptoServiceImpl.
   
   - Parameters:
     - wrapped: The CryptoServiceProtocol implementation to wrap
     - logger: The logger to use for logging
   */
  public init(wrapped: CryptoServiceProtocol, logger: LoggingProtocol) {
    self.wrapped = wrapped
    self.logger = logger
  }
  
  public func encrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws -> SecureBytes {
    await logger.debug("Encrypting data with key length: \(key.count), iv length: \(iv.count)", metadata: nil)
    do {
      let result = try await wrapped.encrypt(data, using: key, iv: iv)
      await logger.debug("Encryption successful", metadata: nil)
      return result
    } catch {
      await logger.error("Encryption failed: \(error.localizedDescription)", metadata: nil)
      throw error
    }
  }
  
  public func decrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws -> SecureBytes {
    await logger.debug("Decrypting data with key length: \(key.count), iv length: \(iv.count)", metadata: nil)
    do {
      let result = try await wrapped.decrypt(data, using: key, iv: iv)
      await logger.debug("Decryption successful", metadata: nil)
      return result
    } catch {
      await logger.error("Decryption failed: \(error.localizedDescription)", metadata: nil)
      throw error
    }
  }
  
  public func deriveKey(
    from password: String,
    salt: SecureBytes,
    iterations: Int
  ) async throws -> SecureBytes {
    await logger.debug("Deriving key from password with salt length: \(salt.count), iterations: \(iterations)", metadata: nil)
    do {
      let result = try await wrapped.deriveKey(from: password, salt: salt, iterations: iterations)
      await logger.debug("Key derivation successful", metadata: nil)
      return result
    } catch {
      await logger.error("Key derivation failed: \(error.localizedDescription)", metadata: nil)
      throw error
    }
  }
  
  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    await logger.debug("Generating secure random key of length: \(length)", metadata: nil)
    do {
      let result = try await wrapped.generateSecureRandomKey(length: length)
      await logger.debug("Key generation successful", metadata: nil)
      return result
    } catch {
      await logger.error("Key generation failed: \(error.localizedDescription)", metadata: nil)
      throw error
    }
  }
  
  public func generateHMAC(for data: SecureBytes, using key: SecureBytes) async throws -> SecureBytes {
    await logger.debug("Generating HMAC with key length: \(key.count)", metadata: nil)
    do {
      let result = try await wrapped.generateHMAC(for: data, using: key)
      await logger.debug("HMAC generation successful", metadata: nil)
      return result
    } catch {
      await logger.error("HMAC generation failed: \(error.localizedDescription)", metadata: nil)
      throw error
    }
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
