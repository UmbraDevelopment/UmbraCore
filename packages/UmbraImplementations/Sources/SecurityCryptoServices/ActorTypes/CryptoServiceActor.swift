import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import ProviderFactories
import SecurityCoreInterfaces
import UmbraErrors

/// Actor implementation of the CryptoServiceProtocol, providing thread-safe
/// cryptographic operations using secure storage for sensitive data.
public actor CryptoServiceActor: CryptoServiceProtocol {
  // MARK: - Properties

  /// The secure storage used by this service for key and data storage
  public let secureStorage: SecureStorageProtocol

  /// The provider registry used to select appropriate providers for operations
  private let providerRegistry: ProviderRegistryProtocol

  /// Logger instance for tracking operations
  private let logger: LoggingProtocol

  /// Default provider to use for encryption operations
  private var provider: EncryptionProviderProtocol

  /// Default configuration for cryptographic operations
  private let defaultConfig: SecurityConfigDTO

  /// Log adapter for domain-specific logging
  private let logAdapter: DomainLogAdapter

  // MARK: - Initialization

  /// Initializes a new crypto service actor with the given dependencies.
  /// - Parameters:
  ///   - providerRegistry: The registry for security providers
  ///   - secureStorage: The secure storage implementation
  ///   - logger: The logger to use for operations
  public init(
    providerRegistry: ProviderRegistryProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) async {
    self.providerRegistry=providerRegistry
    self.secureStorage=secureStorage
    self.logger=logger

    // Initialize with a dummy provider as a fallback that will be replaced
    provider=DummyProvider()

    // Default configuration
    defaultConfig=SecurityConfigDTO(
      encryptionAlgorithm: .aes128CBC,
      hashAlgorithm: .sha256,
      providerType: .basic
    )

    // Create domain log adapter (early initialization)
    logAdapter=DomainLogAdapter(logger: logger, domain: "CryptoService")

    // Now try to get a real provider
    do {
      provider=try await providerRegistry.selectProvider(capabilities: [.standardEncryption])
    } catch {
      // If standard provider selection fails, create a basic provider fallback
      do {
        provider=try await providerRegistry.selectProvider(type: .basic)
      } catch {
        // If even the basic provider fails, log the error
        await logger.error(
          "Failed to create any provider: \(error.localizedDescription)",
          metadata: PrivacyMetadata(),
          source: "CryptoServiceActor"
        )

        // We're already using the dummy provider as fallback, so nothing more to do
        // except log the warning
        await logger.warning(
          "Using minimal security provider as a fallback. Security operations will be limited.",
          metadata: PrivacyMetadata(),
          source: "CryptoServiceActor"
        )
      }
    }
  }

  /// Creates a minimal provider for emergencies when no proper provider can be instantiated
  private func createMinimalProvider() async throws -> EncryptionProviderProtocol {
    // In a real implementation, this would create the simplest possible provider
    // For now, we'll throw an error as we expect a provider to be available
    throw SecurityServiceError.providerError("Unable to create any provider")
  }

  // MARK: - CryptoServiceProtocol Methods

  /// Encrypts data using a key from secure storage.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
  ///   - keyIdentifier: Identifier of the encryption key in secure storage.
  ///   - options: Optional encryption configuration.
  /// - Returns: Identifier for the encrypted data in secure storage, or an error.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options _: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Retrieve the data to encrypt and key from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    guard case let .success(data)=dataResult else {
      return .failure(.dataNotFound)
    }

    guard case let .success(key)=keyResult else {
      return .failure(.keyNotFound)
    }

    // Encrypt the data
    let encryptResult=await encrypt(data: data, using: key)

    guard case let .success(encryptedData)=encryptResult else {
      return .failure(.encryptionFailed)
    }

    // Store the encrypted data
    let identifier=UUID().uuidString
    let storeResult=await secureStorage.storeData(encryptedData, withIdentifier: identifier)

    guard case .success=storeResult else {
      return .failure(.storageUnavailable)
    }

    return .success(identifier)
  }

  /// Decrypts data using a key from secure storage.
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
  ///   - keyIdentifier: Identifier of the decryption key in secure storage.
  ///   - options: Optional decryption configuration.
  /// - Returns: Identifier for the decrypted data in secure storage, or an error.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Retrieve encrypted data and key from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    guard case let .success(encryptedData)=dataResult else {
      return .failure(.dataNotFound)
    }

    guard case let .success(key)=keyResult else {
      return .failure(.keyNotFound)
    }

    // Decrypt the data
    let decryptResult=await decrypt(data: encryptedData, using: key)

    guard case let .success(decryptedData)=decryptResult else {
      return .failure(.decryptionFailed)
    }

    // Store the decrypted data
    let identifier=UUID().uuidString
    let storeResult=await secureStorage.storeData(decryptedData, withIdentifier: identifier)

    guard case .success=storeResult else {
      return .failure(.storageUnavailable)
    }

    return .success(identifier)
  }

  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Retrieve the data to hash from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case let .success(data)=dataResult else {
      return .failure(.dataNotFound)
    }

    // Determine the algorithm to use
    let algorithm=options?.algorithm ?? .sha256

    // Hash the data
    let hashResult=await hash(data: data, algorithm: algorithm)

    guard case let .success(hashedData)=hashResult else {
      return .failure(.hashingFailed)
    }

    // Store the hash
    let identifier=UUID().uuidString
    let storeResult=await secureStorage.storeData(hashedData, withIdentifier: identifier)

    guard case .success=storeResult else {
      return .failure(.storageUnavailable)
    }

    return .success(identifier)
  }

  /// Verifies a cryptographic hash against the expected value, both stored securely.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Retrieve data and expected hash from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

    guard case let .success(data)=dataResult else {
      return .failure(.dataNotFound)
    }

    guard case let .success(expectedHash)=hashResult else {
      return .failure(.hashNotFound)
    }

    // Determine the algorithm to use
    let algorithm=options?.algorithm ?? .sha256

    // Compute the hash of the data
    let computedHashResult=await hash(data: data, algorithm: algorithm)

    guard case let .success(computedHash)=computedHashResult else {
      return .failure(.hashingFailed)
    }

    // Compare hashes
    let match=computedHash == expectedHash

    return .success(match)
  }

  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options _: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Use the provided key length
    let keyLength=length

    // Generate a new key
    let keyResult=await generateKey(size: keyLength)

    guard case let .success(key)=keyResult else {
      return .failure(.keyGenerationFailed)
    }

    // Store the key in secure storage
    let identifier=UUID().uuidString
    let storeResult=await secureStorage.storeData(key, withIdentifier: identifier)

    guard case .success=storeResult else {
      return .failure(.storageUnavailable)
    }

    return .success(identifier)
  }

  /// Imports data into secure storage for use with cryptographic operations.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is
  /// generated.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let identifier=customIdentifier ?? UUID().uuidString
    let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)

    guard case .success=storeResult else {
      return .failure(.storageUnavailable)
    }

    return .success(identifier)
  }

  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await secureStorage.retrieveData(withIdentifier: identifier)
  }

  // MARK: - Private Helper Methods

  /// Encrypts data with a key using the appropriate provider.
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key
  /// - Returns: The encrypted data or an error
  private func encrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityStorageError> {
    do {
      // Convert [UInt8] to Data for provider interface
      let dataAsData=Data(data)
      let keyAsData=Data(key)

      // Generate a fresh IV for each encryption (16 bytes for AES)
      let ivData=try provider.generateIV(size: 16)

      // Create a config for this encryption
      let config=defaultConfig

      // Perform the encryption with the correct parameters
      let encryptedData=try provider.encrypt(
        plaintext: dataAsData,
        key: keyAsData,
        iv: ivData,
        config: config
      )

      // Convert back to [UInt8] for our interface
      return .success([UInt8](encryptedData))
    } catch {
      await logAdapter.error(
        "Encryption failed: \(error.localizedDescription)",
        metadata: PrivacyMetadata()
      )
      return .failure(.encryptionFailed)
    }
  }

  /// Decrypts data with a key using the appropriate provider.
  /// - Parameters:
  ///   - data: The encrypted data
  ///   - key: The decryption key
  /// - Returns: The decrypted data or an error
  private func decrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityStorageError> {
    do {
      // Convert [UInt8] to Data for provider interface
      let dataAsData=Data(data)
      let keyAsData=Data(key)

      // In a real implementation, the IV would be stored alongside the ciphertext
      // Here we're using a default IV for simplicity
      let ivData=Data(repeating: 0, count: 16)

      // Create a config for this decryption
      let config=defaultConfig

      // Perform the decryption with the correct parameters
      let decryptedData=try provider.decrypt(
        ciphertext: dataAsData,
        key: keyAsData,
        iv: ivData,
        config: config
      )

      // Convert back to [UInt8] for our interface
      return .success([UInt8](decryptedData))
    } catch {
      await logAdapter.error(
        "Decryption failed: \(error.localizedDescription)",
        metadata: PrivacyMetadata()
      )
      return .failure(.decryptionFailed)
    }
  }

  /// Hashes data using the specified algorithm.
  /// - Parameters:
  ///   - data: The data to hash
  ///   - algorithm: The hashing algorithm to use
  /// - Returns: The computed hash or an error
  private func hash(
    data: [UInt8],
    algorithm: HashAlgorithm
  ) async -> Result<[UInt8], SecurityStorageError> {
    do {
      // Convert [UInt8] to Data for provider interface
      let dataAsData=Data(data)

      // Convert HashAlgorithm enum to String for the provider interface
      let algorithmString=algorithm.rawValue

      // Perform the hash operation with the correct parameters
      let hashData=try provider.hash(data: dataAsData, algorithm: algorithmString)

      // Convert back to [UInt8] for our interface
      return .success([UInt8](hashData))
    } catch {
      await logAdapter.error(
        "Hashing failed: \(error.localizedDescription)",
        metadata: PrivacyMetadata()
      )
      return .failure(.hashingFailed)
    }
  }

  /// Generates a cryptographic key of the specified size.
  /// - Parameter size: The key size in bytes
  /// - Returns: The generated key or an error
  private func generateKey(size: Int) async -> Result<[UInt8], SecurityStorageError> {
    do {
      let key=try provider.generateKey(size: size, config: defaultConfig)

      // Convert back to [UInt8] for our interface
      return .success([UInt8](key))
    } catch {
      await logAdapter.error(
        "Key generation failed: \(error.localizedDescription)",
        metadata: PrivacyMetadata()
      )
      return .failure(.keyGenerationFailed)
    }
  }
}

/// A log adapter that adds domain context to log messages
private struct DomainLogAdapter {
  /// The underlying logger
  private let logger: LoggingProtocol

  /// The domain to prefix to log messages
  private let domain: String

  init(logger: LoggingProtocol, domain: String) {
    self.logger=logger
    self.domain=domain
  }

  func debug(_ message: String, metadata: PrivacyMetadata?) async {
    await logger.debug("[\(domain)] \(message)", metadata: metadata, source: domain)
  }

  func info(_ message: String, metadata: PrivacyMetadata?) async {
    await logger.info("[\(domain)] \(message)", metadata: metadata, source: domain)
  }

  func warning(_ message: String, metadata: PrivacyMetadata?) async {
    await logger.warning("[\(domain)] \(message)", metadata: metadata, source: domain)
  }

  func error(_ message: String, metadata: PrivacyMetadata?) async {
    await logger.error("[\(domain)] \(message)", metadata: metadata, source: domain)
  }

  func critical(_ message: String, metadata: PrivacyMetadata?) async {
    await logger.critical("[\(domain)] \(message)", metadata: metadata, source: domain)
  }
}

/// A dummy provider that will fail all operations
/// Used only as a last resort when no other provider can be created
private final class DummyProvider: EncryptionProviderProtocol {
  var providerType: SecurityProviderType { .basic }

  func encrypt(
    plaintext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    throw SecurityServiceError.providerError("Dummy provider cannot perform encryption")
  }

  func decrypt(
    ciphertext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    throw SecurityServiceError.providerError("Dummy provider cannot perform decryption")
  }

  func generateKey(size _: Int, config _: SecurityConfigDTO) throws -> Data {
    throw SecurityServiceError.providerError("Dummy provider cannot generate keys")
  }

  func generateIV(size _: Int) throws -> Data {
    throw SecurityServiceError.providerError("Dummy provider cannot generate IVs")
  }

  func hash(data _: Data, algorithm _: String) throws -> Data {
    throw SecurityServiceError.providerError("Dummy provider cannot compute hashes")
  }
}
