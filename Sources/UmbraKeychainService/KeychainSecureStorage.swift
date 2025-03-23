import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Implementation of the SecureStorageProtocol using keychain
@available(macOS 14.0, *)
public final class KeychainSecureStorage: SecureStorageProtocol {
  // This acts as a simple wrapper around the KeychainService
  private let keychain: KeychainServiceProtocol
  private let serviceName="UmbraKeychainStorage"

  /// Initialize with a keychain service
  /// - Parameter keychainService: The keychain service to use
  public init(keychainService: KeychainServiceProtocol) {
    keychain=keychainService
  }

  /// Stores data securely with the given identifier
  /// - Parameters:
  ///   - data: The data to store as SecureBytes
  ///   - identifier: A unique identifier for later retrieval
  /// - Returns: Result of the storage operation
  public func storeSecurely(data: SecureBytes, identifier: String) async -> KeyStorageResult {
    do {
      // Convert SecureBytes to Data
      let dataToStore=Data(data.withUnsafeBytes { Array($0) })
      try await keychain.addItem(
        dataToStore,
        account: identifier,
        service: serviceName,
        accessGroup: nil,
        accessibility: kSecAttrAccessibleWhenUnlocked,
        flags: []
      )
      return .success
    } catch {
      return .failure(.storageFailure)
    }
  }

  /// Retrieves data securely by its identifier
  /// - Parameter identifier: The unique identifier for the data
  /// - Returns: The retrieved data or an error
  public func retrieveSecurely(identifier: String) async -> KeyRetrievalResult {
    do {
      let data=try await keychain.readItem(
        account: identifier,
        service: serviceName,
        accessGroup: nil
      )
      let bytes=[UInt8](data)
      return .success(SecureBytes(bytes: bytes))
    } catch {
      if let keychainError=error as? KeychainError, case .itemNotFound=keychainError {
        return .failure(.keyNotFound)
      }
      return .failure(.storageFailure)
    }
  }

  /// Deletes data securely by its identifier
  /// - Parameter identifier: The unique identifier for the data to delete
  /// - Returns: Result of the deletion operation
  public func deleteSecurely(identifier: String) async -> KeyDeletionResult {
    do {
      try await keychain.deleteItem(
        account: identifier,
        service: serviceName,
        accessGroup: nil
      )
      return .success
    } catch {
      return .failure(.storageFailure)
    }
  }
}
