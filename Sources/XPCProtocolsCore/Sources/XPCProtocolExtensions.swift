import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

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
    var data=Data()
    secureBytes.withUnsafeBytes { rawBuffer in
      data=Data(rawBuffer)
    }
    return data
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
    var bytes=[UInt8]()
    secureBytes.withUnsafeBytes { rawBuffer in
      bytes=Array(rawBuffer)
    }
    return bytes
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
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
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
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await decryptSecureData(data, keyIdentifier: keyIdentifier)
  }
}
