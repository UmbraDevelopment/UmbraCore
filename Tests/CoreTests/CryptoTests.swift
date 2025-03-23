import Core
import CoreErrors
import CoreServicesTypes
import CoreTypesInterfaces
import CryptoTypes
import ErrorHandling
import Foundation
import ServiceTypes
import XCTest

final class CryptoTests: XCTestCase {
  // MARK: - Properties

  // Use local mock implementations
  private var container: CryptoMockServiceContainer!
  private var service: CryptoMockCryptoService!

  // MARK: - Test Lifecycle

  override func setUp() async throws {
    container=CryptoMockServiceContainer()
    service=CryptoMockCryptoService(container: container)

    // Register service with container
    try await container.register(service)
  }

  override func tearDown() async throws {
    service=nil
    container=nil
  }

  // MARK: - Tests

  func testGenerateRandomBytes() async throws {
    // Initialize the service
    try await container.initialiseAll()

    // Generate random bytes
    let bytes=try await service.generateRandomBytes(count: 32)

    // Verify results
    XCTAssertEqual(bytes.count, 32, "Should generate the requested number of bytes")

    // Generate another set of bytes to ensure they're different
    let moreBytes=try await service.generateRandomBytes(count: 32)
    XCTAssertNotEqual(bytes, moreBytes, "Random bytes should be different each time")
  }

  func testEncryptDecrypt() async throws {
    // Initialize the service
    try await container.initialiseAll()

    // Test data and key
    let originalData: [UInt8]=Array("This is a test message".utf8)
    let key: [UInt8]=try await service.generateRandomBytes(count: 32)

    // Encrypt data
    let encryptedData=try await service.encrypt(data: originalData, key: key)
    XCTAssertNotEqual(encryptedData, originalData, "Encrypted data should differ from original")

    // Decrypt data
    let decryptedData=try await service.decrypt(data: encryptedData, key: key)
    XCTAssertEqual(decryptedData, originalData, "Decrypted data should match original")
  }

  func testHash() async throws {
    // Initialize the service
    try await container.initialiseAll()

    // Test data
    let data1: [UInt8]=Array("Test data 1".utf8)
    let data2: [UInt8]=Array("Test data 2".utf8)

    // Generate hashes
    let hash1=try await service.hash(data: data1)
    let hash2=try await service.hash(data: data2)

    // Same input should produce same hash
    let hash1_repeat=try await service.hash(data: data1)

    // Verify results
    XCTAssertEqual(hash1.count, 32, "Hash should be 32 bytes")
    XCTAssertNotEqual(hash1, hash2, "Different inputs should produce different hashes")
    XCTAssertEqual(hash1, hash1_repeat, "Same input should produce same hash")
  }

  func testServiceState() async throws {
    // Service should be initialized during setup
    try await container.initialiseAll()
    XCTAssertEqual(service.state, CoreServicesTypes.ServiceState.ready)

    // Test shutdown
    await service.shutdown()
    XCTAssertEqual(service.state, CoreServicesTypes.ServiceState.shutdown)
  }
}

// MARK: - Mock Implementations

/// Mock implementation of ServiceContainer for testing
actor CryptoMockServiceContainer {
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

/// Mock CryptoService implementation for testing
actor CryptoMockCryptoService: ServiceTypes.UmbraService {
  static var serviceIdentifier: String="com.umbracore.crypto.mock"
  nonisolated let identifier: String=serviceIdentifier
  nonisolated let version: String="1.0.0"

  nonisolated var state: CoreServicesTypes.ServiceState {
    _state
  }

  private weak var container: CryptoMockServiceContainer?
  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized

  init(container: CryptoMockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shutdown
  }

  func generateRandomBytes(count: Int) async throws -> [UInt8] {
    guard state == .ready else {
      throw CoreErrors.ServiceError.dependencyError
    }

    // Actually generate some random bytes instead of sequential numbers
    var bytes=[UInt8](repeating: 0, count: count)
    // Use arc4random to generate random bytes
    for i in 0..<count {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return bytes
  }

  func encrypt(data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // Simple mock encryption (just XOR with key)
    data.enumerated().map { idx, byte in
      byte ^ key[idx % key.count]
    }
  }

  func decrypt(data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // XOR is its own inverse, so reuse encrypt for decrypt
    try await encrypt(data: data, key: key)
  }

  func hash(data: [UInt8]) async throws -> [UInt8] {
    // Simple mock hash - just to provide consistent output for tests
    var result=[UInt8](repeating: 0, count: 32)
    for (idx, byte) in data.enumerated() {
      result[idx % 32]=result[idx % 32] &+ byte
    }
    return result
  }
}
