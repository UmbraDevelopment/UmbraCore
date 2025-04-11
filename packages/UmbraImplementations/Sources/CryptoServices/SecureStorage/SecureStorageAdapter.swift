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
  /// The operation failed with a reason
  case operationFailedWithReason(String)
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
    self.storage=storage
    self.logger=logger
  }

  /**
   Stores data securely with the specified identifier.

   - Parameters:
      - data: The data to store
      - identifier: The identifier to use for the data
   - Returns: A result indicating success or an error
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
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

    do {
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

      return .success(())
    } catch {
      await logger.error(
        "Failed to store data: \(error.localizedDescription)",
        context: CryptoLogContext(
          operation: "storeData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )
      )

      return .failure(.generalError(reason: error.localizedDescription))
    }
  }

  /**
   Retrieves data with the specified identifier.

   - Parameter identifier: The identifier of the data to retrieve
   - Returns: A result containing the retrieved data or an error
   */
  public func retrieveData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
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

    do {
      let data=try await storage.retrieveData(identifier: identifier)

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

      return .success(Array(data))
    } catch {
      await logger.error(
        "Failed to retrieve data: \(error.localizedDescription)",
        context: CryptoLogContext(
          operation: "retrieveData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )
      )

      if let storageError=error as? StorageError, case .dataNotFound=storageError {
        return .failure(.dataNotFound)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }

  /**
   Deletes data with the specified identifier.

   - Parameter identifier: The identifier of the data to delete
   - Returns: A result indicating success or an error
   */
  public func deleteData(
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
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

    do {
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

      return .success(())
    } catch {
      await logger.error(
        "Failed to delete data: \(error.localizedDescription)",
        context: CryptoLogContext(
          operation: "deleteData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )
      )

      return .failure(.generalError(reason: error.localizedDescription))
    }
  }

  /**
   Lists all data identifiers stored in the secure storage.

   - Returns: A result containing an array of identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    await logger.warning(
      "List data identifiers operation not supported",
      context: CryptoLogContext(
        operation: "listIdentifiers",
        additionalContext: LogMetadataDTOCollection()
      )
    )

    return .failure(.generalError(reason: "Operation not supported in this implementation"))
  }
}
