/**
 # UmbraCore Crypto Type Definitions

 This file provides core type definitions for cryptographic operations in the UmbraCore security framework.
 */

import Foundation
import SecurityTypes
import UmbraErrors

/// Data Transfer Object for crypto service operations
public struct CryptoServiceDto: Sendable {
  /// Function type for encrypt operation
  public typealias EncryptFunction=@Sendable (SecureBytes, SecureBytes) async -> Result<
    SecureBytes,
    SecurityProtocolError
  >

  /// Function type for decrypt operation
  public typealias DecryptFunction=@Sendable (SecureBytes, SecureBytes) async -> Result<
    SecureBytes,
    SecurityProtocolError
  >

  /// Function type for hash operation
  public typealias HashFunction=@Sendable (SecureBytes) async -> Result<
    SecureBytes,
    SecurityProtocolError
  >

  /// Function type for hash verification operation
  public typealias VerifyHashFunction=@Sendable (SecureBytes, SecureBytes) async -> Result<
    Bool,
    SecurityProtocolError
  >

  /// The encryption function
  public let encrypt: EncryptFunction

  /// The decryption function
  public let decrypt: DecryptFunction

  /// The hash function
  public let hash: HashFunction

  /// The hash verification function
  public let verifyHash: VerifyHashFunction

  /// Initialise a new crypto service DTO
  /// - Parameters:
  ///   - encrypt: The encryption function
  ///   - decrypt: The decryption function
  ///   - hash: The hash function
  ///   - verifyHash: The hash verification function
  public init(
    encrypt: @escaping EncryptFunction,
    decrypt: @escaping DecryptFunction,
    hash: @escaping HashFunction,
    verifyHash: @escaping VerifyHashFunction
  ) {
    self.encrypt=encrypt
    self.decrypt=decrypt
    self.hash=hash
    self.verifyHash=verifyHash
  }
}

/// Key pair data
public struct KeyPairDto: Sendable, Equatable {
  /// The public key
  public let publicKey: SecureBytes

  /// The private key
  public let privateKey: SecureBytes

  /// Initialise a new key pair
  /// - Parameters:
  ///   - publicKey: The public key
  ///   - privateKey: The private key
  public init(publicKey: SecureBytes, privateKey: SecureBytes) {
    self.publicKey=publicKey
    self.privateKey=privateKey
  }
}

/// Cryptographic key types
public enum CryptoKeyType: String, Sendable, Equatable, CaseIterable {
  /// Symmetric key
  case symmetric
  /// Asymmetric key
  case asymmetric
}

/// Key derivation functions
public enum KeyDerivationFunction: String, Sendable, Equatable, CaseIterable {
  /// PBKDF2
  case pbkdf2
  /// Argon2
  case argon2
  /// Scrypt
  case scrypt
  /// None (no derivation)
  case none
}

/// Key derivation parameters
public struct KeyDerivationParameters: Sendable, Equatable {
  /// The salt
  public let salt: SecureBytes
  /// The number of iterations
  public let iterations: Int
  /// The key derivation function
  public let function: KeyDerivationFunction

  /// Initialise new key derivation parameters
  /// - Parameters:
  ///   - salt: The salt
  ///   - iterations: The number of iterations
  ///   - function: The key derivation function
  public init(
    salt: SecureBytes,
    iterations: Int=10000,
    function: KeyDerivationFunction = .pbkdf2
  ) {
    self.salt=salt
    self.iterations=iterations
    self.function=function
  }
}
