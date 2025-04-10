import CoreSecurityTypes
import CryptoKit
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 SecureStorageService handles secure data storage operations.
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Privacy-aware logging using SecurityLogContext
 - Consistent error handling with typed exceptions
 - Thread safety through actor-based concurrency
 - Type-safe interfaces with proper parameter validation
 - Data encryption at rest using AES-GCM for authenticated encryption
 */
actor SecureStorageService: SecureStorageProtocol {
  // MARK: - Properties
  
  /// The logger instance for recording operation details
  private let logger: LoggingProtocol
  
  /// Storage location for secure data (encrypted)
  private var encryptedStorage: [String: EncryptedData] = [:]
  
  /// Master encryption key for data at rest
  private let masterKey: SymmetricKey
  
  /// Struct to hold encrypted data and associated metadata
  private struct EncryptedData {
    /// The encrypted data blob
    let ciphertext: Data
    
    /// The nonce used for encryption
    let nonce: Data
    
    /// Tag for authenticated encryption
    let tag: Data
    
    /// Timestamp when the data was last modified
    let lastModified: Date
    
    /// Create EncryptedData from AES.GCM.SealedBox
    init(sealedBox: AES.GCM.SealedBox) {
      self.ciphertext = sealedBox.ciphertext
      self.nonce = sealedBox.nonce
      self.tag = sealedBox.tag
      self.lastModified = Date()
    }
    
    /// Create an AES.GCM.SealedBox from this instance
    func toSealedBox() throws -> AES.GCM.SealedBox {
      try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), 
                           ciphertext: ciphertext, 
                           tag: tag)
    }
  }
  
  /**
   Initialises the service with required dependencies
   
   - Parameters:
       - logger: The logging service to use for operation logging
       - masterKeyData: Optional master key data for encryption, generated if not provided
   */
  init(logger: LoggingProtocol, masterKeyData: Data? = nil) {
    self.logger = logger
    
    // Use provided master key or generate a new one
    if let keyData = masterKeyData {
      self.masterKey = SymmetricKey(data: keyData)
    } else {
      // Generate a secure AES-256 key for encryption
      self.masterKey = SymmetricKey(size: .bits256)
    }
  }
  
  // MARK: - SecureStorageProtocol Implementation
  
  /**
   Stores data securely with the given identifier.
   The data is encrypted using AES-GCM for authenticated encryption.
   
   - Parameters:
     - data: The data to store as a byte array
     - identifier: A string identifier for the stored data
   - Returns: Success or an error
   */
  public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "secureStore",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting secure storage operation", context: logContext)
    
    do {
      // Check if identifier is valid
      guard !identifier.isEmpty else {
        let error = SecurityStorageError.invalidIdentifier(reason: "Identifier cannot be empty")
        throw error
      }
      
      // Convert data to Data type for encryption
      let dataToEncrypt = Data(data)
      
      // Encrypt the data using AES-GCM
      let sealedBox = try AES.GCM.seal(dataToEncrypt, using: masterKey)
      
      // Store the encrypted data
      let encryptedData = EncryptedData(sealedBox: sealedBox)
      encryptedStorage[identifier] = encryptedData
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "Secure storage operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "dataSize",
          value: "\(data.count)",
          privacy: .public
        ).adding(
          key: "encryptedSize",
          value: "\(encryptedData.ciphertext.count)",
          privacy: .public
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(())
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "Secure storage operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      // Map to appropriate error type
      if let storageError = error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.storageFailure(reason: "Encryption failed: \(error.localizedDescription)"))
      }
    }
  }
  
  /**
   Retrieves data securely by its identifier.
   Decrypts the data that was previously encrypted using AES-GCM.
   
   - Parameter identifier: A string identifying the data to retrieve
   - Returns: The retrieved data as a byte array or an error
   */
  public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "secureRetrieve",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting secure retrieval operation", context: logContext)
    
    do {
      // Check if identifier is valid
      guard !identifier.isEmpty else {
        let error = SecurityStorageError.invalidIdentifier(reason: "Identifier cannot be empty")
        throw error
      }
      
      // Retrieve encrypted data
      guard let encryptedData = encryptedStorage[identifier] else {
        let error = SecurityStorageError.identifierNotFound(identifier: identifier)
        throw error
      }
      
      // Decrypt the data using AES-GCM
      let sealedBox = try encryptedData.toSealedBox()
      let decryptedData = try AES.GCM.open(sealedBox, using: masterKey)
      
      // Convert to byte array
      let result = [UInt8](decryptedData)
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "Secure retrieval operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "encryptedSize",
          value: "\(encryptedData.ciphertext.count)",
          privacy: .public
        ).adding(
          key: "decryptedSize",
          value: "\(result.count)",
          privacy: .public
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(result)
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "Secure retrieval operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      // Map to appropriate error type
      if let storageError = error as? SecurityStorageError {
        return .failure(storageError)
      } else if error is CryptoKit.CryptoKitError {
        return .failure(.storageFailure(reason: "Decryption failed: \(error.localizedDescription)"))
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }
  
  /**
   Deletes data securely by its identifier.
   Ensures all encrypted data is properly removed.
   
   - Parameter identifier: A string identifying the data to delete
   - Returns: Success or an error
   */
  public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "secureDelete",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting secure deletion operation", context: logContext)
    
    do {
      // Check if identifier is valid
      guard !identifier.isEmpty else {
        let error = SecurityStorageError.invalidIdentifier(reason: "Identifier cannot be empty")
        throw error
      }
      
      // Check if data exists
      guard encryptedStorage[identifier] != nil else {
        let error = SecurityStorageError.identifierNotFound(identifier: identifier)
        throw error
      }
      
      // Delete data from secure storage
      encryptedStorage.removeValue(forKey: identifier)
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "Secure deletion operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(())
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "Secure deletion operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      // Map to appropriate error type
      if let storageError = error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }
  
  /**
   Lists all available data identifiers.
   
   - Returns: An array of data identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Create logging context for the operation
    let logContext = SecurityLogContext(
      operation: "listIdentifiers",
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info("Starting list identifiers operation", context: logContext)
    
    do {
      // Get all identifiers from secure storage
      let identifiers = Array(encryptedStorage.keys)
      
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log success with privacy-aware metadata
      await logger.info(
        "List identifiers operation completed successfully",
        context: logContext.adding(
          key: "identifierCount",
          value: "\(identifiers.count)",
          privacy: .public
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )
      
      return .success(identifiers)
    } catch {
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Log failure with privacy-aware metadata
      let errorContext = logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacy: .public
      )
      
      await logger.error(
        "List identifiers operation failed: \(error.localizedDescription)",
        context: errorContext
      )
      
      return .failure(.generalError(reason: error.localizedDescription))
    }
  }
  
  // MARK: - Bridge Methods for SecurityProviderImpl
  
  /**
   Bridge method to work with Data type and ConfigDTO
   
   - Parameters:
     - data: The data to store
     - identifier: A string identifier for the stored data
   - Throws: SecurityError if the operation fails
   */
  func secureStore(data: Data, identifier: String) async throws {
    // Convert Data to [UInt8]
    let bytes = [UInt8](data)
    
    // Use the protocol implementation
    let result = await storeData(bytes, withIdentifier: identifier)
    
    // Convert Result to throw
    switch result {
    case .success:
      return
    case .failure(let error):
      throw mapToSecurityError(error)
    }
  }
  
  /**
   Bridge method to work with Data type and ConfigDTO
   
   - Parameter identifier: A string identifying the data to retrieve
   - Returns: The retrieved data
   - Throws: SecurityError if the operation fails
   */
  func secureRetrieve(identifier: String) async throws -> Data {
    // Use the protocol implementation
    let result = await retrieveData(withIdentifier: identifier)
    
    // Convert Result to throw
    switch result {
    case .success(let bytes):
      return Data(bytes)
    case .failure(let error):
      throw mapToSecurityError(error)
    }
  }
  
  /**
   Bridge method to work with ConfigDTO
   
   - Parameter identifier: A string identifying the data to delete
   - Throws: SecurityError if the operation fails
   */
  func secureDelete(identifier: String) async throws {
    // Use the protocol implementation
    let result = await deleteData(withIdentifier: identifier)
    
    // Convert Result to throw
    switch result {
    case .success:
      return
    case .failure(let error):
      throw mapToSecurityError(error)
    }
  }
  
  // MARK: - Helper Methods
  
  /**
   Maps StorageError to SecurityError for compatibility
   
   - Parameter error: The storage error to map
   - Returns: A corresponding SecurityError
   */
  private func mapToSecurityError(_ error: SecurityStorageError) -> CoreSecurityTypes.SecurityError {
    switch error {
    case .invalidIdentifier(let reason):
      return .invalidInputData(reason: reason)
    case .identifierNotFound(let identifier):
      return .dataNotFound(reason: "Data with identifier '\(identifier)' not found")
    case .storageFailure(let reason):
      return .storageOperationFailed(reason: reason)
    case .generalError(let reason):
      return .generalError(reason: reason)
    @unknown default:
      return .generalError(reason: "Unknown storage error: \(error.localizedDescription)")
    }
  }
}
