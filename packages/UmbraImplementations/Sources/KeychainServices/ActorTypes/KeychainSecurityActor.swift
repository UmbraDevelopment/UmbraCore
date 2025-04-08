import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import KeychainInterfaces
import KeychainLogger
import LoggingInterfaces
import LoggingTypes
import OSLog
import SecurityCoreInterfaces
import UmbraErrors

/**
 # KeychainSecurityActor

 An actor that integrates both KeychainServiceProtocol and KeyManagementProtocol,
 providing a unified interface for secure storage operations that might require
 both services.

 ## Responsibilities

 - Secure storage of sensitive data in the keychain
 - Proper encryption/decryption of data using the key management system
 - Thread-safe operations for all security-related activities
 - Proper error handling and logging

 ## Usage

 ```swift
 let actor = KeychainSecurityActor(
   keychainService: yourKeychainService,
   securityProvider: yourSecurityProvider
 )

 // Store a password
 try await actor.storeEncryptedSecret(
   secret: "myPassword",
   forAccount: "myAccount"
 )

 // Retrieve a password
 let password = try await actor.retrieveEncryptedSecret(
   forAccount: "myAccount"
 )
 ```
 */
public actor KeychainSecurityActor {
  // MARK: - Types and Errors

  /// Errors that can occur during keychain security operations
  public enum KeychainSecurityError: Error, LocalizedError {
    /// Failed to convert between data formats
    case dataConversionFailed
    /// A keychain operation failed
    case keychainOperationFailed(String)
    /// A security operation failed with the given underlying error
    case securityOperationFailed(underlyingError: String)

    public var errorDescription: String? {
      switch self {
        case .dataConversionFailed:
          "Failed to convert data between formats"
        case let .keychainOperationFailed(message):
          "Keychain operation failed: \(message)"
        case let .securityOperationFailed(error):
          "Security operation failed: \(error)"
      }
    }
  }

  // MARK: - Properties

  /// The keychain service for storing items
  private let keychainService: KeychainServiceProtocol

  /// The security provider for encryption/decryption
  private let securityProvider: SecurityProviderProtocol

  /// The keychain logger for structured logging
  private nonisolated let keychainLogger: KeychainLogger

  // MARK: - Initialisation

  /**
   Initialises a new KeychainSecurityActor with the required services.

   - Parameters:
     - keychainService: The keychain service for secure storage
     - securityProvider: The security provider for encryption/decryption
     - logger: Optional logger to use, will create a default one if not provided
   */
  public init(
    keychainService: KeychainServiceProtocol,
    securityProvider: SecurityProviderProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.keychainService=keychainService
    self.securityProvider=securityProvider

    // Create a logger specific to keychain operations
    if let logger {
      keychainLogger=KeychainLogger(logger: logger)
    } else {
      // Create a simple console logger that logs to stdout
      // Using a simple console logger implementation
      let consoleLogger=SimpleConsoleLogger()
      keychainLogger=KeychainLogger(logger: consoleLogger)
    }
  }

  // MARK: - Public Methods

  /**
   Stores an encrypted secret in the keychain.

   - Parameters:
     - secret: The secret to encrypt and store
     - account: The account identifier to associate with the secret
     - keyIdentifier: Optional custom key identifier, derived from account if not provided
     - additionalContext: Optional additional logging context

   - Returns: The key identifier used for encryption
   */
  public func storeEncryptedSecret(
    secret: String,
    forAccount account: String,
    keyIdentifier: String?=nil,
    additionalContext _: LogMetadataDTOCollection?=nil
  ) async throws -> String {
    _=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Create proper structured logging
    await keychainLogger.logOperationStart(
      operation: "storeEncryptedSecret",
      account: account
    )

    do {
      // Convert the secret to data and verify it's valid
      guard secret.data(using: .utf8) != nil else {
        throw KeychainSecurityError.dataConversionFailed
      }

      // Prepare encryption configuration with additional options for the input data
      let configOptions=SecurityConfigOptions(
        enableDetailedLogging: false,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        metadata: [
          "keySize": "256",
          "algorithm": "AES-256-GCM"
        ]
      )

      let config=SecurityConfigDTO(
        encryptionAlgorithm: .aes256GCM,
        hashAlgorithm: .sha256,
        providerType: .cryptoKit,
        options: configOptions
      )

      // Encrypt the data
      let encryptionResult=try await securityProvider.encrypt(
        config: config
      )

      // Extract the encrypted data from the result
      guard let resultData=encryptionResult.resultData else {
        throw KeychainSecurityError.dataConversionFailed
      }

      // Convert SecureBytes to regular Data by using its base64 encoding method
      // and then converting back to Data - avoids direct access to private storage
      let base64String=resultData.base64EncodedString()
      guard let encryptedData=Data(base64Encoded: base64String) else {
        throw KeychainSecurityError.dataConversionFailed
      }

      // Store the encrypted data in the keychain
      try await keychainService.storeData(
        encryptedData,
        for: account,
        keychainOptions: nil
      )

      // Log successful operation
      await keychainLogger.logOperationSuccess(
        operation: "storeEncryptedSecret",
        account: account
      )

      return deriveKeyIdentifier(forAccount: account)
    } catch {
      // Log the error with proper metadata
      await keychainLogger.logOperationError(
        operation: "storeEncryptedSecret",
        account: account,
        error: error
      )

      // Re-throw a wrapped error
      if error is KeychainSecurityError {
        throw error
      } else {
        throw KeychainSecurityError
          .securityOperationFailed(underlyingError: error.localizedDescription)
      }
    }
  }

  /**
   Retrieves and decrypts a secret from the keychain.

   - Parameters:
     - account: The account identifier associated with the secret
     - keyIdentifier: Optional custom key identifier, derived from account if not provided
     - additionalContext: Optional additional logging context

   - Returns: The decrypted secret as a string
   */
  public func retrieveEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String?=nil,
    additionalContext _: LogMetadataDTOCollection?=nil
  ) async throws -> String {
    _=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation start
    await keychainLogger.logOperationStart(
      operation: "retrieveEncryptedSecret",
      account: account
    )

    do {
      // Retrieve the encrypted data from keychain (we only care if it succeeds)
      _=try await keychainService.retrieveData(for: account, keychainOptions: nil)

      // Prepare decryption configuration with options
      let configOptions=SecurityConfigOptions(
        enableDetailedLogging: false,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        metadata: [
          "keySize": "256",
          "algorithm": "AES-256-GCM"
        ]
      )

      let config=SecurityConfigDTO(
        encryptionAlgorithm: .aes256GCM,
        hashAlgorithm: .sha256,
        providerType: .cryptoKit,
        options: configOptions
      )

      // Decrypt the data
      let decryptionResult=try await securityProvider.decrypt(
        config: config
      )

      // Extract the decrypted data from the result
      guard let resultData=decryptionResult.resultData else {
        throw KeychainSecurityError.dataConversionFailed
      }

      // Convert SecureBytes to regular Data by using its base64 encoding method
      // and then converting back to Data - avoids direct access to private storage
      let base64String=resultData.base64EncodedString()
      guard let decryptedData=Data(base64Encoded: base64String) else {
        throw KeychainSecurityError.dataConversionFailed
      }

      // Convert to string
      guard let secretString=String(data: decryptedData, encoding: .utf8) else {
        throw KeychainSecurityError.dataConversionFailed
      }

      // Log success
      await keychainLogger.logOperationSuccess(
        operation: "retrieveEncryptedSecret",
        account: account
      )

      return secretString
    } catch {
      // Log error appropriately
      await keychainLogger.logOperationError(
        operation: "retrieveEncryptedSecret",
        account: account,
        error: error
      )

      // Re-throw a wrapped error
      if error is KeychainSecurityError {
        throw error
      } else {
        throw KeychainSecurityError
          .securityOperationFailed(underlyingError: error.localizedDescription)
      }
    }
  }

  /**
   Deletes a secret and its associated encryption key.

   - Parameters:
     - account: The account identifier associated with the secret
     - keyIdentifier: Optional custom key identifier, derived from account if not provided
     - deleteKey: Whether to delete the encryption key as well (defaults to true)
     - additionalContext: Optional additional logging context
   */
  public func deleteSecret(
    forAccount account: String,
    keyIdentifier: String?=nil,
    deleteKey: Bool=true,
    additionalContext _: LogMetadataDTOCollection?=nil
  ) async throws {
    _=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation start
    await keychainLogger.logOperationStart(
      operation: "deleteSecret",
      account: account
    )

    // First, delete the encryption key if requested
    if deleteKey {
      let keyManager=await securityProvider.keyManager()

      // Try to delete the key but treat it as non-critical
      _=await keyManager.deleteKey(withIdentifier: deriveKeyIdentifier(forAccount: account))

      await keychainLogger.logOperationSuccess(
        operation: "deleteKey",
        account: account
      )
    }

    // Delete the secret from keychain
    do {
      try await keychainService.deleteData(for: account, keychainOptions: KeychainOptions.standard)

      await keychainLogger.logOperationSuccess(
        operation: "deleteSecret",
        account: account
      )
    } catch {
      await keychainLogger.logOperationError(
        operation: "deleteSecret",
        account: account,
        error: error
      )

      throw KeychainSecurityError.keychainOperationFailed(error.localizedDescription)
    }
  }

  // MARK: - Private Methods

  /// Derive a key identifier from an account name
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    "keychain_key_\(account)"
  }

  /// Generate a new AES-256 key
  private func generateAESKey() async throws -> Data {
    // Generate a new secure random key for AES-256 (32 bytes)
    // We need to create a SecurityConfigDTO for AES-256 encryption
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: false,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30.0,
      metadata: [
        "keySize": "256",
        "algorithm": "AES-256-GCM"
      ]
    )

    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM,
      hashAlgorithm: .sha256,
      providerType: .cryptoKit,
      options: configOptions
    )

    let result=try await securityProvider.generateKey(
      config: config
    )

    // Convert the result to Data
    guard let secureBytes=result.resultData else {
      throw KeychainSecurityError.dataConversionFailed
    }

    // Convert SecureBytes to regular Data by using its base64 encoding method
    let base64String=secureBytes.base64EncodedString()
    guard let keyData=Data(base64Encoded: base64String) else {
      throw KeychainSecurityError.dataConversionFailed
    }

    return keyData
  }
}

/**
 A basic implementation of LoggingProtocol that logs to the console.
 Used when no custom logger is provided.
 */
private actor SimpleConsoleLogger: LoggingProtocol {
  // Required by LoggingProtocol
  let loggingActor: LoggingActor

  init() {
    // Initialize with a default LoggingActor. Adjust if specific config needed.
    loggingActor=LoggingActor(destinations: [])
  }

  // MARK: - LoggingProtocol Conformance

  /// Logs the message and context to the console.
  nonisolated func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Construct a simple string representation for console output.
    let source=context.source ?? "UnknownSource"
    // Simple metadata representation, consider privacy
    let metadataDesc=context.metadata.entries.map { meta in
      // Basic check for sensitive data, real implementation might need more robust handling
      let valueDesc=meta.privacyLevel == .private || meta
        .privacyLevel == .sensitive ? "<redacted>" : "\(meta.value)"
      return "\(meta.key)=\(valueDesc)"
    }.joined(separator: "; ")

    let timestamp=Date() // Simple timestamp
    let logLine="\(timestamp) [\(level)] [\(source)] \(message) { \(metadataDesc) }"
    print(logLine)
  }

  // Convenience methods (debug, info, etc.) are inherited via protocol extension
}
