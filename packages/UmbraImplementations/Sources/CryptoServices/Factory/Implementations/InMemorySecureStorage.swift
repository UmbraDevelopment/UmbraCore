import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import CryptoLogger

/**
 A simple in-memory implementation of SecureStorageProtocol for testing.

 This implementation stores all data in memory and does not persist data between app runs,
 as it only stores data in memory and does not provide persistent storage.
 */
public actor InMemorySecureStorage: SecureStorageProtocol {
  /// In-memory storage dictionary
  private var storage: [String: [UInt8]]=[:]

  /// Logger for operations
  private let logger: PrivacyAwareLoggingProtocol

  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger = logger
  }

  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context = CryptoLogContext(
      operation: "storeData",
      identifier: identifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: String(data.count))
    )
    
    await logger.debug("Storing data with identifier", context: context)

    storage[identifier]=data
    
    let successContext = CryptoLogContext(
      operation: "storeData",
      identifier: identifier,
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: String(data.count))
    )
    
    await logger.debug("Data stored successfully", context: successContext)
    return .success(())
  }

  public func retrieveData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let context = CryptoLogContext(
      operation: "retrieveData",
      identifier: identifier,
      status: "started"
    )
    
    await logger.debug("Retrieving data with identifier", context: context)

    guard let data=storage[identifier] else {
      let errorContext = CryptoLogContext(
        operation: "retrieveData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: "keyNotFound")
      )
      
      await logger.error("Data not found with identifier", context: errorContext)
      return .failure(.keyNotFound)
    }
    
    let successContext = CryptoLogContext(
      operation: "retrieveData",
      identifier: identifier,
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: String(data.count))
    )
    
    await logger.debug("Data retrieved successfully", context: successContext)
    return .success(data)
  }

  public func deleteData(
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context = CryptoLogContext(
      operation: "deleteData",
      identifier: identifier,
      status: "started"
    )
    
    await logger.debug("Deleting data with identifier", context: context)

    storage.removeValue(forKey: identifier)
    
    let successContext = CryptoLogContext(
      operation: "deleteData",
      identifier: identifier,
      status: "success"
    )
    
    await logger.debug("Data deleted successfully", context: successContext)
    return .success(())
  }

  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    let context = CryptoLogContext(
      operation: "listDataIdentifiers",
      status: "started"
    )
    
    await logger.debug("Listing all data identifiers", context: context)
    
    let successContext = CryptoLogContext(
      operation: "listDataIdentifiers",
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "count", value: String(storage.keys.count))
    )
    
    await logger.debug("Retrieved all data identifiers", context: successContext)
    return .success(Array(storage.keys))
  }

  public func exportData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    let context = CryptoLogContext(
      operation: "exportData",
      identifier: identifier,
      status: "started"
    )
    
    await logger.debug("Exporting data with identifier", context: context)
    
    guard let data=storage[identifier] else {
      let errorContext = CryptoLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: "keyNotFound")
      )
      
      await logger.error("Data not found for export", context: errorContext)
      return .failure(.keyNotFound)
    }
    
    let successContext = CryptoLogContext(
      operation: "exportData",
      identifier: identifier,
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: String(data.count))
    )
    
    await logger.debug("Data exported successfully", context: successContext)
    return .success(data)
  }
}
