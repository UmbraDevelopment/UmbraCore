import CryptoTypes
import CryptoTypesProtocols
import CryptoTypesTypes
import ErrorHandlingDomains
import Foundation
import SecurityTypes
import SecurityUtilsProtocols

/// Service for managing encrypted security-scoped bookmarks
public actor EncryptedBookmarkService {
  private let cryptoService: CryptoServiceProtocol
  private let bookmarkService: SecurityBookmarkService
  private let credentialManager: CryptoTypesProtocols.CredentialManagerProtocol
  private let config: CryptoConfiguration
  private let bookmarkKeyIdentifier="bookmark_encryption_key"

  /// Initialises a new encrypted bookmark service
  /// - Parameters:
  ///   - cryptoService: Service for encryption operations
  ///   - bookmarkService: Service for bookmark operations
  ///   - credentialManager: Manager for secure storage
  ///   - config: Crypto configuration to use
  public init(
    cryptoService: CryptoServiceProtocol,
    bookmarkService: SecurityBookmarkService,
    credentialManager: CryptoTypesProtocols.CredentialManagerProtocol,
    config: CryptoConfiguration = .default
  ) {
    self.cryptoService=cryptoService
    self.bookmarkService=bookmarkService
    self.credentialManager=credentialManager
    self.config=config
  }

  /// Create an encrypted security-scoped bookmark for a URL
  /// - Parameter url: URL to create bookmark for
  /// - Returns: Encrypted bookmark data
  /// - Throws: SecurityError or CryptoError if bookmark creation fails
  public func createBookmark(for url: URL) async throws -> Data {
    let bookmarkData=try await bookmarkService.createBookmark(for: url)
    let key=try await generateKey()
    let iv=try await cryptoService.generateSecureRandomKey(length: config.ivLength)
    return try await cryptoService.encrypt(bookmarkData, using: key, iv: iv)
  }

  /// Resolve an encrypted security-scoped bookmark to a URL
  /// - Parameter encryptedData: Encrypted bookmark data
  /// - Returns: Resolved URL
  /// - Throws: SecurityError or CryptoError if bookmark resolution fails
  public func resolveBookmark(_ encryptedData: Data) async throws -> URL {
    let key=try await getKey()
    // Generate a new IV for decryption - this should be stored with the encrypted data in a real
    // implementation
    let iv=try await cryptoService.generateSecureRandomKey(length: config.ivLength)
    let bookmarkData=try await cryptoService.decrypt(encryptedData, using: key, iv: iv)
    return try await bookmarkService.resolveBookmark(bookmarkData)
  }

  /// Resolve a bookmark stored with an identifier
  /// - Parameter identifier: Identifier of the bookmark
  /// - Returns: Resolved URL
  /// - Throws: SecurityError or CryptoError if bookmark resolution fails
  public func resolveBookmark(withIdentifier identifier: String) async throws -> URL {
    let encryptedData=try await credentialManager.retrieve(forIdentifier: identifier)
    let key=try await getKey()
    // Generate a new IV for decryption - this should be stored with the encrypted data in a real
    // implementation to enable proper decryption
    let ivLen=config.ivLength
    let dataLen=encryptedData.count - ivLen
    let iv=encryptedData.prefix(ivLen)
    let encryptedBookmark=encryptedData.suffix(dataLen)

    let bookmarkData=try await cryptoService.decrypt(encryptedBookmark, using: key, iv: iv)
    return try await bookmarkService.resolveBookmark(bookmarkData)
  }

  /// Store an encrypted bookmark with an identifier
  /// - Parameters:
  ///   - url: URL to create bookmark for
  ///   - identifier: Identifier to store the bookmark under
  /// - Throws: SecurityError or CryptoError if bookmark creation fails
  public func storeBookmark(for url: URL, withIdentifier identifier: String) async throws {
    let encryptedBookmark=try await createBookmark(for: url)
    try await credentialManager.save(encryptedBookmark, forIdentifier: identifier)
  }

  /// Start accessing a security-scoped resource
  /// - Parameter url: URL to access
  /// - Returns: Whether access was started successfully
  public func startAccessing(_ url: URL) async -> Bool {
    url.startAccessingSecurityScopedResource()
  }

  /// Stop accessing a security-scoped resource
  /// - Parameter url: URL to stop accessing
  public func stopAccessing(_ url: URL) async {
    url.stopAccessingSecurityScopedResource()
  }

  private func generateKey() async throws -> Data {
    // Check if key exists
    do {
      return try await getKey()
    } catch {
      // Generate new key if it doesn't exist
      let key=try await cryptoService.generateSecureRandomKey(length: config.keyLength)
      try await credentialManager.save(key, forIdentifier: bookmarkKeyIdentifier)
      return key
    }
  }

  private func getKey() async throws -> Data {
    try await credentialManager.retrieve(forIdentifier: bookmarkKeyIdentifier)
  }
}
