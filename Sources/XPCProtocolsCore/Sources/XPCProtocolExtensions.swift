import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/**
 # XPC Protocol Extensions

 This file contains extensions to the XPC protocol types that provide utility functions
 and shared implementations across protocol hierarchies. These extensions help ensure
 consistency across protocol implementations and reduce code duplication.

 ## Features

 * Protocol bridging utilities between different protocol levels
 * Data conversion helpers for working with different data representations
 * Common implementation patterns for protocol requirements
 * Extension methods for Swift-native protocols

 These extensions are designed to simplify the implementation of XPC services
 by providing reusable functionality.
 */

/// Extension methods for easier implementation of XPC service protocols
extension XPCServiceProtocolBasic {
  /// Convert UInt8 array to Data
  /// - Parameter bytes: Byte array to convert
  /// - Returns: Data object containing the bytes
  public func convertBytesToData(_ bytes: [UInt8]) -> Data {
    Data(bytes)
  }

  /// Convert Data to UInt8 array
  /// - Parameter data: Data to convert
  /// - Returns: Array of bytes
  public func convertDataToBytes(_ data: Data) -> [UInt8] {
    [UInt8](data)
  }

  /// Convert Data to SecureBytes
  /// - Parameter data: Data to convert
  /// - Returns: SecureBytes safely containing the data
  public func convertDataToSecureBytes(_ data: Data) -> SecureBytes {
    SecureBytes(bytes: [UInt8](data))
  }

  /// Convert SecureBytes to Data
  /// - Parameter secureBytes: SecureBytes to convert
  /// - Returns: Data representation
  public func convertSecureBytesToData(_ secureBytes: SecureBytes) -> Data {
    Data([UInt8](secureBytes))
  }

  /// Convert UInt8 array to SecureBytes
  /// - Parameter bytes: Byte array to convert
  /// - Returns: SecureBytes safely containing the bytes
  public func convertBytesToSecureBytes(_ bytes: [UInt8]) -> SecureBytes {
    SecureBytes(bytes: bytes)
  }

  /// Convert SecureBytes to bytes
  /// - Parameter secureBytes: SecureBytes to convert
  /// - Returns: A byte array containing the bytes
  public func convertSecureBytesToBytes(_ secureBytes: SecureBytes) -> [UInt8] {
    [UInt8](secureBytes)
  }
}

/// Extension methods for standard protocol implementations
extension XPCServiceProtocolStandard {
  /// Convenience method to get service status
  /// - Returns: Dictionary with status information
  public func getStatus() -> [String: Any] {
    [
      "timestamp": Date().timeIntervalSince1970,
      "protocol": Self.protocolIdentifier,
      "isActive": true
    ]
  }

  /// Default implementation for generating random data
  /// - Parameter length: Length in bytes
  /// - Returns: SecureBytes containing random data
  public func generateRandomSecureBytes(length: Int) -> SecureBytes {
    let bytes=(0..<length).map { _ in UInt8.random(in: 0...255) }
    return SecureBytes(bytes: bytes)
  }
}

/// Extension methods for complete protocol implementations
extension XPCServiceProtocolComplete {
  /// Bridge encryption from standard protocol to complete protocol
  /// - Parameters:
  ///   - data: SecureBytes to encrypt
  ///   - keyIdentifier: Optional key identifier
  /// - Returns: Result with encrypted data or error
  public func bridgeEncryption(
    data: SecureBytes,
    keyIdentifier: String?
  ) async -> Result<SecureBytes, SecurityError> {
    await encryptSecureData(data, keyIdentifier: keyIdentifier)
  }

  /// Bridge decryption from standard protocol to complete protocol
  /// - Parameters:
  ///   - data: SecureBytes to decrypt
  ///   - keyIdentifier: Optional key identifier
  /// - Returns: Result with decrypted data or error
  public func bridgeDecryption(
    data: SecureBytes,
    keyIdentifier: String?
  ) async -> Result<SecureBytes, SecurityError> {
    await decryptSecureData(data, keyIdentifier: keyIdentifier)
  }

  /// Bridge getting random bytes from standard protocol to complete protocol
  /// - Parameter count: Number of bytes to generate
  /// - Returns: Result with random bytes if successful
  public func getRandomBytes(count: Int) async -> Result<SecureBytes, CryptoError> {
    let result=await generateRandomData(length: count)

    // Convert SecurityError to CryptoError
    switch result {
      case let .success(randomBytes):
        return .success(randomBytes)
      case let .failure(error):
        return .failure(UmbraErrors.CryptoError(
          type: .randomData,
          code: UmbraErrors.CryptoErrorDomain.randomDataGenerationFailed.rawValue,
          description: "Failed to generate random bytes: \(error.localizedDescription)"
        ))
    }
  }

  /// Bridge encryption from standard protocol to complete protocol
  /// - Parameters:
  ///   - data: SecureBytes to encrypt
  ///   - keyIdentifier: Optional key identifier
  ///   - algorithm: Optional algorithm specification
  /// - Returns: Result with encrypted data if successful
  public func encrypt(
    data: SecureBytes,
    keyIdentifier: String,
    algorithm _: String
  ) async -> Result<SecureBytes, CryptoError> {
    // Use the encryptSecureData method which is part of the protocol
    let result=await encryptSecureData(data, keyIdentifier: keyIdentifier)

    // Convert SecurityError to CryptoError
    switch result {
      case let .success(encryptedData):
        return .success(encryptedData)
      case let .failure(error):
        return .failure(UmbraErrors.CryptoError(
          type: .encryption,
          code: UmbraErrors.CryptoErrorDomain.encryptionFailed.rawValue,
          description: "Encryption failed: \(error.localizedDescription)"
        ))
    }
  }

  /// Bridge decryption from standard protocol to complete protocol
  /// - Parameters:
  ///   - data: SecureBytes to decrypt
  ///   - keyIdentifier: Optional key identifier
  ///   - algorithm: Optional algorithm specification
  /// - Returns: Result with decrypted data if successful
  public func decrypt(
    data: SecureBytes,
    keyIdentifier: String,
    algorithm _: String
  ) async -> Result<SecureBytes, CryptoError> {
    // Use the decryptSecureData method which is part of the protocol
    let result=await decryptSecureData(data, keyIdentifier: keyIdentifier)

    // Convert SecurityError to CryptoError
    switch result {
      case let .success(decryptedData):
        return .success(decryptedData)
      case let .failure(error):
        return .failure(UmbraErrors.CryptoError(
          type: .decryption,
          code: UmbraErrors.CryptoErrorDomain.decryptionFailed.rawValue,
          description: "Decryption failed: \(error.localizedDescription)"
        ))
    }
  }
}
