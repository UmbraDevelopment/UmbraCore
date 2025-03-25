import CoreServicesTypes
import Foundation
import FoundationBridgeTypes
import SecurityInterfaces
import SecurityUtils
import SecurityInterfacesProtocols
import SecurityTypes
import UmbraCoreTypes
import UmbraLogging
import XPCProtocolsCore
import SecurityInterfacesBase

/// Factory for creating security services with different configurations
/// This demonstrates how to use the various components we've created to break circular dependencies
public enum SecurityServiceFactory {
  /// Create a minimal security service with no crypto dependencies
  /// This is useful when you need basic security functionality but want to avoid circular
  /// dependencies
  public static func createMinimalService() -> SecurityServiceNoCrypto {
    SecurityServiceNoCrypto()
  }

  /// Create a bridge that provides crypto operations without circular dependencies
  /// This uses our Foundation-free crypto implementation under the hood
  public static func createCryptoBridge() -> SecurityServiceBridge {
    SecurityServiceBridge()
  }

  /// Example of how to use the security service with the crypto bridge
  /// This demonstrates the pattern for breaking circular dependencies
  public static func encryptData(_ data: Data, withKey key: Data) throws -> Data {
    // Use the bridge to perform crypto operations
    let bridge=createCryptoBridge()
    return try bridge.encrypt(data: data, key: key)
  }

  /// Example of how to use the security service with the crypto bridge
  /// This demonstrates the pattern for breaking circular dependencies
  public static func decryptData(_ data: Data, withKey key: Data) throws -> Data {
    // Use the bridge to perform crypto operations
    let bridge=createCryptoBridge()
    return try bridge.decrypt(data: data, key: key)
  }

  /// Generate a random encryption key
  /// This demonstrates the pattern for breaking circular dependencies
  public static func generateKey(size: Int=32) -> Data {
    // Use the bridge to perform crypto operations
    let bridge=createCryptoBridge()
    return bridge.generateKey(size: size)
  }
}
