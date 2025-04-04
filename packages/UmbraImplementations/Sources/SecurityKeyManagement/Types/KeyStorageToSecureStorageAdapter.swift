import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # KeyStorageToSecureStorageAdapter
 
 Adapts the KeyStorage protocol to the SecureStorageProtocol interface.
 This adapter allows a KeyStorage implementation to be used where a 
 SecureStorageProtocol is required, maintaining compatibility with
 interfaces that expect SecureStorageProtocol.
 
 The adapter maps operations between the two protocols, handling differences
 in their method signatures and error types.
 */
public actor KeyStorageToSecureStorageAdapter: SecureStorageProtocol {
    /// The underlying key storage implementation
    private let keyStorage: KeyStorage
    
    /**
     Initialises a new adapter with the specified key storage.
     
     - Parameter keyStorage: The underlying key storage implementation
     */
    public init(keyStorage: KeyStorage) {
        self.keyStorage = keyStorage
    }
    
    /**
     Stores data securely with the given identifier.
     
     - Parameters:
       - data: The data to store as a byte array
       - identifier: A string identifier for the stored data
     - Returns: Success or an error
     */
    public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        do {
            try await keyStorage.storeKey(data, identifier: identifier)
            return .success(())
        } catch {
            return .failure(.encryptionFailed)
        }
    }
    
    /**
     Retrieves data securely by its identifier.
     
     - Parameter identifier: A string identifying the data to retrieve
     - Returns: The retrieved data as a byte array or an error
     */
    public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
        do {
            if let data = try await keyStorage.getKey(identifier: identifier) {
                return .success(data)
            } else {
                return .failure(.keyNotFound)
            }
        } catch {
            return .failure(.dataNotFound)
        }
    }
    
    /**
     Deletes data securely by its identifier.
     
     - Parameter identifier: A string identifying the data to delete
     - Returns: Success or an error
     */
    public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        do {
            try await keyStorage.deleteKey(identifier: identifier)
            return .success(())
        } catch {
            return .failure(.dataNotFound)
        }
    }
    
    /**
     Lists all available data identifiers.
     
     - Returns: An array of data identifiers or an error
     */
    public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
        // Since KeyStorage doesn't have a built-in method to list keys,
        // we'll either need to maintain a separate registry or return an empty list
        
        // This is a placeholder - in a real implementation, we would need
        // a way to track stored identifiers separately
        return .success([])
    }
}
