import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import OSLog
import SecurityCoreInterfaces
import UmbraErrors

/**
 # KeychainSecurityActor

 An actor that integrates both KeychainServiceProtocol and ApplicationSecurityProviderProtocol,
 providing a unified interface for secure storage operations that might require
 both services.

 ## Responsibilities

 - Secure storage of sensitive data in the keychain
 - Proper encryption/decryption of data using the application security provider
 - Thread-safe operations for all security-related activities
 - Proper error handling and logging

 ## Usage

 ```swift
 // Create the actor
 let securityActor = KeychainSecurityActor(
     keychainService: await KeychainServiceFactory.createService(),
     securityProvider: await SecurityProviderFactory.createApplicationSecurityProvider(),
     logger: myLogger
 )

 // Store a password securely
 try await securityActor.storeEncryptedSecret(
     secret: "password123",
     forAccount: "user@example.com"
 )

 // Retrieve it later
 let password = try await securityActor.retrieveEncryptedSecret(
     forAccount: "user@example.com"
 )
 ```
 */
public actor KeychainSecurityActor {
  // MARK: - Properties

  /// The keychain service for storing items
  private let keychainService: KeychainServiceProtocol

  /// The security provider for encryption/decryption
  private let securityProvider: SecurityProviderProtocol

  /// Logger for recording operations
  private let logger: LoggingProtocol

  // MARK: - Initialization

  /**
   Initializes a new KeychainSecurityActor with the required services.

   - Parameters:
     - keychainService: The keychain service for secure storage
     - securityProvider: The security provider for encryption/decryption
     - logger: Logger for recording operations (optional)
   */
  public init(
    keychainService: KeychainServiceProtocol,
    securityProvider: SecurityProviderProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.keychainService=keychainService
    self.securityProvider=securityProvider

    // Use provided logger or create a simple console logger
    if let logger {
      self.logger=logger
    } else {
      self.logger=SimpleConsoleLogger()
    }
  }

  // MARK: - Public methods

  /**
   Stores an encrypted secret in the keychain.

   - Parameters:
     - secret: The secret to encrypt and store
     - account: The account identifier to associate with the secret
     - keyIdentifier: Optional custom key identifier, derived from account if not provided

   - Returns: The key identifier used for encryption
   - Throws: KeychainError if storage fails
   */
  public func storeEncryptedSecret(
    secret: String,
    forAccount account: String,
    keyIdentifier: String?=nil
  ) async throws -> String {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation (without sensitive details)
    let metadataItems: [LogMetadataDTO] = [
        LogMetadataDTO(key: "account", value: account, privacyLevel: PrivacyClassification.private),
        LogMetadataDTO(key: "operation", value: "storeEncryptedSecret", privacyLevel: PrivacyClassification.public),
        LogMetadataDTO(key: "keyID", value: keyID, privacyLevel: PrivacyClassification.private)
    ]
    let metadataCollection = LogMetadataDTOCollection(entries: metadataItems)

    let debugContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollection
    )
    await logger.debug(
      "Storing encrypted secret for account", context: debugContext
    )

    do {
      // Convert the secret to data
      guard let secretData=secret.data(using: .utf8) else {
        throw KeychainError.dataConversionError
      }

      // Prepare encryption configuration with options
      var options=[String: String]()
      options["keyIdentifier"]=keyID
      options["algorithm"]="AES256GCM"
      options["data"]=secretData.base64EncodedString()

      // Create the config with our options
      let encryptionConfig=SecurityConfigDTO(
        encryptionAlgorithm: .aes256GCM,
        hashAlgorithm: .sha256,
        providerType: .basic,
        options: SecurityConfigOptions(
          enableDetailedLogging: false,
          useHardwareAcceleration: true,
          verifyOperations: true,
          metadata: [
            "encryptedData": secretData.base64EncodedString()
          ]
        )
      )

      // Encrypt the data
      let encryptionResult=try await securityProvider.encrypt(
        config: encryptionConfig
      )

      // Extract the encrypted data from the result
      guard let resultData=encryptionResult.resultData else {
        throw KeychainError.dataConversionError
      }

      // Store the encrypted data in the keychain
      try await keychainService.storeData(
        resultData,
        for: account,
        keychainOptions: KeychainOptions.standard
      )

      // Log success
      let infoContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollection
      )
      await logger.info(
        "Successfully stored encrypted secret for account", context: infoContext
      )

      return keyID
    } catch {
      // Log error with appropriate metadata
      let errorMetadataItems: [LogMetadataDTO] = [
          LogMetadataDTO(key: "account", value: account, privacyLevel: PrivacyClassification.private),
          LogMetadataDTO(key: "operation", value: "storeEncryptedSecret", privacyLevel: PrivacyClassification.public),
          LogMetadataDTO(key: "error", value: error.localizedDescription, privacyLevel: PrivacyClassification.public)
      ]
      let errorMetadataCollection = LogMetadataDTOCollection(entries: errorMetadataItems)

      let errorContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: errorMetadataCollection
      )
      await logger.error(
        "Failed to store encrypted secret", context: errorContext
      )

      throw error
    }
  }

  /**
   Retrieves and decrypts a secret from the keychain.

   - Parameters:
     - account: The account identifier associated with the secret
     - keyIdentifier: Optional custom key identifier, derived from account if not provided

   - Returns: The decrypted secret as a string
   - Throws: KeychainError if retrieval or decryption fails
   */
  public func retrieveEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String?=nil
  ) async throws -> String {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation (without sensitive details)
    let metadataItemsRetrieve: [LogMetadataDTO] = [
        LogMetadataDTO(key: "account", value: account, privacyLevel: PrivacyClassification.private),
        LogMetadataDTO(key: "operation", value: "retrieveEncryptedSecret", privacyLevel: PrivacyClassification.public),
        LogMetadataDTO(key: "keyID", value: keyID, privacyLevel: PrivacyClassification.private)
    ]
    let metadataCollectionRetrieve = LogMetadataDTOCollection(entries: metadataItemsRetrieve)

    let debugContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollectionRetrieve
    )
    await logger.debug(
      "Retrieving encrypted secret for account", context: debugContext
    )

    do {
      // Retrieve the encrypted data from keychain
      let encryptedData=try await keychainService.retrieveData(
        for: account,
        keychainOptions: KeychainOptions.standard
      )

      // Add the data to the config options
      let configOptions=SecurityConfigOptions(
        enableDetailedLogging: false,
        useHardwareAcceleration: true,
        verifyOperations: true,
        metadata: [
          "encryptedData": encryptedData.base64EncodedString()
        ]
      )

      // Create the config with our options
      let decryptionConfig=SecurityConfigDTO(
        encryptionAlgorithm: .aes256GCM,
        hashAlgorithm: .sha256,
        providerType: .basic,
        options: configOptions
      )

      // Decrypt the data
      let decryptionResult=try await securityProvider.decrypt(
        config: decryptionConfig
      )

      // Extract the decrypted data from the result
      guard let resultData=decryptionResult.resultData else {
        throw KeychainError.dataConversionError
      }

      // Convert to string
      guard let secretString=String(data: resultData, encoding: .utf8) else {
        throw KeychainError.dataConversionError
      }

      // Log success
      let infoContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollectionRetrieve
      )
      await logger.info(
        "Successfully retrieved encrypted secret", context: infoContext
      )

      return secretString
    } catch {
      // Log error
      let errorMetadataItemsRetrieve: [LogMetadataDTO] = [
          LogMetadataDTO(key: "account", value: account, privacyLevel: PrivacyClassification.private),
          LogMetadataDTO(key: "operation", value: "retrieveEncryptedSecret", privacyLevel: PrivacyClassification.public),
          LogMetadataDTO(key: "error", value: error.localizedDescription, privacyLevel: PrivacyClassification.public)
      ]
      let errorMetadataCollectionRetrieve = LogMetadataDTOCollection(entries: errorMetadataItemsRetrieve)

      let errorContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: errorMetadataCollectionRetrieve
      )
      await logger.error(
        "Failed to retrieve encrypted secret", context: errorContext
      )

      throw error
    }
  }

  /**
   Deletes a secret and its associated encryption key.

   - Parameters:
     - account: The account identifier associated with the secret
     - keyIdentifier: Optional custom key identifier, derived from account if not provided
     - deleteKey: Whether to delete the encryption key as well

   - Throws: KeychainError if deletion fails
   */
  public func deleteSecret(
    forAccount account: String,
    keyIdentifier: String?=nil,
    deleteKey: Bool=true
  ) async throws {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation
    let metadataItemsDelete: [LogMetadataDTO] = [
        LogMetadataDTO(key: "account", value: account, privacyLevel: PrivacyClassification.private),
        LogMetadataDTO(key: "operation", value: "deleteSecret", privacyLevel: PrivacyClassification.public),
        LogMetadataDTO(key: "keyID", value: keyID, privacyLevel: PrivacyClassification.private)
    ]
    let metadataCollectionDelete = LogMetadataDTOCollection(entries: metadataItemsDelete)

    let debugContext1 = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollectionDelete
    )
    await logger.debug(
      "Attempting to delete secret for account", context: debugContext1
    )

    do {
      // Delete the secret from keychain
      try await keychainService.deleteData(for: account, keychainOptions: KeychainOptions.standard)

      // Delete the encryption key if requested
      if deleteKey {
        let keyManager=await securityProvider.keyManager()
        _=await keyManager.deleteKey(withIdentifier: keyID)

        let debugContext2 = BaseLogContextDTO(
          domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollectionDelete
        )
        await logger.debug(
          "Also deleting associated derived key", context: debugContext2
        )
      }

      // Log success
      let infoContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: metadataCollectionDelete
      )
      await logger.info(
        "Successfully deleted secret for account", context: infoContext
      )
    } catch {
      // Log error
      let errorMetadataItemsDelete: [LogMetadataDTO] = [
          LogMetadataDTO(key: "account", value: account, privacyLevel: PrivacyClassification.private),
          LogMetadataDTO(key: "operation", value: "deleteSecret", privacyLevel: PrivacyClassification.public),
          LogMetadataDTO(key: "error", value: error.localizedDescription, privacyLevel: PrivacyClassification.public)
      ]
      let errorMetadataCollectionDelete = LogMetadataDTOCollection(entries: errorMetadataItemsDelete)

      let errorContext = BaseLogContextDTO(
        domainName: "Keychain", source: "KeychainSecurityActor", metadata: errorMetadataCollectionDelete
      )
      await logger.error(
        "Failed to delete secret", context: errorContext
      )

      throw error
    }
  }

  // MARK: - Private methods

  /// Derive a key identifier from an account name
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    "keychain_key_\(account)"
  }

  /// Generate a new AES-256 key
  private func generateAESKey() async throws -> Data {
    // Generate a new secure random key for AES-256 (32 bytes)
    // We need to create a SecurityConfigDTO for AES-256 encryption
    let configOptions=SecurityConfigOptions()

    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: configOptions
    )

    // Generate the key
    let result=try await securityProvider.generateKey(config: config)

    // Extract the key data
    guard let keyData=result.resultData else {
      throw KeychainError.keyGenerationError
    }

    return keyData
  }
}

/**
 Custom error types for keychain operations.
 */
public enum KeychainError: Error, LocalizedError {
  /// Failed to convert between data formats
  case dataConversionError
  /// A keychain operation failed
  case keychainOperationFailed(String)
  /// A security operation failed
  case securityOperationFailed(String)
  /// Key generation failed
  case keyGenerationError

  public var errorDescription: String? {
    switch self {
      case .dataConversionError:
        "Failed to convert data between formats"
      case let .keychainOperationFailed(message):
        "Keychain operation failed: \(message)"
      case let .securityOperationFailed(error):
        "Security operation failed: \(error)"
      case .keyGenerationError:
        "Failed to generate key"
    }
  }
}

/**
 A basic implementation of LoggingProtocol that logs to the console.
 Used when no custom logger is provided.
 */
private actor SimpleConsoleLogger: LoggingProtocol {
  // Provide a basic LoggingActor instance to satisfy the protocol.
  // Note: This default actor might not be fully configured for all scenarios.
  public let loggingActor = LoggingActor(destinations: [])

  public func log(_ level: LoggingTypes.LogLevel, _ message: String, context: LogContextDTO) async {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let levelString = String(describing: level).uppercased() // Use LoggingTypes.LogLevel
    let source = context.source
    print("\(timestamp) [\(source)] [\(levelString)]: \(message)")
  }
}
