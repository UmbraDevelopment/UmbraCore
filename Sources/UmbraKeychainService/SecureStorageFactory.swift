import Foundation
import os
import SecurityProtocolsCore
import UmbraCoreTypes
import UmbraLogging

/// Factory for creating SecureStorageProtocol implementations
public enum SecureStorageFactory {
  /// Service name for the keychain in the system keychain
  public static let systemKeychainServiceName="UmbraSystemKeychain"

  /// A simple implementation of LoggingProtocol that uses OSLog internally
  private final class SimpleLogger: LoggingProtocol {
    private let osLog: OSLog

    init(category: String) {
      osLog=OSLog(subsystem: "dev.mpy.UmbraCore", category: category)
    }

    func debug(_ message: String, metadata _: LogMetadata?) async {
      os_log(.debug, log: osLog, "%{public}@", message)
    }

    func info(_ message: String, metadata _: LogMetadata?) async {
      os_log(.info, log: osLog, "%{public}@", message)
    }

    func warning(_ message: String, metadata _: LogMetadata?) async {
      os_log(.fault, log: osLog, "%{public}@", message)
    }

    func error(_ message: String, metadata _: LogMetadata?) async {
      os_log(.error, log: osLog, "%{public}@", message)
    }
  }

  /// Create a SecureStorageProtocol implementation using the system keychain
  /// - Returns: A SecureStorageProtocol implementation
  @available(macOS 14.0, *)
  public static func createKeychainStorage() -> any SecureStorageProtocol {
    let logger=SimpleLogger(category: "KeychainStorage")
    let keychainService=KeychainService(logger: logger)
    return KeychainSecureStorage(keychainService: keychainService)
  }

  /// Create a SecureStorageProtocol implementation using in-memory storage (for testing)
  /// - Returns: A SecureStorageProtocol implementation
  public static func createInMemoryStorage() -> any SecureStorageProtocol {
    InMemorySecureStorage()
  }
}

/// In-memory implementation of SecureStorageProtocol for testing
private final class InMemorySecureStorage: SecureStorageProtocol {
  // Using an actor to make this thread-safe for Swift 6
  private actor StorageActor {
    var storage: [String: SecureBytes]=[:]

    func store(_ data: SecureBytes, for identifier: String) {
      storage[identifier]=data
    }

    func retrieve(for identifier: String) -> SecureBytes? {
      storage[identifier]
    }

    func delete(for identifier: String) -> Bool {
      storage.removeValue(forKey: identifier) != nil
    }
  }

  private let storage=StorageActor()

  func storeSecurely(data: SecureBytes, identifier: String) async -> KeyStorageResult {
    await storage.store(data, for: identifier)
    return .success
  }

  func retrieveSecurely(identifier: String) async -> KeyRetrievalResult {
    if let data=await storage.retrieve(for: identifier) {
      .success(data)
    } else {
      .failure(.keyNotFound)
    }
  }

  func deleteSecurely(identifier: String) async -> KeyDeletionResult {
    if await storage.delete(for: identifier) {
      .success
    } else {
      .failure(.keyNotFound)
    }
  }
}
