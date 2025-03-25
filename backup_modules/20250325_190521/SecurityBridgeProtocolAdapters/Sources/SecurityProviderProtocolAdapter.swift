import CoreTypesInterfaces
import FoundationBridgeTypes
import SecurityInterfacesProtocols
import SecurityProtocolsCore
import SecurityTypeConverters
import UmbraCoreTypes
import XPCProtocolsCore

/// Bridge protocol that connects security providers to Foundation-free interfaces
/// This helps break circular dependencies between security modules
public protocol SecurityProviderBridge: Sendable {
  /// Protocol identifier - used for protocol negotiation
  static var protocolIdentifier: String { get }

  /// Encrypt data using the provider's encryption mechanism
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  /// - Throws: Error if encryption fails
  func encrypt(_ data: DataBridge, key: DataBridge) async throws -> DataBridge

  /// Decrypt data using the provider's decryption mechanism
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  /// - Throws: Error if decryption fails
  func decrypt(_ data: DataBridge, key: DataBridge) async throws -> DataBridge

  /// Generate a cryptographically secure random key
  /// - Parameter sizeInBytes: Size of the key to generate
  /// - Returns: Generated key
  /// - Throws: Error if key generation fails
  func generateKey(sizeInBytes: Int) async throws -> DataBridge

  /// Hash data using the provider's hashing mechanism
  /// - Parameter data: Data to hash
  /// - Returns: Hash of the data
  /// - Throws: Error if hashing fails
  func hash(_ data: DataBridge) async throws -> DataBridge
}

/// Adapter that connects a foundation-free security provider to a Foundation-based interface
/// Implementing the SecurityProviderProtocol while delegating to a foundation-free bridge
public final class SecurityProviderProtocolAdapter: SecurityInterfacesProtocols
.SecurityProviderProtocol {
  /// The underlying bridge implementation
  private let adapter: any SecurityProviderBridge

  /// Protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.security.provider.adapter"
  }

  /// Wrap any error into a SecurityProtocolError
  private func wrapError(_ error: Error) throws -> Never {
    // Use our centralised error mapping to get a consistent error description
    let errorDescription="Security operation failed: \(error)"
    throw UmbraErrors.Security.Protocols
      .missingProtocolImplementation(protocolName: errorDescription)
  }

  /// Create a new adapter with the given bridge
  /// - Parameter bridge: The security provider bridge implementation
  public init(bridge: any SecurityProviderBridge) {
    adapter=bridge
  }

  /// Encrypt data using the provider's encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  /// - Throws: UmbraErrors.Security.Protocols if encryption fails
  public func encrypt(
    _ data: CoreTypesInterfaces.SecureData,
    key: CoreTypesInterfaces.SecureData
  ) async throws -> CoreTypesInterfaces.SecureData {
    do {
      // Use the standardised converter from SecurityTypeConverters
      let bridgeData=data.toDataBridge()
      let bridgeKey=key.toDataBridge()

      let result=try await adapter.encrypt(bridgeData, key: bridgeKey)
      return CoreTypesInterfaces.SecureData.from(bridge: result)
    } catch {
      try wrapError(error)
    }
  }

  /// Decrypt data using the provider's decryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  /// - Throws: UmbraErrors.Security.Protocols if decryption fails
  public func decrypt(
    _ data: CoreTypesInterfaces.SecureData,
    key: CoreTypesInterfaces.SecureData
  ) async throws -> CoreTypesInterfaces.SecureData {
    do {
      // Use the standardised converter from SecurityTypeConverters
      let bridgeData=data.toDataBridge()
      let bridgeKey=key.toDataBridge()

      let result=try await adapter.decrypt(bridgeData, key: bridgeKey)
      return CoreTypesInterfaces.SecureData.from(bridge: result)
    } catch {
      try wrapError(error)
    }
  }

  /// Generate a cryptographically secure random key
  /// - Parameter length: Size of the key to generate in bytes
  /// - Returns: Generated key
  /// - Throws: UmbraErrors.Security.Protocols if key generation fails
  public func generateKey(length: Int) async throws -> CoreTypesInterfaces.SecureData {
    do {
      let result=try await adapter.generateKey(sizeInBytes: length)
      return CoreTypesInterfaces.SecureData.from(bridge: result)
    } catch {
      try wrapError(error)
    }
  }

  /// Hash data using the provider's hashing mechanism
  /// - Parameter data: Data to hash
  /// - Returns: Hash of the data
  /// - Throws: UmbraErrors.Security.Protocols if hashing fails
  public func hash(_ data: CoreTypesInterfaces.SecureData) async throws -> CoreTypesInterfaces
  .SecureData {
    do {
      // Use the standardised converter from SecurityTypeConverters
      let bridgeData=data.toDataBridge()

      let result=try await adapter.hash(bridgeData)
      return CoreTypesInterfaces.SecureData.from(bridge: result)
    } catch {
      try wrapError(error)
    }
  }
}
