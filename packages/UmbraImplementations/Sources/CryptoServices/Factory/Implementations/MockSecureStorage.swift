import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 A mock implementation of SecureStorageProtocol for testing and development.
 
 This implementation provides a simple in-memory storage solution that can be used
 when a real secure storage implementation is not available or not required.
 It should only be used for testing and development purposes.
 */
public final class MockSecureStorage: SecureStorageProtocol {
    /// In-memory storage for data
    private let storageActor = StorageActor()
    
    /// Logger for operations
    private let logger: LoggingProtocol
    
    /// Actor to handle thread-safe storage operations
    private actor StorageActor {
        /// In-memory storage for data
        var storage: [String: [UInt8]] = [:]
        
        /// Store data in the storage
        func store(_ data: [UInt8], identifier: String) {
            storage[identifier] = data
        }
        
        /// Retrieve data from the storage
        func retrieve(identifier: String) -> [UInt8]? {
            return storage[identifier]
        }
        
        /// Delete data from the storage
        func delete(identifier: String) {
            storage.removeValue(forKey: identifier)
        }
        
        /// Check if the storage has a key
        func hasKey(_ identifier: String) -> Bool {
            return storage[identifier] != nil
        }
    }
    
    /// Initialise with a logger
    public init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    /// Store data with an identifier
    public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        await storageActor.store(data, identifier: identifier)
        return .success(())
    }
    
    /// Retrieve data with an identifier
    public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
        guard let data = await storageActor.retrieve(identifier: identifier) else {
            return .failure(.dataNotFound)
        }
        return .success(data)
    }
    
    /// Delete data with an identifier
    public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        await storageActor.delete(identifier: identifier)
        return .success(())
    }
    
    /// Check if data exists with an identifier
    public func hasData(withIdentifier identifier: String) async -> Bool {
        return await storageActor.hasKey(identifier)
    }
    
    /// List all identifiers
    public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
        let identifiers = await storageActor.storage.keys
        return .success(Array(identifiers))
    }
}
