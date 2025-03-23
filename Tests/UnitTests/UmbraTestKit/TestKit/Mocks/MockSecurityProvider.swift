import CoreTypesInterfaces
import ErrorHandlingDomains
import Foundation
import KeyManagementTypes
@preconcurrency import SecurityInterfaces
import SecurityProtocolsCore
import SecurityTypesProtocols
import UmbraCoreTypes

/// Mock implementation of security provider for testing
public actor MockSecurityProvider: SecurityProtocolsCore.SecurityProviderProtocol {
  private var bookmarks: [String: [UInt8]]
  private var accessedPaths: Set<String>
  private var mockConfiguration: SecurityProtocolsCore.SecurityConfigDTO

  // Required protocol properties
  public nonisolated let cryptoService: CryptoServiceProtocol
  public nonisolated let keyManager: KeyManagementProtocol

  public init() {
    bookmarks=[:]
    accessedPaths=[]
    mockConfiguration=SecurityProtocolsCore.SecurityConfigDTO(
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
    )

    // Initialize the required services
    cryptoService=MockSecurityCryptoService()
    keyManager=MockKeyManagementService()
  }

  // MARK: - SecurityProvider Protocol Implementation

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

  // MARK: - Security Provider Protocol Implementation

  public func startAccessing(path: String) async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !path.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeStorageOperationFailed(message: "Empty path")
      )
    }
    accessedPaths.insert(path)
    return .success(true)
  }

  public func stopAccessing(path: String) async {
    accessedPaths.remove(path)
  }

  public func isPathBeingAccessed(_ path: String) async -> Bool {
    accessedPaths.contains(path)
  }

  public func createBookmark(forPath path: String) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !path.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeStorageOperationFailed(message: "Empty path")
      )
    }

    let bookmarkBytes: [UInt8]=Array(path.utf8)
    bookmarks[path]=bookmarkBytes
    return .success(UmbraCoreTypes.SecureBytes(bytes: bookmarkBytes))
  }

  public func resolveBookmark(_ bookmarkData: UmbraCoreTypes.SecureBytes) async -> Result<(
    path: String,
    isStale: Bool
  ), ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Convert SecureBytes to array for comparison
    var bookmarkBytes=[UInt8]()
    for i in 0..<bookmarkData.count {
      bookmarkBytes.append(bookmarkData[i])
    }

    for (path, storedBytes) in bookmarks {
      var storedBookmarkBytes=[UInt8]()
      for i in 0..<storedBytes.count {
        storedBookmarkBytes.append(storedBytes[i])
      }

      if bookmarkBytes == storedBookmarkBytes {
        return .success((path, false))
      }
    }

    return .failure(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols
        .makeStorageOperationFailed(message: "Bookmark not found")
    )
  }

  // MARK: - Host, Client, Key Operations

  public func getHostIdentifier() async
  -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success("mock-host-identifier")
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

  // MARK: - Encryption and Decryption

  public func encrypt(
    _ data: UmbraCoreTypes.SecureBytes,
    key: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !data.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Empty data")
      )
    }

    guard !key.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Empty key")
      )
    }

    // Simple mock: just return the same data
    return .success(data)
  }

  public func decrypt(
    _ data: UmbraCoreTypes.SecureBytes,
    key: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !data.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Empty data")
      )
    }

    guard !key.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Empty key")
      )
    }

    // Simple mock: just return the same data
    return .success(data)
  }

  public func encryptData(
    _ data: UmbraCoreTypes.SecureBytes,
    withKey key: UmbraCoreTypes.SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await encrypt(data, key: key)
  }

  public func decryptData(
    _ data: UmbraCoreTypes.SecureBytes,
    withKey key: UmbraCoreTypes.SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await decrypt(data, key: key)
  }

  // MARK: - Hash Functions

  public func hash(
    _ data: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !data.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Empty data")
      )
    }

    // Simple mock: just return first 8 bytes repeated
    let sampleBytes=Array(data.prefix(8))
    let hash=sampleBytes + sampleBytes + sampleBytes + sampleBytes
    return .success(UmbraCoreTypes.SecureBytes(bytes: hash))
  }

  // MARK: - Random Data Generation

  public func generateRandomData(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard length > 0 else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Invalid length")
      )
    }

    // Simple mock: just return zeros
    let data=Array(repeating: UInt8(0), count: length)
    return .success(UmbraCoreTypes.SecureBytes(bytes: data))
  }

  // Helper method that throws
  private func generateRandomDataThrowing(length: Int) async throws -> UmbraCoreTypes.SecureBytes {
    let result=await generateRandomData(length: length)
    switch result {
      case let .success(data):
        return data
      case let .failure(error):
        throw error
    }
  }

  public func randomBytes(count: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await generateRandomData(length: count)
  }

  // Helper method that throws
  private func randomBytesThrowing(count: Int) async throws -> UmbraCoreTypes.SecureBytes {
    let result=await randomBytes(count: count)
    switch result {
      case let .success(data):
        return data
      case let .failure(error):
        throw error
    }
  }

  public func generateKey(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=await generateRandomData(length: length)
    switch result {
      case let .success(data):
        return .success(data)
      case let .failure(error):
        return .failure(error)
    }
  }

  public func generateKey(algorithm _: String, keySizeInBits: Int) async throws -> UmbraCoreTypes
  .SecureBytes {
    let bytesLength=keySizeInBits / 8
    let result=await generateRandomData(length: bytesLength)
    switch result {
      case let .success(data):
        return data
      case let .failure(error):
        throw error
    }
  }

  public nonisolated func getKeyInfo(keyID: String) async
  -> Result<[String: AnyObject], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    guard !keyID.isEmpty else {
      return .failure(
        ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .makeServiceError(message: "Empty key ID")
      )
    }

    let info: [String: AnyObject]=[
      "keyId": keyID as NSString,
      "algorithm": "AES256" as NSString,
      "status": "active" as NSString,
      "created": Date() as NSDate
    ]

    return .success(info)
  }

  public func registerNotifications() async
  -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    .success(())
  }

  // MARK: - Operation Execution

  public func performSecurityOperation(
    operation _: String,
    data _: [UInt8]?,
    parameters _: [String: String]
  ) async
  -> Result<MockSecurityOperationResult, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=MockSecurityOperationResult(success: true, data: nil)
    return .success(result)
  }

  public func performSecureOperation(
    operation _: SecurityProtocolsCore.SecurityOperation,
    config _: SecurityProtocolsCore.SecurityConfigDTO
  ) async -> SecurityProtocolsCore.SecurityResultDTO {
    // Simple mock implementation
    let emptyBytes=UmbraCoreTypes.SecureBytes(bytes: [])
    return SecurityProtocolsCore.SecurityResultDTO(data: emptyBytes)
  }

  public nonisolated func createSecureConfig(options: [String: Any]?) -> SecurityProtocolsCore
  .SecurityConfigDTO {
    SecurityProtocolsCore.SecurityConfigDTO(
      algorithm: options?["algorithm"] as? String ?? "AES-256",
      keySizeInBits: options?["keySize"] as? Int ?? 256,
      initializationVector: nil,
      additionalAuthenticatedData: nil,
      iterations: nil,
      options: options?["parameters"] as? [String: String] ?? [:],
      keyIdentifier: nil,
      inputData: nil,
      key: nil,
      additionalData: nil
    )
  }

  public nonisolated func getSecureConfig(options: [String: String]?) -> SecurityConfigDTO {
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
}

/// Security operation result
public struct MockSecurityOperationResult: Sendable {
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

/// A mock crypto service implementation for testing
final class MockSecurityCryptoService: CryptoServiceProtocol {
  func encrypt(data: Data, keyID _: String, options _: [String: String]?) -> Data {
    data
  }

  func decrypt(data: Data, keyID _: String, options _: [String: String]?) -> Data {
    data
  }

  func generateKey(algorithm _: String, options _: [String: String]?) -> String {
    "test-key-\(UUID().uuidString)"
  }

  func hash(data _: Data, algorithm _: String) -> Data {
    Data(repeating: 0, count: 32)
  }

  // Protocol methods implementation
  func encrypt(
    data: UmbraCoreTypes.SecureBytes,
    using _: UmbraCoreTypes
      .SecureBytes
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decrypt(
    data: UmbraCoreTypes.SecureBytes,
    using _: UmbraCoreTypes
      .SecureBytes
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func generateKey() async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  func generateKey(
    algorithm _: String,
    length: Int
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: length)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  func hashData(
    _: UmbraCoreTypes.SecureBytes,
    algorithm _: String
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  func hash(
    data _: UmbraCoreTypes
      .SecureBytes
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  func verify(
    data _: UmbraCoreTypes.SecureBytes,
    against _: UmbraCoreTypes.SecureBytes
  ) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    .success(true)
  }

  func encryptSymmetric(
    data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes.SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decryptSymmetric(
    data: UmbraCoreTypes.SecureBytes,
    key _: UmbraCoreTypes.SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func encryptAsymmetric(
    data: UmbraCoreTypes.SecureBytes,
    publicKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func decryptAsymmetric(
    data: UmbraCoreTypes.SecureBytes,
    privateKey _: UmbraCoreTypes.SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .success(data)
  }

  func hash(
    data _: UmbraCoreTypes.SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  func generateRandomData(length: Int) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: length)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }
}

@preconcurrency
final class MockKeyManagementService: KeyManagementProtocol, @unchecked Sendable {
  private var storedKeys: [String: UmbraCoreTypes.SecureBytes]=[:]

  // Implementing KeyManagementProtocol

  func retrieveKey(withIdentifier identifier: String) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    guard let key=storedKeys[identifier] else {
      return .failure(
        UmbraErrors.Security.Protocols
          .makeServiceError(message: "Key not found: \(identifier)")
      )
    }
    return .success(key)
  }

  func storeKey(
    _ key: UmbraCoreTypes.SecureBytes,
    withIdentifier identifier: String
  ) async -> Result<Void, UmbraErrors.Security.Protocols> {
    storedKeys[identifier]=key
    return .success(())
  }

  func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, UmbraErrors.Security.Protocols> {
    guard storedKeys.removeValue(forKey: identifier) != nil else {
      return .failure(
        UmbraErrors.Security.Protocols
          .makeServiceError(message: "Key not found: \(identifier)")
      )
    }
    return .success(())
  }

  func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: UmbraCoreTypes.SecureBytes?
  ) async -> Result<(
    newKey: UmbraCoreTypes.SecureBytes,
    reencryptedData: UmbraCoreTypes.SecureBytes?
  ), UmbraErrors.Security.Protocols> {
    guard storedKeys[identifier] != nil else {
      return .failure(
        UmbraErrors.Security.Protocols
          .makeServiceError(message: "Key not found: \(identifier)")
      )
    }

    // Generate a new key
    let newKey=UmbraCoreTypes.SecureBytes(bytes: Array(repeating: UInt8(0), count: 32))

    // Store the new key with the same identifier
    storedKeys[identifier]=newKey

    // If data was provided, "reencrypt" it (in this mock, we're just returning it as-is)
    let reencryptedData=dataToReencrypt

    return .success((newKey: newKey, reencryptedData: reencryptedData))
  }

  func listKeyIdentifiers() async -> Result<[String], UmbraErrors.Security.Protocols> {
    .success(Array(storedKeys.keys))
  }

  // These are the old methods which can still be used by other code

  func createKey(algorithm _: String, options _: [String: String]?) -> String {
    "test-key-\(UUID().uuidString)"
  }

  func getKey(_ keyID: String) -> UmbraCoreTypes.SecureBytes? {
    storedKeys[keyID]
  }

  func deleteKey(_ keyID: String) -> Bool {
    storedKeys.removeValue(forKey: keyID) != nil
  }

  func storeKey(_ key: UmbraCoreTypes.SecureBytes, keyID: String) -> Bool {
    storedKeys[keyID]=key
    return true
  }

  func updateKeyStatus(keyID _: String, status _: KeyStatus) -> Bool {
    true
  }

  func getKeyStatus(keyID _: String) -> KeyStatus {
    .active
  }

  func listKeys() -> [String] {
    Array(storedKeys.keys)
  }

  func generateKey(algorithm _: String, options _: [String: String]?) async -> String {
    "test-key-\(UUID().uuidString)"
  }

  func createEncryptionKey() async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let bytes=Array(repeating: UInt8(0), count: 32)
    return .success(UmbraCoreTypes.SecureBytes(bytes: bytes))
  }

  func getAllKeys() async -> Result<[String], UmbraErrors.Security.Protocols> {
    .success(Array(storedKeys.keys))
  }

  func getKeyData(_ keyID: String) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    guard let key=storedKeys[keyID] else {
      return .failure(
        UmbraErrors.Security.Protocols
          .makeServiceError(message: "Key not found: \(keyID)")
      )
    }
    return .success(key)
  }

  func rotateKey(_ keyID: String) async -> Result<String, UmbraErrors.Security.Protocols> {
    guard storedKeys[keyID] != nil else {
      return .failure(
        UmbraErrors.Security.Protocols
          .makeServiceError(message: "Key not found: \(keyID)")
      )
    }
    let newKeyID="rotated-\(keyID)"
    let bytes=Array(repeating: UInt8(0), count: 32)
    storedKeys[newKeyID]=UmbraCoreTypes.SecureBytes(bytes: bytes)
    return .success(newKeyID)
  }

  func setKeyCompromised(_ keyID: String) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    guard storedKeys[keyID] != nil else {
      return .failure(
        UmbraErrors.Security.Protocols
          .makeServiceError(message: "Key not found: \(keyID)")
      )
    }
    return .success(true)
  }

  func keysMatchingPolicy(_: String) async -> Result<[String], UmbraErrors.Security.Protocols> {
    .success(Array(storedKeys.keys))
  }
}
