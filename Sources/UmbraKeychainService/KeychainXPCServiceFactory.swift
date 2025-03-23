import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import XPCProtocolsCore

/// Factory for creating KeychainXPCServiceProtocol implementations
public enum KeychainXPCServiceFactory {
  /// Create a keychain XPC service with the specified service identifier
  /// - Parameter serviceIdentifier: Optional service identifier. If nil, the default identifier is
  /// used.
  /// - Returns: A KeychainXPCServiceProtocol implementation
  public static func createService(serviceIdentifier _: String?=nil)
  -> any KeychainXPCServiceProtocol {
    // DEPRECATED: Previously used KeychainXPCServiceAdapter and KeychainSecureStorageAdapter
    // Now returns the in-memory implementation as a temporary solution until proper replacement is
    // implemented
    createInMemoryService()
  }

  /// Create an in-memory keychain service for testing
  /// - Returns: A KeychainXPCServiceProtocol implementation backed by an in-memory store
  public static func createInMemoryService() -> any KeychainXPCServiceProtocol {
    InMemoryKeychainService()
  }
}

// Previously contained KeychainXPCServiceAdapter class which has been removed
// DEPRECATED: KeychainXPCServiceAdapter has been removed.
// Use a modern implementation instead.

/// An in-memory implementation of KeychainXPCServiceProtocol for testing
private actor InMemoryKeychainService: KeychainXPCServiceProtocol {
  private var storage: [String: SecureBytes]=[:]

  func storeData(_ request: KeychainXPCDTO.StoreRequest) async -> KeychainXPCDTO.OperationResult {
    let key="\(request.service)|\(request.identifier)"
    storage[key]=request.data
    return .success
  }

  func retrieveData(_ request: KeychainXPCDTO.RetrieveRequest) async -> KeychainXPCDTO
  .OperationResult {
    let key="\(request.service)|\(request.identifier)"

    if let data=storage[key] {
      return .successWithData(data)
    } else {
      return .failure(.itemNotFound)
    }
  }

  func deleteData(_ request: KeychainXPCDTO.DeleteRequest) async -> KeychainXPCDTO.OperationResult {
    let key="\(request.service)|\(request.identifier)"

    if storage.removeValue(forKey: key) != nil {
      return .success
    } else {
      return .failure(.itemNotFound)
    }
  }

  func generateRandomData(length: Int) async -> KeychainXPCDTO.OperationResult {
    // Generate random data for testing
    var bytes=[UInt8](repeating: 0, count: length)
    for i in 0..<length {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return .successWithData(SecureBytes(bytes: bytes))
  }
}
