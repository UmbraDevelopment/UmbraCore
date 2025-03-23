import Foundation

/// A generic result type for security operations
public enum SecurityResult<Success> {
  /// Operation succeeded with the associated value
  case success(Success)
  /// Operation failed with the associated error
  case failure(Error)
}

/// Protocol defining the core requirements for security service providers
/// This represents the base functionality that all security providers must implement
public protocol CoreProvider: Sendable {
  /// The unique identifier for this provider
  var providerID: String { get }

  /// A human-readable name for this provider
  var providerName: String { get }

  /// The version of this provider
  var providerVersion: String { get }

  /// Check if this provider is available and ready to use
  /// - Returns: True if the provider is available and ready
  func isAvailable() async -> Bool

  /// Reset the provider to its initial state
  /// - Returns: Result indicating success or failure with error
  func reset() async -> SecurityResult<Void>

  /// Get capabilities supported by this provider
  /// - Returns: List of capability identifiers
  func getCapabilities() async -> [String]
}

/// Capability identifiers for common security provider capabilities
public enum CoreCapability {
  /// Provider supports encryption operations
  public static let encryption="encryption"

  /// Provider supports decryption operations
  public static let decryption="decryption"

  /// Provider supports key generation
  public static let keyGeneration="key.generation"

  /// Provider supports key storage
  public static let keyStorage="key.storage"

  /// Provider supports random number generation
  public static let randomGeneration="random.generation"

  /// Provider supports hashing operations
  public static let hashing="hashing"

  /// Provider supports message authentication
  public static let messageAuthentication="message.authentication"

  /// Provider supports secure storage
  public static let secureStorage="secure.storage"
}
