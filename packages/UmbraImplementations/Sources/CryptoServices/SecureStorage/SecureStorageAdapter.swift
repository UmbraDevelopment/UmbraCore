import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 An adapter that implements SecureStorageProtocol using SecureCryptoStorage.

 This adapter class allows the SecureCryptoStorage to be used with the
 SecureStorageProtocol interface, providing a unified interface for secure
 data storage operations.
 */
public final class SecureStorageAdapter: SecureStorageProtocol {
  /// The underlying secure storage implementation
  private let storage: SecureCryptoStorage

  /// Logger for operations
  private let logger: any LoggingProtocol

  /**
   Initializes a new secure storage adapter.

   - Parameters:
      - storage: The secure crypto storage implementation to adapt
      - logger: Logger for recording operations
   */
  public init(storage: SecureCryptoStorage, logger: any LoggingProtocol) {
    self.storage=storage
    self.logger=logger
  }

  /**
   Stores data securely with the specified identifier.

   - Parameters:
      - data: The data to store
      - identifier: The identifier to use for the data

   - Returns: Result indicating success or failure with error details
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    do {
      try await storage.storeData(Data(data), identifier: identifier)

      var metadata=PrivacyMetadata()
      metadata["dataSize"]=PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.debug(
        "Data stored successfully",
        metadata: metadata,
        source: "SecureStorageAdapter"
      )

      return .success(())
    } catch {
      var metadata=PrivacyMetadata()
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .public)
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.error(
        "Failed to store data",
        metadata: metadata,
        source: "SecureStorageAdapter"
      )

      return .failure(.operationFailed(error.localizedDescription))
    }
  }

  /**
   Retrieves data with the specified identifier.

   - Parameter identifier: The identifier of the data to retrieve

   - Returns: Result containing the retrieved data or error details
   */
  public func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    do {
      let data=try await storage.retrieveData(identifier: identifier)

      var metadata=PrivacyMetadata()
      metadata["dataSize"]=PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.debug(
        "Data retrieved successfully",
        metadata: metadata,
        source: "SecureStorageAdapter"
      )

      return .success(Array(data))
    } catch {
      var metadata=PrivacyMetadata()
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .public)
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.error(
        "Failed to retrieve data",
        metadata: metadata,
        source: "SecureStorageAdapter"
      )

      return .failure(.dataNotFound)
    }
  }

  /**
   Deletes data with the specified identifier.

   - Parameter identifier: The identifier of the data to delete

   - Returns: Result indicating success or failure with error details
   */
  public func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    do {
      try await storage.deleteData(identifier: identifier)

      var metadata=PrivacyMetadata()
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.debug(
        "Data deleted successfully",
        metadata: metadata,
        source: "SecureStorageAdapter"
      )

      return .success(())
    } catch {
      var metadata=PrivacyMetadata()
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .public)
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.error(
        "Failed to delete data",
        metadata: metadata,
        source: "SecureStorageAdapter"
      )

      return .failure(.dataNotFound)
    }
  }

  /**
   Lists all data identifiers stored in the secure storage.

   - Returns: Result containing array of identifiers or error details
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    let metadata=PrivacyMetadata()

    await logger.warning(
      "List data identifiers operation not supported",
      metadata: metadata,
      source: "SecureStorageAdapter"
    )

    return .failure(.unsupportedOperation)
  }
}
