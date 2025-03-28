import Foundation

/// Protocol for providing security-related operations
public protocol SecurityProvider: Sendable {
  /// Create a security-scoped bookmark for a URL
  /// - Parameter url: The URL to create a bookmark for
  /// - Returns: The bookmark data
  /// - Throws: Error if bookmark creation fails
  func createSecurityBookmark(for url: URL) async throws -> Data

  /// Resolve a security-scoped bookmark to a URL
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: The resolved URL
  /// - Throws: Error if bookmark resolution fails
  func resolveSecurityBookmark(_ bookmarkData: Data) async throws -> URL

  /// Start accessing a security-scoped resource
  /// - Parameter path: Path to the resource
  /// - Returns: True if access was granted
  /// - Throws: Error if access cannot be granted
  func startAccessing(path: String) async throws -> Bool

  /// Stop accessing a security-scoped resource
  /// - Parameter path: Path to the resource
  func stopAccessing(path: String) async

  /// Stop accessing all security-scoped resources
  func stopAccessingAllResources() async

  /// Check if a security-scoped resource is being accessed
  /// - Parameter path: Path to the resource
  /// - Returns: True if the resource is being accessed
  func isAccessing(path: String) async -> Bool

  /// Get all paths that are currently being accessed
  /// - Returns: Set of paths that are currently being accessed
  func getAccessedPaths() async -> Set<String>

  /// Perform an operation with security-scoped access to a resource
  /// - Parameters:
  ///   - path: Path to the resource
  ///   - operation: Operation to perform while resource is accessible
  /// - Returns: Result of the operation
  /// - Throws: Error if access cannot be granted or operation fails
  func withSecurityScopedAccess<T>(
    to path: String,
    perform operation: @Sendable () async throws -> T
  ) async throws -> T

  /// Encrypt data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - algorithm: Encryption algorithm to use
  /// - Returns: Encrypted data result
  /// - Throws: Security error if encryption fails
  func encrypt(
    _ data: Data,
    using algorithm: String
  ) async -> Result<Data, SecurityErrorDTO>

  /// Decrypt data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - algorithm: Decryption algorithm to use
  /// - Returns: Decrypted data result
  /// - Throws: Security error if decryption fails
  func decrypt(
    _ data: Data,
    using algorithm: String
  ) async -> Result<Data, SecurityErrorDTO>

  /// Generate a cryptographic hash for data
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Hash algorithm to use
  /// - Returns: Hash result
  func hash(
    _ data: Data,
    using algorithm: HashAlgorithm
  ) async -> Result<Data, SecurityErrorDTO>
}
