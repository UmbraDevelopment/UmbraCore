import CommonCrypto
import UmbraErrors
import UmbraErrorsCore

import CoreServicesTypes
import Foundation
import FoundationBridgeTypes
import SecurityBridge
import SecurityBridgeTypes
import SecurityInterfacesProtocols
import SecurityProtocolsCore
import SecurityUtils
import UmbraCoreTypes
import UmbraLogging
import XPCProtocolsCore

/// Protocol for random data generation capabilities
protocol RandomDataGenerating {
  func generateRandomDouble() -> Double
  func generateRandomBytes(count: Int) -> [UInt8]
  func generateSecureToken(byteCount: Int) -> String
}

/// Simple protocol for bookmark services to break dependency cycles
protocol BookmarkServiceType {
  func createBookmark(for url: URL) throws -> [UInt8]
  func resolveBookmark(_ bookmark: [UInt8]) throws -> (URL, Bool)
  func startAccess(to url: URL) throws -> Bool
  func stopAccess(to url: URL) throws
}

/// Main implementation of the security service
///
/// This class provides cryptographic services and bookmark management
/// using Foundation-based implementations.
@available(macOS 12.0, *)
@MainActor
public final class SecurityService {
  /// Shared instance of the security service
  public static let shared=SecurityService()

  // Dependencies
  private let securityProvider: DefaultSecurityProviderImpl
  private let bookmarkService: BookmarkServiceType

  /// Initialise the service
  public init() {
    bookmarkService=DefaultBookmarkService()
    securityProvider=DefaultSecurityProviderImpl()
    print("SecurityService initialised with DefaultBookmarkService")
  }

  /// Create a security-scoped bookmark for a URL
  /// - Parameter path: The path to create a bookmark for
  /// - Returns: Bookmark data as bytes
  public func createBookmark(for path: String) async throws -> [UInt8] {
    let url=URL(fileURLWithPath: path)
    return try bookmarkService.createBookmark(for: url)
  }

  /// Resolve a security-scoped bookmark
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: The resolved URL and whether the bookmark is stale
  public func resolveBookmark(_ bookmarkData: [UInt8]) async throws -> (String, Bool) {
    let (url, isStale)=try bookmarkService.resolveBookmark(bookmarkData)
    return (url.path, isStale)
  }

  /// Start accessing a security-scoped resource
  /// - Parameter path: The path to the security-scoped resource
  /// - Returns: Whether access was granted
  public func startAccess(to path: String) async throws -> Bool {
    let url=URL(fileURLWithPath: path)
    return try bookmarkService.startAccess(to: url)
  }

  /// Stop accessing a security-scoped resource
  /// - Parameter path: The path to the security-scoped resource
  public func stopAccess(to path: String) async throws {
    let url=URL(fileURLWithPath: path)
    try bookmarkService.stopAccess(to: url)
  }

  /// Generate a random number between 0.0 and 1.0
  /// - Returns: Random double value
  public func generateRandomDouble() -> Double {
    securityProvider.generateRandomDouble()
  }

  /// Generate random bytes
  /// - Parameter count: Number of bytes to generate
  /// - Returns: Random bytes
  public func generateRandomBytes(count: Int) -> [UInt8] {
    securityProvider.generateRandomBytes(count: count)
  }

  /// Generate a secure random token as a hexadecimal string
  /// - Parameter byteCount: Number of bytes (before hex encoding)
  /// - Returns: Hexadecimal string
  public func generateSecureToken(byteCount: Int) -> String {
    securityProvider.generateSecureToken(byteCount: byteCount)
  }

  /// Perform key derivation
  /// - Parameters:
  ///   - password: The password to derive from
  ///   - salt: Salt value
  ///   - rounds: Number of PBKDF2 rounds
  ///   - derivedKeyLength: Desired key length in bytes
  /// - Returns: Derived key bytes
  public func deriveKey(
    from password: String,
    salt: [UInt8],
    rounds: UInt32,
    derivedKeyLength: Int
  ) async throws -> [UInt8] {
    try await securityProvider.deriveKey(
      from: password,
      salt: salt,
      rounds: rounds,
      derivedKeyLength: derivedKeyLength
    )
  }

  /// Encrypt data using a key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  public func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    try await securityProvider.encrypt(data, key: key)
  }

  /// Decrypt data using a key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  public func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    try await securityProvider.decrypt(data, key: key)
  }

  /// Compute a hash for data
  /// - Parameter data: Input data
  /// - Returns: Hash value
  public func hashData(_ data: [UInt8]) async throws -> [UInt8] {
    try await securityProvider.hashData(data)
  }
}

/// Default implementation of the security provider
private final class DefaultSecurityProviderImpl: NSObject, RandomDataGenerating {
  // MARK: - Properties

  /// Random data generator
  private let randomGenerator: RandomDataGenerator

  // MARK: - Initialization

  override init() {
    randomGenerator=RandomDataGenerator()
    super.init()
    // Setup can be done here if needed
  }

  // MARK: - Random Generation Methods

  /// Generate a random number between 0.0 and 1.0
  /// - Returns: Random double value
  func generateRandomDouble() -> Double {
    randomGenerator.generateRandomDouble()
  }

  /// Generate random bytes
  /// - Parameter count: Number of bytes to generate
  /// - Returns: Random bytes
  func generateRandomBytes(count: Int) -> [UInt8] {
    randomGenerator.generateRandomBytes(count: count)
  }

  /// Generate a secure random token as a hexadecimal string
  /// - Parameter byteCount: Number of bytes (before hex encoding)
  /// - Returns: Hexadecimal string
  func generateSecureToken(byteCount: Int) -> String {
    randomGenerator.generateSecureToken(byteCount: byteCount)
  }

  // MARK: - Cryptographic Operations

  /// Perform key derivation
  /// - Parameters:
  ///   - password: The password to derive from
  ///   - salt: Salt value
  ///   - rounds: Number of PBKDF2 rounds
  ///   - derivedKeyLength: Desired key length in bytes
  /// - Returns: Derived key bytes
  func deriveKey(
    from password: String,
    salt: [UInt8],
    rounds: UInt32,
    derivedKeyLength: Int
  ) async throws -> [UInt8] {
    // Convert salt to Data
    let saltData=Data(salt)

    // Use CommonCrypto for key derivation
    guard let passwordData=password.data(using: .utf8) else {
      throw UmbraErrors.Security.Core.internalError(reason: "Failed to convert password to data")
    }

    var derivedKeyData=Data(count: derivedKeyLength)

    let derivationStatus=derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
      passwordData.withUnsafeBytes { passwordBytes in
        saltData.withUnsafeBytes { saltBytes in
          CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes.baseAddress, passwordData.count,
            saltBytes.baseAddress, saltData.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            rounds,
            derivedKeyBytes.baseAddress, derivedKeyLength
          )
        }
      }
    }

    guard derivationStatus == kCCSuccess else {
      throw UmbraErrors.Security.Core
        .internalError(reason: "PBKDF2 derivation failed with code \(derivationStatus)")
    }

    return [UInt8](derivedKeyData)
  }

  /// Encrypt data using a key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // Implementation using CommonCrypto
    let keyData=Data(key)

    // Prepare for encryption
    var encryptedData=Data(count: data.count + kCCBlockSizeAES128)
    var encryptedDataLength=0

    let result=keyData.withUnsafeBytes { keyBytes in
      encryptedData.withUnsafeMutableBytes { encryptedBytes in
        CCCrypt(
          CCOperation(kCCEncrypt),
          CCAlgorithm(kCCAlgorithmAES),
          CCOptions(kCCOptionPKCS7Padding),
          keyBytes.baseAddress, min(keyBytes.count, kCCKeySizeAES256),
          nil, // IV - should use a proper IV in production
          data, data.count,
          encryptedBytes.baseAddress, encryptedBytes.count,
          &encryptedDataLength
        )
      }
    }

    guard result == kCCSuccess else {
      throw UmbraErrors.Security.Core
        .encryptionFailed(reason: "Encryption failed with code \(result)")
    }

    // Resize to actual encrypted data length
    encryptedData.count=encryptedDataLength

    return [UInt8](encryptedData)
  }

  /// Decrypt data using a key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    // Implementation using CommonCrypto
    let keyData=Data(key)

    // Prepare for decryption
    var decryptedData=Data(count: data.count + kCCBlockSizeAES128)
    var decryptedDataLength=0

    let result=keyData.withUnsafeBytes { keyBytes in
      decryptedData.withUnsafeMutableBytes { decryptedBytes in
        CCCrypt(
          CCOperation(kCCDecrypt),
          CCAlgorithm(kCCAlgorithmAES),
          CCOptions(kCCOptionPKCS7Padding),
          keyBytes.baseAddress, min(keyBytes.count, kCCKeySizeAES256),
          nil as UnsafeRawPointer?, // IV - should use a proper IV in production
          data, data.count,
          decryptedBytes.baseAddress, decryptedBytes.count,
          &decryptedDataLength
        )
      }
    }

    guard result == kCCSuccess else {
      throw UmbraErrors.Security.Core
        .decryptionFailed(reason: "Decryption failed with code \(result)")
    }

    // Resize to actual decrypted data length
    decryptedData.count=decryptedDataLength

    return [UInt8](decryptedData)
  }

  /// Compute a hash for data
  /// - Parameter data: Input data
  /// - Returns: Hash value
  func hashData(_ data: [UInt8]) async throws -> [UInt8] {
    // Implementation using CommonCrypto
    // Use SHA-256 hash
    var hashData=Data(count: Int(CC_SHA256_DIGEST_LENGTH))

    _=hashData.withUnsafeMutableBytes { hashBytes in
      CC_SHA256(
        data,
        CC_LONG(data.count),
        hashBytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
      )
    }

    return [UInt8](hashData)
  }
}

/// Implementation of random data generation
private class RandomDataGenerator {
  /// Generate a random number between 0.0 and 1.0
  /// - Returns: Random double value
  func generateRandomDouble() -> Double {
    Double.random(in: 0...1)
  }

  /// Generate random bytes
  /// - Parameter count: Number of bytes to generate
  /// - Returns: Random bytes
  func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: count)
    let status=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    guard status == errSecSuccess else {
      // Fallback to less secure method if SecRandomCopyBytes fails
      return (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
    }
    return bytes
  }

  /// Generate a secure random token as a hexadecimal string
  /// - Parameter byteCount: Number of bytes (before hex encoding)
  /// - Returns: Hexadecimal string
  func generateSecureToken(byteCount: Int) -> String {
    let bytes=generateRandomBytes(count: byteCount)
    return bytes.map { String(format: "%02hhx", $0) }.joined()
  }
}

/// Default implementation of the bookmark service
private final class DefaultBookmarkService: BookmarkServiceType {
  func createBookmark(for url: URL) throws -> [UInt8] {
    let bookmark=try url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
    return Array(bookmark)
  }

  func resolveBookmark(_ bookmark: [UInt8]) throws -> (URL, Bool) {
    let bookmarkData=Data(bookmark)
    var isStale=false
    let url=try URL(
      resolvingBookmarkData: bookmarkData,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &isStale
    )
    return (url, isStale)
  }

  func startAccess(to url: URL) throws -> Bool {
    let granted=url.startAccessingSecurityScopedResource()
    if !granted {
      throw UmbraErrors.Security.Core.internalError(reason: "Access not granted to \(url.path)")
    }
    return granted
  }

  func stopAccess(to url: URL) throws {
    url.stopAccessingSecurityScopedResource()
  }
}
