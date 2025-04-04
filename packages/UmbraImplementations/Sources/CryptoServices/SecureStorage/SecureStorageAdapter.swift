/**
 # SecureStorageAdapter
 
 Adapter for bridging between different secure storage protocols in the UmbraCore system.
 
 This adapter ensures compatibility between SecureStorageProtocol methods and the older
 secure storage interfaces, following the Alpha Dot Five architecture principles.
 */

import Foundation
import SecurityCoreInterfaces
import CoreSecurityTypes
import UmbraErrors
import LoggingInterfaces
import LoggingTypes

/**
 Adapts SecureCryptoStorage to support SecureStorageProtocol.
 
 This adapter converts between the SecureStorageProtocol methods and the methods
 used by SecureCryptoStorage, allowing for a clean integration with the rest of
 the system without requiring changes to the core storage implementation.
 */
public actor SecureStorageAdapter: SecureStorageProtocol {
    /// The underlying SecureCryptoStorage instance
    private let storage: SecureCryptoStorage
    
    /// Logger for recording storage operations with proper privacy controls
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new SecureStorageAdapter.
     
     - Parameters:
        - storage: The SecureCryptoStorage instance to adapt
        - logger: Logger for recording operations
     */
    public init(storage: SecureCryptoStorage, logger: any LoggingProtocol) {
        self.storage = storage
        self.logger = logger
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
            let dataObj = Data(data)
            let config = SecureStorageConfig(
                accessControl: .standard,
                encrypt: true,
                context: ["type": "generic_data"]
            )
            
            // Create a key reference for storing as a generic data item
            try await storage.storeKey(
                dataObj,
                identifier: identifier,
                purpose: .generic,
                algorithm: nil
            )
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "storeData", privacy: .public)
            metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)
            
            await logger.debug(
                "Successfully stored data with adapter",
                metadata: metadata,
                source: "SecureStorageAdapter"
            )
            
            return .success(())
        } catch {
            await logger.error(
                "Failed to store data with adapter: \(error.localizedDescription)",
                metadata: nil,
                source: "SecureStorageAdapter"
            )
            return .failure(.storageError(error.localizedDescription))
        }
    }
    
    /**
     Retrieves data securely by its identifier.
     
     - Parameter identifier: A string identifying the data to retrieve
     - Returns: The retrieved data as a byte array or an error
     */
    public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
        do {
            let data = try await storage.retrieveKey(identifier: identifier)
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "retrieveData", privacy: .public)
            metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)
            
            await logger.debug(
                "Successfully retrieved data with adapter",
                metadata: metadata,
                source: "SecureStorageAdapter"
            )
            
            return .success([UInt8](data))
        } catch {
            await logger.error(
                "Failed to retrieve data with adapter: \(error.localizedDescription)",
                metadata: nil,
                source: "SecureStorageAdapter"
            )
            return .failure(.itemNotFound(identifier))
        }
    }
    
    /**
     Deletes data securely by its identifier.
     
     - Parameter identifier: A string identifying the data to delete
     - Returns: Success or an error
     */
    public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        do {
            try await storage.deleteKey(identifier: identifier)
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "deleteData", privacy: .public)
            metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)
            
            await logger.debug(
                "Successfully deleted data with adapter",
                metadata: metadata,
                source: "SecureStorageAdapter"
            )
            
            return .success(())
        } catch {
            await logger.error(
                "Failed to delete data with adapter: \(error.localizedDescription)",
                metadata: nil,
                source: "SecureStorageAdapter"
            )
            return .failure(.itemNotFound(identifier))
        }
    }
    
    /**
     Lists all available data identifiers.
     
     - Returns: An array of data identifiers or an error
     
     Note: This implementation provides a stub as the underlying storage
     does not directly support listing all identifiers.
     */
    public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
        await logger.warning(
            "listDataIdentifiers not fully implemented in SecureStorageAdapter",
            metadata: nil,
            source: "SecureStorageAdapter"
        )
        return .failure(.operationNotSupported("Listing identifiers is not supported by this storage implementation"))
    }
}
