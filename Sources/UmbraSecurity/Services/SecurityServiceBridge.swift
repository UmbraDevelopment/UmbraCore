import CoreServicesTypesNoFoundation
import CryptoSwiftFoundationIndependent
import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import Foundation
import FoundationBridgeTypes
import SecurityInterfaces
import SecurityInterfacesBase
import SecurityInterfacesProtocols
import SecurityTypes
import SecurityUtils
import UmbraCoreTypes
import UmbraLogging
import UmbraSecurityCryptoNoFoundation
import XPCProtocolsCore

/// A bridge adapter that connects Foundation-free crypto operations with Foundation-based services
/// This helps break circular dependencies between Foundation and CryptoSwift
public final class SecurityServiceBridge: Sendable {
  // MARK: - Properties

  /// The crypto service implementation
  private let cryptoService: SecurityCryptoService

  // MARK: - Initialisation

  /// Initialise a new security service bridge
  /// - Parameter cryptoService: The crypto service implementation
  public init(cryptoService: SecurityCryptoService = SecurityCryptoService()) {
    self.cryptoService = cryptoService
  }

  // MARK: - Security Operations

  /// Encrypt data using the crypto service
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  public func encrypt(data: Data, key: Data) throws -> Data {
    // Convert Foundation Data to [UInt8]
    let dataBytes = [UInt8](data)
    let keyBytes = [UInt8](key)

    // Use the crypto service to encrypt
    let encryptedBytes = try cryptoService.encrypt(data: dataBytes, key: keyBytes)

    // Convert back to Foundation Data
    return Data(encryptedBytes)
  }

  /// Decrypt data using the crypto service
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  public func decrypt(data: Data, key: Data) throws -> Data {
    // Convert Foundation Data to [UInt8]
    let dataBytes = [UInt8](data)
    let keyBytes = [UInt8](key)

    // Use the crypto service to decrypt
    let decryptedBytes = try cryptoService.decrypt(data: dataBytes, key: keyBytes)

    // Convert back to Foundation Data
    return Data(decryptedBytes)
  }

  /// Generate a random encryption key
  /// - Parameter size: Size of the key in bytes
  /// - Returns: Random key data
  public func generateKey(size: Int = 32) -> Data {
    // Use the crypto service to generate a key
    let keyBytes = cryptoService.generateKey(size: size)

    // Convert to Foundation Data
    return Data(keyBytes)
  }

  /// Calculate hash of data
  /// - Parameter data: Input data
  /// - Returns: Hash value
  public func hash(data: Data) -> Data {
    // Convert Foundation Data to [UInt8]
    let dataBytes = [UInt8](data)

    // Use the crypto service to hash
    let hashBytes = cryptoService.hash(data: dataBytes)

    // Convert back to Foundation Data
    return Data(hashBytes)
  }
}
