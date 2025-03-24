import Foundation
@testable import UmbraKeychainService

@objc
final class MockKeychainService: NSObject, KeychainXPCProtocol {
  // Use an actor to make the storage Sendable-compliant
  private actor StorageActor {
    var storage: [String: Data]=[:]

    func getValue(for key: String) -> Data? {
      storage[key]
    }

    func setValue(_ value: Data, for key: String) {
      storage[key]=value
    }

    func removeValue(for key: String) {
      storage.removeValue(forKey: key)
    }

    func removeAll() {
      storage.removeAll()
    }

    func hasValue(for key: String) -> Bool {
      storage[key] != nil
    }
  }

  private let storageActor=StorageActor()
  private let queue=DispatchQueue(label: "com.umbracore.mock-keychain", attributes: .concurrent)

  private func key(account: String, service: String, accessGroup: String?) -> String {
    [service, account, accessGroup].compactMap(\.self).joined(separator: "_")
  }

  func addItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    Task {
      let key=key(account: account, service: service, accessGroup: accessGroup)
      if await storageActor.hasValue(for: key) {
        reply(KeychainError.duplicateItem)
        return
      }
      await storageActor.setValue(data, for: key)
      reply(nil)
    }
  }

  func updateItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    Task {
      let key=key(account: account, service: service, accessGroup: accessGroup)
      guard await storageActor.hasValue(for: key) else {
        reply(KeychainError.itemNotFound)
        return
      }
      await storageActor.setValue(data, for: key)
      reply(nil)
    }
  }

  // Add the missing method from the protocol
  func getItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Data?, Error?) -> Void
  ) {
    Task {
      let key=key(account: account, service: service, accessGroup: accessGroup)
      let data=await storageActor.getValue(for: key)
      if let data {
        reply(data, nil)
      } else {
        reply(nil, KeychainError.itemNotFound)
      }
    }
  }

  // Add the missing method from the protocol
  func deleteItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    Task {
      let key=key(account: account, service: service, accessGroup: accessGroup)
      if await storageActor.hasValue(for: key) {
        await storageActor.removeValue(for: key)
        reply(nil)
      } else {
        reply(KeychainError.itemNotFound)
      }
    }
  }

  // These methods appear to be additional to the protocol, but keeping them for test purposes
  func retrieveItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Data?, Error?) -> Void
  ) {
    getItem(account: account, service: service, accessGroup: accessGroup, reply: reply)
  }

  func containsItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Bool, Error?) -> Void
  ) {
    Task {
      let key=key(account: account, service: service, accessGroup: accessGroup)
      let exists=await storageActor.hasValue(for: key)
      reply(exists, nil)
    }
  }

  func removeItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Error?) -> Void
  ) {
    deleteItem(account: account, service: service, accessGroup: accessGroup, reply: reply)
  }

  func removeAllItems(reply: @escaping @Sendable (Error?) -> Void) {
    Task {
      await storageActor.removeAll()
      reply(nil)
    }
  }

  // Required by protocol
  func synchroniseKeys(_: Data) async throws {
    // No-op implementation for mock
  }

  // Test helper methods
  func reset() {
    Task {
      await storageActor.removeAll()
    }
  }
}
