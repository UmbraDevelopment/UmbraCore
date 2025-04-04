import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import UmbraErrors
import LoggingInterfaces

/**
 # TestSecureStorageActor
 
 A simple in-memory actor implementation of SecureStorageProtocol specifically for testing purposes.
 This implementation uses Swift's actor model to provide thread-safe access to an in-memory storage.
 
 This actor is intended ONLY for testing and should not be used in production code.
 It provides no actual security guarantees and stores all data in volatile memory.
 */
public actor TestSecureStorageActor: SecureStorageProtocol {
    /// Provider type identifier - basic is used as there is no specific 'test' type
    public nonisolated let providerType: SecurityProviderType = .basic
    
    /// In-memory storage for data
    private var storage: [String: [UInt8]] = [:]
    
    /// Logger for operations
    private let logger: LoggingProtocol
    
    /**
     Initialises a new test secure storage actor with the specified logger.
     
     - Parameter logger: The logger to use for recording operations
     */
    public init(logger: LoggingProtocol) {
        self.logger = logger
        Task {
            await logger.warning(
                "Using TestSecureStorageActor which is intended for testing only. Data is stored in memory and will be lost when the application terminates.",
                metadata: nil,
                source: "TestSecureStorageActor"
            )
        }
    }
    
    /**
     Stores data securely and returns an identifier.
     
     - Parameters:
        - data: The data to store
        - identifier: The identifier for the data
     - Returns: Success or an error
     */
    public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        await logger.debug("Storing data in test secure storage", metadata: nil, source: "TestSecureStorageActor")
        storage[identifier] = data
        return .success(())
    }
    
    /**
     Retrieves data by its identifier.
     
     - Parameter identifier: The identifier of the data to retrieve
     - Returns: The retrieved data or an error
     */
    public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
        await logger.debug("Retrieving data from test secure storage", metadata: nil, source: "TestSecureStorageActor")
        
        guard let data = storage[identifier] else {
            await logger.error("Data not found with identifier: \(identifier)", metadata: nil, source: "TestSecureStorageActor")
            return .failure(.dataNotFound)
        }
        
        return .success(data)
    }
    
    /**
     Removes data by its identifier.
     
     - Parameter identifier: The identifier of the data to remove
     - Returns: Success or an error
     */
    public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        await logger.debug("Removing data from test secure storage", metadata: nil, source: "TestSecureStorageActor")
        
        guard storage[identifier] != nil else {
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
        await logger.debug("Listing identifiers in test secure storage", metadata: nil, source: "TestSecureStorageActor")
        return .success(Array(storage.keys))
    }
}
