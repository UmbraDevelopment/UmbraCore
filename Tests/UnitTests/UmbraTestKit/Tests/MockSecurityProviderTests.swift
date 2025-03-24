import Core
import CoreDTOs
import CoreTypesInterfaces
import ErrorHandlingDomains
import Foundation // Only used for String conversion operations
import SecurityInterfaces
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

/// A mock security provider for testing
@preconcurrency
actor TestMockSecurityProvider: SecurityInterfacesProtocols.SecurityProviderProtocol,
@unchecked Sendable {
  private var bookmarks: [String: [UInt8]]=[:]
  private var accessCount: [String: Int]=[:]
  private var accessedPaths: Set<String>=[]
  private var storedBookmarks: [String: [UInt8]]=[:]
  private var shouldFailBookmarkCreation=false
  private var shouldFailAccess=false

  // MARK: - Protocol properties

  public var cryptoService: SecurityProtocolsCore.CryptoServiceProtocol {
    // Return the mock crypto service
    mockCryptoService
  }

  public var keyManager: SecurityProtocolsCore.KeyManagementProtocol {
    // Return mock key manager
    mockKeyManager
  }

  // Mock implementations
  private let mockCryptoService=MockCryptoService()
  private let mockKeyManager=MockKeyManagementServiceImpl()

  // MARK: - SecurityProviderProtocol implementation

  public func performSecureOperation(
    operation _: SecurityProtocolsCore.SecurityOperation,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> SecurityProtocolsCore.SecurityResultDTO {
    // Simple mock implementation that succeeds for all operations
    SecurityProtocolsCore.SecurityResultDTO(success: true)
  }

  // Must be nonisolated to conform to protocol
  public nonisolated func createSecureConfig(options _: [String: Any]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    // Return a basic secure config with default settings
    SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: "AES-256",
      keySizeInBits: 256,
      initializationVector: nil,
      additionalAuthenticatedData: nil,
      iterations: nil,
      options: [:],
      keyIdentifier: nil,
      inputData: nil,
      key: nil,
      additionalData: nil
    )
  }

  // MARK: - SecurityProvider Implementation

  // Additional required protocol methods
  public func getSecurityConfiguration() async
    -> Result<
      SecurityProtocolsCore.SecurityConfigDTO,
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
    >
  {
    .success(SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: "AES-256",
      keySizeInBits: 256,
      initializationVector: nil,
      additionalAuthenticatedData: nil,
      iterations: nil,
      options: [:],
      keyIdentifier: nil,
      inputData: nil,
      key: nil,
      additionalData: nil
    ))
  }

  public func updateSecurityConfiguration(_: SecurityProtocolsCore.SecurityConfigDTO) async throws {
    // Just a mock implementation
  }

  public func generateRandomData(length: Int) async
  -> Result<CoreTypesInterfaces.BinaryData, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(CoreTypesInterfaces.BinaryData(bytes: [UInt8](repeating: 0, count: length)))
  }

  public func getKeyInfo(keyID _: String) async
  -> Result<[String: AnyObject], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let info: [String: AnyObject]=[
      "algorithm": "AES-256" as NSString,
      "keySize": 256 as NSNumber,
      "created": Date() as NSDate
    ]
    return .success(info)
  }

  public func registerNotifications() async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  // New protocol methods
  public func randomBytes(count: Int) async
  -> Result<CoreTypesInterfaces.BinaryData, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(CoreTypesInterfaces.BinaryData(bytes: [UInt8](repeating: 0, count: count)))
  }

  public func encryptData(
    _ data: CoreTypesInterfaces.BinaryData,
    withKey _: CoreTypesInterfaces.BinaryData
  ) async
  -> Result<CoreTypesInterfaces.BinaryData, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data) // Mock just returns the same data
  }

  public func decryptData(
    _ data: CoreTypesInterfaces.BinaryData,
    withKey _: CoreTypesInterfaces.BinaryData
  ) async
  -> Result<CoreTypesInterfaces.BinaryData, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data) // Mock just returns the same data
  }

  public func performSecurityOperation(
    operationName _: String,
    data _: [UInt8]?,
    parameters _: [String: String]
  ) async throws -> SecurityProtocolsCore.SecurityResultDTO {
    SecurityProtocolsCore.SecurityResultDTO(
      success: true,
      data: UmbraCoreTypes.SecureBytes(bytes: [])
    )
  }

  /// Encrypt data using a simple mock implementation
  func encrypt(
    _ data: CoreTypesInterfaces.BinaryData,
    key _: CoreTypesInterfaces.BinaryData
  ) async throws -> CoreTypesInterfaces.BinaryData {
    data
  }

  /// Decrypt data using a simple mock implementation
  func decrypt(
    _ data: CoreTypesInterfaces.BinaryData,
    key _: CoreTypesInterfaces.BinaryData
  ) async throws -> CoreTypesInterfaces.BinaryData {
    data
  }

  /// Generate a mock key
  func generateKey(length: Int) async throws -> CoreTypesInterfaces.BinaryData {
    // Mock implementation just returns array of zeros
    CoreTypesInterfaces.BinaryData(bytes: [UInt8](repeating: 0, count: length))
  }

  /// Mock hash function
  func hash(_ data: CoreTypesInterfaces.BinaryData) async throws -> CoreTypesInterfaces.BinaryData {
    // Mock implementation just returns first 32 bytes or pads with zeros
    if data.count >= 32 {
      var result=[UInt8]()
      for i in 0..<32 {
        result.append(data[i])
      }
      return CoreTypesInterfaces.BinaryData(bytes: result)
    } else {
      var result=[UInt8]()
      for i in 0..<data.count {
        result.append(data[i])
      }
      result.append(contentsOf: [UInt8](repeating: 0, count: 32 - result.count))
      return CoreTypesInterfaces.BinaryData(bytes: result)
    }
  }

  // MARK: - SecurityProviderBase Implementation

  /// Reset all security data
  func resetSecurityData() async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    bookmarks.removeAll()
    accessCount.removeAll()
    accessedPaths.removeAll()
    return .success(())
  }

  /// Get the host identifier
  func getHostIdentifier() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success("mock-host-identifier")
  }

  /// Register a client application
  func registerClient(bundleIdentifier _: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  /// Request key rotation - mock implementation
  func requestKeyRotation(keyID _: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  /// Notify about a potentially compromised key - mock implementation
  func notifyKeyCompromise(keyID _: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  // MARK: - Additional required protocol methods

  /// Rotate key implementation
  func rotateKey(
    withIdentifier _: String,
    dataToReencrypt: UmbraCoreTypes.SecureBytes?
  ) async -> Result<(
    newKey: UmbraCoreTypes.SecureBytes,
    reencryptedData: UmbraCoreTypes.SecureBytes?
  ), ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let newKey=UmbraCoreTypes.SecureBytes(bytes: [UInt8](repeating: 0, count: 32))
    let reencrypted=dataToReencrypt
    return .success((newKey: newKey, reencryptedData: reencrypted))
  }

  /// List key identifiers
  func listKeyIdentifiers() async
  -> Result<[String], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(["test-key-1", "test-key-2"])
  }

  // MARK: - Original Implementation

  func createSecurityBookmark(for path: String) async
  -> Result<[UInt8], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if shouldFailBookmarkCreation {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Mock failure")
      )
    }
    // Convert path to bytes for mock bookmark
    let bookmarkData=Array(("mock_bookmark_\(path)").utf8)
    bookmarks[path]=bookmarkData
    return .success(bookmarkData)
  }

  func resolveBookmark(_ bookmark: [UInt8]) async
  -> Result<(path: String, isStale: Bool), ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Convert bookmark bytes back to string for mock implementation
    guard let mockPath=String(bytes: bookmark, encoding: .utf8) else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Invalid bookmark data")
      )
    }
    let path=mockPath.replacingOccurrences(of: "mock_bookmark_", with: "")
    if shouldFailAccess {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Mock access denied")
      )
    }
    accessCount[path, default: 0] += 1
    return .success((path: path, isStale: false))
  }

  func startAccessing(path: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if shouldFailAccess {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Mock access denied")
      )
    }
    accessedPaths.insert(path)
    return .success(true)
  }

  func stopAccessing(path: String) async {
    accessedPaths.remove(path)
  }

  func stopAccessingAllResources() async {
    accessedPaths.removeAll()
  }

  // MARK: - Security Scoped Resources

  func performOperationWithSecurityScopeAccess<T: Sendable>(
    to path: String,
    perform operation: @Sendable () async throws -> T
  ) async -> Result<T, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if shouldFailAccess {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Mock access denied")
      )
    }

    // Simulate the security scope access
    accessedPaths.insert(path)
    defer { accessedPaths.remove(path) }

    do {
      let result=try await operation()
      return .success(result)
    } catch {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Operation failed: \(error.localizedDescription)")
      )
    }
  }

  // MARK: - Bookmark Storage

  func validateBookmark(_ bookmarkData: [UInt8]) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard let mockPath=String(bytes: bookmarkData, encoding: .utf8) else {
      return .success(false)
    }
    let isValid=mockPath.hasPrefix("mock_bookmark_")
    return .success(isValid)
  }

  func saveBookmark(
    _ bookmarkData: [UInt8],
    withIdentifier identifier: String
  ) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if shouldFailAccess {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Mock storage failure")
      )
    }
    storedBookmarks[identifier]=bookmarkData
    return .success(())
  }

  func loadBookmark(withIdentifier identifier: String) async
  -> Result<[UInt8], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard let bookmark=storedBookmarks[identifier] else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Bookmark not found: \(identifier)")
      )
    }
    return .success(bookmark)
  }

  func deleteBookmark(withIdentifier identifier: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if shouldFailAccess {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Mock storage failure")
      )
    }
    storedBookmarks.removeValue(forKey: identifier)
    return .success(())
  }

  /// Set whether bookmark creation should fail
  func setShouldFailBookmarkCreation(_ shouldFail: Bool) {
    shouldFailBookmarkCreation=shouldFail
  }

  /// Set whether access operations should fail
  func setShouldFailAccess(_ shouldFail: Bool) {
    shouldFailAccess=shouldFail
  }

  /// Get the access count for a path
  nonisolated func getAccessCount(for path: String) async -> Int {
    await accessCount[path] ?? 0
  }

  /// Check if a path is currently being accessed
  nonisolated func isAccessing(path: String) async -> Bool {
    await accessedPaths.contains(path)
  }
}

// Create a mock crypto service
@preconcurrency
class MockCryptoService: SecurityProtocolsCore.CryptoServiceProtocol, @unchecked Sendable {
  // Use UmbraCoreTypes.SecureBytes for all SecureBytes references

  func encrypt(
    data: UmbraCoreTypes.SecureBytes,
    using _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decrypt(
    data: UmbraCoreTypes.SecureBytes,
    using _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func generateKey() async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: [UInt8](repeating: 0, count: 32)))
  }

  func hash(
    data _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: [UInt8](repeating: 0, count: 32)))
  }

  func verify(
    data _: UmbraCoreTypes.SecureBytes,
    against _: UmbraCoreTypes
      .SecureBytes
  ) async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  func encryptSymmetric(
    data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decryptSymmetric(
    data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func encryptAsymmetric(
    data: UmbraCoreTypes.SecureBytes,
    publicKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decryptAsymmetric(
    data: UmbraCoreTypes.SecureBytes,
    privateKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func hash(
    data _: UmbraCoreTypes.SecureBytes,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: [UInt8](repeating: 0, count: 32)))
  }

  func generateRandomData(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: [UInt8](repeating: 0, count: length)))
  }
}

// Mock implementation of KeyManagementProtocol
@preconcurrency
class MockKeyManagementServiceImpl: SecurityProtocolsCore.KeyManagementProtocol,
@unchecked Sendable {
  private var storedKeys: [String: UmbraCoreTypes.SecureBytes]=[:]

  // Implementation of KeyManagementProtocol

  func retrieveKey(withIdentifier identifier: String) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    if let key=storedKeys[identifier] {
      .success(key)
    } else {
      .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Key with ID \(identifier) not found")
      )
    }
  }

  func storeKey(
    _ key: UmbraCoreTypes.SecureBytes,
    withIdentifier identifier: String
  ) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    storedKeys[identifier]=key
    return .success(())
  }

  func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    storedKeys[identifier]=nil
    return .success(())
  }

  func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: UmbraCoreTypes.SecureBytes?
  ) async -> Result<(
    newKey: UmbraCoreTypes.SecureBytes,
    reencryptedData: UmbraCoreTypes.SecureBytes?
  ), ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let newKey=UmbraCoreTypes.SecureBytes(bytes: [UInt8](repeating: 0, count: 32))
    storedKeys[identifier]=newKey
    return .success((newKey: newKey, reencryptedData: dataToReencrypt))
  }

  func listKeyIdentifiers() async
  -> Result<[String], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(Array(storedKeys.keys))
  }
}

final class MockSecurityProviderTests: XCTestCase {
  private var provider: TestMockSecurityProvider!

  // Add static property for test discovery
  static var allTests=[
    ("testCreateBookmark", testCreateBookmark),
    ("testResolveBookmark", testResolveBookmark),
    ("testAccessControl", testAccessControl),
    ("testSecurityScopedOperations", testSecurityScopedOperations),
    ("testBookmarkStorage", testBookmarkStorage)
  ]

  override func setUp() async throws {
    provider=TestMockSecurityProvider()
  }

  override func tearDown() async throws {
    _=await provider.resetSecurityData()
    provider=nil
  }

  func testCreateBookmark() async throws {
    let testPath="/test/path"

    // Test successful bookmark creation
    let result=await provider.createSecurityBookmark(for: testPath)
    switch result {
      case let .success(bookmarkData):
        XCTAssertFalse(bookmarkData.isEmpty)
        // Mock bookmarks are stored as UTF-8 data
        let bookmarkString=String(bytes: bookmarkData, encoding: .utf8)
        XCTAssertEqual(bookmarkString, "mock_bookmark_\(testPath)")
      case let .failure(error):
        XCTFail("Bookmark creation should succeed, got error: \(error)")
    }

    // Test failed bookmark creation
    await provider.setShouldFailBookmarkCreation(true)
    let failResult=await provider.createSecurityBookmark(for: testPath)
    switch failResult {
      case .success:
        XCTFail("Bookmark creation should fail when shouldFailBookmarkCreation is true")
      case .failure:
        // Expected failure
        break
    }
  }

  func testResolveBookmark() async throws {
    let testPath="/test/path"
    let result=await provider.createSecurityBookmark(for: testPath)

    switch result {
      case let .success(bookmarkData):
        // Test successful resolution
        let resolveResult=await provider.resolveBookmark(bookmarkData)
        switch resolveResult {
          case let .success(resolved):
            XCTAssertEqual(resolved.path, testPath)
            XCTAssertFalse(resolved.isStale)
            let accessCount=await provider.getAccessCount(for: testPath)
            XCTAssertEqual(accessCount, 1)
          case let .failure(error):
            XCTFail("Bookmark resolution should succeed, got error: \(error)")
        }

        // Test failed resolution
        await provider.setShouldFailAccess(true)
        let failResult=await provider.resolveBookmark(bookmarkData)
        switch failResult {
          case .success:
            XCTFail("Bookmark resolution should fail when shouldFailAccess is true")
          case .failure:
            // Expected failure
            break
        }
      case let .failure(error):
        XCTFail("Could not create bookmark for testing: \(error)")
    }
  }

  func testAccessControl() async throws {
    let testPath="/test/path"

    // Test starting access
    let startResult=await provider.startAccessing(path: testPath)
    switch startResult {
      case let .success(success):
        XCTAssertTrue(success)
        let isAccessing=await provider.isAccessing(path: testPath)
        XCTAssertTrue(isAccessing)
      case let .failure(error):
        XCTFail("Starting access should succeed, got error: \(error)")
    }

    // Test stopping access
    await provider.stopAccessing(path: testPath)
    let isAccessingAfterStop=await provider.isAccessing(path: testPath)
    XCTAssertFalse(isAccessingAfterStop)

    // Test failed access
    await provider.setShouldFailAccess(true)
    let failResult=await provider.startAccessing(path: testPath)
    switch failResult {
      case .success:
        XCTFail("Starting access should fail when shouldFailAccess is true")
      case .failure:
        // Expected failure
        break
    }
  }

  func testSecurityScopedOperations() async throws {
    let testPath="/test/path"

    // Test successful operation
    let result=await provider.performOperationWithSecurityScopeAccess(to: testPath) { [self] in
      // No need for capture list as we're just using self
      let isAccessing=await provider.isAccessing(path: testPath)
      XCTAssertTrue(isAccessing)
      return "operation completed"
    }

    switch result {
      case let .success(value):
        XCTAssertEqual(value, "operation completed")
        // Path should no longer be accessed after operation completes
        let isAccessing=await provider.isAccessing(path: testPath)
        XCTAssertFalse(isAccessing)
      case let .failure(error):
        XCTFail("Security scoped operation should succeed, got error: \(error)")
    }

    // Test failed operation
    await provider.setShouldFailAccess(true)
    let failResult=await provider.performOperationWithSecurityScopeAccess(to: testPath) {
      XCTFail("Operation block should not be called when access is denied")
      return "should not reach here"
    }

    switch failResult {
      case .success:
        XCTFail("Operation should fail when shouldFailAccess is true")
      case .failure:
        // Expected failure
        break
    }
  }

  func testBookmarkStorage() async throws {
    let testPath="/test/path"
    let identifier="test_bookmark_id"

    // Create a bookmark to store
    let bookmarkResult=await provider.createSecurityBookmark(for: testPath)
    guard case let .success(bookmarkData)=bookmarkResult else {
      XCTFail("Could not create test bookmark")
      return
    }

    // Test saving a bookmark
    let saveResult=await provider.saveBookmark(bookmarkData, withIdentifier: identifier)
    XCTAssertTrue(saveResult.isSuccess)

    // Test loading the saved bookmark
    let loadResult=await provider.loadBookmark(withIdentifier: identifier)
    switch loadResult {
      case let .success(loadedData):
        XCTAssertEqual(loadedData, bookmarkData)
      case let .failure(error):
        XCTFail("Loading bookmark should succeed, got error: \(error)")
    }

    // Test validating a bookmark
    let validateResult=await provider.validateBookmark(bookmarkData)
    XCTAssertTrue(validateResult.isSuccess)
    if let isValid=validateResult.value {
      XCTAssertTrue(isValid)
    }

    // Test deleting a bookmark
    let deleteResult=await provider.deleteBookmark(withIdentifier: identifier)
    XCTAssertTrue(deleteResult.isSuccess)

    // Verify the bookmark is gone
    let reloadResult=await provider.loadBookmark(withIdentifier: identifier)
    XCTAssertTrue(reloadResult.isFailure)
  }
}

// MARK: - Helper extensions

extension Result {
  var isSuccess: Bool {
    switch self {
      case .success: true
      case .failure: false
    }
  }

  var isFailure: Bool {
    !isSuccess
  }

  var value: Success? {
    switch self {
      case let .success(value): value
      case .failure: nil
    }
  }
}
