import Errors
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

// Import the required modules
@_exported import Protocols
@_exported import Types

/// Factory for creating and managing security core adapters
/// This provides a consistent entry point for all adapter functionality
public enum SecurityCoreAdapters {
  /// Create a type-erased wrapper for a crypto service DTO
  /// - Parameter dto: The crypto service DTO to wrap
  /// - Returns: A type-erased crypto service
  public static func createAnyCryptoService(dto: CryptoServiceDTO) -> AnyCryptoService {
    AnyCryptoService(dto: dto)
  }

  /// Create a type-erased wrapper by converting a protocol implementation to a DTO
  /// - Parameter service: The crypto service protocol implementation
  /// - Returns: A type-erased crypto service
  public static func createAnyCryptoServiceFromProtocol(
    service: Protocols.CryptoServiceProtocol & Sendable
  ) -> AnyCryptoService {
    // Create a DTO from the protocol implementation
    let dto=CryptoServiceDTO(
      encrypt: { data, key in
        await service.encrypt(data: data, using: key)
      },
      decrypt: { data, key in
        await service.decrypt(data: data, using: key)
      },
      hash: { data in
        await service.hash(data: data)
      },
      verifyHash: { data, hash in
        await service.verifyHash(data: data, expectedHash: hash)
      }
    )

    return AnyCryptoService(dto: dto)
  }

  /// Creates a CryptoServiceAdapter from a DTO
  /// - Parameter dto: The crypto service DTO
  /// - Returns: A CryptoServiceAdapter instance
  public static func createCryptoServiceAdapter(dto: CryptoServiceDTO) -> CryptoServiceAdapter {
    CryptoServiceAdapter(dto: dto)
  }
}
