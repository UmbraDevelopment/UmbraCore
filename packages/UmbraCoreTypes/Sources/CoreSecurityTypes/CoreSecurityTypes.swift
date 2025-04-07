/**
 # CoreSecurityTypes Module

 This module provides foundational security-related types, DTOs, and error definitions for the UmbraCore security framework.
 It includes the fundamental building blocks used across the security subsystem, with particular focus on
 type safety and actor isolation support.

 ## Components

 - Error types for security operations
 - Data Transfer Objects (DTOs) for security configuration and results
 - Core security type definitions
 - Hash and encryption algorithm specifications

 All types in this module conform to `Sendable` to support safe usage across actor boundaries.
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies

// MARK: - Core Security Protocols

// MARK: - Enumerations

/**
 Encryption mode options. Defines how block ciphers handle data blocks.
 */
public enum EncryptionMode: String, Sendable, Equatable, CaseIterable {
  /// Cipher Block Chaining mode. Requires an IV.
  case cbc = "CBC"
  /// Galois/Counter Mode. Provides authenticated encryption (AEAD). Requires an IV/nonce.
  case gcm = "GCM"
}

/**
 Cryptographic key types.
 */
public enum KeyType: String, Sendable, Equatable, CaseIterable {
  /// Advanced Encryption Standard (Symmetric).
  case aes = "AES"
  /// Rivest–Shamir–Adleman (Asymmetric).
  case rsa = "RSA"
  /// Elliptic Curve cryptography (Asymmetric).
  case ec = "EC"
}

/**
 Defines padding modes for block cipher operations. Needed when data isn't a multiple of the block size.
 */
public enum EncryptionPadding: String, Sendable, Equatable, CaseIterable {
  /// PKCS#7 padding (RFC 5652). Standard padding scheme.
  case pkcs7

  /// No padding. Data must be an exact multiple of the block size.
  case none

  /// Zero padding. Fills the last block with zeros. (Use with caution, may not be reversible).
  case zero

  /// Description of the padding mode.
  public var description: String {
    switch self {
    case .pkcs7: "PKCS#7 Padding"
    case .none: "No Padding"
    case .zero: "Zero Padding"
    }
  }
}

// MARK: - Structs for Options and Configurations

/**
 Options for configuring encryption operations.
 */
public struct EncryptionOptions: Sendable, Equatable {
  // Properties defining encryption configuration will go here.
  // For now, let's add placeholders or common ones.
  public let algorithm: EncryptionAlgorithm
  public let mode: EncryptionMode
  public let padding: EncryptionPadding
  public let iv: [UInt8]? // Initialisation Vector
  public let additionalAuthenticatedData: [UInt8]? // For AEAD modes like GCM

  public init(
    algorithm: EncryptionAlgorithm,
    mode: EncryptionMode,
    padding: EncryptionPadding,
    iv: [UInt8]? = nil,
    additionalAuthenticatedData: [UInt8]? = nil
  ) {
    self.algorithm = algorithm
    self.mode = mode
    self.padding = padding
    self.iv = iv
    self.additionalAuthenticatedData = additionalAuthenticatedData
  }
}

/**
 Options for configuring decryption operations.
 Often mirrors EncryptionOptions.
 */
public typealias DecryptionOptions = EncryptionOptions

/**
 Options for configuring hashing operations.
 */
public struct HashingOptions: Sendable, Equatable {
  public let algorithm: HashAlgorithm
  // Add other common hashing options if needed, e.g., salt, iterations.

  public init(algorithm: HashAlgorithm) {
    self.algorithm = algorithm
  }
}

/**
 Options for configuring key generation operations.
 */
public struct KeyGenerationOptions: Sendable, Equatable {
  public let keyType: KeyType
  public let keySizeInBits: Int // e.g., 128, 192, 256 for AES; 2048, 3072, 4096 for RSA
  public let isExtractable: Bool // Can the key material be exported?
  public let useSecureEnclave: Bool // Hint to use hardware security module if available

  public init(
    keyType: KeyType,
    keySizeInBits: Int,
    isExtractable: Bool = false, // Default to non-extractable for security
    useSecureEnclave: Bool = false
  ) {
    self.keyType = keyType
    self.keySizeInBits = keySizeInBits
    self.isExtractable = isExtractable
    self.useSecureEnclave = useSecureEnclave
  }
}

/**
 Defines the type of security operation to be performed.
 */
public enum SecurityOperationType: String, Sendable, Equatable, CaseIterable {
  case encrypt
  case decrypt
  case hash
  case generateKey
  case storeKey
  case retrieveKey
  case deleteKey
  case sign
  case verifySignature
}

// MARK: - Error Handling

/**
 Represents errors that can occur during security operations.
 */
public enum SecurityError: Error, Sendable, Equatable {
  case encryptionFailed(reason: String?)
  case decryptionFailed(reason: String?)
  case hashingFailed(reason: String?)
  case keyGenerationFailed(reason: String?)
  case keyStorageFailed(reason: String?)
  case keyRetrievalFailed(reason: String?)
  case keyDeletionFailed(reason: String?)
  case signingFailed(reason: String?)
  case verificationFailed(reason: String?)
  case invalidInputData
  case invalidConfiguration
  case algorithmNotSupported
  case secureEnclaveUnavailable
  case operationCancelled
  case underlyingError(Error)
  case unknownError(String?)

  // Implement Equatable conformance manually for the .underlyingError case
  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    switch (lhs, rhs) {
    case (.encryptionFailed(let l), .encryptionFailed(let r)): return l == r
    case (.decryptionFailed(let l), .decryptionFailed(let r)): return l == r
    case (.hashingFailed(let l), .hashingFailed(let r)): return l == r
    case (.keyGenerationFailed(let l), .keyGenerationFailed(let r)): return l == r
    case (.keyStorageFailed(let l), .keyStorageFailed(let r)): return l == r
    case (.keyRetrievalFailed(let l), .keyRetrievalFailed(let r)): return l == r
    case (.keyDeletionFailed(let l), .keyDeletionFailed(let r)): return l == r
    case (.signingFailed(let l), .signingFailed(let r)): return l == r
    case (.verificationFailed(let l), .verificationFailed(let r)): return l == r
    case (.invalidInputData, .invalidInputData): return true
    case (.invalidConfiguration, .invalidConfiguration): return true
    case (.algorithmNotSupported, .algorithmNotSupported): return true
    case (.secureEnclaveUnavailable, .secureEnclaveUnavailable): return true
    case (.operationCancelled, .operationCancelled): return true
    case (.underlyingError(let l), .underlyingError(let r)): return String(reflecting: l) == String(reflecting: r) // Compare descriptions for non-Equatable errors
    case (.unknownError(let l), .unknownError(let r)): return l == r
    default: return false
    }
  }
}
