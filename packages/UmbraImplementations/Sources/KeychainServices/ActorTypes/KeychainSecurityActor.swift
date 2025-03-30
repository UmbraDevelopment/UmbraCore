import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors
import KeychainLogger
import OSLog

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
        return "Failed to convert data between formats"
      case .keychainOperationFailed(let message):
        return "Keychain operation failed: \(message)"
      case .securityOperationFailed(let error):
        return "Security operation failed: \(error)"
      }
    }
  }
  
  // MARK: - Properties

  /// The keychain service for storing items
  private let keychainService: KeychainServiceProtocol
  
  /// The security provider for encryption/decryption
  private let securityProvider: SecurityProviderProtocol
  
  /// The keychain logger for structured logging
  nonisolated private let keychainLogger: KeychainLogger
  
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
    logger: LoggingProtocol? = nil
  ) {
    self.keychainService = keychainService
    self.securityProvider = securityProvider
    
    // Create a logger specific to keychain operations
    if let logger = logger {
      self.keychainLogger = KeychainLogger(logger: logger)
    } else {
      // Create a simple console logger that logs to stdout
      // Using a simple console logger implementation
      let consoleLogger = SimpleConsoleLogger()
      self.keychainLogger = KeychainLogger(logger: consoleLogger)
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
    keyIdentifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async throws -> String {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
    
    // Create proper structured logging
    await keychainLogger.logOperationStart(
      account: account,
      operation: "storeEncryptedSecret",
      keyIdentifier: keyID,
      additionalContext: additionalContext
    )
    
    do {
      // Convert the secret to data
      guard let secretData = secret.data(using: .utf8) else {
        throw KeychainSecurityError.dataConversionFailed
      }
      
      // Prepare encryption configuration with additional options for the input data
      var options = [String: String]()
      options["keyIdentifier"] = keyID
      options["algorithm"] = EncryptionAlgorithm.aes256Gcm.rawValue
      options["data"] = secretData.base64EncodedString() // Include the data directly in the options
      
      // Create the config with our options
      let encryptionConfig = SecurityConfigDTO(
        algorithm: EncryptionAlgorithm.aes256Gcm.rawValue,
        keySize: 256,
        options: options
      )
      
      // Encrypt the data
      let encryptionResult = try await securityProvider.encrypt(
        config: encryptionConfig
      )
      
      // Extract the encrypted data from the result
      guard let resultData = encryptionResult.data else {
        throw KeychainSecurityError.dataConversionFailed
      }
      
      // Convert SecureBytes to regular Data by using its base64 encoding method
      // and then converting back to Data - avoids direct access to private storage
      let base64String = resultData.base64EncodedString()
      guard let encryptedData = Data(base64Encoded: base64String) else {
        throw KeychainSecurityError.dataConversionFailed
      }
      
      // Store the encrypted data in the keychain
      try await keychainService.storeData(
        encryptedData,
        for: account,
        accessOptions: nil
      )
      
      // Log successful operation
      await keychainLogger.logOperationSuccess(
        account: account,
        operation: "storeEncryptedSecret",
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
      
      return keyID
    } catch let error {
      // Log the error with proper metadata
      await keychainLogger.logOperationError(
        account: account,
        operation: "storeEncryptedSecret",
        error: error,
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
      
      // Re-throw a wrapped error
      if error is KeychainSecurityError {
        throw error
      } else {
        throw KeychainSecurityError.securityOperationFailed(underlyingError: error.localizedDescription)
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
    keyIdentifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async throws -> String {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
    
    // Log the operation start
    await keychainLogger.logOperationStart(
      account: account,
      operation: "retrieveEncryptedSecret",
      keyIdentifier: keyID,
      additionalContext: additionalContext
    )
    
    do {
      // Retrieve the encrypted data from keychain
      let encryptedData = try await keychainService.retrieveData(for: account)
      
      // Prepare decryption configuration with options
      var options = [String: String]()
      options["keyIdentifier"] = keyID
      options["algorithm"] = EncryptionAlgorithm.aes256Gcm.rawValue
      options["data"] = encryptedData.base64EncodedString() // Include the data directly in the options
      
      // Create the config with our options
      let decryptionConfig = SecurityConfigDTO(
        algorithm: EncryptionAlgorithm.aes256Gcm.rawValue,
        keySize: 256,
        options: options
      )
      
      // Decrypt the data
      let decryptionResult = try await securityProvider.decrypt(
        config: decryptionConfig
      )
      
      // Extract the decrypted data from the result
      guard let resultData = decryptionResult.data else {
        throw KeychainSecurityError.dataConversionFailed
      }
      
      // Convert SecureBytes to regular Data by using its base64 encoding method
      // and then converting back to Data - avoids direct access to private storage
      let base64String = resultData.base64EncodedString()
      guard let decryptedData = Data(base64Encoded: base64String) else {
        throw KeychainSecurityError.dataConversionFailed
      }
      
      // Convert to string
      guard let secretString = String(data: decryptedData, encoding: .utf8) else {
        throw KeychainSecurityError.dataConversionFailed
      }
      
      // Log success
      await keychainLogger.logOperationSuccess(
        account: account,
        operation: "retrieveEncryptedSecret",
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
      
      return secretString
    } catch let error {
      // Log error appropriately
      await keychainLogger.logOperationError(
        account: account,
        operation: "retrieveEncryptedSecret",
        error: error,
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
      
      // Re-throw a wrapped error
      if error is KeychainSecurityError {
        throw error
      } else {
        throw KeychainSecurityError.securityOperationFailed(underlyingError: error.localizedDescription)
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
    keyIdentifier: String? = nil,
    deleteKey: Bool = true,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async throws {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
    
    // Log the operation start
    await keychainLogger.logOperationStart(
      account: account,
      operation: "deleteSecret",
      keyIdentifier: keyID,
      additionalContext: additionalContext
    )
    
    // First, delete the encryption key if requested
    if deleteKey {
      let keyManager = await securityProvider.keyManager()
      
      // Try to delete the key but treat it as non-critical
      let _ = await keyManager.deleteKey(withIdentifier: keyID)
      
      await keychainLogger.logOperationSuccess(
        account: account,
        operation: "deleteKey",
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
    }
    
    // Delete the secret from keychain
    do {
      try await keychainService.deleteData(for: account)
      
      await keychainLogger.logOperationSuccess(
        account: account,
        operation: "deleteSecret",
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
    } catch let error {
      await keychainLogger.logOperationError(
        account: account,
        operation: "deleteSecret",
        error: error,
        keyIdentifier: keyID,
        additionalContext: additionalContext
      )
      
      throw KeychainSecurityError.keychainOperationFailed(error.localizedDescription)
    }
  }
  
  // MARK: - Private Methods
  
  /// Derive a key identifier from an account name
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    return "keychain_key_\(account)"
  }
  
  /// Generate a new AES-256 key
  private func generateAESKey() async throws -> Data {
    // Generate a new secure random key for AES-256 (32 bytes)
    // We need to create a SecurityConfigDTO for AES-256 encryption
    let configOptions = [
      "algorithm": EncryptionAlgorithm.aes256Gcm.rawValue
    ]
    
    let config = SecurityConfigDTO(
      algorithm: EncryptionAlgorithm.aes256Gcm.rawValue,
      keySize: 256,
      options: configOptions
    )
    
    let result = try await securityProvider.generateKey(
        config: config
    )
    
    // Convert the result to Data
    guard let secureBytes = result.data else {
      throw KeychainSecurityError.dataConversionFailed
    }
    
    // Convert SecureBytes to regular Data by using its base64 encoding method
    let base64String = secureBytes.base64EncodedString()
    guard let keyData = Data(base64Encoded: base64String) else {
      throw KeychainSecurityError.dataConversionFailed
    }
    
    return keyData
  }
}

/**
 A basic implementation of LoggingProtocol that logs to the console.
 Used when no custom logger is provided.
 */
fileprivate final class SimpleConsoleLogger: LoggingProtocol {
  // Required by LoggingProtocol
  let loggingActor: LoggingActor
  
  init() {
    // Create an empty array of destinations since we'll log directly
    self.loggingActor = LoggingActor(destinations: [])
  }
  
  // Log message implementation
  func logMessage(
    _ level: LogLevel,
    _ message: String,
    context: LogContext
  ) async {
    print("[\(level.rawValue)] \(message)")
  }
  
  // Default implementations
  func trace(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.trace, message, context: context)
  }
  
  func debug(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.debug, message, context: context)
  }
  
  func info(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.info, message, context: context)
  }
  
  // Map notice to info since LogLevel doesn't have a notice level
  func notice(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.info, message, context: context)
  }
  
  func warning(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.warning, message, context: context)
  }
  
  func error(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.error, message, context: context)
  }
  
  func critical(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.critical, message, context: context)
  }
  
  // Fault is mapped to critical since LogLevel doesn't have a fault level
  func fault(_ message: String, metadata: LogMetadata?, source: String?) async {
    let context = LogContext(source: source ?? "KeychainSecurityActor")
    await logMessage(.critical, message, context: context)
  }
}
