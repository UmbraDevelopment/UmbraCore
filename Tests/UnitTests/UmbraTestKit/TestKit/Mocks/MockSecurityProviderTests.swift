import Core
import ErrorHandling
import ErrorHandlingDomains
import SecurityInterfaces
import SecurityProtocolsCore
import SecurityTypesProtocols
import UmbraCoreTypes
import XCTest

/// A mock security provider for testing
actor TestMockSecurityProvider: SecurityProtocolsCore.SecurityProviderProtocol {
  private var bookmarks: [String: Data]=[:]
  private var accessCount: [String: Int]=[:]
  private var mockedResults: [String: Bool]=[:]
  private var lastAccessedFile: String?

  public nonisolated let cryptoService: CryptoServiceProtocol=MockSecurityCryptoService()
  public nonisolated let keyManager: KeyManagementProtocol=MockKeyManagementService()

  init() {
    // Default initialization
  }

  // MARK: - Test Customization Methods

  /// Set a mocked result for a specific operation
  func setMockedResult(forOperation operation: String, result: Bool) {
    mockedResults[operation]=result
  }

  /// Get the last accessed file path
  func getLastAccessedFile() -> String? {
    lastAccessedFile
  }

  /// Get the number of times a file was accessed
  func getAccessCount(forPath path: String) -> Int {
    accessCount[path] ?? 0
  }

  // MARK: - Bookmark Management

  func createBookmark(forPath path: String) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !bookmarks.keys.contains(path) else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeStorageOperationFailed(message: "Bookmark already exists for path: \(path)")
      )
    }

    let bookmark="test-bookmark-\(path)".data(using: .utf8)!
    bookmarks[path]=bookmark
    return .success(UmbraCoreTypes.SecureBytes(bytes: [UInt8](bookmark)))
  }

  func resolveBookmark(_ bookmarkData: UmbraCoreTypes.SecureBytes) async -> Result<(
    path: String,
    isStale: Bool
  ), ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=Array(bookmarkData)
    let data=Data(bytes)
    let bookmarkString=String(data: data, encoding: .utf8) ?? ""

    guard bookmarkString.hasPrefix("test-bookmark-") else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeStorageOperationFailed(message: "Invalid bookmark format")
      )
    }

    let path=String(bookmarkString.dropFirst("test-bookmark-".count))

    guard bookmarks[path] == data else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeStorageOperationFailed(message: "Bookmark not found for path: \(path)")
      )
    }

    return .success((path, false))
  }

  func startAccessing(path: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    lastAccessedFile=path
    accessCount[path]=(accessCount[path] ?? 0) + 1

    if let mockedResult=mockedResults["startAccessing-\(path)"] {
      return mockedResult ? .success(true) :
        .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(message: "Mocked failure")
        )
    }

    return .success(true)
  }

  func stopAccessing(path: String) async {
    // No need to return anything, just update internal state
    accessCount[path]=(accessCount[path] ?? 0) - 1
    if accessCount[path] == 0 {
      accessCount.removeValue(forKey: path)
    }
  }

  func isPathBeingAccessed(_ path: String) async -> Bool {
    (accessCount[path] ?? 0) > 0
  }

  // MARK: - SecurityProviderProtocol implementation

  func encrypt(
    _ data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decrypt(
    _ data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func encryptData(
    _ data: UmbraCoreTypes.SecureBytes,
    withKey key: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await encrypt(data, key: key)
  }

  func decryptData(
    _ data: UmbraCoreTypes.SecureBytes,
    withKey key: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await decrypt(data, key: key)
  }

  func generateKey(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: Array(repeating: 0, count: length)))
  }

  func generateKey(algorithm _: String, keySizeInBits: Int) async throws -> UmbraCoreTypes
  .SecureBytes {
    UmbraCoreTypes.SecureBytes(bytes: Array(repeating: UInt8(0), count: keySizeInBits / 8))
  }

  func hash(
    _: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: Array(repeating: 0, count: 8)))
  }

  func getSecurityConfig() async
  -> Result<SecurityConfigDTO, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(SecurityConfigDTO(
      algorithm: "AES-256",
      keySizeInBits: 256,
      initializationVector: nil,
      additionalAuthenticatedData: nil,
      iterations: nil,
      options: ["requireAuthentication": "true"],
      keyIdentifier: nil,
      inputData: nil,
      key: nil,
      additionalData: nil
    ))
  }

  func updateSecurityConfig(_: SecurityConfigDTO) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Mock implementation does nothing
    .success(())
  }

  func getHostIdentifier() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success("test-host-id")
  }

  func registerClient(bundleIdentifier _: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  func requestKeyRotation(keyID _: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  func notifyKeyCompromise(keyID _: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  func generateRandomData(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(UmbraCoreTypes.SecureBytes(bytes: Array(repeating: UInt8(0), count: length)))
  }

  func randomBytes(count: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await generateRandomData(length: count)
  }

  nonisolated func getKeyInfo(keyID _: String) async
  -> Result<[String: AnyObject], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(["status": "active" as NSString])
  }

  func registerNotifications() async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  func performSecurityOperation(
    data _: Data?,
    parameters _: [String: String]
  ) async
    -> Result<
      SecurityProtocolsCore.SecurityResult,
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
    >
  {
    // Simply create a successful result
    let result=SecurityProtocolsCore.SecurityResult(success: true)
    return .success(result)
  }

  func performSecurityOperation(
    operation _: String,
    data _: Data?,
    parameters _: [String: String]
  ) async
    -> Result<
      SecurityProtocolsCore.SecurityResult,
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
    >
  {
    // Simply create a successful result without data
    let result=SecurityProtocolsCore.SecurityResult(success: true)
    return .success(result)
  }

  func performSecureOperation(
    operation _: SecurityProtocolsCore.SecurityOperation,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> SecurityProtocolsCore.SecurityResultDTO {
    let emptyBytes=UmbraCoreTypes.SecureBytes(bytes: [])
    return SecurityProtocolsCore.SecurityResultDTO(data: emptyBytes)
  }

  nonisolated func getSecureConfig(options: [String: String]?) -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: "AES-256",
      keySizeInBits: 256,
      initializationVector: nil,
      additionalAuthenticatedData: nil,
      iterations: nil,
      options: options ?? [:],
      keyIdentifier: nil,
      inputData: nil,
      key: nil,
      additionalData: nil
    )
  }

  nonisolated func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO {
    var securityOptions: [String: String]=[:]

    if let options {
      for (key, value) in options {
        if let stringValue=value as? String {
          securityOptions[key]=stringValue
        } else {
          securityOptions[key]=String(describing: value)
        }
      }
    }

    return SecurityConfigDTO(
      algorithm: "AES-256",
      keySizeInBits: 256,
      initializationVector: nil,
      additionalAuthenticatedData: nil,
      iterations: nil,
      options: securityOptions,
      keyIdentifier: nil,
      inputData: nil,
      key: nil,
      additionalData: nil
    )
  }
}

// MARK: - Test Error Types

// Using the shared SecTestError from TestErrors.swift

final class MockSecurityProviderTests: XCTestCase {
  private var provider: TestMockSecurityProvider!

  override func setUp() async throws {
    provider=TestMockSecurityProvider()
  }

  override func tearDown() async throws {
    provider=nil
  }

  func testStartStopAccessing() async throws {
    // Test starting access
    let path="/test/path"
    let result=await provider.startAccessing(path: path)
    XCTAssertEqual(try result.get(), true)

    // Check that the path is being accessed
    let isAccessed=await provider.isPathBeingAccessed(path)
    XCTAssertTrue(isAccessed)

    // Test stopping access
    await provider.stopAccessing(path: path)

    // Check that the path is no longer being accessed
    let isStillAccessed=await provider.isPathBeingAccessed(path)
    XCTAssertFalse(isStillAccessed)
  }

  func testBookmarkCreation() async throws {
    let path="/test/path"
    let result=await provider.createBookmark(forPath: path)

    // Check that bookmark was created successfully
    let bookmark=try result.get()
    XCTAssertGreaterThan(bookmark.count, 0)
  }

  func testBookmarkValidation() async throws {
    // Create valid bookmark
    let path="/test/path"
    let createResult=await provider.createBookmark(forPath: path)

    // Resolve the bookmark
    let bookmark=try createResult.get()
    let resolveResult=await provider.resolveBookmark(bookmark)

    // Check that the path was resolved correctly
    let resolved=try resolveResult.get()
    XCTAssertEqual(resolved.path, path)
    XCTAssertFalse(resolved.isStale)
  }
}
