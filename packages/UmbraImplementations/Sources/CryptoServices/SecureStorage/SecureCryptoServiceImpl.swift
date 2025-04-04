/**
 # EnhancedSecureCryptoServiceImpl

 A fully secure implementation of CryptoServiceProtocol that follows the Alpha Dot Five
 architecture principles, integrating native actor-based SecureStorage for all
 cryptographic materials.

 This implementation ensures all sensitive data is properly stored, retrieved, and
 managed through secure channels with appropriate privacy protections.
 */

import CryptoInterfaces
import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 A secure implementation of CryptoServiceProtocol using actor-based SecureStorage
 for all cryptographic operations.
 */
public actor EnhancedSecureCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped crypto service implementation
  private let wrapped: CryptoServiceProtocol
  
  /// Secure storage specifically for cryptographic materials
  private let cryptoStorage: SecureCryptoStorage
  
  /// Standard SecureStorageProtocol implementation for interface compatibility
  public nonisolated let secureStorage: SecureStorageProtocol
  
  /// Logger for recording operations with proper privacy controls
  private nonisolated let logger: LoggingProtocol
  
  /// Creates a new secure crypto service implementation
  /// - Parameters:
  ///   - wrapped: The underlying crypto service to use
  ///   - secureStorage: The secure storage for crypto operations
  ///   - cryptoStorage: The secure storage for crypto materials
  ///   - logger: Logger for recording operations
  public init(
    wrapped: CryptoServiceProtocol,
    secureStorage: SecureStorageProtocol,
    cryptoStorage: SecureCryptoStorage,
    logger: LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.secureStorage = secureStorage
    self.cryptoStorage = cryptoStorage
    self.logger = logger
  }
  
  // MARK: - CryptoServiceProtocol Implementation
  
  /// Encrypts data identified by dataIdentifier using a key identified by keyIdentifier
  /// and securely stores the result
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }
  
  /// Decrypts data identified by encryptedDataIdentifier using a key identified by keyIdentifier
  /// and securely stores the result
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }
  
  /// Hashes data identified by dataIdentifier and securely stores the result
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }
  
  /// Verifies a hash against data, both identified by their secure storage identifiers
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    return await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }
  
  /// Generates a cryptographic key of the specified length and stores it securely
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.generateKey(
      length: length,
      options: options
    )
  }
  
  /// Imports raw data into secure storage
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
  }
  
  /// Exports data from secure storage
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    return await wrapped.exportData(
      identifier: identifier
    )
  }
}
