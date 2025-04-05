import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # KeyStorageToSecureStorageAdapter

 Adapter class that bridges between KeyStorage and SecureStorageProtocol interfaces.
 This allows components that expect a KeyStorage instance to use a SecureStorageProtocol
 implementation, and vice versa.

 The adapter maps operations between the two protocols, handling differences
 in their method signatures and error types.
 */
public actor KeyStorageToSecureStorageAdapter: KeyStorage, SecureStorageProtocol {
  /// The underlying key storage implementation
  private let keyStorage: KeyStorage

  /// The underlying secure storage implementation
  private let secureStorage: SecureStorageProtocol

  /**
   Initialises a new adapter with the specified storage implementations.

   - Parameters:
     - keyStorage: The key storage implementation
     - secureStorage: The secure storage implementation
   */
  public init(keyStorage: KeyStorage, secureStorage: SecureStorageProtocol) {
    self.keyStorage=keyStorage
    self.secureStorage=secureStorage
  }

  /**
   Initialiser that creates a self-adaptive implementation.
   When only the keyStorage is provided, the adapter functions as both
   the KeyStorage and the SecureStorageProtocol.

   - Parameter keyStorage: The key storage implementation
   */
  public init(keyStorage: KeyStorage) {
    self.keyStorage=keyStorage
    // Create a circular reference where the adapter works with the underlying storage
    secureStorage=CircularSecureStorage(keyStorage: keyStorage)
  }

  // MARK: - SecureStorageProtocol Implementation

  /**
   Stores data securely with the specified identifier.

   - Parameters:
     - data: The data to store as a byte array
     - identifier: A string identifying where to store the data
   - Returns: Success or an error
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    do {
      try await keyStorage.storeKey(data, identifier: identifier)
      return .success(())
    } catch {
      return .failure(.encryptionFailed)
    }
  }

  /**
   Retrieves data securely by its identifier.

   - Parameter identifier: A string identifying the data to retrieve
   - Returns: The retrieved data as a byte array or an error
   */
  public func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    do {
      if let data=try await keyStorage.getKey(identifier: identifier) {
        return .success(data)
      } else {
        return .failure(.keyNotFound)
      }
    } catch {
      return .failure(.dataNotFound)
    }
  }

  /**
   Deletes data securely by its identifier.

   - Parameter identifier: A string identifying the data to delete
   - Returns: Success or an error
   */
  public func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    do {
      try await keyStorage.deleteKey(identifier: identifier)
      return .success(())
    } catch {
      return .failure(.dataNotFound)
    }
  }

  /**
   Lists all available data identifiers.

   - Returns: An array of data identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    do {
      let identifiers=try await keyStorage.listKeyIdentifiers()
      return .success(identifiers)
    } catch {
      return .failure(.operationFailed("Failed to list identifiers: \(error.localizedDescription)"))
    }
  }

  // MARK: - KeyStorage Implementation

  /**
   Stores a key with the specified identifier.

   - Parameters:
     - key: The key to store as a byte array
     - identifier: The identifier for the key
   - Throws: An error if storing the key fails
   */
  public func storeKey(_ key: [UInt8], identifier: String) async throws {
    switch await secureStorage.storeData(key, withIdentifier: identifier) {
      case .success:
        return
      case let .failure(error):
        throw KeyMetadataError
          .keyStorageError(details: "Failed to store key: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves a key by its identifier.

   - Parameter identifier: The identifier for the key
   - Returns: The key as a byte array or nil if not found
   - Throws: An error if retrieving the key fails
   */
  public func getKey(identifier: String) async throws -> [UInt8]? {
    switch await secureStorage.retrieveData(withIdentifier: identifier) {
      case let .success(data):
        return data
      case let .failure(error):
        if case .keyNotFound=error {
          return nil
        }
        throw KeyMetadataError
          .keyStorageError(details: "Failed to retrieve key: \(error.localizedDescription)")
    }
  }

  /**
   Deletes a key by its identifier.

   - Parameter identifier: The identifier for the key
   - Throws: An error if deleting the key fails
   */
  public func deleteKey(identifier: String) async throws {
    switch await secureStorage.deleteData(withIdentifier: identifier) {
      case .success:
        return
      case let .failure(error):
        throw KeyMetadataError
          .keyStorageError(details: "Failed to delete key: \(error.localizedDescription)")
    }
  }

  /**
   Checks if a key exists.

   - Parameter identifier: The identifier for the key
   - Returns: True if the key exists
   - Throws: An error if checking the key fails
   */
  public func containsKey(identifier: String) async throws -> Bool {
    switch await secureStorage.retrieveData(withIdentifier: identifier) {
      case .success:
        return true
      case let .failure(error):
        if case .keyNotFound=error {
          return false
        }
        throw KeyMetadataError
          .keyStorageError(details: "Failed to check key existence: \(error.localizedDescription)")
    }
  }

  /**
   Lists all stored key identifiers.

   - Returns: Array of key identifiers
   - Throws: If listing keys fails
   */
  public func listKeyIdentifiers() async throws -> [String] {
    switch await secureStorage.listDataIdentifiers() {
      case let .success(identifiers):
        return identifiers
      case let .failure(error):
        throw KeyMetadataError
          .metadataError(details: "Failed to list key identifiers: \(error.localizedDescription)")
    }
  }
}

/**
 Provides a simple wrapper around KeyStorage to implement SecureStorageProtocol.
 This is used for the self-adapting convenience initializer pattern.
 */
private actor CircularSecureStorage: SecureStorageProtocol {
  private let keyStorage: KeyStorage

  init(keyStorage: KeyStorage) {
    self.keyStorage=keyStorage
  }

  func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    do {
      try await keyStorage.storeKey(data, identifier: identifier)
      return .success(())
    } catch {
      return .failure(.encryptionFailed)
    }
  }

  func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    do {
      if let data=try await keyStorage.getKey(identifier: identifier) {
        return .success(data)
      } else {
        return .failure(.keyNotFound)
      }
    } catch {
      return .failure(.dataNotFound)
    }
  }

  func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
    do {
      try await keyStorage.deleteKey(identifier: identifier)
      return .success(())
    } catch {
      return .failure(.dataNotFound)
    }
  }

  func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    do {
      let identifiers=try await keyStorage.listKeyIdentifiers()
      return .success(identifiers)
    } catch {
      return .failure(.operationFailed("Failed to list identifiers: \(error.localizedDescription)"))
    }
  }
}
