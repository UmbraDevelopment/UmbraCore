import Foundation
import UmbraCoreTypes

/// Security configuration data transfer object
/// Used to configure security operations with specific options
public struct SecurityConfigDTO: Sendable, Equatable {
  /// Algorithm to use for cryptographic operations
  public enum Algorithm: String, Sendable, Equatable {
    /// AES algorithm
    case aes = "AES"
    /// RSA algorithm
    case rsa = "RSA"
    /// ChaCha20 algorithm
    case chacha20 = "ChaCha20"
  }
  
  /// Mode of operation for block ciphers
  public enum Mode: String, Sendable, Equatable {
    /// Galois/Counter Mode
    case gcm = "GCM"
    /// Cipher Block Chaining
    case cbc = "CBC"
    /// Counter Mode
    case ctr = "CTR"
  }
  
  /// Key size in bits
  public let keySize: Int
  
  /// Algorithm to use
  public let algorithm: Algorithm
  
  /// Mode of operation (for block ciphers)
  public let mode: Mode?
  
  /// Hash algorithm for hashing operations
  public let hashAlgorithm: HashAlgorithm
  
  /// Authentication data (for authenticated encryption modes)
  public let authenticationData: SecureBytes?
  
  /// Additional options as key-value pairs
  public let options: [String: String]
  
  /// Initialise with configuration options
  /// - Parameters:
  ///   - keySize: Key size in bits (default: 256)
  ///   - algorithm: Algorithm to use (default: .aes)
  ///   - mode: Mode of operation (default: .gcm)
  ///   - hashAlgorithm: Hash algorithm (default: .sha256)
  ///   - authenticationData: Authentication data (default: nil)
  ///   - options: Additional options (default: empty dictionary)
  public init(
    keySize: Int = 256,
    algorithm: Algorithm = .aes,
    mode: Mode? = .gcm,
    hashAlgorithm: HashAlgorithm = .sha256,
    authenticationData: SecureBytes? = nil,
    options: [String: String] = [:]
  ) {
    self.keySize = keySize
    self.algorithm = algorithm
    self.mode = mode
    self.hashAlgorithm = hashAlgorithm
    self.authenticationData = authenticationData
    self.options = options
  }
  
  /// Create a copy with modified options
  /// - Parameter options: New options to apply
  /// - Returns: A new configuration with updated options
  public func withOptions(_ options: [String: String]) -> SecurityConfigDTO {
    SecurityConfigDTO(
      keySize: self.keySize,
      algorithm: self.algorithm,
      mode: self.mode,
      hashAlgorithm: self.hashAlgorithm,
      authenticationData: self.authenticationData,
      options: options
    )
  }
}
