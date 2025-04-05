import Foundation
import LoggingServices
import SecurityCoreInterfaces

/**
 A simple in-memory implementation of SecureStorageProtocol for testing.
 
 This implementation stores all data in memory and does not persist data between app runs,
 as it only stores data in memory and does not provide persistent storage.
 */
public actor InMemorySecureStorage: SecureStorageProtocol {
  /// In-memory storage dictionary
  private var storage: [String: [UInt8]] = [:]
  
  /// Logger for operations
  private let logger: LoggingProtocol
  
  public init(logger: LoggingProtocol) {
    self.logger = logger
  }
  
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Storing data with identifier: \(identifier)",
      metadata: nil,
      source: "InMemorySecureStorage"
    )
    
    storage[identifier] = data
    return .success(())
  }
  
  public func retrieveData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "Retrieving data with identifier: \(identifier)",
      metadata: nil,
      source: "InMemorySecureStorage"
    )
    
    guard let data = storage[identifier] else {
      return .failure(.keyNotFound)
    }
    
    return .success(data)
  }
  
  public func deleteData(
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      metadata: nil,
      source: "InMemorySecureStorage"
    )
    
    storage.removeValue(forKey: identifier)
    return .success(())
  }
  
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    await logger.debug(
      "Listing all data identifiers",
      metadata: nil,
      source: "InMemorySecureStorage"
    )
    
    return .success(Array(storage.keys))
  }
}
