import CoreSecurityTypes
import CryptoTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # CryptoServiceFactory

 Factory for creating different implementations of the CryptoServiceProtocol
 following the Alpha Dot Five architecture principles.
 */
public class CryptoServiceFactory {
  
  /**
   Creates a default crypto service implementation.
   
   - Parameter secureStorage: The secure storage implementation to use
   - Returns: A default crypto service implementation
   */
  public static func createDefault(
    secureStorage: SecureStorageProtocol
  ) async -> CryptoServiceProtocol {
    return DefaultCryptoServiceImpl(secureStorage: secureStorage)
  }
  
  /**
   Creates a default crypto service with logging capabilities.
   
   - Parameters:
     - wrapped: The base implementation to decorate with logging
     - logger: The logger to use for recording operations
   - Returns: A crypto service with logging capabilities
   */
  public static func createLoggingDecorator(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) async -> CryptoServiceProtocol {
    return LoggingCryptoService(wrapped: wrapped, logger: logger)
  }
  
  /**
   Creates a mock crypto service for testing purposes.
   
   - Parameters:
     - secureStorage: The secure storage implementation to use
     - configuration: Configuration options for the mock service
   - Returns: A mock crypto service implementation
   */
  public static func createMock(
    secureStorage: SecureStorageProtocol,
    configuration: [String: Any]
  ) async -> CryptoServiceProtocol {
    // Since the MockCryptoServiceImpl doesn't exist yet, return the default implementation
    return DefaultCryptoServiceImpl(secureStorage: secureStorage)
  }
  
  /**
   Creates a secure crypto service for enhanced security operations.
   
   - Parameters:
     - secureStorage: The secure storage implementation to use
     - cryptoStorage: The crypto storage implementation for key management
     - logger: The logger to use for recording operations
   - Returns: A secure crypto service implementation
   */
  public static func createSecure(
    secureStorage: SecureStorageProtocol,
    cryptoStorage: SecureCryptoStorage,
    logger: LoggingProtocol
  ) async -> CryptoServiceProtocol {
    let base = DefaultCryptoServiceImpl(secureStorage: secureStorage)
    return SecureCryptoServiceImpl(
      wrapped: base,
      logger: logger
    )
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
  
  /// Logger for recording operations
  private let logger: LoggingProtocol
  
  /**
   Creates a new secure crypto service implementation
   
   - Parameters:
     - wrapped: The base implementation to delegate to
     - logger: Logger for recording operations
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.logger = logger
  }
  
  // MARK: - CryptoServiceProtocol Conformance
  
  /// Encrypts binary data using a key from secure storage.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }
  
  /// Decrypts binary data using a key from secure storage.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }
  
  /// Computes a cryptographic hash of data in secure storage.
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }
  
  /// Verifies a cryptographic hash against the expected value, both stored securely.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }
  
  /// Generates a cryptographic key and stores it securely.
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await wrapped.generateKey(
      length: length,
      options: options
    )
  }
  
  /// Imports data into secure storage for use with cryptographic operations.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
  }
  
  /// Exports data from secure storage.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Log for auditing (using simple string metadata to avoid privacy metadata issues)
    await logger.info(
      "Exporting data from secure storage exposes sensitive material",
      metadata: ["operation": "exportData", "identifier_present": "true"],
      source: "SecureCryptoService"
    )

    let result = await wrapped.exportData(identifier: identifier)
    
    switch result {
    case .success(let data):
      // Log success
      await logger.info(
        "Data export completed successfully", 
        metadata: [
          "data_size": String(data.count),
          "operation": "exportData"
        ],
        source: "SecureCryptoService"
      )
      return .success(data)
      
    case .failure(let error):
      // Log failure
      await logger.error(
        "Data export failed: \(error.localizedDescription)", 
        metadata: [
          "error_description": error.localizedDescription,
          "operation": "exportData"
        ],
        source: "SecureCryptoService"
      )
      return .failure(error)
    }
  }
}
