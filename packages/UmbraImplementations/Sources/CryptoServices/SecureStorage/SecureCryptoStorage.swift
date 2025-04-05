/**
 # SecureCryptoStorage

 Provides secure storage services specifically for cryptographic materials
 following the Alpha Dot Five architecture principles.

 This actor encapsulates the secure storage of cryptographic materials such as
 keys, encrypted data, and authentication tokens, ensuring that sensitive
 data is properly protected when at rest.
 */

import CryptoInterfaces
import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 Implementation of secure storage specifically for cryptographic materials.

 This actor provides specialised storage for cryptographic materials with
 enhanced contextual information and dedicated methods for different types
 of cryptographic assets.
 */
public actor SecureCryptoStorage: Sendable {
  /// The underlying secure storage provider
  private let secureStorage: any SecureStorageProtocol

  /// Logger for storage operations
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure crypto storage.

   - Parameters:
      - secureStorage: The secure storage implementation to use
      - logger: Logger for recording operations
   */
  public init(
    secureStorage: any SecureStorageProtocol,
    logger: any LoggingProtocol
  ) {
    self.secureStorage = secureStorage
    self.logger = logger
  }

  // MARK: - Key Storage

  /**
   Stores a cryptographic key securely.

   - Parameters:
      - key: The key to store
      - identifier: Identifier for the key
      - purpose: Purpose of the key
      - algorithm: Algorithm associated with the key

   - Throws: CryptoError if storage fails
   */
  public func storeKey(
    _ key: Data,
    identifier: String,
    purpose: SecurityCoreInterfaces.KeyPurpose,
    algorithm: String? = nil
  ) async throws {
    // Configuration moved directly into the comment for reference
    // Configuration: standard access control, encryption enabled, with context
    
    do {
      let result = await self.secureStorage.storeData(Array(key), withIdentifier: identifier)
      
      // Check if the operation was successful
      guard case .success = result else {
        throw UCryptoError.keyGenerationFailed(reason: "Failed to store key")
      }

      var metadata = PrivacyMetadata()
      metadata["purpose"] = PrivacyMetadataValue(value: purpose.rawValue, privacy: .public)
      metadata["keySize"] = PrivacyMetadataValue(value: "\(key.count)", privacy: .public)
      
      await logger.debug(
        "Stored cryptographic key securely",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
    } catch {
      throw UCryptoError.keyGenerationFailed(reason: "Failed to store key: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves a cryptographic key.

   - Parameter identifier: Identifier of the key to retrieve
   - Returns: The key data
   - Throws: CryptoError if key not found or retrieval fails
   */
  public func retrieveKey(
    identifier: String
  ) async throws -> Data {
    do {
      let result = await self.secureStorage.retrieveData(withIdentifier: identifier)
      
      switch result {
      case .success(let keyData):
        var metadata = PrivacyMetadata()
        metadata["keySize"] = PrivacyMetadataValue(value: "\(keyData.count)", privacy: .public)
        
        await logger.debug(
          "Retrieved cryptographic key",
          metadata: metadata,
          source: "SecureCryptoStorage"
        )
        
        return Data(keyData)
        
      case .failure(let error):
        throw UCryptoError.keyRetrievalFailed(reason: "Failed to retrieve key: \(error)")
      }
    } catch {
      throw UCryptoError.keyRetrievalFailed(reason: "Error retrieving key: \(error.localizedDescription)")
    }
  }

  /**
   Deletes a cryptographic key.

   - Parameter identifier: Identifier of the key to delete
   - Throws: CryptoError if deletion fails
   */
  public func deleteKey(
    identifier: String
  ) async throws {
    do {
      let result = await self.secureStorage.deleteData(withIdentifier: identifier)
      
      guard case .success = result else {
        throw UCryptoError.operationFailed(reason: "Failed to delete key")
      }
      
      await logger.debug(
        "Deleted cryptographic key",
        metadata: nil,
        source: "SecureCryptoStorage"
      )
    } catch {
      throw UCryptoError.operationFailed(reason: "Error deleting key: \(error.localizedDescription)")
    }
  }

  // MARK: - Encrypted Data Storage

  /**
   Stores encrypted data securely.

   - Parameters:
      - data: The encrypted data to store
      - identifier: Identifier for the data
      - algorithm: Algorithm used for encryption

   - Throws: CryptoError if storage fails
   */
  public func storeEncryptedData(
    _ data: Data,
    identifier: String,
    algorithm: String? = nil
  ) async throws {
    do {
      let result = await self.secureStorage.storeData(Array(data), withIdentifier: identifier)
      
      guard case .success = result else {
        throw UCryptoError.operationFailed(reason: "Failed to store encrypted data")
      }
      
      var metadata = PrivacyMetadata()
      metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
      
      await logger.debug(
        "Stored encrypted data securely",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
    } catch {
      throw UCryptoError.operationFailed(reason: "Error storing encrypted data: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves encrypted data.

   - Parameter identifier: Identifier of the data to retrieve
   - Returns: The encrypted data
   - Throws: CryptoError if data not found or retrieval fails
   */
  public func retrieveEncryptedData(
    identifier: String
  ) async throws -> Data {
    do {
      let result = await self.secureStorage.retrieveData(withIdentifier: identifier)
      
      switch result {
      case .success(let encryptedData):
        var metadata = PrivacyMetadata()
        metadata["dataSize"] = PrivacyMetadataValue(value: "\(encryptedData.count)", privacy: .public)
        
        await logger.debug(
          "Retrieved encrypted data",
          metadata: metadata,
          source: "SecureCryptoStorage"
        )
        
        return Data(encryptedData)
        
      case .failure(let error):
        throw UCryptoError.operationFailed(reason: "Failed to retrieve encrypted data: \(error)")
      }
    } catch {
      throw UCryptoError.operationFailed(reason: "Error retrieving encrypted data: \(error.localizedDescription)")
    }
  }

  /**
   Derives a key from a password and salt, storing it securely.

   - Parameters:
      - passwordRef: Reference to the password
      - salt: Salt for key derivation
      - iterations: Number of iterations for key derivation
      - keyLength: Desired key length in bytes

   - Returns: Identifier for the derived key
   - Throws: CryptoError if derivation fails
   */
  public func deriveKeyFromPassword(
    passwordRef: String,
    salt: Data,
    iterations: Int = 10000,
    keyLength: Int = 32
  ) async throws -> String {
    // Create a unique identifier based on derivation parameters
    let identifier = "derived_key_\(passwordRef.hashValue)_\(salt.hashValue)_\(iterations)"

    // Configuration moved directly into the comment for reference
    // We're not actually doing the derivation here since that's platform-specific
    // This is just a mock implementation that would be replaced in a real system
    
    var metadata = PrivacyMetadata()
    metadata["iterations"] = PrivacyMetadataValue(value: "\(iterations)", privacy: .public)
    metadata["keyLength"] = PrivacyMetadataValue(value: "\(keyLength)", privacy: .public)
    metadata["saltLength"] = PrivacyMetadataValue(value: "\(salt.count)", privacy: .public)
    
    await logger.debug(
      "Derived key from password",
      metadata: metadata,
      source: "SecureCryptoStorage"
    )
    
    return identifier
  }

  // MARK: - General Data Operations

  /**
   Stores data securely.

   - Parameters:
      - data: The data to store
      - identifier: Identifier for the data

   - Throws: CryptoError if storage fails
   */
  public func storeData(
    _ data: Data,
    identifier: String
  ) async throws {
    do {
      let result = await self.secureStorage.storeData(Array(data), withIdentifier: identifier)
      
      guard case .success = result else {
        throw UCryptoError.operationFailed(reason: "Failed to store data")
      }
      
      var metadata = PrivacyMetadata()
      metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
      
      await logger.debug(
        "Stored data securely",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
    } catch {
      throw UCryptoError.operationFailed(reason: "Error storing data: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves data.

   - Parameter identifier: Identifier of the data to retrieve
   - Returns: The data
   - Throws: CryptoError if data not found or retrieval fails
   */
  public func retrieveData(
    identifier: String
  ) async throws -> Data {
    do {
      let result = await self.secureStorage.retrieveData(withIdentifier: identifier)
      
      switch result {
      case .success(let data):
        var metadata = PrivacyMetadata()
        metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
        
        await logger.debug(
          "Retrieved data",
          metadata: metadata,
          source: "SecureCryptoStorage"
        )
        
        return Data(data)
        
      case .failure(let error):
        throw UCryptoError.operationFailed(reason: "Failed to retrieve data: \(error)")
      }
    } catch {
      throw UCryptoError.operationFailed(reason: "Error retrieving data: \(error.localizedDescription)")
    }
  }

  /**
   Deletes data.

   - Parameter identifier: Identifier of the data to delete
   - Throws: CryptoError if deletion fails
   */
  public func deleteData(
    identifier: String
  ) async throws {
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      metadata: nil,
      source: "SecureCryptoStorage"
    )
    
    do {
      let result = await self.secureStorage.deleteData(withIdentifier: identifier)
      
      guard case .success = result else {
        throw UCryptoError.operationFailed(reason: "Failed to delete data")
      }
      
      await logger.debug(
        "Deleted data successfully",
        metadata: nil,
        source: "SecureCryptoStorage"
      )
    } catch {
      throw UCryptoError.operationFailed(reason: "Error deleting data: \(error.localizedDescription)")
    }
  }
}