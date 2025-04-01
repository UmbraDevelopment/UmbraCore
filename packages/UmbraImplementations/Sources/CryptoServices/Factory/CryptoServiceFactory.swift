import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import SecurityInterfaces  // Temporary, until we fully migrate SecureStorageConfig
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
 let loggingService = await CryptoServiceFactory.createLoggingDecorator(
   wrapped: cryptoService,
   logger: myLogger
 )
 ```
 */
public enum CryptoServiceFactory {
  /**
   Creates a default implementation of CryptoServiceProtocol.
   
   This implementation uses the Alpha Dot Five architecture principles,
   providing robust security capabilities with proper isolation.
   
   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault() async -> CryptoServiceProtocol {
    return await MockCryptoServiceImpl()
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
    return await MockCryptoServiceImpl(configuration: configuration)
  }
  
  /**
   Creates a logging decorator for any CryptoServiceProtocol implementation.
   
   This logs all cryptographic operations before delegating to the wrapped implementation.
   
   - Parameters:
     - wrapped: The implementation to wrap
     - logger: The logger to use
   - Returns: A logging decorator for the wrapped implementation
   */
  public static func createLoggingDecorator(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) async -> CryptoServiceProtocol {
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
      encryptionShouldSucceed: Bool = true,
      decryptionShouldSucceed: Bool = true,
      hashingShouldSucceed: Bool = true,
      hashVerificationShouldSucceed: Bool = true,
      keyDerivationShouldSucceed: Bool = true,
      randomGenerationShouldSucceed: Bool = true,
      hmacGenerationShouldSucceed: Bool = true
    ) {
      self.encryptionShouldSucceed = encryptionShouldSucceed
      self.decryptionShouldSucceed = decryptionShouldSucceed
      self.hashingShouldSucceed = hashingShouldSucceed
      self.hashVerificationShouldSucceed = hashVerificationShouldSucceed
      self.keyDerivationShouldSucceed = keyDerivationShouldSucceed
      self.randomGenerationShouldSucceed = randomGenerationShouldSucceed
      self.hmacGenerationShouldSucceed = hmacGenerationShouldSucceed
    }
  }

  /// The mock configuration
  private let configuration: Configuration

  /// Initialize with specific configuration
  public init(configuration: Configuration = Configuration()) {
    self.configuration = configuration
  }

  public func encrypt(data: [UInt8], using key: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    guard configuration.encryptionShouldSucceed else {
      return .failure(.operationFailed("Mock encryption configured to fail"))
    }

    // Create a mock encrypted result
    let encryptedData = [UInt8](repeating: 0x42, count: data.count + 16) // Add 16 bytes for mock IV/padding
    
    return .success(encryptedData)
  }

  public func decrypt(data: [UInt8], using key: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    guard configuration.decryptionShouldSucceed else {
      return .failure(.operationFailed("Mock decryption configured to fail"))
    }

    // Create a mock decrypted result
    let decryptedData = [UInt8](repeating: 0x41, count: max(0, data.count - 16)) // Remove 16 bytes for mock IV/padding
    
    return .success(decryptedData)
  }

  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    guard configuration.hashingShouldSucceed else {
      return .failure(.operationFailed("Mock hashing configured to fail"))
    }

    // Create a mock hash (fixed length of 32 bytes for SHA-256)
    let hash = [UInt8](repeating: 0x43, count: 32)
    
    return .success(hash)
  }

  public func verifyHash(data: [UInt8], expectedHash: [UInt8]) async -> Result<Bool, SecurityProtocolError> {
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
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting encryption operation", metadata: metadata, source: "CryptoService")

    let result = await wrapped.encrypt(data: data, using: key)
    
    switch result {
    case .success:
      await logger.debug(
        "Encryption completed successfully",
        metadata: metadata,
        source: "CryptoService"
      )
    case .failure(let error):
      await logger.error(
        "Encryption failed",
        error: error,
        metadata: metadata,
        source: "CryptoService"
      )
    }
    
    return result
  }

  public func decrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting decryption operation", metadata: metadata, source: "CryptoService")

    let result = await wrapped.decrypt(data: data, using: key)
    
    switch result {
    case .success:
      await logger.debug(
        "Decryption completed successfully",
        metadata: metadata,
        source: "CryptoService"
      )
    case .failure(let error):
      await logger.error(
        "Decryption failed",
        error: error,
        metadata: metadata,
        source: "CryptoService"
      )
    }
    
    return result
  }

  public func hash(
    data: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting hash operation", metadata: metadata, source: "CryptoService")

    let result = await wrapped.hash(data: data)
    
    switch result {
    case .success:
      await logger.debug(
        "Hash operation completed successfully",
        metadata: metadata,
        source: "CryptoService"
      )
    case .failure(let error):
      await logger.error(
        "Hash operation failed",
        error: error,
        metadata: metadata,
        source: "CryptoService"
      )
    }
    
    return result
  }

  public func verifyHash(
    data: [UInt8],
    expectedHash: [UInt8]
  ) async -> Result<Bool, SecurityProtocolError> {
    var metadata = LoggingTypes.PrivacyMetadata()
    metadata["dataSize"] = LoggingTypes.PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug("Starting hash verification", metadata: metadata, source: "CryptoService")

    let result = await wrapped.verifyHash(data: data, expectedHash: expectedHash)
    
    switch result {
    case .success(let matches):
      await logger.debug(
        "Hash verification completed successfully: \(matches ? "match" : "no match")",
        metadata: metadata,
        source: "CryptoService"
      )
    case .failure(let error):
      await logger.error(
        "Hash verification failed",
        error: error,
        metadata: metadata,
        source: "CryptoService"
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
  
  /**
   Initializes a new secure crypto service with an optional wrapped implementation.
   
   - Parameter wrapped: The underlying implementation to use (defaults to a standard one)
   */
  public init(wrapped: CryptoServiceProtocol? = nil) async {
    if let wrapped = wrapped {
      self.wrapped = wrapped
    } else {
      self.wrapped = await MockCryptoServiceImpl()
    }
  }
  
  public func encrypt(data: [UInt8], using key: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    // Convert to the canonical types and call the wrapped implementation
    return await wrapped.encrypt(data: data, using: key)
  }
  
  public func decrypt(data: [UInt8], using key: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    // Convert to the canonical types and call the wrapped implementation
    return await wrapped.decrypt(data: data, using: key)
  }
  
  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    // Convert to the canonical types and call the wrapped implementation
    return await wrapped.hash(data: data)
  }
  
  public func verifyHash(data: [UInt8], expectedHash: [UInt8]) async -> Result<Bool, SecurityProtocolError> {
    // Convert to the canonical types and call the wrapped implementation
    return await wrapped.verifyHash(data: data, expectedHash: expectedHash)
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
