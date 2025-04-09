import CryptoInterfaces
import CryptoServices
import Foundation
import CoreSecurityTypes
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import SecurityImplementation
import UmbraErrors

/// Factory for creating instances of the SecurityProviderProtocol.
///
/// This factory provides methods for creating fully configured security service
/// instances with various configurations and crypto service integrations, ensuring
/// proper domain separation and delegation to crypto services.
///
/// All security services created by this factory use privacy-aware logging through
/// SecureLoggerActor, following the Alpha Dot Five architecture principles.
public enum SecurityServiceFactory {
  /// Creates a standard security service with default configuration
  /// - Parameters:
  ///   - logger: The logger to use for general logging
  ///   - secureLogger: The secure logger to use for privacy-aware logging (created if nil)
  /// - Returns: A security service instance
  public static func createStandard(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor? = nil
  ) async -> SecurityProviderProtocol {
    // Create a secure logger if one wasn't provided
    let secureLogger = secureLogger ?? await createSecureLogger(
      logger: logger,
      category: "SecurityService",
      includeTimestamps: true
    )

    // Create default configuration
    let configuration = SecurityConfigurationDTO(
      securityLevel: .standard,
      loggingLevel: .info
    )
    
    // Create the security service with secure logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: secureLogger,
      configuration: configuration
    )
  }

  /// Creates a security service with the specified logger
  /// - Parameter logger: The logger to use
  /// - Returns: A security service instance
  public static func createWithLogger(
    _ logger: LoggingInterfaces.LoggingProtocol
  ) async -> SecurityProviderProtocol {
    await createWithLoggers(logger: logger, secureLogger: nil, configuration: nil)
  }

  /// Creates a security service with the specified loggers
  /// - Parameters:
  ///   - logger: The standard logger to use for general operations
  ///   - secureLogger: The secure logger to use for privacy-aware logging (created if nil)
  ///   - configuration: The security configuration to use (created if nil)
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createWithLoggers(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor? = nil,
    configuration: SecurityImplementation.SecurityConfigurationDTO? = nil
  ) async -> SecurityProviderProtocol {
    // Create dependencies
    let cryptoService = await CryptoServiceFactory().createDefaultService()
    
    // Create a secure logger if one wasn't provided
    let secureLoggerInstance: SecureLoggerActor
    if let secureLogger = secureLogger {
      secureLoggerInstance = secureLogger
    } else {
      secureLoggerInstance = await LoggingServiceFactory.createSecureLogger(
        baseLogger: logger,
        domain: "SecurityService",
        privacyLevel: .high
      )
    }

    // Create default configuration if needed
    let configurationInstance = configuration ?? SecurityImplementation.SecurityConfigurationDTO(
      securityLevel: .standard,
      loggingLevel: .info
    )
    
    // Create the security service with the configured dependencies
    return SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLoggerInstance,
      configuration: configurationInstance
    )
  }

  /// Creates a mock security service for testing
  /// - Parameters:
  ///   - logger: The logger to use for general logging
  ///   - secureLogger: The secure logger to use for privacy-aware logging
  /// - Returns: A mock security service instance
  public static func createMock(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor? = nil
  ) async -> SecurityProviderProtocol {
    // Create a secure logger if one wasn't provided
    let secureLogger = secureLogger ?? await createSecureLogger(logger: logger)
    
    // Create mock crypto service
    let cryptoService = MockCryptoService()

    // Create mock configuration
    let configuration = SecurityImplementation.SecurityConfigurationDTO(
      securityLevel: .standard,
      loggingLevel: .debug
    )
    
    // Create the security service with mock dependencies
    return SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLogger,
      configuration: configuration
    )
  }

  /// Creates a security service for development with verbose logging
  /// - Returns: A security service instance with verbose logging
  public static func createForDevelopment() async -> SecurityProviderProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let logger = await loggingFactory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "SecurityImplementation",
      environment: .development
    )

    // Create default configuration
    let configuration = SecurityImplementation.SecurityConfigurationDTO(
      securityLevel: .standard,
      loggingLevel: .debug
    )
    
    // Create the security service with verbose logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: nil,
      configuration: configuration
    )
  }

  /// Creates a security service for production with secure logging
  /// - Returns: A security service instance with production logging
  public static func createForProduction() async -> SecurityProviderProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let logger = await loggingFactory.createProductionPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "SecurityImplementation"
    )

    // Create default configuration
    let configuration = SecurityImplementation.SecurityConfigurationDTO(
      securityLevel: .standard,
      loggingLevel: .warning
    )
    
    // Create the security service with production logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: nil,
      configuration: configuration
    )
  }
}

/// Helper function to create metadata dictionary from LogMetadataDTOCollection
private func createMetadataDictionary(_ metadata: LogMetadataDTOCollection) -> [String: String] {
  var metadataDict = [String: String]()
  for (key, value) in metadata.publicMetadata {
    metadataDict[key] = value
  }
  return metadataDict
}

/// Helper function to create a secure logger
/// - Parameters:
///   - logger: The logger to use as a base
///   - category: The category for the logger
///   - includeTimestamps: Whether to include timestamps in log messages
/// - Returns: A secure logger instance
private func createSecureLogger(
  logger: LoggingInterfaces.LoggingProtocol,
  category: String = "SecurityService",
  includeTimestamps: Bool = true
) async -> SecureLoggerActor {
  return await LoggingServiceFactory.createSecureLogger(
    baseLogger: logger,
    domain: category,
    privacyLevel: .high
  )
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
