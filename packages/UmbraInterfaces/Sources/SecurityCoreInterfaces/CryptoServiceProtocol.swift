import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import UmbraErrors

/// Protocol defining cryptographic service operations in a Foundation-independent manner.
/// All operations use Result types for proper error handling and follow the Alpha Dot Five architecture principles.
public protocol CryptoServiceProtocol: Sendable {
  /// The secure storage used for handling sensitive data
  var secureStorage: SecureStorageProtocol { get }

  /// Encrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
  ///   - keyIdentifier: Identifier of the encryption key in secure storage.
  ///   - options: Optional encryption configuration.
  /// - Returns: Identifier for the encrypted data in secure storage, or an error.
  func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError>

  /// Decrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
  ///   - keyIdentifier: Identifier of the decryption key in secure storage.
  ///   - options: Optional decryption configuration.
  /// - Returns: Identifier for the decrypted data in secure storage, or an error.
  func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError>

  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityProtocolError>

  /// Verifies a cryptographic hash against the expected value, both stored securely.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError>
  
  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Imports data into secure storage for use with cryptographic operations.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is generated.
  /// - Returns: The identifier for the data in secure storage, or an error.
  func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  /// - Warning: Use with caution as this exposes sensitive data.
  func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError>
}

/// Configuration options for encryption.
public struct EncryptionOptions: Sendable {
  /// The encryption algorithm to use.
  public let algorithm: EncryptionAlgorithm
  
  /// Optional authenticated data for AEAD algorithms.
  public let authenticatedData: [UInt8]?
  
  /// Initialises encryption options with defaults.
  public init(
    algorithm: EncryptionAlgorithm = .aes256CBC,
    authenticatedData: [UInt8]? = nil
  ) {
    self.algorithm = algorithm
    self.authenticatedData = authenticatedData
  }
}

/// Configuration options for decryption.
public struct DecryptionOptions: Sendable {
  /// The decryption algorithm to use.
  public let algorithm: EncryptionAlgorithm
  
  /// Optional authenticated data for AEAD algorithms.
  public let authenticatedData: [UInt8]?
  
  /// Initialises decryption options with defaults.
  public init(
    algorithm: EncryptionAlgorithm = .aes256CBC,
    authenticatedData: [UInt8]? = nil
  ) {
    self.algorithm = algorithm
    self.authenticatedData = authenticatedData
  }
}

/// Configuration options for hashing.
public struct HashingOptions: Sendable {
  /// The hash algorithm to use.
  public let algorithm: HashAlgorithm
  
  /// Initialises hashing options with defaults.
  public init(algorithm: HashAlgorithm = .sha256) {
    self.algorithm = algorithm
  }
}

/// Configuration options for key generation.
public struct KeyGenerationOptions: Sendable {
  /// Whether to store the key in long-term persistent storage.
  public let persistent: Bool
  
  /// The key type to generate.
  public let keyType: KeyType
  
  /// Initialises key generation options with defaults.
  public init(persistent: Bool = true, keyType: KeyType = .symmetric) {
    self.persistent = persistent
    self.keyType = keyType
  }
}

/// Supported encryption algorithms.
public enum EncryptionAlgorithm: UInt8, Sendable {
  case aes256CBC = 0
  case aes256GCM = 1
  case chaCha20Poly1305 = 2
}

/// Supported hash algorithms.
public enum HashAlgorithm: UInt8, Sendable {
  case sha256 = 0
  case sha384 = 1
  case sha512 = 2
  case blake2b = 3
}

/// Supported key types.
public enum KeyType: UInt8, Sendable {
  case symmetric = 0
  case asymmetric = 1
  case hmac = 2
}

/// Data transfer object for cryptographic operations.
/// Used for passing cryptographic functions between processes.
public struct CryptoServiceDto: Sendable {
  /// Type alias for encrypt function
  public typealias EncryptFunction = @Sendable (
    String, String, EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Type alias for decrypt function
  public typealias DecryptFunction = @Sendable (
    String, String, DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Type alias for hash function
  public typealias HashFunction = @Sendable (
    String, HashingOptions?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Type alias for verify hash function
  public typealias VerifyHashFunction = @Sendable (
    String, String, HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError>
  
  /// Type alias for generate key function
  public typealias GenerateKeyFunction = @Sendable (
    Int, KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Type alias for import data function
  public typealias ImportDataFunction = @Sendable (
    [UInt8], String?
  ) async -> Result<String, SecurityProtocolError>
  
  /// Type alias for export data function
  public typealias ExportDataFunction = @Sendable (
    String
  ) async -> Result<[UInt8], SecurityProtocolError>
  
  /// The secure storage for this DTO
  public let secureStorage: SecureStorageProtocol
  
  /// Function to encrypt data
  public let encrypt: EncryptFunction
  
  /// Function to decrypt data
  public let decrypt: DecryptFunction
  
  /// Function to hash data
  public let hash: HashFunction
  
  /// Function to verify hash
  public let verifyHash: VerifyHashFunction
  
  /// Function to generate key
  public let generateKey: GenerateKeyFunction
  
  /// Function to import data
  public let importData: ImportDataFunction
  
  /// Function to export data
  public let exportData: ExportDataFunction
  
  /// Initialises a new DTO from the given functions
  public init(
    secureStorage: SecureStorageProtocol,
    encrypt: @escaping EncryptFunction,
    decrypt: @escaping DecryptFunction,
    hash: @escaping HashFunction,
    verifyHash: @escaping VerifyHashFunction,
    generateKey: @escaping GenerateKeyFunction,
    importData: @escaping ImportDataFunction,
    exportData: @escaping ExportDataFunction
  ) {
    self.secureStorage = secureStorage
    self.encrypt = encrypt
    self.decrypt = decrypt
    self.hash = hash
    self.verifyHash = verifyHash
    self.generateKey = generateKey
    self.importData = importData
    self.exportData = exportData
  }
}

extension CryptoServiceDto {
  /// Converts this DTO to a CryptoServiceProtocol implementation
  /// - Returns: A CryptoServiceProtocol instance
  public func toProtocol() -> some CryptoServiceProtocol {
    struct ProtocolAdapter: CryptoServiceProtocol {
      let dto: CryptoServiceDto
      
      var secureStorage: SecureStorageProtocol { dto.secureStorage }
      
      func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: EncryptionOptions?
      ) async -> Result<String, SecurityProtocolError> {
        await dto.encrypt(dataIdentifier, keyIdentifier, options)
      }
      
      func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: DecryptionOptions?
      ) async -> Result<String, SecurityProtocolError> {
        await dto.decrypt(encryptedDataIdentifier, keyIdentifier, options)
      }
      
      func hash(
        dataIdentifier: String,
        options: HashingOptions?
      ) async -> Result<String, SecurityProtocolError> {
        await dto.hash(dataIdentifier, options)
      }
      
      func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: HashingOptions?
      ) async -> Result<Bool, SecurityProtocolError> {
        await dto.verifyHash(dataIdentifier, hashIdentifier, options)
      }
      
      func generateKey(
        length: Int,
        options: KeyGenerationOptions?
      ) async -> Result<String, SecurityProtocolError> {
        await dto.generateKey(length, options)
      }
      
      func importData(
        _ data: [UInt8],
        customIdentifier: String?
      ) async -> Result<String, SecurityProtocolError> {
        await dto.importData(data, customIdentifier)
      }
      
      func exportData(
        identifier: String
      ) async -> Result<[UInt8], SecurityProtocolError> {
        await dto.exportData(identifier)
      }
    }
    
    return ProtocolAdapter(dto: self)
  }
}
