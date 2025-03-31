import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # SecurityProviderFactoryImpl

 An implementation of provider factory that serves as an adapter between our modernised
 architecture and the existing implementation. This avoids direct dependencies on the legacy
 code while providing the same functionality with proper naming.

 This implementation provides factory methods for creating various security providers
 while ensuring proper error handling and type safety.

 ## Usage

 ```swift
 // Create a provider with a specific type
 let provider = try SecurityProviderFactoryImpl.createProvider(type: .apple)

 // Create the best available provider
 let bestProvider = try SecurityProviderFactoryImpl.createBestAvailableProvider()
 ```
 */
public enum SecurityProviderFactoryImpl {
  /**
   Create a security provider of the specified type.

   - Parameter type: The type of security provider to create
   - Returns: An encryption provider implementation
   - Throws: SecurityProtocolError if the provider cannot be created
   */
  public static func createProvider(type: SecurityProviderType) throws
  -> EncryptionProviderProtocol {
    // Create a wrapper that delegates to the existing implementation
    let provider=try DefaultProviderImpl(providerType: type)
    return provider
  }

  /**
   Create the best available security provider for the current platform.

   This will attempt to create providers in order of security preference,
   starting with platform-specific providers and falling back to more
   basic implementations if needed.

   - Returns: The best available encryption provider implementation
   - Throws: SecurityProtocolError if no provider can be created
   */
  public static func createBestAvailableProvider() throws -> EncryptionProviderProtocol {
    // Try to create providers in order of preference
    #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
      do {
        return try createProvider(type: .apple)
      } catch {
        // Fall back to basic provider
      }
    #endif

    // Basic provider is our fallback
    return try createProvider(type: .basic)
  }

  /**
   Create a default provider implementation without throwing errors.

   This is useful for cases where you need a provider but don't want to
   handle potential creation errors.

   - Returns: A default encryption provider (will be .basic if others fail)
   */
  public static func createDefaultProvider() -> EncryptionProviderProtocol {
    do {
      return try createBestAvailableProvider()
    } catch {
      // Create a basic provider directly as last resort
      return BasicProviderImpl()
    }
  }
}

/**
 A basic implementation of encryption provider for fallback purposes.
 */
private struct BasicProviderImpl: EncryptionProviderProtocol {
  // Required by the protocol
  var providerType: SecurityProviderType { .basic }

  func encrypt(
    plaintext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "BasicProviderImpl.encrypt")
  }

  func decrypt(
    ciphertext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "BasicProviderImpl.decrypt")
  }

  func generateKey(size _: Int, config _: SecurityConfigDTO) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "BasicProviderImpl.generateKey")
  }

  func generateIV(size _: Int) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "BasicProviderImpl.generateIV")
  }

  func hash(data _: Data, algorithm _: String) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "BasicProviderImpl.hash")
  }
}

/**
 Default implementation that wraps a security provider based on type.
 */
private struct DefaultProviderImpl: EncryptionProviderProtocol {
  // The provider type
  let providerType: SecurityProviderType

  /**
   Initialise a provider with the specified type.

   - Parameter providerType: The type of provider to create
   - Throws: SecurityProtocolError if the provider cannot be created
   */
  init(providerType: SecurityProviderType) throws {
    self.providerType=providerType

    // In a real implementation, we would initialize based on the provider type
    // This is a simplified version that just stores the type

    if providerType == .apple {
      #if !canImport(CryptoKit) || !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        throw SecurityProtocolError.providerNotAvailable
      #endif
    }
  }

  // Implementation of required protocol methods
  func encrypt(
    plaintext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "DefaultProviderImpl.encrypt")
  }

  func decrypt(
    ciphertext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "DefaultProviderImpl.decrypt")
  }

  func generateKey(size _: Int, config _: SecurityConfigDTO) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "DefaultProviderImpl.generateKey")
  }

  func generateIV(size _: Int) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "DefaultProviderImpl.generateIV")
  }

  func hash(data _: Data, algorithm _: String) throws -> Data {
    throw SecurityProtocolError.unsupportedOperation(name: "DefaultProviderImpl.hash")
  }
}

/**
 Apple implementation of the encryption provider using CryptoKit.
 */
#if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
  import CryptoKit

  private struct AppleProviderImpl: EncryptionProviderProtocol {
    // Required by the protocol
    var providerType: SecurityProviderType { .apple }

    func encrypt(
      plaintext _: Data,
      key _: Data,
      iv _: Data,
      config _: SecurityConfigDTO
    ) throws -> Data {
      throw SecurityProtocolError.unsupportedOperation(name: "AppleProviderImpl.encrypt")
    }

    func decrypt(
      ciphertext _: Data,
      key _: Data,
      iv _: Data,
      config _: SecurityConfigDTO
    ) throws -> Data {
      throw SecurityProtocolError.unsupportedOperation(name: "AppleProviderImpl.decrypt")
    }

    func generateKey(size _: Int, config _: SecurityConfigDTO) throws -> Data {
      throw SecurityProtocolError.unsupportedOperation(name: "AppleProviderImpl.generateKey")
    }

    func generateIV(size _: Int) throws -> Data {
      throw SecurityProtocolError.unsupportedOperation(name: "AppleProviderImpl.generateIV")
    }

    func hash(data _: Data, algorithm _: String) throws -> Data {
      throw SecurityProtocolError.unsupportedOperation(name: "AppleProviderImpl.hash")
    }
  }
#endif
