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
    var metadata=PrivacyMetadata()
    metadata["account"]=PrivacyMetadataValue(value: account, privacy: .private)
    metadata["operation"]=PrivacyMetadataValue(value: "storeEncryptedSecret", privacy: .public)
    metadata["keyID"]=PrivacyMetadataValue(value: keyID, privacy: .private)

    await logger.debug(
      "Storing encrypted secret for account",
      metadata: metadata,
      source: "KeychainSecurityActor"
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
      await logger.info(
        "Successfully stored encrypted secret for account",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )

      return keyID
    } catch {
      // Log error with appropriate metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["account"]=PrivacyMetadataValue(value: account, privacy: .private)
      errorMetadata["operation"]=PrivacyMetadataValue(value: "storeEncryptedSecret",
                                                      privacy: .public)
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription,
                                                  privacy: .public)

      await logger.error(
        "Failed to store encrypted secret",
        metadata: errorMetadata,
        source: "KeychainSecurityActor"
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
    var metadata=PrivacyMetadata()
    metadata["account"]=PrivacyMetadataValue(value: account, privacy: .private)
    metadata["operation"]=PrivacyMetadataValue(value: "retrieveEncryptedSecret", privacy: .public)
    metadata["keyID"]=PrivacyMetadataValue(value: keyID, privacy: .private)

    await logger.debug(
      "Retrieving encrypted secret for account",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    do {
      // Retrieve the encrypted data from keychain
      let encryptedData=try await keychainService.retrieveData(
        for: account,
        keychainOptions: KeychainOptions.standard
      )

      // Add the data to the config options
      let configOptions = SecurityConfigOptions(
        enableDetailedLogging: false,
        useHardwareAcceleration: true,
        verifyOperations: true,
        metadata: [
          "encryptedData": encryptedData.base64EncodedString()
        ]
      )

      // Create the config with our options
      let decryptionConfig = SecurityConfigDTO(
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
      await logger.info(
        "Successfully retrieved encrypted secret for account",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )

      return secretString
    } catch {
      // Log error with appropriate metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["account"]=PrivacyMetadataValue(value: account, privacy: .private)
      errorMetadata["operation"]=PrivacyMetadataValue(value: "retrieveEncryptedSecret",
                                                      privacy: .public)
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription,
                                                  privacy: .public)

      await logger.error(
        "Failed to retrieve encrypted secret",
        metadata: errorMetadata,
        source: "KeychainSecurityActor"
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
    var metadata=PrivacyMetadata()
    metadata["account"]=PrivacyMetadataValue(value: account, privacy: .private)
    metadata["operation"]=PrivacyMetadataValue(value: "deleteSecret", privacy: .public)
    metadata["keyID"]=PrivacyMetadataValue(value: keyID, privacy: .private)

    await logger.debug(
      "Deleting secret for account",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    do {
      // Delete the secret from keychain
      try await keychainService.deleteData(for: account, keychainOptions: KeychainOptions.standard)

      // Delete the encryption key if requested
      if deleteKey {
        let keyManager=await securityProvider.keyManager()
        _=await keyManager.deleteKey(withIdentifier: keyID)

        await logger.debug(
          "Deleted associated encryption key",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )
      }

      // Log success
      await logger.info(
        "Successfully deleted secret for account",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
    } catch {
      // Log error with appropriate metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["account"]=PrivacyMetadataValue(value: account, privacy: .private)
      errorMetadata["operation"]=PrivacyMetadataValue(value: "deleteSecret", privacy: .public)
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription,
                                                  privacy: .public)

      await logger.error(
        "Failed to delete secret",
        metadata: errorMetadata,
        source: "KeychainSecurityActor"
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
    let configOptions = SecurityConfigOptions()

    let config = SecurityConfigDTO(
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
private final class SimpleConsoleLogger: LoggingProtocol {
  // Required by LoggingProtocol
  let loggingActor: LoggingActor

  init() {
    // Create an empty array of destinations since we'll log directly
    loggingActor=LoggingActor(destinations: [])
  }

  // Log message implementation
  func logMessage(
    _ level: LogLevel,
    _ message: String,
    context _: LogContext
  ) async {
    print("[\(level.rawValue)] \(message)")
  }

  // Default implementations
  func trace(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.trace, message, context: context)
  }

  func debug(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.debug, message, context: context)
  }

  func info(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.info, message, context: context)
  }

  // Map notice to info since LogLevel doesn't have a notice level
  func notice(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.info, message, context: context)
  }

  func warning(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.warning, message, context: context)
  }

  func error(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.error, message, context: context)
  }

  func critical(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.critical, message, context: context)
  }

  // Fault is mapped to critical since LogLevel doesn't have a fault level
  func fault(_ message: String, metadata _: PrivacyMetadata?, source: String?) async {
    let context=LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.critical, message, context: context)
  }
}
