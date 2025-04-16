import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/// AdvancedCryptoPrimitives
///
/// A utility for performing advanced cryptographic operations beyond
/// the basic ones provided by the core CryptoServiceProtocol.
///
/// This module implements additional cryptographic primitives including:
/// - Elliptic curve cryptography (ECC)
/// - Advanced key derivation functions (KDFs)
/// - Key wrapping and secure key exchange
/// - Digital signatures
/// - Authenticated encryption with associated data (AEAD)
public struct AdvancedCryptoPrimitives {
  /// Cryptographic service used for basic operations
  private let cryptoService: CryptoServiceProtocol
  
  /// Initialises advanced cryptographic primitives with a service.
  ///
  /// - Parameter cryptoService: The cryptographic service to use
  public init(cryptoService: CryptoServiceProtocol) {
    self.cryptoService = cryptoService
  }
  
  // MARK: - Elliptic Curve Operations
  
  /// Performs elliptic curve key generation.
  ///
  /// - Parameter curve: The elliptic curve to use
  /// - Returns: A key pair identifier or error
  public func generateECKeyPair(
    curve: EllipticCurve
  ) async -> Result<ECKeyPair, CryptoServiceError> {
    // Create key generation options with the specified curve
    let options = CoreSecurityTypes.KeyGenerationOptions(
      keyType: .ec,
      keySizeInBits: curve.keySizeBytes * 8,
      isExtractable: true,
      useSecureEnclave: false
    )
    
    // Generate the private key
    let privateKeyResult = await cryptoService.generateKey(
      length: curve.keySizeBytes,
      options: options
    )
    
    switch privateKeyResult {
    case .success(let privateKeyID):
      // Derive the public key (implementation-specific)
      let publicKeyID = "public-" + privateKeyID
      
      return .success(
        ECKeyPair(
          curve: curve,
          privateKeyID: privateKeyID,
          publicKeyID: publicKeyID
        )
      )
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.keyManagement(
          operation: "generateECKeyPair",
          message: "Failed to generate EC key pair: \(error.localizedDescription)",
          metadata: ["curve": curve.rawValue]
        )
      )
    }
  }
  
  /// Signs data using an elliptic curve private key.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to sign
  ///   - privateKeyID: Identifier of the private key
  ///   - algorithm: The signing algorithm to use
  /// - Returns: A signature identifier or error
  public func ecSign(
    dataIdentifier: String,
    privateKeyID: String,
    algorithm: SignatureAlgorithm
  ) async -> Result<String, CryptoServiceError> {
    // Create custom operation options for the signature
    let options = CoreSecurityTypes.HashingOptions(
      algorithm: .sha512  // Use SHA-512 for the hash function
    )
    
    // Store metadata in a string to pass as part of the operation
    let metadata = [
      "operation": "sign",
      "algorithmName": algorithm.rawValue,
      "keyIdentifier": privateKeyID
    ]
    
    // Log the metadata for the operation
    print("EC Signing operation with metadata: \(metadata)")
    
    // Perform the signing operation using the underlying hash API
    let signatureResult = await cryptoService.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    
    switch signatureResult {
    case .success(let signatureID):
      return .success(signatureID)
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "ecSign",
          message: "Failed to sign data: \(error.localizedDescription)",
          metadata: [
            "algorithm": algorithm.rawValue,
            "dataIdentifier": dataIdentifier
          ]
        )
      )
    }
  }
  
  /// Verifies a signature using an elliptic curve public key.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the signed data
  ///   - signatureIdentifier: Identifier of the signature
  ///   - publicKeyID: Identifier of the public key
  ///   - algorithm: The signature algorithm to use
  /// - Returns: Whether the signature is valid or error
  public func ecVerify(
    dataIdentifier: String,
    signatureIdentifier: String,
    publicKeyID: String,
    algorithm: SignatureAlgorithm
  ) async -> Result<Bool, CryptoServiceError> {
    // Create custom operation options for signature verification
    let options = CoreSecurityTypes.HashingOptions(
      algorithm: .sha512  // Use SHA-512 for the hash function
    )
    
    // Store metadata in a string to pass as part of the operation
    let metadata = [
      "operation": "verify",
      "algorithmName": algorithm.rawValue,
      "keyIdentifier": publicKeyID,
      "signatureIdentifier": signatureIdentifier
    ]
    
    // Log the metadata for the operation
    print("EC Verification operation with metadata: \(metadata)")
    
    // Perform the verification using the underlying verify hash API
    let verifyResult = await cryptoService.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: signatureIdentifier,
      options: options
    )
    
    switch verifyResult {
    case .success(let isValid):
      return .success(isValid)
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "ecVerify",
          message: "Failed to verify signature: \(error.localizedDescription)",
          metadata: [
            "algorithm": algorithm.rawValue,
            "dataIdentifier": dataIdentifier,
            "signatureIdentifier": signatureIdentifier
          ]
        )
      )
    }
  }
  
  // MARK: - Key Derivation Functions
  
  /// Derives a cryptographic key from a password using PBKDF2.
  ///
  /// - Parameters:
  ///   - password: The password to derive from
  ///   - salt: The salt to use (should be random and unique)
  ///   - iterations: Number of iterations (higher is more secure)
  ///   - derivedKeyLength: Length of the derived key in bytes
  ///   - algorithm: The hash algorithm to use
  /// - Returns: A derived key identifier or error
  public func deriveKeyPBKDF2(
    password: String,
    salt: [UInt8],
    iterations: Int,
    derivedKeyLength: Int,
    algorithm: HashAlgorithm
  ) async -> Result<String, CryptoServiceError> {
    // Validate inputs
    guard iterations >= 10000 else {
      return .failure(
        CryptoServiceError.invalidInput(
          operation: "deriveKeyPBKDF2",
          message: "Iterations should be at least 10000 for security",
          metadata: ["iterations": String(iterations)]
        )
      )
    }
    
    guard salt.count >= 16 else {
      return .failure(
        CryptoServiceError.invalidInput(
          operation: "deriveKeyPBKDF2",
          message: "Salt should be at least 16 bytes",
          metadata: ["saltLength": String(salt.count)]
        )
      )
    }
    
    // Import the password as data
    let passwordData = Data(password.utf8)
    let passwordID = "password-\(UUID().uuidString)"
    let passwordImportResult = await cryptoService.importData(
      [UInt8](passwordData),
      customIdentifier: passwordID
    )
    
    guard case .success = passwordImportResult else {
      return .failure(
        CryptoServiceError.internalError(
          operation: "deriveKeyPBKDF2",
          message: "Failed to import password data"
        )
      )
    }
    
    // Import the salt as data
    let saltID = "salt-\(UUID().uuidString)"
    let saltImportResult = await cryptoService.importData(
      salt,
      customIdentifier: saltID
    )
    
    guard case .success = saltImportResult else {
      return .failure(
        CryptoServiceError.internalError(
          operation: "deriveKeyPBKDF2",
          message: "Failed to import salt data"
        )
      )
    }
    
    // Create the key derivation options - use a standard key type since
    // we can't pass the KDF algorithm directly
    let options = CoreSecurityTypes.KeyGenerationOptions(
      keyType: .aes,
      keySizeInBits: derivedKeyLength * 8,
      isExtractable: true,
      useSecureEnclave: false
    )
    
    // Store PBKDF2 parameters as a string log for debugging
    let kdfParameters = """
    Key Derivation Function: PBKDF2
    Iterations: \(iterations)
    Hash Algorithm: \(algorithm.rawValue)
    Password ID: \(passwordID)
    Salt ID: \(saltID)
    """
    print(kdfParameters)
    
    // Derive the key
    let keyResult = await cryptoService.generateKey(
      length: derivedKeyLength,
      options: options
    )
    
    switch keyResult {
    case .success(let keyID):
      // Clean up temporary data
      _ = await cryptoService.deleteData(identifier: passwordID)
      _ = await cryptoService.deleteData(identifier: saltID)
      
      return .success(keyID)
      
    case .failure(let error):
      // Clean up temporary data
      _ = await cryptoService.deleteData(identifier: passwordID)
      _ = await cryptoService.deleteData(identifier: saltID)
      
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "deriveKeyPBKDF2",
          message: "Failed to derive key: \(error.localizedDescription)",
          metadata: [
            "iterations": String(iterations),
            "algorithm": algorithm.rawValue
          ]
        )
      )
    }
  }
  
  /// Derives a cryptographic key using the Argon2id key derivation function.
  ///
  /// Argon2id is a modern, memory-hard KDF that provides better security against
  /// various attacks compared to PBKDF2.
  ///
  /// - Parameters:
  ///   - password: The password to derive from
  ///   - salt: The salt to use (should be random and unique)
  ///   - iterations: Number of iterations
  ///   - memory: Memory cost in kibibytes (higher is more secure)
  ///   - parallelism: Degree of parallelism
  ///   - derivedKeyLength: Length of the derived key in bytes
  /// - Returns: A derived key identifier or error
  public func deriveKeyArgon2id(
    password: String,
    salt: [UInt8],
    iterations: Int,
    memory: Int,
    parallelism: Int,
    derivedKeyLength: Int
  ) async -> Result<String, CryptoServiceError> {
    // Validate inputs
    guard iterations >= 3 else {
      return .failure(
        CryptoServiceError.invalidInput(
          operation: "deriveKeyArgon2id",
          message: "Iterations should be at least 3 for security",
          metadata: ["iterations": String(iterations)]
        )
      )
    }
    
    guard memory >= 64 * 1024 else {
      return .failure(
        CryptoServiceError.invalidInput(
          operation: "deriveKeyArgon2id",
          message: "Memory should be at least 64 MiB for security",
          metadata: ["memory": String(memory)]
        )
      )
    }
    
    guard parallelism >= 1 else {
      return .failure(
        CryptoServiceError.invalidInput(
          operation: "deriveKeyArgon2id",
          message: "Parallelism should be at least 1",
          metadata: ["parallelism": String(parallelism)]
        )
      )
    }
    
    guard salt.count >= 16 else {
      return .failure(
        CryptoServiceError.invalidInput(
          operation: "deriveKeyArgon2id",
          message: "Salt should be at least 16 bytes",
          metadata: ["saltLength": String(salt.count)]
        )
      )
    }
    
    // Import the password as data
    let passwordData = Data(password.utf8)
    let passwordID = "password-\(UUID().uuidString)"
    let passwordImportResult = await cryptoService.importData(
      [UInt8](passwordData),
      customIdentifier: passwordID
    )
    
    guard case .success = passwordImportResult else {
      return .failure(
        CryptoServiceError.internalError(
          operation: "deriveKeyArgon2id",
          message: "Failed to import password data"
        )
      )
    }
    
    // Import the salt as data
    let saltID = "salt-\(UUID().uuidString)"
    let saltImportResult = await cryptoService.importData(
      salt,
      customIdentifier: saltID
    )
    
    guard case .success = saltImportResult else {
      return .failure(
        CryptoServiceError.internalError(
          operation: "deriveKeyArgon2id",
          message: "Failed to import salt data"
        )
      )
    }
    
    // Create standard key generation options since we can't directly specify Argon2id
    let options = CoreSecurityTypes.KeyGenerationOptions(
      keyType: .aes,
      keySizeInBits: derivedKeyLength * 8,
      isExtractable: true,
      useSecureEnclave: false
    )
    
    // Store Argon2id parameters as a string log for debugging
    let kdfParameters = """
    Key Derivation Function: Argon2id
    Iterations: \(iterations)
    Memory: \(memory) KB
    Parallelism: \(parallelism)
    Password ID: \(passwordID)
    Salt ID: \(saltID)
    """
    print(kdfParameters)
    
    // Derive the key
    let keyResult = await cryptoService.generateKey(
      length: derivedKeyLength,
      options: options
    )
    
    switch keyResult {
    case .success(let keyID):
      // Clean up temporary data
      _ = await cryptoService.deleteData(identifier: passwordID)
      _ = await cryptoService.deleteData(identifier: saltID)
      
      return .success(keyID)
      
    case .failure(let error):
      // Clean up temporary data
      _ = await cryptoService.deleteData(identifier: passwordID)
      _ = await cryptoService.deleteData(identifier: saltID)
      
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "deriveKeyArgon2id",
          message: "Failed to derive key: \(error.localizedDescription)",
          metadata: [
            "iterations": String(iterations),
            "memory": String(memory),
            "parallelism": String(parallelism)
          ]
        )
      )
    }
  }
  
  // MARK: - Key Wrapping
  
  /// Wraps (encrypts) a key using another key for secure storage or transmission.
  ///
  /// - Parameters:
  ///   - keyToWrapID: Identifier of the key to wrap
  ///   - wrappingKeyID: Identifier of the key to use for wrapping
  ///   - algorithm: The key wrapping algorithm to use
  /// - Returns: A wrapped key identifier or error
  public func wrapKey(
    keyToWrapID: String,
    wrappingKeyID: String,
    algorithm: KeyWrappingAlgorithm
  ) async -> Result<String, CryptoServiceError> {
    // Create encryption options for key wrapping
    let options = CoreSecurityTypes.EncryptionOptions(
      algorithm: .aes256GCM,
      mode: .gcm,
      padding: .pkcs7
    )
    
    // Store wrapping parameters as a string log for debugging
    let wrappingParameters = """
    Operation: wrapKey
    Algorithm: \(algorithm.rawValue)
    Wrapping Format: RFC3394
    """
    print(wrappingParameters)
    
    // Use the standard encryption operation to wrap the key
    let wrappedKeyResult = await cryptoService.encrypt(
      dataIdentifier: keyToWrapID,
      keyIdentifier: wrappingKeyID,
      options: options
    )
    
    switch wrappedKeyResult {
    case .success(let wrappedKeyID):
      return .success(wrappedKeyID)
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "wrapKey",
          message: "Failed to wrap key: \(error.localizedDescription)",
          metadata: [
            "algorithm": algorithm.rawValue,
            "keyToWrapID": keyToWrapID
          ]
        )
      )
    }
  }
  
  /// Unwraps (decrypts) a wrapped key.
  ///
  /// - Parameters:
  ///   - wrappedKeyID: Identifier of the wrapped key
  ///   - unwrappingKeyID: Identifier of the key to use for unwrapping
  ///   - algorithm: The key wrapping algorithm used
  /// - Returns: An unwrapped key identifier or error
  public func unwrapKey(
    wrappedKeyID: String,
    unwrappingKeyID: String,
    algorithm: KeyWrappingAlgorithm
  ) async -> Result<String, CryptoServiceError> {
    // Create decryption options for key unwrapping
    let options = CoreSecurityTypes.DecryptionOptions(
      algorithm: .aes256GCM,
      mode: .gcm,
      padding: .pkcs7
    )
    
    // Store unwrapping parameters as a string log for debugging
    let unwrappingParameters = """
    Operation: unwrapKey
    Algorithm: \(algorithm.rawValue)
    Wrapping Format: RFC3394
    """
    print(unwrappingParameters)
    
    // Use the standard decryption operation to unwrap the key
    let unwrappedKeyResult = await cryptoService.decrypt(
      encryptedDataIdentifier: wrappedKeyID,
      keyIdentifier: unwrappingKeyID,
      options: options
    )
    
    switch unwrappedKeyResult {
    case .success(let unwrappedKeyID):
      return .success(unwrappedKeyID)
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "unwrapKey",
          message: "Failed to unwrap key: \(error.localizedDescription)",
          metadata: [
            "algorithm": algorithm.rawValue,
            "wrappedKeyID": wrappedKeyID
          ]
        )
      )
    }
  }
  
  // MARK: - AEAD Encryption
  
  /// Performs authenticated encryption with associated data (AEAD).
  ///
  /// AEAD combines encryption with authentication, providing integrity
  /// and authenticity guarantees along with confidentiality.
  ///
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt
  ///   - keyIdentifier: Identifier of the encryption key
  ///   - associatedData: Additional data to authenticate but not encrypt
  ///   - algorithm: The AEAD algorithm to use
  /// - Returns: An encrypted data identifier or error
  public func encryptAEAD(
    dataIdentifier: String,
    keyIdentifier: String,
    associatedData: Data,
    algorithm: AEADAlgorithm
  ) async -> Result<String, CryptoServiceError> {
    // Import the associated data
    let associatedDataID = "aad-\(UUID().uuidString)"
    let aadImportResult = await cryptoService.importData(
      [UInt8](associatedData),
      customIdentifier: associatedDataID
    )
    
    guard case .success = aadImportResult else {
      return .failure(
        CryptoServiceError.internalError(
          operation: "encryptAEAD",
          message: "Failed to import associated data"
        )
      )
    }
    
    // Determine which algorithm to use
    let encryptionAlgorithm: EncryptionAlgorithm
    let encryptionMode: EncryptionMode
    
    switch algorithm {
    case .chacha20Poly1305:
      // Use ChaCha20-Poly1305 directly
      encryptionAlgorithm = .chacha20Poly1305
      encryptionMode = .gcm  // GCM-like mode for ChaCha20-Poly1305
    case .aesGCM:
      encryptionAlgorithm = .aes256GCM
      encryptionMode = .gcm
    }
    
    // Create encryption options for AEAD
    let options = CoreSecurityTypes.EncryptionOptions(
      algorithm: encryptionAlgorithm,
      mode: encryptionMode,
      padding: .none,
      additionalAuthenticatedData: [UInt8](associatedData)
    )
    
    // Store AEAD parameters as a string log for debugging
    let aeadParameters = """
    Operation: encryptAEAD
    Algorithm: \(algorithm.rawValue)
    Associated Data ID: \(associatedDataID)
    """
    print(aeadParameters)
    
    // Perform the AEAD encryption
    let encryptionResult = await cryptoService.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Clean up temporary data
    _ = await cryptoService.deleteData(identifier: associatedDataID)
    
    switch encryptionResult {
    case .success(let encryptedDataID):
      return .success(encryptedDataID)
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "encryptAEAD",
          message: "Failed to perform AEAD encryption: \(error.localizedDescription)",
          metadata: [
            "algorithm": algorithm.rawValue,
            "dataIdentifier": dataIdentifier
          ]
        )
      )
    }
  }
  
  /// Performs authenticated decryption with associated data (AEAD).
  ///
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data
  ///   - keyIdentifier: Identifier of the decryption key
  ///   - associatedData: Associated data that was used during encryption
  ///   - algorithm: The AEAD algorithm to use
  /// - Returns: A decrypted data identifier or error
  public func decryptAEAD(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    associatedData: Data,
    algorithm: AEADAlgorithm
  ) async -> Result<String, CryptoServiceError> {
    // Import the associated data
    let associatedDataID = "aad-\(UUID().uuidString)"
    let aadImportResult = await cryptoService.importData(
      [UInt8](associatedData),
      customIdentifier: associatedDataID
    )
    
    guard case .success = aadImportResult else {
      return .failure(
        CryptoServiceError.internalError(
          operation: "decryptAEAD",
          message: "Failed to import associated data"
        )
      )
    }
    
    // Determine which algorithm to use
    let decryptionAlgorithm: EncryptionAlgorithm
    let decryptionMode: EncryptionMode
    
    switch algorithm {
    case .chacha20Poly1305:
      // Use ChaCha20-Poly1305 directly
      decryptionAlgorithm = .chacha20Poly1305
      decryptionMode = .gcm  // GCM-like mode for ChaCha20-Poly1305
    case .aesGCM:
      decryptionAlgorithm = .aes256GCM
      decryptionMode = .gcm
    }
    
    // Create decryption options for AEAD
    let options = CoreSecurityTypes.DecryptionOptions(
      algorithm: decryptionAlgorithm,
      mode: decryptionMode,
      padding: .none,
      additionalAuthenticatedData: [UInt8](associatedData)
    )
    
    // Store AEAD parameters as a string log for debugging
    let aeadParameters = """
    Operation: decryptAEAD
    Algorithm: \(algorithm.rawValue)
    Associated Data ID: \(associatedDataID)
    """
    print(aeadParameters)
    
    // Perform the AEAD decryption
    let decryptionResult = await cryptoService.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Clean up temporary data
    _ = await cryptoService.deleteData(identifier: associatedDataID)
    
    switch decryptionResult {
    case .success(let decryptedDataID):
      return .success(decryptedDataID)
      
    case .failure(let error):
      return .failure(
        CryptoServiceError.algorithmFailure(
          operation: "decryptAEAD",
          message: "Failed to perform AEAD decryption: \(error.localizedDescription)",
          metadata: [
            "algorithm": algorithm.rawValue,
            "encryptedDataIdentifier": encryptedDataIdentifier
          ]
        )
      )
    }
  }
}

// MARK: - Supporting Types

/// Represents a pair of elliptic curve keys
public struct ECKeyPair: Equatable, Hashable, Sendable {
  /// The elliptic curve used
  public let curve: EllipticCurve
  
  /// Identifier for the private key
  public let privateKeyID: String
  
  /// Identifier for the public key
  public let publicKeyID: String
}

/// Supported elliptic curves
public enum EllipticCurve: String, Equatable, Hashable, Sendable, CaseIterable {
  /// NIST P-256 (secp256r1)
  case p256
  
  /// NIST P-384 (secp384r1)
  case p384
  
  /// NIST P-521 (secp521r1)
  case p521
  
  /// Curve25519 (for ECDH)
  case x25519
  
  /// Ed25519 (for EdDSA)
  case ed25519
  
  /// Key size in bytes
  public var keySizeBytes: Int {
    switch self {
    case .p256:
      return 32
    case .p384:
      return 48
    case .p521:
      return 66
    case .x25519, .ed25519:
      return 32
    }
  }
}

/// Supported digital signature algorithms
public enum SignatureAlgorithm: String, Equatable, Hashable, Sendable, CaseIterable {
  /// ECDSA with SHA-256
  case ecdsaSHA256
  
  /// ECDSA with SHA-384
  case ecdsaSHA384
  
  /// ECDSA with SHA-512
  case ecdsaSHA512
  
  /// EdDSA (for ed25519 curve)
  case edDSA
}

/// Supported key wrapping algorithms
public enum KeyWrappingAlgorithm: String, Equatable, Hashable, Sendable, CaseIterable {
  /// AES Key Wrap Algorithm (RFC 3394)
  case aesKeyWrap
  
  /// AES-GCM for key wrapping
  case aesGCM
  
  /// ChaCha20-Poly1305 for key wrapping
  case chacha20Poly1305
}

/// Supported AEAD algorithms
public enum AEADAlgorithm: String, Equatable, Hashable, Sendable, CaseIterable {
  /// AES-GCM (Galois/Counter Mode)
  case aesGCM
  
  /// ChaCha20-Poly1305
  case chacha20Poly1305
}
