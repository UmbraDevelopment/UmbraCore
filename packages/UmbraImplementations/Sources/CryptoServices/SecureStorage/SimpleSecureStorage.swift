import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 A simple in-memory implementation of SecureStorageProtocol.

 This implementation provides a minimal implementation for testing and development,
 without the full security features of the production implementation.
 */
public actor SimpleSecureStorage: SecureStorageProtocol {
  /// In-memory storage dictionary
  private var storage: [String: [UInt8]]=[:]

  /// Logger for operations
  private let logger: LoggingProtocol

  /**
   Initialises a new simple secure storage.

   - Parameter logger: Logger for operation tracking
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   Creates a simple log context for operations.

   - Parameters:
      - operation: The operation being performed
      - identifier: Optional identifier for the item being operated on
   - Returns: A log context
   */
  private func createLogContext(operation: String, identifier: String?=nil) -> LogContextDTO {
    var metadata=LogMetadataDTOCollection()

    if let identifier {
      metadata=metadata.withPublic(key: "identifier", value: identifier)
    }

    metadata=metadata.withPublic(key: "operation", value: operation)

    return SimpleLogContext(
      domainName: "CryptoServices",
      operation: operation,
      category: "Storage",
      source: "SimpleSecureStorage",
      correlationID: nil,
      metadata: metadata
    )
  }

  /**
   Stores data under the specified identifier.

   - Parameters:
      - data: The data to store
      - identifier: The identifier to associate with the data
   - Returns: Success or failure with error information
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let logContext=createLogContext(operation: "storeData", identifier: identifier)
    await logger.debug(
      "Storing \(data.count) bytes with identifier \(identifier)",
      context: logContext
    )

    storage[identifier]=data
    return .success(())
  }

  /**
   Retrieves data associated with the specified identifier.

   - Parameter identifier: The identifier of the data to retrieve
   - Returns: The retrieved data or an error
   */
  public func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    let logContext=createLogContext(operation: "retrieveData", identifier: identifier)
    await logger.debug("Retrieving data with identifier \(identifier)", context: logContext)

    guard let data=storage[identifier] else {
      return .failure(.operationFailed("No data found for identifier \(identifier)"))
    }

    return .success(data)
  }

  /**
   Deletes data associated with the specified identifier.

   - Parameter identifier: The identifier of the data to delete
   - Returns: Success or an error
   */
  public func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    let logContext=createLogContext(operation: "deleteData", identifier: identifier)
    await logger.debug("Deleting data with identifier \(identifier)", context: logContext)

    storage.removeValue(forKey: identifier)
    return .success(())
  }

  /**
   Lists all identifiers in storage.

   - Returns: Array of identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    let logContext=createLogContext(operation: "listDataIdentifiers")
    await logger.debug("Listing all data identifiers", context: logContext)

    return .success(Array(storage.keys))
  }
}

/**
 A simple implementation of LogContextDTO for use with SimpleSecureStorage.
 */
private struct SimpleLogContext: LogContextDTO {
  /// The domain name
  public let domainName: String

  /// The operation being performed (required by protocol)
  public let operation: String
  
  /// The category for the log entry (required by protocol)
  public let category: String

  /// The source identifier (optional as per protocol)
  public let source: String?

  /// The correlation ID (required by protocol)
  public let correlationID: String?

  /// The log metadata
  public let metadata: LogMetadataDTOCollection

  /**
   Initializes a new SimpleLogContext.

   - Parameters:
      - domainName: The domain name
      - operation: The operation being performed
      - category: The category for the log entry
      - source: The source identifier
      - correlationID: Optional correlation ID for tracing
      - metadata: The log metadata
   */
  init(
    domainName: String,
    operation: String,
    category: String,
    source: String,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.domainName=domainName
    self.operation=operation
    self.category=category
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  /**
   Creates a new log context with additional metadata merged with the existing metadata.
   
   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    var newMetadata = self.metadata
     
    for entry in additionalMetadata.entries {
      newMetadata = newMetadata.with(
        key: entry.key,
        value: entry.value,
        privacyLevel: entry.privacyLevel
      )
    }
     
    return SimpleLogContext(
      domainName: self.domainName,
      operation: self.operation,
      category: self.category,
      source: self.source,
      correlationID: self.correlationID,
      metadata: newMetadata
    )
  }
}
