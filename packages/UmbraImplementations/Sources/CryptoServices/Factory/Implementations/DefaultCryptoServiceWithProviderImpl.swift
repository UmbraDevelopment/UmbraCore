import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 A default implementation of CryptoServiceProtocol that delegates operations to a SecurityProviderProtocol.

 This class serves as a bridge between the CryptoServiceProtocol and SecurityProviderProtocol interfaces,
 enabling the use of any security provider that conforms to SecurityProviderProtocol with the
 CryptoServiceProtocol API.
 */
public actor DefaultCryptoServiceWithProviderImpl: CryptoServiceProtocol {
  private let provider: SecurityProviderProtocol
  public let secureStorage: SecureStorageProtocol
  private let logger: PrivacyAwareLoggingProtocol

  public init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.provider = provider
    self.secureStorage = secureStorage
    self.logger = logger
  }

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = BaseLogContextDTO(
      domainName: "CryptoServiceWithProvider",
      source: "DefaultCryptoServiceWithProviderImpl.encrypt",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "keyIdentifier", value: keyIdentifier)
    )

    await logger.log(.debug, "Encrypting data: \(dataIdentifier)", context: context)

    // 1. Retrieve original data
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case let .success(dataBytes) = dataResult else {
      let error: SecurityStorageError
      if case let .failure(retrievalError) = dataResult {
        error = retrievalError
      } else {
        error = .dataNotFound // Should not happen if guard fails, but fallback
      }
      await logger.log(
        .error,
        "Failed to retrieve data for encryption: \(error)",
        context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: dataIdentifier))
      )
      return .failure(error)
    }
    let data = Data(dataBytes)

    // Prepare operation options
    // Note: Assuming SecurityProviderProtocol handles specific algorithm/mode based on Key type or options.
    // The protocol doesn't specify SecurityProviderOptions, so we pass the CryptoService options.

    // Delegate to security provider
    // Assuming provider has an `encryptData` method matching the required signature
    let result = await provider.encryptData(
      data: data,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
    case .success(let encryptedData):
      // 3. Store encrypted data
      let encryptedDataStoreIdentifier = "enc-\(UUID().uuidString)"
      let storeResult = await secureStorage.storeData([UInt8](encryptedData), withIdentifier: encryptedDataStoreIdentifier)
      switch storeResult {
      case .success:
        await logger.log(
          .info,
          "Successfully encrypted and stored data",
          context: context.withMetadata(
            LogMetadataDTOCollection().withPublic(key: "encryptedIdentifier", value: encryptedDataStoreIdentifier)
          )
        )
        return .success(encryptedDataStoreIdentifier) // Return the *storage* identifier
      case .failure(let error):
        await logger.log(
          .error,
          "Failed to store encrypted data: \(error)",
          context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: encryptedDataStoreIdentifier))
        )
        return .failure(.operationFailed("Failed to store encrypted data: \(error)"))
      }
    case .failure(let error):
      let mappedError = mapProviderError(error)
      await logger.log(
        .error,
        "Encryption failed by provider: \(error)",
        context: context.withMetadata(context.metadata.withError(mappedError))
      )
      return .failure(mappedError)
    }
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = BaseLogContextDTO(
      domainName: "CryptoServiceWithProvider",
      source: "DefaultCryptoServiceWithProviderImpl.decrypt",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
        .withPublic(key: "keyIdentifier", value: keyIdentifier)
    )

    await logger.log(.debug, "Decrypting data: \(encryptedDataIdentifier)", context: context)

    // 1. Retrieve encrypted data
    let dataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    guard case let .success(dataBytes) = dataResult else {
      let error: SecurityStorageError
      if case let .failure(retrievalError) = dataResult {
        error = retrievalError
      } else {
        error = .dataNotFound // Should not happen if guard fails, but fallback
      }
      await logger.log(
        .error,
        "Failed to retrieve encrypted data: \(error)",
        context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: encryptedDataIdentifier))
      )
      return .failure(error)
    }
    let encryptedData = Data(dataBytes)

    // Prepare operation options
    // Note: Assuming SecurityProviderProtocol handles specific algorithm/mode based on Key type or options.
    // The protocol doesn't specify SecurityProviderOptions, so we pass the CryptoService options.

    // Delegate to security provider
    // Assuming provider has a `decryptData` method
    let result = await provider.decryptData(
      data: encryptedData,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
    case .success(let decryptedData):
      // 3. Store decrypted data
      let decryptedDataStoreIdentifier = "dec-\(UUID().uuidString)"
      let storeResult = await secureStorage.storeData([UInt8](decryptedData), withIdentifier: decryptedDataStoreIdentifier)
      switch storeResult {
      case .success:
        await logger.log(
          .info,
          "Successfully decrypted and stored data",
          context: context.withMetadata(
            LogMetadataDTOCollection().withPublic(key: "decryptedIdentifier", value: decryptedDataStoreIdentifier)
          )
        )
        return .success(decryptedDataStoreIdentifier) // Return the *storage* identifier
      case .failure(let error):
        await logger.log(
          .error,
          "Failed to store decrypted data: \(error)",
          context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: decryptedDataStoreIdentifier))
        )
        return .failure(.operationFailed("Failed to store decrypted data: \(error)"))
      }
    case .failure(let error):
      let mappedError = mapProviderError(error)
      await logger.log(
        .error,
        "Decryption failed by provider: \(error)",
        context: context.withMetadata(context.metadata.withError(mappedError))
      )
      return .failure(mappedError)
    }
  }

  public func hash(
    dataIdentifier: String,
    options: HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    let context = BaseLogContextDTO(
      domainName: "CryptoServiceWithProvider",
      source: "DefaultCryptoServiceWithProviderImpl.hash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )

    await logger.log(.debug, "Hashing data: \(dataIdentifier)", context: context)

    // 1. Retrieve original data
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case let .success(dataBytes) = dataResult else {
      let error: SecurityStorageError
      if case let .failure(retrievalError) = dataResult {
        error = retrievalError
      } else {
        error = .dataNotFound // Should not happen if guard fails, but fallback
      }
      await logger.log(
        .error,
        "Failed to retrieve data for hashing: \(error)",
        context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: dataIdentifier))
      )
      return .failure(error)
    }
    let data = Data(dataBytes)

    // Note: Assuming provider has a `hashData` method

    // Delegate to security provider
    let result = await provider.hashData(
      data: data,
      options: options
    )

    switch result {
    case .success(let hashData):
      // 3. Store hash data
      let hashStoreIdentifier = "hash-\(UUID().uuidString)"
      let storeResult = await secureStorage.storeData([UInt8](hashData), withIdentifier: hashStoreIdentifier)
      switch storeResult {
      case .success:
        await logger.log(
          .info,
          "Successfully hashed and stored data",
          context: context.withMetadata(
            LogMetadataDTOCollection().withPublic(key: "hashIdentifier", value: hashStoreIdentifier)
          )
        )
        return .success(hashStoreIdentifier) // Return the *storage* identifier
      case .failure(let error):
        await logger.log(
          .error,
          "Failed to store hash data: \(error)",
          context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: hashStoreIdentifier))
        )
        return .failure(.operationFailed("Failed to store hash data: \(error)"))
      }
    case .failure(let error):
      let mappedError = mapProviderError(error)
      await logger.log(
        .error,
        "Hashing failed by provider: \(error)",
        context: context.withMetadata(context.metadata.withError(mappedError))
      )
      return .failure(mappedError)
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    let context = BaseLogContextDTO(
      domainName: "CryptoServiceWithProvider",
      operationName: "verifyHash",
      source: "DefaultCryptoServiceWithProviderImpl.verifyHash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )

    await logger.log(.debug, "Verifying hash for data: \(dataIdentifier) against hash: \(hashIdentifier)", context: context)

    // 1. Retrieve original data
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case let .success(dataBytes) = dataResult else {
      let error: SecurityStorageError
      if case let .failure(retrievalError) = dataResult {
        error = retrievalError
      } else {
        error = .dataNotFound // Should not happen if guard fails, but fallback
      }
      await logger.log(
        .error,
        "Failed to retrieve original data for hash verification: \(error)",
        context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: dataIdentifier))
      )
      return .failure(error)
    }
    let data = Data(dataBytes)

    // 2. Retrieve expected hash
    let hashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
    guard case let .success(hashBytes) = hashResult else {
      let error: SecurityStorageError
      if case let .failure(retrievalError) = hashResult {
        error = retrievalError
      } else {
        error = .hashNotFound // Should not happen if guard fails, but fallback
      }
      await logger.log(
        .error,
        "Failed to retrieve expected hash for verification: \(error)",
        context: context.withMetadata(context.metadata.withError(error).withPublic(key: "identifier", value: hashIdentifier))
      )
      return .failure(error)
    }
    let expectedHash = Data(hashBytes)

    // Delegate to security provider
    // Assuming provider has a `verifyHashData` method
    let result = await provider.verifyHashData(
      data: dataBytes,
      expectedHash: hashBytes,
      algorithm: algorithm
    )

    switch result {
    case .success(let isValid):
      await logger.log(
        .info,
        "Hash verification result: \(isValid)",
        context: context.withMetadata(LogMetadataDTOCollection().withPublic(key: "isValid", value: "\(isValid)"))
      )
      return .success(isValid)
    case .failure(let error):
      let mappedError = mapProviderError(error)
      await logger.log(
        .error,
        "Hash verification failed by provider: \(error)",
        context: context.withMetadata(context.metadata.withError(mappedError))
      )
      return .failure(mappedError)
    }
  }

  // MARK: - Key Management (Stubs - Implement using Provider)

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = BaseLogContextDTO(domainName: "CryptoServiceWithProvider", source: "generateKey")
    await logger.log(.warning, "generateKey not fully implemented, needs provider integration", context: context)

    // TODO: Delegate to provider.generateKey(length: options:)
    // Example placeholder:
    /*
     let providerResult = await provider.generateKey(length: length, options: options)
     switch providerResult {
     case .success(let keyData):
       let keyIdentifier = "key-\(UUID().uuidString)"
       let storeResult = await secureStorage.storeData([UInt8](keyData), withIdentifier: keyIdentifier)
       return storeResult.map { keyIdentifier }.mapError { .operationFailed("Failed to store generated key: \($0)") }
     case .failure(let error):
       return .failure(mapProviderError(error))
     }
     */
    return .failure(.unsupportedOperation)
  }

  public func importKey(
    keyData: Data,
    options: KeyImportOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = BaseLogContextDTO(domainName: "CryptoServiceWithProvider", source: "importKey")
    await logger.log(.warning, "importKey not fully implemented, needs provider integration", context: context)
    // TODO: Delegate to provider.importKey(keyData: options:)
    // TODO: Store the key using secureStorage and return its identifier
    return .failure(.unsupportedOperation)
  }

  public func exportKey(
    keyIdentifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let context = BaseLogContextDTO(domainName: "CryptoServiceWithProvider", source: "exportKey")
    await logger.log(.warning, "exportKey not fully implemented, needs provider integration", context: context)
    // TODO: Retrieve key identifier from storage if necessary
    // TODO: Delegate to provider.exportKey(keyIdentifier:)
    return .failure(.unsupportedOperation)
  }

  // MARK: - Signing (Stubs - Implement using Provider)

  public func signData(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SigningOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = BaseLogContextDTO(domainName: "CryptoServiceWithProvider", source: "signData")
    await logger.log(.warning, "signData not fully implemented, needs provider integration", context: context)
    // TODO: Retrieve data
    // TODO: Delegate to provider.signData(data: keyIdentifier: options:)
    // TODO: Store signature and return identifier
    return .failure(.unsupportedOperation)
  }

  public func verifySignature(
    dataIdentifier: String,
    signatureIdentifier: String,
    keyIdentifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    let context = BaseLogContextDTO(domainName: "CryptoServiceWithProvider", source: "verifySignature")
    await logger.log(.warning, "verifySignature not fully implemented, needs provider integration", context: context)
    // TODO: Retrieve data and signature
    // TODO: Delegate to provider.verifySignature(data: signature: keyIdentifier:)
    return .failure(.unsupportedOperation)
  }

  // MARK: - Direct Data Handling (Pass-through to SecureStorage)

  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await secureStorage.storeData([UInt8](data), withIdentifier: identifier)
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let result = await secureStorage.retrieveData(withIdentifier: identifier)
    return result.map { Data($0) } // Convert [UInt8] to Data
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await secureStorage.deleteData(withIdentifier: identifier)
  }

  public func importData(
    _ data: Data,
    customIdentifier: String? = nil
  ) async -> Result<String, SecurityStorageError> {
    let identifier = customIdentifier ?? UUID().uuidString
    let storeResult = await secureStorage.storeData([UInt8](data), withIdentifier: identifier)
    return storeResult.map { identifier }
  }

  // Protocol requires exportData as [UInt8], but provider likely works with Data.
  // This conflicts slightly, returning Data based on assumed provider interaction.
  // If strict conformance is needed, provider might need adjustment or this needs [UInt8].
  public func exportData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let result = await secureStorage.retrieveData(withIdentifier: identifier)
    return result.map { Data($0) }
  }

  // MARK: - Helper Methods

  /// Maps potential errors from the SecurityProviderProtocol to SecurityStorageError.
  /// Placeholder implementation - replace with actual error mapping.
  private func mapProviderError(_ error: Error) -> SecurityStorageError {
    // TODO: Implement proper mapping based on SecurityProviderError definition
    if let storageError = error as? SecurityStorageError {
      return storageError // Pass through if it's already the correct type
    }
    // Example mapping (adjust based on actual provider errors)
    /*
     if let providerError = error as? SecurityProviderError {
       switch providerError {
       case .keyNotFound:
         return .keyNotFound
       case .encryptionFailed:
         return .encryptionFailed
       // ... other cases ...
       default:
         return .operationFailed("Provider error: \(providerError)")
       }
     }
     */
    return .operationFailed("Provider operation failed: \(error)")
  }
}
