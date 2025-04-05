import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # SecureStorageActor

 A Swift actor that provides thread-safe access to secure storage operations.
 This actor implements the SecureStorageProtocol and ensures proper isolation
 of sensitive data.
 */
public actor SecureStorageActor: SecureStorageProtocol {
  /// The provider type for this implementation
  public nonisolated let providerType: SecurityProviderType

  /// The URL where secure storage is located
  private let storageURL: URL

  /// Logger instance for recording operations
  private let logger: LoggingProtocol

  /// In-memory storage for sensitive data (temporary implementation)
  private var storage: [String: [UInt8]]=[:]

  /**
   Initializes a new secure storage actor.

   - Parameters:
      - providerType: The type of provider to use
      - storageURL: The URL where secure storage is located
      - logger: Logger for recording operations
   */
  public init(
    providerType: SecurityProviderType,
    storageURL: URL,
    logger: LoggingProtocol
  ) {
    self.providerType=providerType
    self.storageURL=storageURL
    self.logger=logger
  }

  /**
   Stores data securely and returns an identifier.

   - Parameters:
      - data: The data to store
      - customIdentifier: Optional custom identifier
   - Returns: The identifier for the stored data
   */
  public func store(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Storing data in secure storage",
      metadata: nil,
      source: "SecureStorageActor"
    )

    let identifier=customIdentifier ?? UUID().uuidString
    storage[identifier]=data

    return .success(identifier)
  }

  /**
   Retrieves data using its identifier.

   - Parameter identifier: The identifier for the data
   - Returns: The retrieved data or an error
   */
  public func retrieve(identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "Retrieving data from secure storage: \(identifier)",
      metadata: nil,
      source: "SecureStorageActor"
    )

    guard let data=storage[identifier] else {
      return .failure(.dataNotFound)
    }

    return .success(data)
  }

  /**
   Deletes data using its identifier.

   - Parameter identifier: The identifier for the data to delete
   - Returns: Success or failure
   */
  public func delete(identifier: String) async -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Deleting data from secure storage: \(identifier)",
      metadata: nil,
      source: "SecureStorageActor"
    )

    guard storage[identifier] != nil else {
      return .failure(.dataNotFound)
    }

    storage.removeValue(forKey: identifier)
    return .success(())
  }

  // MARK: - SecureStorageProtocol Implementation

  /**
   Stores data securely with the given identifier.

   - Parameters:
      - data: The data to store as a byte array
      - identifier: A string identifier for the stored data
   - Returns: Success or an error
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Storing data with identifier: \(identifier)",
      metadata: PrivacyMetadata(),
      source: "SecureStorageActor"
    )

    storage[identifier]=data
    return .success(())
  }

  /**
   Retrieves data securely by its identifier.

   - Parameter identifier: A string identifying the data to retrieve
   - Returns: The retrieved data as a byte array or an error
   */
  public func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "Retrieving data with identifier: \(identifier)",
      metadata: PrivacyMetadata(),
      source: "SecureStorageActor"
    )

    guard let data=storage[identifier] else {
      await logger.error(
        "Data not found for identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "SecureStorageActor"
      )
      return .failure(.dataNotFound)
    }

    return .success(data)
  }

  /**
   Deletes data securely by its identifier.

   - Parameter identifier: A string identifying the data to delete
   - Returns: Success or an error
   */
  public func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      metadata: PrivacyMetadata(),
      source: "SecureStorageActor"
    )

    guard storage[identifier] != nil else {
      await logger.error(
        "Data not found for deletion, identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "SecureStorageActor"
      )
      return .failure(.dataNotFound)
    }

    storage.removeValue(forKey: identifier)
    return .success(())
  }

  /**
   Lists all available data identifiers.

   - Returns: An array of data identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    await logger.debug(
      "Listing all data identifiers",
      metadata: PrivacyMetadata(),
      source: "SecureStorageActor"
    )

    return .success(Array(storage.keys))
  }
}
