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
 Error type for secure storage operations
 */
public enum StorageError: Error {
  /// The requested data was not found
  case dataNotFound
  /// The operation failed with a specific underlying error
  case operationFailed(Error)
}

/**
 An adapter that implements SecureStorageProtocol using SecureCryptoStorage.

 This actor allows the SecureCryptoStorage to be used with the
 SecureStorageProtocol interface, providing a clean abstraction for secure storage operations.
 */
public actor SecureStorageAdapter: SecureStorageProtocol {
  /// The underlying secure storage implementation
  private let storage: SecureCryptoStorage

  /// Logger for operations
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure storage adapter.

   - Parameters:
      - storage: The secure crypto storage implementation to adapt
      - logger: Logger for recording operations
   */
  public init(storage: SecureCryptoStorage, logger: any LoggingProtocol) {
    self.storage = storage
    self.logger = logger
  }

  /**
   Stores data securely with the specified identifier.

   - Parameters:
      - data: The data to store
      - identifier: The identifier to use for the data
   - Throws: If storing the data fails
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async throws {
    await logger.debug(
      "Storing data to secure storage",
      context: CryptoLogContext(
        operation: "storeData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        ).withPublic(
          key: "dataSize",
          value: "\(data.count)"
        )
      )
    )

    try await storage.storeData(Data(data), identifier: identifier)

    await logger.debug(
      "Data stored successfully",
      context: CryptoLogContext(
        operation: "storeData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )
  }

  /**
   Retrieves data with the specified identifier.

   - Parameter identifier: The identifier of the data to retrieve
   - Throws: If retrieving the data fails
   - Returns: The retrieved data
   */
  public func retrieveData(
    withIdentifier identifier: String
  ) async throws -> [UInt8] {
    await logger.debug(
      "Retrieving data from secure storage",
      context: CryptoLogContext(
        operation: "retrieveData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    let data = try await storage.retrieveData(identifier: identifier)

    await logger.debug(
      "Data retrieved successfully",
      context: CryptoLogContext(
        operation: "retrieveData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        ).withPublic(
          key: "dataSize",
          value: "\(data.count)"
        )
      )
    )
    return Array(data)
  }

  /**
   Deletes data with the specified identifier.

   - Parameter identifier: The identifier of the data to delete
   - Throws: If deleting the data fails
   */
  public func deleteData(
    withIdentifier identifier: String
  ) async throws {
    await logger.debug(
      "Deleting data from secure storage",
      context: CryptoLogContext(
        operation: "deleteData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    try await storage.deleteData(identifier: identifier)

    await logger.debug(
      "Data deleted successfully",
      context: CryptoLogContext(
        operation: "deleteData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )
  }

  /**
   Checks if data exists with the specified identifier.

   - Parameter identifier: The identifier of the data to check
   - Throws: If checking the data existence fails
   - Returns: A boolean indicating whether the data exists
   */
  public func containsData(
    withIdentifier identifier: String
  ) async throws -> Bool {
    await logger.debug(
      "Querying data existence in secure storage",
      context: CryptoLogContext(
        operation: "containsData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    return try await storage.hasData(withIdentifier: identifier)
  }

  /**
   Lists all data identifiers stored in the secure storage.

   - Throws: If listing the data identifiers fails
   - Returns: An array of identifiers
   */
  public func listDataIdentifiers() async throws -> [String] {
    await logger.warning(
      "List data identifiers operation not supported",
      context: CryptoLogContext(
        operation: "listIdentifiers",
        additionalContext: LogMetadataDTOCollection()
      )
    )

    throw StorageError.operationFailed("Operation not supported in this implementation")
  }
}
