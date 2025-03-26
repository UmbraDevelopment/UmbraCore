/**
 # UmbraCore Crypto Type Definitions

 This file provides core type definitions for cryptographic operations in the UmbraCore security framework.
 */

import Errors // Import for SecurityProtocolError
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes // Import for SecureBytes

// Note: CryptoServiceProtocol has been moved to Core/Protocols/CryptoServiceProtocol.swift
// to eliminate duplicate protocol definitions. Please use the protocol from that module instead.

// Note: EncryptionAlgorithm has been consolidated in SecurityTypes.swift
// to eliminate duplicate type definitions.

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

  /// Creates a new CryptoServiceDto with the specified functions
  /// - Parameters:
  ///   - encrypt: Function to encrypt data
  ///   - decrypt: Function to decrypt data
  ///   - hash: Function to hash data
  ///   - verifyHash: Function to verify hash
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

/// Type alias for CryptoServiceDto to maintain backward compatibility
/// while transitioning away from using DTO acronym in type names
@available(*, deprecated, renamed: "CryptoServiceDto", message: "Use CryptoServiceDto instead")
public typealias CryptoServiceDTO=CryptoServiceDto

/// A type-erased wrapper for a crypto service
public struct AnyCryptoService {
  private let dto: CryptoServiceDto

  /// Initialises a new type-erased crypto service wrapper
  /// - Parameter dto: The CryptoServiceDto containing service functions
  public init(dto: CryptoServiceDto) {
    self.dto=dto
  }

  /// Encrypts binary data using the provided key
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.encrypt(data, key)
  }

  /// Decrypts binary data using the provided key
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.decrypt(data, key)
  }

  /// Computes a cryptographic hash of binary data
  public func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.hash(data)
  }

  /// Verifies a cryptographic hash against the expected value
  public func verifyHash(
    data: SecureBytes,
    expectedHash: SecureBytes
  ) async -> Result<Bool, SecurityProtocolError> {
    await dto.verifyHash(data, expectedHash)
  }
}

/// A CryptoServiceAdapter for converting between different types used by crypto service
/// implementations
public struct CryptoServiceAdapter {
  private let dto: CryptoServiceDto

  /// Initialises a new crypto service adapter
  /// - Parameter dto: The CryptoServiceDto to adapt
  public init(dto: CryptoServiceDto) {
    self.dto=dto
  }

  /// Encrypts binary data using the provided key
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.encrypt(data, key)
  }

  /// Decrypts binary data using the provided key
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.decrypt(data, key)
  }

  /// Computes a cryptographic hash of binary data
  public func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.hash(data)
  }

  /// Verifies a cryptographic hash against the expected value
  public func verifyHash(
    data: SecureBytes,
    expectedHash: SecureBytes
  ) async -> Result<Bool, SecurityProtocolError> {
    await dto.verifyHash(data, expectedHash)
  }
}
