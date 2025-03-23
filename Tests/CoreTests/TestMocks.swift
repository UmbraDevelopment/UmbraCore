import Core
import CoreErrors
import CoreServicesTypes
import CoreTypesInterfaces
import CryptoTypes
import ErrorHandling
import Foundation
import KeyManagementTypes
import SecurityTypes
import ServiceTypes

// MARK: - Service Container Mocks

/// Generic mock implementation of ServiceContainer for testing
actor GenericMockServiceContainer {
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

// MARK: - Crypto Service Mocks

/// Generic mock implementation of CryptoService for testing
@preconcurrency
actor GenericMockCryptoService {
  static let serviceIdentifier="com.umbracore.crypto.mock"
  nonisolated let identifier: String=GenericMockCryptoService.serviceIdentifier
  nonisolated let version: String="1.0.0"

  nonisolated var state: CoreServicesTypes.ServiceState {
    _state
  }

  private weak var container: GenericMockServiceContainer?
  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized

  init(container: GenericMockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shutdown
  }

  // Crypto operations
  func generateRandomBytes(count: Int) async throws -> [UInt8] {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }
    // Simple mock implementation that creates random bytes
    return (0..<count).map { _ in UInt8.random(in: 0...255) }
  }

  func encrypt(data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }
    // Mock encryption by XORing with the key (for testing only, not secure)
    let repeatedKey=Array(repeating: key, count: (data.count / key.count) + 1).flatMap(\.self)
      .prefix(data.count)
    return zip(data, repeatedKey).map { $0 ^ $1 }
  }

  func decrypt(data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }
    // XOR is symmetric, so encryption and decryption are the same
    return try await encrypt(data: data, key: key)
  }

  func hash(data: [UInt8]) async throws -> [UInt8] {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }
    // Simple mock hash function (not cryptographically secure)
    var result: [UInt8]=Array(repeating: 0, count: 32)
    for (index, byte) in data.enumerated() {
      result[index % 32] ^= byte
    }
    return result
  }
}

// MARK: - Security Service Mocks

/// Generic mock implementation of SecurityService for testing
@preconcurrency
actor GenericMockSecurityService {
  static let serviceIdentifier="com.umbracore.security.mock"
  nonisolated let identifier: String=GenericMockSecurityService.serviceIdentifier
  nonisolated let version: String="1.0.0"

  nonisolated var state: CoreServicesTypes.ServiceState {
    _state
  }

  private var bookmarkStorage: [String: [UInt8]]=[:]
  private weak var container: GenericMockServiceContainer?
  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized

  init(container: GenericMockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shutdown
  }

  // Security operations
  func createBookmark(forPath path: String) async throws -> [UInt8] {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }

    guard !path.isEmpty else {
      throw CoreErrors.SecurityError.invalidParameter(name: "path", reason: "Invalid path")
    }

    // Mock bookmark creation by returning a simple representation of the path
    return Array(path.utf8)
  }

  func resolveBookmark(_ bookmark: [UInt8]) async throws -> String {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }

    guard !bookmark.isEmpty else {
      throw CoreErrors.SecurityError.invalidParameter(
        name: "bookmark",
        reason: "Invalid bookmark data"
      )
    }

    // Mock bookmark resolution by converting bytes back to string
    if let path=String(bytes: bookmark, encoding: .utf8) {
      return path
    } else {
      throw CoreErrors.SecurityError.invalidParameter(
        name: "bookmark",
        reason: "Could not resolve bookmark"
      )
    }
  }

  func storeBookmark(_ bookmark: [UInt8], withIdentifier identifier: String) async throws {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }

    bookmarkStorage[identifier]=bookmark
  }

  func loadBookmark(withIdentifier identifier: String) async throws -> [UInt8] {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }

    guard let bookmark=bookmarkStorage[identifier] else {
      throw CoreErrors.SecurityError.invalidParameter(
        name: "identifier",
        reason: "Bookmark not found: \(identifier)"
      )
    }

    return bookmark
  }

  func verifyAccess(forPath _: String) async throws -> Bool {
    guard state == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.operationFailed
    }

    // For testing, always return true
    return true
  }
}

// MARK: - Key Manager Mocks

/// Generic mock implementation of KeyManagerDependencies for testing
struct GenericMockKeyManagerDependencies {
  let cryptoService: GenericMockCryptoService
}

/// Generic mock implementation of KeyManager for testing
actor GenericMockKeyManager {
  private let dependencies: GenericMockKeyManagerDependencies
  private var keyStore: [String: [UInt8]]=[:]

  init(dependencies: GenericMockKeyManagerDependencies) {
    self.dependencies=dependencies
  }

  func generateKey(withID keyID: String, bits: Int) async throws -> [UInt8] {
    let byteCount=bits / 8
    let keyData=try await dependencies.cryptoService.generateRandomBytes(count: byteCount)
    keyStore[keyID]=keyData
    return keyData
  }

  func getKey(withID keyID: String) async throws -> [UInt8] {
    guard let keyData=keyStore[keyID] else {
      throw NSError(
        domain: "KeyManager",
        code: 404,
        userInfo: [NSLocalizedDescriptionKey: "Key not found: \(keyID)"]
      )
    }
    return keyData
  }

  func hasKey(withID keyID: String) async -> Bool {
    keyStore[keyID] != nil
  }

  func deleteKey(withID keyID: String) async throws {
    guard keyStore[keyID] != nil else {
      throw NSError(
        domain: "KeyManager",
        code: 404,
        userInfo: [NSLocalizedDescriptionKey: "Key not found: \(keyID)"]
      )
    }
    keyStore.removeValue(forKey: keyID)
  }

  func encryptData(_ data: [UInt8], withKeyID keyID: String) async throws -> [UInt8] {
    let key=try await getKey(withID: keyID)
    return try await dependencies.cryptoService.encrypt(data: data, key: key)
  }

  func decryptData(_ data: [UInt8], withKeyID keyID: String) async throws -> [UInt8] {
    let key=try await getKey(withID: keyID)
    return try await dependencies.cryptoService.decrypt(data: data, key: key)
  }
}

// MARK: - Generic Service Mocks

/// Generic mock service for testing
@preconcurrency
actor GenericMockService: ServiceTypes.UmbraService {
  static let serviceIdentifier="com.umbracore.mock"
  nonisolated let identifier: String=GenericMockService.serviceIdentifier
  nonisolated let version: String="1.0.0"

  nonisolated var state: CoreServicesTypes.ServiceState {
    _state
  }

  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.initializing
    // Simulate some initialization work
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shuttingDown
    // Simulate some shutdown work
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    _state=CoreServicesTypes.ServiceState.shutdown
  }
}

/// Generic mock dependent service for testing dependency initialization
@preconcurrency
actor GenericMockDependentService: ServiceTypes.UmbraService {
  static let serviceIdentifier="com.umbracore.dependent"
  nonisolated let identifier: String=GenericMockDependentService.serviceIdentifier
  nonisolated let version: String="1.0.0"

  nonisolated var state: CoreServicesTypes.ServiceState {
    _state
  }

  private let dependency: GenericMockService
  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized

  init(dependency: GenericMockService) {
    self.dependency=dependency
  }

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.initializing

    // Ensure dependency is ready
    let dependencyState=await dependency.state
    guard dependencyState == CoreServicesTypes.ServiceState.ready else {
      throw CoreErrors.ServiceError.dependencyError
    }

    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shuttingDown
    _state=CoreServicesTypes.ServiceState.shutdown
  }
}
