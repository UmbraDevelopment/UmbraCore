import DomainSecurityTypes

/**
 # Crypto Service Protocol

 Defines the core cryptographic operations required by the system.
 This protocol ensures a standard interface for all cryptographic
 service implementations, providing:

 - Secure encryption and decryption
 - Password-based key derivation
 - Secure random key generation
 - Message authentication

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety:

 ```swift
 actor CryptoServiceImpl: CryptoServiceProtocol {
     // Private state should be isolated within the actor
     private let securityProvider: SecurityProviderProtocol
     private let logger: PrivacyAwareLoggingProtocol
     
     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class CryptoService: CryptoServiceProtocol {
     private let actor: CryptoServiceActor
     
     // Forward all protocol methods to the actor
     public func encrypt(...) async throws -> SecureBytes {
         try await actor.encrypt(...)
     }
 }
 ```

 ## Privacy Considerations

 Cryptographic operations involve highly sensitive data. Implementations must:
 - Never log keys, passwords, or other sensitive cryptographic material
 - Use privacy-aware logging for operation contexts
 - Ensure secure memory handling for all cryptographic materials
 - Properly zeroize memory after operations complete
 */
public protocol CryptoServiceProtocol: Sendable {
  /**
   Encrypts data using AES encryption.

   This method encrypts the provided data using the specified key and initialisation vector.
   The implementation must ensure data confidentiality and integrity.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - iv: Initialisation vector
     - cryptoOptions: Optional additional encryption configuration options
   - Returns: Encrypted data as SecureBytes
   - Throws: CryptoError if encryption fails
   */
  func encrypt(
    _ data: SecureBytes, 
    using key: SecureBytes, 
    iv: SecureBytes,
    cryptoOptions: CryptoOptions?
  ) async throws -> SecureBytes

  /**
   Decrypts data using AES encryption.

   This method decrypts the provided data using the specified key and initialisation vector.
   The implementation must verify data integrity before returning decrypted content.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - iv: Initialisation vector
     - cryptoOptions: Optional additional decryption configuration options
   - Returns: Decrypted data as SecureBytes
   - Throws: CryptoError if decryption fails or authentication fails
   */
  func decrypt(
    _ data: SecureBytes, 
    using key: SecureBytes, 
    iv: SecureBytes,
    cryptoOptions: CryptoOptions?
  ) async throws -> SecureBytes

  /**
   Derives a key from a password using PBKDF2.

   This method performs key derivation to transform a user password into a cryptographic key
   using a secure key derivation function with the provided salt and iteration count.

   - Parameters:
     - password: Password to derive key from
     - salt: Salt for key derivation
     - iterations: Number of iterations for key derivation (higher is more secure)
     - derivationOptions: Optional additional key derivation configuration options
   - Returns: Derived key as SecureBytes
   - Throws: CryptoError if key derivation fails
   */
  func deriveKey(
    from password: String, 
    salt: SecureBytes, 
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> SecureBytes

  /**
   Generates a cryptographically secure random key.

   This method creates a random key using a cryptographically secure random number generator
   with sufficient entropy to ensure key security.

   - Parameters:
     - length: Length of the key in bytes
     - keyOptions: Optional additional key generation configuration options
   - Returns: The generated key as SecureBytes
   - Throws: CryptoError if key generation fails
   */
  func generateSecureRandomKey(
    length: Int,
    keyOptions: KeyGenerationOptions?
  ) async throws -> SecureBytes

  /**
   Generates a message authentication code (HMAC) using SHA-256.

   This method creates an authentication code for the provided data using the specified key,
   which can be used to verify data integrity and authenticity.

   - Parameters:
     - data: Data to authenticate
     - key: The authentication key
     - hmacOptions: Optional additional HMAC configuration options
   - Returns: The authentication code as SecureBytes
   - Throws: CryptoError if HMAC generation fails
   */
  func generateHMAC(
    for data: SecureBytes, 
    using key: SecureBytes,
    hmacOptions: HMACOptions?
  ) async throws -> SecureBytes
}

/**
 Configuration options for cryptographic operations.
 
 These options allow customization of the encryption or decryption process.
 */
public struct CryptoOptions: Sendable, Equatable {
  /// Encryption algorithm to use
  public enum Algorithm: String, Sendable, Equatable {
    /// AES with Galois/Counter Mode
    case aesGCM
    /// AES with Cipher Block Chaining
    case aesCBC
    /// ChaCha20-Poly1305
    case chaCha20Poly1305
  }
  
  /// Encryption algorithm
  public let algorithm: Algorithm
  
  /// Additional authenticated data for AEAD ciphers
  public let authenticatedData: SecureBytes?
  
  /// Authentication tag length in bits for GCM mode
  public let tagLength: Int?
  
  /// Creates new crypto options
  public init(
    algorithm: Algorithm = .aesGCM,
    authenticatedData: SecureBytes? = nil,
    tagLength: Int? = nil
  ) {
    self.algorithm = algorithm
    self.authenticatedData = authenticatedData
    self.tagLength = tagLength
  }
}

/**
 Configuration options for key derivation operations.
 
 These options allow customization of the key derivation process.
 */
public struct KeyDerivationOptions: Sendable, Equatable {
  /// Key derivation function to use
  public enum KeyDerivationFunction: String, Sendable, Equatable {
    /// PBKDF2 with HMAC-SHA256
    case pbkdf2
    /// Argon2id
    case argon2id
    /// Scrypt
    case scrypt
  }
  
  /// Key derivation function
  public let function: KeyDerivationFunction
  
  /// Output key length in bytes
  public let outputKeyLength: Int
  
  /// Memory cost parameter (for memory-hard functions)
  public let memoryCost: Int?
  
  /// Parallelism parameter (for functions supporting parallelism)
  public let parallelism: Int?
  
  /// Creates new key derivation options
  public init(
    function: KeyDerivationFunction = .pbkdf2,
    outputKeyLength: Int = 32,
    memoryCost: Int? = nil,
    parallelism: Int? = nil
  ) {
    self.function = function
    self.outputKeyLength = outputKeyLength
    self.memoryCost = memoryCost
    self.parallelism = parallelism
  }
}

/**
 Configuration options for key generation operations.
 
 These options allow customization of the key generation process.
 */
public struct KeyGenerationOptions: Sendable, Equatable {
  /// Key purpose
  public enum KeyPurpose: String, Sendable, Equatable {
    /// Encryption key
    case encryption
    /// Authentication key
    case authentication
    /// Signing key
    case signing
    /// Master key
    case master
  }
  
  /// Purpose of the generated key
  public let purpose: KeyPurpose
  
  /// Whether to persist the generated key
  public let persistKey: Bool
  
  /// Key identifier for persistence
  public let keyIdentifier: String?
  
  /// Creates new key generation options
  public init(
    purpose: KeyPurpose = .encryption,
    persistKey: Bool = false,
    keyIdentifier: String? = nil
  ) {
    self.purpose = purpose
    self.persistKey = persistKey
    self.keyIdentifier = keyIdentifier
  }
}

/**
 Configuration options for HMAC operations.
 
 These options allow customization of the HMAC generation process.
 */
public struct HMACOptions: Sendable, Equatable {
  /// Hash algorithm to use for HMAC
  public enum HashAlgorithm: String, Sendable, Equatable {
    /// SHA-256
    case sha256
    /// SHA-384
    case sha384
    /// SHA-512
    case sha512
  }
  
  /// Hash algorithm
  public let algorithm: HashAlgorithm
  
  /// Output truncation length in bytes (if applicable)
  public let truncateLength: Int?
  
  /// Creates new HMAC options
  public init(
    algorithm: HashAlgorithm = .sha256,
    truncateLength: Int? = nil
  ) {
    self.algorithm = algorithm
    self.truncateLength = truncateLength
  }
}
