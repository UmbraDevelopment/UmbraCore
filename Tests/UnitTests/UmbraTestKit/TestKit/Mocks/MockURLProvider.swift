import Core
import ErrorHandlingDomains
import Foundation
@preconcurrency import SecurityInterfaces
import SecurityProtocolsCore
import SecurityTypes
import SecurityTypesProtocols
import UmbraCoreTypes

/// Mock implementation of URL security provider
@preconcurrency
public actor MockURLProvider: SecurityProtocolsCore.SecurityProviderProtocol, @unchecked Sendable {
  private var bookmarks: [String: [UInt8]]=[:]
  private var accessedPaths: Set<String>=[]
  private var contents: [String: String]=[:]
  private var mockConfiguration=SecurityProtocolsCore.SecurityConfigDTO(
    algorithm: "AES-256",
    keySizeInBits: 256,
    options: ["level": "advanced"]
  )

  // Properties marked as nonisolated to satisfy protocol requirements
  public nonisolated var cryptoService: CryptoServiceProtocol {
    MockCryptoService()
  }

  public nonisolated var keyManager: KeyManagementProtocol {
    MockKeyManagementService()
  }

  public init() {}

  // MARK: - URL Bookmark Methods

  public func createBookmark(forPath path: String) async throws -> [UInt8] {
    guard !bookmarks.keys.contains(path) else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Bookmark already exists for path: \(path)")
    }
    let bookmark=Array("mock-bookmark-\(path)".utf8)
    bookmarks[path]=bookmark
    return bookmark
  }

  public func resolveBookmark(_ bookmark: [UInt8]) async throws -> (path: String, isStale: Bool) {
    let bookmarkString=String(bytes: bookmark, encoding: .utf8) ?? ""
    guard bookmarkString.hasPrefix("mock-bookmark-") else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Invalid bookmark format")
    }
    let path=String(bookmarkString.dropFirst("mock-bookmark-".count))
    guard bookmarks[path] == bookmark else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Bookmark not found for path: \(path)")
    }
    accessedPaths.insert(path)
    return (path: path, isStale: false)
  }

  public func startAccessing(path: String) async -> Bool {
    accessedPaths.insert(path)
    return true
  }

  public func stopAccessing(path: String) async {
    accessedPaths.remove(path)
  }

  public func isPathBeingAccessed(_ path: String) async -> Bool {
    accessedPaths.contains(path)
  }

  public func createDirectory(at path: String) async throws {
    contents[path]="directory"
  }

  public func withSecurityScopedAccess<T: Sendable>(
    to path: String,
    perform operation: @Sendable () async throws -> T
  ) async throws -> T {
    let granted=await startAccessing(path: path)
    guard granted else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Failed to access \(path)")
    }
    defer { Task { await stopAccessing(path: path) } }
    return try await operation()
  }

  // MARK: - Bookmark Storage

  public func loadBookmark(withIdentifier identifier: String) async throws -> [UInt8] {
    guard let bookmarkData=bookmarks[identifier] else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Bookmark not found for identifier: \(identifier)")
    }
    return bookmarkData
  }

  public func deleteBookmark(withIdentifier identifier: String) async throws {
    guard bookmarks.removeValue(forKey: identifier) != nil else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Bookmark not found for identifier: \(identifier)")
    }
  }

  // MARK: - File and Directory Methods

  public func saveData(_ data: [UInt8], to path: String) async throws {
    let content=String(bytes: data, encoding: .utf8) ?? "binary content"
    contents[path]=content
  }

  public func readData(from path: String) async throws -> [UInt8] {
    guard let content=contents[path] else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No content found at path: \(path)")
    }
    guard let data=content.data(using: .utf8) else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Failed to encode content as data")
    }
    return [UInt8](data)
  }

  public func deleteFile(at path: String) async throws {
    guard contents.removeValue(forKey: path) != nil else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "No file found at path: \(path)")
    }
  }

  // MARK: - Configuration Methods

  public func getSecurityConfig() async
    -> Result<
      SecurityProtocolsCore.SecurityConfigDTO,
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
    >
  {
    .success(mockConfiguration)
  }

  public func updateSecurityConfig(
    _ configuration: SecurityProtocolsCore
      .SecurityConfigDTO
  ) async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    mockConfiguration=configuration
    return .success(())
  }

  // MARK: - Host and Client Methods

  public func getHostIdentifier() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success("mock-url-provider-host")
  }

  public func registerClient(bundleIdentifier _: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(true)
  }

  public func requestKeyRotation(keyID _: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  public func notifyKeyCompromise(keyID _: String) async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  // MARK: - Encryption Methods

  public func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    guard !key.isEmpty else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeServiceError(message: "Empty encryption key")
    }

    var result=[UInt8](repeating: 0, count: data.count)
    for i in 0..<data.count {
      let keyByte=key[i % key.count]
      let dataByte=data[i]
      result[i]=dataByte ^ keyByte
    }

    return result
  }

  public func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // XOR is symmetric, so encryption and decryption are the same operation
    try await encrypt(data, key: key)
  }

  public func generateKey(length: Int) async throws -> [UInt8] {
    guard length > 0 else {
      throw ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeServiceError(message: "Invalid key length")
    }

    // Simple mock implementation - not cryptographically secure
    var key=[UInt8](repeating: 0, count: length)
    for i in 0..<length {
      key[i]=UInt8.random(in: 0...255)
    }
    return key
  }

  // MARK: - Required SecurityProviderProtocol Methods

  public nonisolated func performSecureOperation(
    operation _: SecurityProtocolsCore.SecurityOperation,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> SecurityProtocolsCore.SecurityResultDTO {
    // Simple implementation that always succeeds
    SecurityProtocolsCore.SecurityResultDTO.success()
  }

  public nonisolated func createSecureConfig(options: [String: Any]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    var configOptions: [String: String]=[:]
    options?.forEach { key, value in
      configOptions[key]=String(describing: value)
    }

    return SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: "AES-256",
      keySizeInBits: 256,
      options: configOptions
    )
  }

  public func generateRandomData(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let bytes=[UInt8](repeating: 0, count: length)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  @preconcurrency
  public nonisolated func getKeyInfo(keyID _: String) async
  -> Result<[String: AnyObject], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(["status": "active" as NSString])
  }

  public func registerNotifications() async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  public func performSecurityOperation(
    operation _: String,
    data _: [UInt8]?,
    parameters _: [String: String]
  ) async -> Result<SecurityOperationResult, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=SecurityOperationResult(success: true, data: nil)
    return .success(result)
  }
}

// MARK: - Security Operation Result

/// Result of a security operation
public struct SecurityOperationResult: Sendable {
  /// Whether the operation succeeded
  public let success: Bool

  /// Result data, if any
  public let data: [UInt8]?

  /// Create a new security operation result
  public init(success: Bool, data: [UInt8]?) {
    self.success=success
    self.data=data
  }
}
