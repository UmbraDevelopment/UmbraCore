import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
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

    /// Initialise with default values (all operations succeed)
    public init(
      encryptionShouldSucceed: Bool=true,
      decryptionShouldSucceed: Bool=true,
      keyDerivationShouldSucceed: Bool=true,
      randomGenerationShouldSucceed: Bool=true,
      hmacGenerationShouldSucceed: Bool=true
    ) {
      self.encryptionShouldSucceed=encryptionShouldSucceed
      self.decryptionShouldSucceed=decryptionShouldSucceed
      self.keyDerivationShouldSucceed=keyDerivationShouldSucceed
      self.randomGenerationShouldSucceed=randomGenerationShouldSucceed
      self.hmacGenerationShouldSucceed=hmacGenerationShouldSucceed
    }
  }

  private let configuration: Configuration

  /// Initialise a new mock with the specified configuration
  public init(configuration: Configuration) {
    self.configuration=configuration
  }

  public func encrypt(
    _ data: SecureBytes,
    using _: SecureBytes,
    iv _: SecureBytes
  ) async throws -> SecureBytes {
    guard configuration.encryptionShouldSucceed else {
      throw CryptoError.encryptionFailed(reason: "Mock encryption configured to fail")
    }

    // Just return the original data as "encrypted"
    return data
  }

  public func decrypt(
    _ data: SecureBytes,
    using _: SecureBytes,
    iv _: SecureBytes
  ) async throws -> SecureBytes {
    guard configuration.decryptionShouldSucceed else {
      throw CryptoError.decryptionFailed(reason: "Mock decryption configured to fail")
    }

    // Just return the original data as "decrypted"
    return data
  }

  public func deriveKey(
    from _: String,
    salt _: SecureBytes,
    iterations _: Int
  ) async throws -> SecureBytes {
    guard configuration.keyDerivationShouldSucceed else {
      throw CryptoError.keyDerivationFailed(reason: "Mock key derivation configured to fail")
    }

    // Generate a deterministic "key" based on the input
    let length=32 // Default key length
    return SecureBytes(bytes: [UInt8](repeating: 0x42, count: length))
  }

  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    guard configuration.randomGenerationShouldSucceed else {
      throw CryptoError.keyGenerationFailed(reason: "Mock key generation configured to fail")
    }

    return SecureBytes(bytes: [UInt8](repeating: 0x41, count: length))
  }

  public func generateSecureRandomBytes(length: Int) async throws -> SecureBytes {
    guard configuration.randomGenerationShouldSucceed else {
      throw CryptoError.keyGenerationFailed(reason: "Mock random generation configured to fail")
    }

    return SecureBytes(bytes: [UInt8](repeating: 0x43, count: length))
  }

  public func generateHMAC(
    for _: SecureBytes,
    using _: SecureBytes
  ) async throws -> SecureBytes {
    guard configuration.hmacGenerationShouldSucceed else {
      throw CryptoError.operationFailed(reason: "Mock HMAC generation configured to fail")
    }

    // Return a fixed HMAC value
    return SecureBytes(bytes: [UInt8](repeating: 0x44, count: 32))
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
    self.wrapped=wrapped
    self.logger=logger
  }

  public func encrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["dataSize"]=LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting encryption operation", metadata: metadata, source: "CryptoService")

    do {
      let result=try await wrapped.encrypt(data, using: key, iv: iv)
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
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["dataSize"]=LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting decryption operation", metadata: metadata, source: "CryptoService")

    do {
      let result=try await wrapped.decrypt(data, using: key, iv: iv)
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
    salt: SecureBytes,
    iterations: Int
  ) async throws -> SecureBytes {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["iterations"]=LoggingTypes
      .PrivacyMetadataValue(value: "\(iterations)", privacy: .public)

    await logger.debug("Starting key derivation", metadata: metadata, source: "CryptoService")

    do {
      let result=try await wrapped.deriveKey(from: password, salt: salt, iterations: iterations)

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

  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["length"]=LoggingTypes.PrivacyMetadataValue(value: "\(length)", privacy: .public)

    await logger.debug("Generating secure random key", metadata: metadata, source: "CryptoService")

    do {
      let result=try await wrapped.generateSecureRandomKey(length: length)
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
    for data: SecureBytes,
    using key: SecureBytes
  ) async throws -> SecureBytes {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["dataSize"]=LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Generating HMAC", metadata: metadata, source: "CryptoService")

    do {
      let result=try await wrapped.generateHMAC(for: data, using: key)
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
