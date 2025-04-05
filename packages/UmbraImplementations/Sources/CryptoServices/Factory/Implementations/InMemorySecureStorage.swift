import CryptoInterfaces
import CryptoTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 A simple in-memory secure storage implementation to avoid circular dependencies.
 This is an internal implementation used when no external storage is provided.

 Note: This implementation is not intended for production use with sensitive data
 as it only stores data in memory and does not provide persistent storage.
 */
public actor InMemorySecureStorage: SecureStorageProtocol {
  /// In-memory storage dictionary
  private var storage: [String: [UInt8]]=[:]

  /// Logger for operations
  private let logger: LoggingProtocol

  /// Base URL for storage (used for identifier generation)
  private let baseURL: URL

  /// Initialises a new in-memory secure storage implementation.
  ///
  /// - Parameters:
  ///   - logger: Logger to use for operations
  ///   - baseURL: Base URL for storage (used for identifier generation)
  public init(
    logger: LoggingProtocol,
    baseURL: URL
  ) {
    self.logger=logger
    self.baseURL=baseURL
  }

  public func storeSecurely(
    data: [UInt8],
    identifier: String
  ) async -> Result<Void, KeyStorageError> {
    await logger.debug(
      "Storing data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "InMemorySecureStorage"
    )

    storage[identifier]=data
    return .success(())
  }

  public func retrieveSecurely(
    identifier: String
  ) async -> Result<[UInt8], KeyStorageError> {
    await logger.debug(
      "Retrieving data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "InMemorySecureStorage"
    )

    if let data=storage[identifier] {
      return .success(data)
    } else {
      await logger.error(
        "Data not found with identifier: \(identifier)",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "InMemorySecureStorage"
      )
      return .failure(.keyNotFound)
    }
  }

  public func deleteSecurely(
    identifier: String
  ) async -> Result<Void, KeyStorageError> {
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "InMemorySecureStorage"
    )

    if storage.removeValue(forKey: identifier) != nil {
      return .success(())
    } else {
      await logger.error(
        "Data not found for deletion with identifier: \(identifier)",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "InMemorySecureStorage"
      )
      return .failure(.keyNotFound)
    }
  }
}
