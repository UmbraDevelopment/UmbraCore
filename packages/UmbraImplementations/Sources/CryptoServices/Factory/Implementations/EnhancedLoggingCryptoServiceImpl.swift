import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # EnhancedLoggingCryptoServiceImpl

 A decorator implementation of CryptoServiceProtocol that adds privacy-aware logging capabilities.
 This implementation wraps another CryptoServiceProtocol implementation and provides enhanced
 logging with proper privacy tags for sensitive data.
 */
public actor EnhancedLoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// Enhanced privacy-aware logger
  private let logger: PrivacyAwareLoggingProtocol

  /**
   Initialises a new enhanced logging crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap
     - logger: The privacy-aware logger to use
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.wrapped=wrapped
    self.logger=logger
  }

  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    options: CryptoServiceOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "encrypt",
      identifiers: [
        "keyIdentifier": .private(keyIdentifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Encrypting data with key",
      context: context
    )

    // Perform the operation
    let result=await wrapped.encrypt(
      data: data,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log result with enhanced privacy context
    switch result {
      case let .success(identifier):
        context.updateMetadata(["dataIdentifier": .private(identifier)])
        await logger.debug(
          "Encryption successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Encryption failed",
          context: context
        )
    }

    return result
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CryptoServiceOptions?=nil
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "decrypt",
      identifiers: [
        "encryptedDataIdentifier": .private(encryptedDataIdentifier),
        "keyIdentifier": .private(keyIdentifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Decrypting data",
      context: context
    )

    // Perform the operation
    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log result with enhanced privacy context
    switch result {
      case .success:
        await logger.debug(
          "Decryption successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Decryption failed",
          context: context
        )
    }

    return result
  }

  public func generateHash(
    data: [UInt8],
    algorithm: HashAlgorithm
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "generateHash",
      identifiers: [
        "algorithm": .public(String(describing: algorithm))
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Generating hash",
      context: context
    )

    // Perform the operation
    let result=await wrapped.generateHash(
      data: data,
      algorithm: algorithm
    )

    // Log result with enhanced privacy context
    switch result {
      case let .success(identifier):
        context.updateMetadata(["hashIdentifier": .private(identifier)])
        await logger.debug(
          "Hash generation successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Hash generation failed",
          context: context
        )
    }

    return result
  }

  public func verifyHash(
    dataIdentifier: String,
    expectedHashIdentifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "verifyHash",
      identifiers: [
        "dataIdentifier": .private(dataIdentifier),
        "expectedHashIdentifier": .private(expectedHashIdentifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Verifying hash",
      context: context
    )

    // Perform the operation
    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      expectedHashIdentifier: expectedHashIdentifier
    )

    // Log result with enhanced privacy context
    switch result {
      case let .success(matches):
        context.updateMetadata(["matches": .public(String(describing: matches))])
        await logger.debug(
          "Hash verification completed",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Hash verification failed",
          context: context
        )
    }

    return result
  }

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "generateKey",
      identifiers: [
        "keyLength": .public(String(describing: length))
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Generating key",
      context: context
    )

    // Perform the operation
    let result=await wrapped.generateKey(
      length: length,
      options: options
    )

    // Log result with enhanced privacy context
    switch result {
      case let .success(identifier):
        context.updateMetadata(["keyIdentifier": .private(identifier)])
        await logger.debug(
          "Key generation successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Key generation failed",
          context: context
        )
    }

    return result
  }

  public func storeData(
    data: [UInt8],
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "storeData",
      identifiers: [
        "identifier": .private(identifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Storing data",
      context: context
    )

    // Perform the operation
    let result=await wrapped.storeData(
      data: data,
      identifier: identifier
    )

    // Log result with enhanced privacy context
    switch result {
      case .success:
        await logger.debug(
          "Data storage successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Data storage failed",
          context: context
        )
    }

    return result
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "retrieveData",
      identifiers: [
        "identifier": .private(identifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Retrieving data",
      context: context
    )

    // Perform the operation
    let result=await wrapped.retrieveData(
      identifier: identifier
    )

    // Log result with enhanced privacy context
    switch result {
      case .success:
        await logger.debug(
          "Data retrieval successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Data retrieval failed",
          context: context
        )
    }

    return result
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "exportData",
      identifiers: [
        "identifier": .private(identifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Exporting data",
      context: context
    )

    // Perform the operation
    let result=await wrapped.exportData(
      identifier: identifier
    )

    // Log result with enhanced privacy context
    switch result {
      case .success:
        await logger.debug(
          "Data export successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Data export failed",
          context: context
        )
    }

    return result
  }

  public func importData(
    data: [UInt8],
    identifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "importData",
      identifiers: [:]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Importing data with identifier",
      context: context
    )

    // Perform the operation
    let result=await wrapped.importData(
      data: data,
      identifier: identifier
    )

    // Log result with enhanced privacy context
    switch result {
      case let .success(resultIdentifier):
        context.updateMetadata(["resultIdentifier": .private(resultIdentifier)])
        await logger.debug(
          "Data import successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Data import failed",
          context: context
        )
    }

    return result
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    var context=createEnhancedLogContext(
      operation: "deleteData",
      identifiers: [
        "identifier": .private(identifier)
      ]
    )

    // Log operation with enhanced privacy context
    await logger.debug(
      "Deleting data",
      context: context
    )

    // Perform the operation
    let result=await wrapped.deleteData(
      identifier: identifier
    )

    // Log result with enhanced privacy context
    switch result {
      case .success:
        await logger.debug(
          "Data deletion successful",
          context: context
        )
      case let .failure(error):
        context.updateMetadata(["error": .hash(String(describing: error))])
        await logger.error(
          "Data deletion failed",
          context: context
        )
    }

    return result
  }

  // MARK: - Helper Methods

  /**
   Creates an enhanced log context for crypto operations with proper privacy controls.

   - Parameters:
     - operation: The operation being performed
     - identifiers: Dictionary of identifiers with privacy levels
   - Returns: An enhanced log context
   */
  private func createEnhancedLogContext(
    operation: String,
    identifiers: [String: PrivacyLevel]
  ) -> EnhancedLogContext {
    var context=EnhancedLogContext(
      domainName: "CryptoServices",
      source: "CryptoServiceFactory",
      correlationID: nil
    )

    var metadata=identifiers
    metadata["operation"] = .public(operation)

    context.updateMetadata(metadata)
    return context
  }
}
