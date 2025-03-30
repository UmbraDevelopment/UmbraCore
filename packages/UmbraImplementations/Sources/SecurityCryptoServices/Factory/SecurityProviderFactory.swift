import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # SecurityProviderFactory

 Factory for creating security provider implementations based on the desired provider type.

 This factory simplifies the process of selecting between different security
 implementation options, including:
 - Apple CryptoKit (native Apple platforms)
 - Ring FFI (cross-platform, Rust-based)
 - Basic AES-CBC (fallback implementation)

 The factory automatically selects the appropriate implementation based on
 platform capabilities and specified preferences, with sensible defaults.
 */
public enum SecurityProviderFactory {
  /**
   Creates a security provider implementation based on the specified type.

   If no type is specified, the factory will select the optimal provider for the
   current platform.

   - Parameter type: The desired provider type (optional)
   - Returns: An implementation of the EncryptionProviderProtocol
   - Throws: SecurityProtocolError if the requested provider is not available on this platform
   */
  public static func createProvider(type: SecurityProviderType?=nil) throws
  -> EncryptionProviderProtocol {
    let providerType=type ?? SecurityProviderType.defaultProvider

    switch providerType {
      case .apple:
        #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
          return AppleSecurityProvider()
        #else
          throw SecurityProtocolError
            .unsupportedOperation(name: "Apple CryptoKit is not available on this platform")
        #endif

      case .ring:
        #if canImport(RingCrypto)
          return RingSecurityProvider()
        #else
          throw SecurityProtocolError
            .unsupportedOperation(name: "Ring crypto is not available on this platform")
        #endif

      case .basic:
        return BasicSecurityProvider()
    }
  }

  /**
   Creates the best available provider for the current platform.

   The selection priority is:
   1. Apple CryptoKit on Apple platforms
   2. Ring on any platform where available
   3. Basic AES implementation as fallback

   - Returns: An implementation of the EncryptionProviderProtocol
   - Throws: SecurityProtocolError if no provider can be created
   */
  public static func createBestAvailableProvider() throws -> EncryptionProviderProtocol {
    // Try Apple provider first on Apple platforms
    #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
      do {
        return try createProvider(type: .apple)
      } catch {
        // Fall through to next option
      }
    #endif

    // Try Ring provider next
    #if canImport(RingCrypto)
      do {
        return try createProvider(type: .ring)
      } catch {
        // Fall through to basic provider
      }
    #endif

    // Fall back to basic provider
    return createDefaultProvider()
  }

  /**
   Creates the default fallback provider, which is always available.

   - Returns: A basic implementation of the EncryptionProviderProtocol
   */
  public static func createDefaultProvider() -> EncryptionProviderProtocol {
    BasicSecurityProvider()
  }
}
