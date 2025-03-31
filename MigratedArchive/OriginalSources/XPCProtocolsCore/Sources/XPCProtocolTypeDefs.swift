/**
 # XPC Protocol Type Definitions

 This file contains type definitions and constants used throughout the XPC protocol
 system. It centralises shared types to ensure consistency across the protocol layers.

 ## Features

 * Type definitions for XPC protocol communications
 * Constants for protocol identification and versioning
 * Common enumerations used across protocol boundaries
 * Interface types that bridge between protocol layers

 These types are designed to work efficiently across XPC boundaries and maintain
 type safety when communicating between processes.
 */

import Foundation
import UmbraCoreTypes

/// Namespace for XPC Protocol Type Definitions to avoid naming conflicts
/// This helps prevent circular dependencies by providing a clear namespace
public enum XPCProtocolTypeDefs {
  /// Protocol operation types used across the XPC service interfaces
  public enum OperationType: String, Codable, Sendable {
    /// Cryptographic operations
    case encrypt
    case decrypt
    case hash
    case sign
    case verify

    /// Key management operations
    case generateKey
    case deriveKey
    case importKey
    case exportKey
    case deleteKey

    /// Administrative operations
    case status
    case reset
    case synchronise
    case configure
  }

  /// Represents the type of cryptographic key used in operations
  public enum KeyType: String, Codable, Sendable {
    /// Symmetric encryption key (AES, ChaCha20, etc.)
    case symmetric

    /// Asymmetric key (RSA, ECC, etc.)
    case asymmetric

    /// HMAC key for authentication
    case hmac

    /// Default bit length for each key type
    public var defaultBitLength: Int {
      switch self {
        case .symmetric: 256
        case .asymmetric: 2048
        case .hmac: 256
      }
    }

    /// Whether this key type is asymmetric (has separate public/private keys)
    public var isAsymmetric: Bool {
      switch self {
        case .symmetric, .hmac:
          false
        case .asymmetric:
          true
      }
    }
  }

  /// Specific implementation of cryptographic key types
  public enum SpecificKeyType: String, Codable, Sendable {
    /// AES symmetric encryption key
    case aes

    /// RSA asymmetric key
    case rsa

    /// ECC elliptic curve key
    case ecc

    /// HMAC key for hashing
    case hmac

    /// ChaCha20 stream cipher key
    case chacha20

    /// Number of bits for each key type
    public var bitLength: Int {
      switch self {
        case .aes: 128
        case .rsa: 2048
        case .ecc: 256
        case .hmac: 256
        case .chacha20: 256
      }
    }

    /// Whether this key type is asymmetric (has separate public/private keys)
    public var isAsymmetric: Bool {
      switch self {
        case .aes, .hmac, .chacha20:
          false
        case .rsa, .ecc:
          true
      }
    }

    /// Convert to generic KeyType
    public var genericType: KeyType {
      switch self {
        case .aes, .chacha20:
          .symmetric
        case .rsa, .ecc:
          .asymmetric
        case .hmac:
          .hmac
      }
    }
  }

  /// Represents the status of a service
  public enum ServiceStatus: String, Codable, Sendable {
    /// Service is fully operational
    case operational

    /// Service is degraded but still operational
    case degraded

    /// Service is in maintenance mode
    case maintenance

    /// Service is offline or unavailable
    case offline

    /// Service status is unknown
    case unknown
  }

  /// Configuration options for XPC services
  public struct ServiceConfiguration: Codable, Sendable, Equatable {
    /// Service identification
    public let serviceID: String

    /// Version of the service
    public let version: String

    /// Whether secure logging is enabled
    public let secureLogging: Bool

    /// Maximum key lifetime in seconds (0 = no expiry)
    public let maxKeyLifetime: TimeInterval

    /// Default security level for operations
    public let defaultSecurityLevel: SecurityLevel

    /// Initialise with default values
    public init(
      serviceID: String,
      version: String="1.0.0",
      secureLogging: Bool=false,
      maxKeyLifetime: TimeInterval=0,
      defaultSecurityLevel: SecurityLevel = .standard
    ) {
      self.serviceID=serviceID
      self.version=version
      self.secureLogging=secureLogging
      self.maxKeyLifetime=maxKeyLifetime
      self.defaultSecurityLevel=defaultSecurityLevel
    }
  }

  /// Security levels for operations
  public enum SecurityLevel: String, Codable, Sendable, CaseIterable {
    /// Standard security suitable for most operations
    case standard

    /// High security with additional protections
    case high

    /// Maximum security with all protections enabled
    case maximum
  }

  /// Format options for exporting keys
  public enum KeyFormat: String, Codable, Sendable {
    /// Raw key material
    case raw

    /// PKCS#8 formatted key (commonly used for asymmetric keys)
    case pkcs8

    /// PEM format (Base64-encoded with header/footer)
    case pem

    /// JWK format (JSON Web Key)
    case jwk
  }

  /// Configuration options for XPC service operations
  public struct OperationConfiguration: Codable, Sendable {
    /// The operation type
    public let operationType: OperationType

    /// Additional parameters for the operation, specific to the operation type
    public let parameters: [String: String]

    /// Timeout in seconds (0 = default)
    public let timeoutSeconds: Double

    /// Create a new operation configuration
    /// - Parameters:
    ///   - operationType: The type of operation to perform
    ///   - parameters: Additional parameters for the operation
    ///   - timeoutSeconds: Operation timeout in seconds (0 = default)
    public init(
      operationType: OperationType,
      parameters: [String: String]=[:],
      timeoutSeconds: Double=0
    ) {
      self.operationType=operationType
      self.parameters=parameters
      self.timeoutSeconds=timeoutSeconds
    }
  }

  /// Service status information
  public struct ServiceStatusInfo: Codable, Sendable {
    /// The operational status
    public let status: String

    /// Additional status details
    public let details: String?

    /// Protocol version supported by the service
    public let protocolVersion: String

    /// Create a new service status object
    /// - Parameters:
    ///   - status: The operational status
    ///   - details: Additional status details
    ///   - protocolVersion: Protocol version supported by the service
    public init(
      status: String,
      details: String?=nil,
      protocolVersion: String
    ) {
      self.status=status
      self.details=details
      self.protocolVersion=protocolVersion
    }
  }

  /// Protocol versioning information
  public enum ProtocolVersion {
    /// Current protocol version
    public static let current="2.0.0"

    /// Minimum supported protocol version
    public static let minimumSupported="1.0.0"

    /// Check if a protocol version is supported
    /// - Parameter version: The version to check
    /// - Returns: True if the version is supported
    public static func isSupported(_ version: String) -> Bool {
      // Simple version check - in a real implementation this would be more sophisticated
      version == current || version == minimumSupported
    }
  }
}
