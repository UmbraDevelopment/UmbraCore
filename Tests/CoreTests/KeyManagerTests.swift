import Core
import CoreErrors
import CoreServicesTypes
import CoreTypesInterfaces
import CryptoTypes
import ErrorHandling
import Foundation
import ServiceTypes
import XCTest

/// Test cases for the KeyManager functionality
final class KeyManagerTests: XCTestCase {
  // MARK: - Properties

  private var container: KeyManagerMockServiceContainer!
  private var cryptoService: MockCryptoService!
  private var keyManager: MockKeyManager!

  // MARK: - Test Lifecycle

  override func setUp() async throws {
    container=KeyManagerMockServiceContainer()
    cryptoService=MockCryptoService(container: container)

    // Register service with container
    try await container.register(cryptoService)
    try await container.initialiseAll()

    keyManager=MockKeyManager(container: container)
    try await container.register(keyManager)
    try await container.initialiseAll()
  }

  override func tearDown() async throws {
    keyManager=nil
    cryptoService=nil
    container=nil
  }

  // MARK: - Tests

  func testKeyGeneration() async throws {
    let keyID="test-key-1"
    let keyBits=256 // 32 bytes

    // Generate key
    let key=try await keyManager.generateKey(keyID: keyID, size: keyBits / 8)
    XCTAssertEqual(key.count, keyBits / 8, "Key should be the requested size")

    // Check that key exists
    var exists=true
    do {
      _=try await keyManager.retrieveKey(keyID: keyID)
    } catch {
      exists=false
    }
    XCTAssertTrue(exists, "Key should exist after generation")

    // Retrieve key
    let retrievedKey=try await keyManager.retrieveKey(keyID: keyID)
    XCTAssertEqual(retrievedKey, key, "Retrieved key should match generated key")
  }

  func testKeyDeletion() async throws {
    let keyID="test-key-2"

    // Generate key
    _=try await keyManager.generateKey(keyID: keyID, size: 32)

    // Delete key
    try await keyManager.storeKey(keyData: [], keyID: keyID)

    // Check that key no longer exists
    var exists=true
    do {
      _=try await keyManager.retrieveKey(keyID: keyID)
    } catch {
      exists=false
    }
    XCTAssertFalse(exists, "Key should not exist after deletion")

    // Attempt to retrieve deleted key
    do {
      _=try await keyManager.retrieveKey(keyID: keyID)
      XCTFail("Expected error when retrieving deleted key")
    } catch {
      // Expected error
    }
  }

  func testKeyUsage() async throws {
    let keyID="test-key-3"

    // Generate key
    _=try await keyManager.generateKey(keyID: keyID, size: 32)

    // Test data encryption
    let plaintext=Array("This is a test message".utf8)
    let ciphertext=try await cryptoService.encrypt(
      data: plaintext,
      key: keyManager.retrieveKey(keyID: keyID)
    )
    XCTAssertNotEqual(ciphertext, plaintext, "Encrypted data should differ from plaintext")

    // Test data decryption
    let decrypted=try await cryptoService.decrypt(
      data: ciphertext,
      key: keyManager.retrieveKey(keyID: keyID)
    )
    XCTAssertEqual(decrypted, plaintext, "Decrypted data should match original plaintext")
  }

  func testKeyErrorHandling() async throws {
    let keyID="non-existent-key"

    // Check if key exists
    var exists=true
    do {
      _=try await keyManager.retrieveKey(keyID: keyID)
    } catch {
      exists=false
    }
    XCTAssertFalse(exists, "Key should not exist")

    // Try to get non-existent key
    do {
      _=try await keyManager.retrieveKey(keyID: keyID)
      XCTFail("Expected error when retrieving non-existent key")
    } catch {
      // Expected error
    }

    // Try to encrypt with non-existent key
    do {
      let testData=Array("Test".utf8)
      _=try await cryptoService.encrypt(data: testData, key: keyManager.retrieveKey(keyID: keyID))
      XCTFail("Expected error when encrypting with non-existent key")
    } catch {
      // Expected error
    }
  }
}

// MARK: - Mock Implementations

/// Mock implementation of ServiceContainer for testing
actor KeyManagerMockServiceContainer {
  var services: [String: Any]=[:]
  var serviceStates: [String: CoreServicesTypes.ServiceState]=[:]

  func register(_ service: any ServiceTypes.UmbraService) async throws {
    services[service.identifier]=service
    serviceStates[service.identifier]=CoreServicesTypes.ServiceState.uninitialized
  }

  func initialiseAll() async throws {
    for serviceID in services.keys {
      serviceStates[serviceID]=CoreServicesTypes.ServiceState.ready
      if let service=services[serviceID] as? any ServiceTypes.UmbraService {
        try await service.validate()
      }
    }
  }

  func initialiseService(_ identifier: String) async throws {
    serviceStates[identifier]=CoreServicesTypes.ServiceState.ready
  }

  func resolve<T>(_: T.Type) async throws -> T where T: ServiceTypes.UmbraService {
    guard let service=services.values.first(where: { $0 is T }) as? T else {
      throw CoreErrors.ServiceError.dependencyError
    }
    return service
  }
}

/// Mock implementation of CryptoService for testing in KeyManagerTests
actor MockCryptoService: ServiceTypes.UmbraService {
  static var serviceIdentifier: String="com.umbracore.crypto.mock"
  nonisolated let identifier: String=serviceIdentifier
  nonisolated let version: String="1.0.0"

  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized
  nonisolated var state: CoreServicesTypes.ServiceState { _state }

  private weak var container: KeyManagerMockServiceContainer?

  init(container: KeyManagerMockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shutdown
  }

  // Simplified mock crypto methods
  func generateRandomBytes(count: Int) async throws -> [UInt8] {
    Array(repeating: 0, count: count)
  }

  func encrypt(data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // Mock encryption by XORing with the key (for testing only, not secure)
    let repeatedKey=Array(repeating: key, count: (data.count / key.count) + 1).flatMap(\.self)
      .prefix(data.count)
    return zip(data, repeatedKey).map { $0 ^ $1 }
  }

  func decrypt(data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // XOR is symmetric, so encryption and decryption are the same
    try await encrypt(data: data, key: key)
  }

  func hash(data: [UInt8]) async throws -> [UInt8] {
    // Simple mock hash function (not cryptographically secure)
    var result: [UInt8]=Array(repeating: 0, count: 32)
    for (index, byte) in data.enumerated() {
      result[index % 32] ^= byte
    }
    return result
  }
}

/// Mock KeyManager implementation for testing
actor MockKeyManager: ServiceTypes.UmbraService {
  static var serviceIdentifier: String="com.umbracore.keymanager.mock"
  nonisolated let identifier: String=serviceIdentifier
  nonisolated let version: String="1.0.0"

  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized
  nonisolated var state: CoreServicesTypes.ServiceState { _state }

  private weak var container: KeyManagerMockServiceContainer?
  private var keyStore: [String: [UInt8]]=[:]

  init(container: KeyManagerMockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    // Initialize with an empty state
    _state = .ready
    return true
  }

  func shutdown() async {
    // Clear all keys on shutdown
    keyStore.removeAll()
    _state = .shutdown
  }

  // KeyManager methods
  func retrieveKey(keyID: String) async throws -> [UInt8] {
    guard state == .ready else {
      throw CoreErrors.ServiceError.dependencyError
    }

    // Check if key exists - do NOT auto-generate for test cases that check for non-existent keys
    if let key=keyStore[keyID] {
      return key
    } else {
      // Non-existent key requested, throw an error for test cases
      throw NSError(
        domain: "KeyManager",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Key not found: \(keyID)"]
      )
    }
  }

  func storeKey(keyData: [UInt8], keyID: String) async throws {
    guard state == .ready else {
      throw CoreErrors.ServiceError.dependencyError
    }

    // Empty key data means delete
    if keyData.isEmpty {
      keyStore.removeValue(forKey: keyID)
    } else {
      keyStore[keyID]=keyData
    }
  }

  // Generate a key and store it
  func generateKey(keyID: String, size: Int) async throws -> [UInt8] {
    guard state == .ready else {
      throw CoreErrors.ServiceError.dependencyError
    }

    let key=try await generateRandomKey(size: size)
    keyStore[keyID]=key
    return key
  }

  private func generateRandomKey(size: Int) async throws -> [UInt8] {
    var key=[UInt8](repeating: 0, count: size)
    for i in 0..<size {
      key[i]=UInt8.random(in: 0...255)
    }
    return key
  }
}
