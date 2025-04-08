import CryptoInterfaces
import CryptoServices
import Foundation
import CoreSecurityTypes
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/// Helper function to create PrivacyMetadata from dictionary
private func createPrivacyMetadata(_ dict: [String: String]) -> PrivacyMetadata {
  var metadata = PrivacyMetadata()
  for (key, value) in dict {
    metadata = metadata.withPublic(key: key, value: value)
  }
  return metadata
}

/// Factory for creating instances of the SecurityProviderProtocol.
///
/// This factory provides methods for creating fully configured security service
/// instances with various configurations and crypto service integrations, ensuring
/// proper domain separation and delegation to crypto services.
///
/// All security services created by this factory use privacy-aware logging through
/// SecureLoggerActor, following the Alpha Dot Five architecture principles.
public enum SecurityServiceFactory {
  /// Creates a default security service instance with standard configuration
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createDefault() async -> SecurityProviderProtocol {
    let factory = LoggingServiceFactory()
    let logger = await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security", 
      category: "SecurityImplementation"
    )

    let secureLogger = await LoggingServices.createSecureLogger(
      subsystem: "com.umbra.security",
      category: "SecurityService",
      includeTimestamps: true
    )

    // Create the security service with secure logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: secureLogger
    )
  }

  /// Creates a security service with the specified standard logger
  /// - Parameter logger: The standard logger to use for security operations
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createWithLogger(
    _ logger: LoggingInterfaces.LoggingProtocol
  ) async -> SecurityProviderProtocol {
    await createWithLoggers(logger: logger, secureLogger: nil)
  }

  /// Creates a security service with the specified loggers
  /// - Parameters:
  ///   - logger: The standard logger to use for general operations
  ///   - secureLogger: The secure logger to use for privacy-aware logging (created if nil)
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createWithLoggers(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor?
  ) async -> SecurityProviderProtocol {
    // Create dependencies
    let cryptoService = await CryptoServiceFactory().createDefaultService()
    
    // Create secure logger if needed
    let secureLoggerInstance: SecureLoggerActor
    if let secureLogger = secureLogger {
      secureLoggerInstance = secureLogger
    } else {
      secureLoggerInstance = await LoggingServices.createSecureLogger(
        subsystem: "com.umbra.security",
        category: "SecurityService",
        includeTimestamps: true
      )
    }

    // Create the security service with the configured dependencies
    return SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLoggerInstance
    )
  }

  /// Creates a security service for testing with mock dependencies
  /// - Returns: A security service configured for testing
  public static func createForTesting() async -> SecurityProviderProtocol {
    let factory = LoggingServiceFactory()
    let logger = await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security.test", 
      category: "SecurityImplementation"
    )
    
    let secureLogger = await LoggingServices.createSecureLogger(
      subsystem: "com.umbra.security.test",
      category: "SecurityService",
      includeTimestamps: true
    )

    // Create mock crypto service
    let cryptoService = MockCryptoService()

    // Create the security service with mock dependencies
    return SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLogger
    )
  }

  /// Creates a security service for development with verbose logging
  /// - Returns: A security service configured for development
  public static func createDevelopment() async -> SecurityProviderProtocol {
    // Create verbose logger for development
    let factory = LoggingServiceFactory()
    let logger = await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security", 
      category: "SecurityImplementation"
    )

    // Create the security service with verbose logging
    return await createWithLogger(logger)
  }

  /// Creates a security service for production with secure logging
  /// - Returns: A security service configured for production
  public static func createProduction() async -> SecurityProviderProtocol {
    // Create production logger with appropriate privacy settings
    let factory = LoggingServiceFactory()
    let logger = await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security", 
      category: "SecurityImplementation"
    )

    // Create the security service with production logging
    return await createWithLogger(logger)
  }
}

/// Mock implementation of CryptoServiceProtocol for testing
private final class MockCryptoService: CryptoServiceProtocol {
  // MARK: - Required Properties
  
  /// The secure storage used for handling sensitive data
  public var secureStorage: SecureStorageProtocol {
    // Return a mock secure storage implementation
    fatalError("Secure storage not implemented in mock")
  }
  
  // MARK: - Required Methods
  
  /// Encrypts binary data using a key from secure storage.
  func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success("mock-encrypted-data-id")
  }

  /// Decrypts binary data using a key from secure storage.
  func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success("mock-decrypted-data-id")
  }

  /// Computes a cryptographic hash of data in secure storage.
  func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success("mock-hash-id")
  }

  /// Verifies a cryptographic hash against the expected value, both stored securely.
  func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Mock implementation that always verifies successfully
    return .success(true)
  }

  /// Generates a cryptographic key and stores it securely.
  func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success("mock-key-id")
  }

  /// Imports data into secure storage for use with cryptographic operations.
  func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success(customIdentifier ?? "mock-data-id")
  }

  /// Exports data from secure storage.
  func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success([0, 1, 2, 3]) // Mock data
  }

  /// Generates a hash of the data associated with the given identifier.
  func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success("mock-hash-id")
  }

  /// Stores raw data under a specific identifier in secure storage.
  func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success(())
  }

  /// Retrieves raw data associated with a specific identifier from secure storage.
  func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success(Data([0, 1, 2, 3])) // Mock data
  }

  /// Deletes data associated with a specific identifier from secure storage.
  func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success(())
  }

  /// Imports data into secure storage with a specific identifier.
  func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Mock implementation that always succeeds
    return .success(customIdentifier)
  }
}
