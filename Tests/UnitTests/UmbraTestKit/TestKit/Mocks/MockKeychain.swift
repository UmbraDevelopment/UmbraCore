import ErrorHandlingDomains
import Foundation
import SecurityInterfaces
import SecurityTypes
import SecurityTypesProtocols

/// Mock implementation of the secure storage provider
public actor MockKeychain: SecureStorageProvider {
  private var storage: [String: Data]=[:]
  private var metadata: [String: [String: String]]=[:]

  public init() {}

  public func save(_ data: Data, forKey key: String, metadata: [String: String]?=nil) async throws {
    storage[key]=data
    if let metadata {
      self.metadata[key]=metadata
    }
  }

  public func load(forKey key: String) async throws -> Data {
    guard let data=storage[key] else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No data found for key: \(key)")
    }
    return data
  }

  public func loadWithMetadata(forKey key: String) async throws -> (Data, [String: String]?) {
    guard let data=storage[key] else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No data found for key: \(key)")
    }
    return (data, metadata[key])
  }

  public func delete(forKey key: String) async throws {
    guard storage.removeValue(forKey: key) != nil else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No data found for key: \(key)")
    }
    metadata.removeValue(forKey: key)
  }

  /// Resets the mock keychain by clearing all stored data and metadata
  public func reset() async {
    storage.removeAll()
    metadata.removeAll()
  }

  public func getMetadata(forKey key: String) async throws -> [String: String]? {
    guard storage[key] != nil else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No data found for key: \(key)")
    }
    return metadata[key]
  }

  public func updateMetadata(_ metadata: [String: String], forKey key: String) async throws {
    guard storage[key] != nil else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No data found for key: \(key)")
    }
    self.metadata[key]=metadata
  }

  public func exists(forKey key: String) async -> Bool {
    storage[key] != nil
  }

  public func allKeys() async throws -> [String] {
    Array(storage.keys)
  }

  public func reset(preserveKeys: Bool) async {
    if !preserveKeys {
      storage.removeAll()
      metadata.removeAll()
    }
  }
}
