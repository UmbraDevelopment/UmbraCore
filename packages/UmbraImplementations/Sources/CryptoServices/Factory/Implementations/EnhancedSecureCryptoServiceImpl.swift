import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 An enhanced secure implementation of CryptoServiceProtocol that adds additional security measures.

 This implementation wraps another CryptoServiceProtocol implementation and adds
 additional security features such as rate limiting, secure storage, and enhanced
 validation of cryptographic operations.
 */
public actor EnhancedSecureCryptoServiceImpl: CryptoServiceProtocol {

  /// The wrapped implementation that does the actual cryptographic work
  private let wrapped: CryptoServiceProtocol

  /// The secure storage used for handling sensitive data
  private let storage: SecureStorageProtocol

  /// The logger to use
  private let logger: LoggingProtocol

  /// Last operation timestamps for rate limiting
  private var lastOperationTimes: [String: TimeInterval]=[:]

  /// The minimum interval between operations (in seconds)
  private let operationRateLimit: TimeInterval=0.1 // 100ms

  /**
   Initialises a new enhanced secure crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap
     - storage: The secure storage to use
     - logger: The logger to use
   */
  public init(
    wrapped: CryptoServiceProtocol,
    storage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped=wrapped
    self.storage=storage
    self.logger=logger
  }

  /// Checks if an operation should be rate limited.
  ///
  /// - Parameter operation: The operation to check
  /// - Returns: True if the operation should proceed, false if it should be rate limited
  private func checkRateLimit(operation: String) -> Bool {
    let now=Date().timeIntervalSince1970

    if
      let lastTime=lastOperationTimes[operation],
      now - lastTime < operationRateLimit
    {
      return false
    }

    lastOperationTimes[operation]=now
    return true
  }

  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    options: CryptoServiceOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "encrypt") else {
      await logger.warning(
        "Operation rate-limited: encrypt",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !data.isEmpty else {
      await logger.error(
        "Empty data provided for encryption",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidInput))
    }

    guard !keyIdentifier.isEmpty else {
      await logger.error(
        "Empty key identifier provided for encryption",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    // Delegate to wrapped implementation
    return await wrapped.encrypt(
      data: data,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CryptoServiceOptions?=nil
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "decrypt") else {
      await logger.warning(
        "Operation rate-limited: decrypt",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !encryptedDataIdentifier.isEmpty else {
      await logger.error(
        "Empty encrypted data identifier provided for decryption",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    guard !keyIdentifier.isEmpty else {
      await logger.error(
        "Empty key identifier provided for decryption",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    // Delegate to wrapped implementation
    return await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  public func generateHash(
    data: [UInt8],
    algorithm: HashAlgorithm
  ) async -> Result<String, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "generateHash") else {
      await logger.warning(
        "Operation rate-limited: generateHash",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !data.isEmpty else {
      await logger.error(
        "Empty data provided for hash generation",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidInput))
    }

    // Delegate to wrapped implementation
    return await wrapped.generateHash(
      data: data,
      algorithm: algorithm
    )
  }

  public func verifyHash(
    dataIdentifier: String,
    expectedHashIdentifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "verifyHash") else {
      await logger.warning(
        "Operation rate-limited: verifyHash",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !dataIdentifier.isEmpty else {
      await logger.error(
        "Empty data identifier provided for hash verification",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    guard !expectedHashIdentifier.isEmpty else {
      await logger.error(
        "Empty hash identifier provided for hash verification",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    // Delegate to wrapped implementation
    return await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      expectedHashIdentifier: expectedHashIdentifier
    )
  }

  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "generateKey") else {
      await logger.warning(
        "Operation rate-limited: generateKey",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard length >= 16 else { // Minimum 128-bit key
      await logger.error(
        "Key length too short: \(length) bytes",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidKeyLength))
    }

    // Delegate to wrapped implementation
    return await wrapped.generateKey(
      length: length,
      options: options
    )
  }

  public func storeData(
    data: [UInt8],
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "storeData") else {
      await logger.warning(
        "Operation rate-limited: storeData",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !data.isEmpty else {
      await logger.error(
        "Empty data provided for storage",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidInput))
    }

    guard !identifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for data storage",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidInput))
    }

    // Delegate to wrapped implementation
    return await wrapped.storeData(
      data: data,
      identifier: identifier
    )
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "retrieveData") else {
      await logger.warning(
        "Operation rate-limited: retrieveData",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !identifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for data retrieval",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    // Delegate to wrapped implementation
    return await wrapped.retrieveData(
      identifier: identifier
    )
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "exportData") else {
      await logger.warning(
        "Operation rate-limited: exportData",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !identifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for data export",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    // Delegate to wrapped implementation
    return await wrapped.exportData(
      identifier: identifier
    )
  }

  public func importData(
    data: [UInt8],
    identifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "importData") else {
      await logger.warning(
        "Operation rate-limited: importData",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !data.isEmpty else {
      await logger.error(
        "Empty data provided for import",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidInput))
    }

    guard !identifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for data import",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.invalidInput))
    }

    // Delegate to wrapped implementation
    return await wrapped.importData(
      data: data,
      identifier: identifier
    )
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Rate limit check
    guard checkRateLimit(operation: "deleteData") else {
      await logger.warning(
        "Operation rate-limited: deleteData",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed(UmbraErrors.Security.Core.rateLimited))
    }

    // Validate input
    guard !identifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for data deletion",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound(""))
    }

    // Delegate to wrapped implementation
    return await wrapped.deleteData(
      identifier: identifier
    )
  }
}
