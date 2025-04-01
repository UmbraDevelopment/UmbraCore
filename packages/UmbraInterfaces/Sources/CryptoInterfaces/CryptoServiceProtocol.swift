import Foundation

/**
 # Crypto Service Protocol

 Defines cryptographic operations following the Alpha Dot Five architecture.
 
 This protocol provides methods for common cryptographic operations including
 encryption, decryption, key derivation, and secure random generation.
 */
public protocol CryptoServiceProtocol: Sendable {
  /**
   Encrypts data using AES encryption.
   
   This method encrypts the provided data using the specified key and initialisation vector.
   
   - Parameters:
      - data: Data to encrypt
      - key: Encryption key
      - iv: Initialisation vector
      - cryptoOptions: Optional configuration for the encryption operation
   
   - Returns: Encrypted data
   - Throws: CryptoError if encryption fails
   */
  func encrypt(
    _ data: Data, 
    using key: Data, 
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data
  
  /**
   Decrypts data using AES decryption.
   
   This method decrypts the provided data using the specified key and initialisation vector.
   
   - Parameters:
      - data: Data to decrypt
      - key: Decryption key
      - iv: Initialisation vector
      - cryptoOptions: Optional configuration for the decryption operation
   
   - Returns: Decrypted data
   - Throws: CryptoError if decryption fails
   */
  func decrypt(
    _ data: Data, 
    using key: Data, 
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data
  
  /**
   Derives a key from a password using PBKDF2 or other key derivation function.
   
   - Parameters:
      - password: The password to derive the key from
      - salt: Salt for the key derivation
      - iterations: Number of iterations for the key derivation
      - derivationOptions: Optional configuration for the derivation operation
   
   - Returns: The derived key
   - Throws: CryptoError if key derivation fails
   */
  func deriveKey(
    from password: String, 
    salt: Data, 
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data
  
  /**
   Generates a random cryptographic key.
   
   - Parameters:
      - length: Length of the key in bytes
      - keyOptions: Optional configuration for key generation
   
   - Returns: Generated key
   - Throws: CryptoError if key generation fails
   */
  func generateKey(
    length: Int,
    keyOptions: KeyGenerationOptions?
  ) async throws -> Data
  
  /**
   Generates an HMAC for the provided data and key.
   
   - Parameters:
      - data: Data to generate HMAC for
      - key: Key to use for HMAC generation
      - hmacOptions: Optional configuration for HMAC generation
   
   - Returns: Generated HMAC
   - Throws: CryptoError if HMAC generation fails
   */
  func generateHMAC(
    for data: Data, 
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data
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
  public let authenticatedData: Data?
  
  /// Authentication tag length in bits for GCM mode
  public let tagLength: Int?
  
  /// Creates new crypto options
  public init(
    algorithm: Algorithm = .aesGCM,
    authenticatedData: Data? = nil,
    tagLength: Int? = nil
  ) {
    self.algorithm = algorithm
    self.authenticatedData = authenticatedData
    self.tagLength = tagLength
  }
  
  /// Equality comparison for CryptoOptions
  public static func == (lhs: CryptoOptions, rhs: CryptoOptions) -> Bool {
    // Compare the algorithm
    guard lhs.algorithm == rhs.algorithm else {
      return false
    }
    
    // Compare tag length
    guard lhs.tagLength == rhs.tagLength else {
      return false
    }
    
    // Compare authenticated data
    if let lhsData = lhs.authenticatedData, let rhsData = rhs.authenticatedData {
      return lhsData == rhsData
    }
    
    // If one has data and the other doesn't, they're not equal
    // If both are nil, they're equal
    return lhs.authenticatedData == nil && rhs.authenticatedData == nil
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
