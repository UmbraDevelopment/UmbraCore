import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # KeyMetadataStore
 
 Manages metadata for cryptographic keys stored in the security system.
 This component separates the metadata storage from the actual key material,
 providing better security compartmentalisation while enabling efficient
 key discovery and management.
 
 The metadata store uses a secure storage backend (SecureStorageProtocol)
 with prefix-based naming to isolate metadata entries from key material.
 */
public actor KeyMetadataStore: Sendable {
    /// Prefix used for all metadata entries to distinguish them from actual keys
    private let metadataPrefix: String = "metadata:"
    
    /// Secure storage backend used for persisting metadata
    private let secureStorage: SecureStorageProtocol
    
    /**
     Initialises a new KeyMetadataStore with the specified secure storage.
     
     - Parameter secureStorage: The secure storage implementation to use
     */
    public init(secureStorage: SecureStorageProtocol) {
        self.secureStorage = secureStorage
    }
    
    /**
     Gets the metadata identifier for a key identifier.
     
     - Parameter keyIdentifier: The key identifier
     - Returns: The corresponding metadata identifier
     */
    private func metadataIdentifier(for keyIdentifier: String) -> String {
        return "\(metadataPrefix)\(keyIdentifier)"
    }
    
    /**
     Extracts the key identifier from a metadata identifier.
     
     - Parameter metadataIdentifier: The metadata identifier
     - Returns: The corresponding key identifier, or nil if not a valid metadata identifier
     */
    private func keyIdentifier(from metadataIdentifier: String) -> String? {
        guard metadataIdentifier.hasPrefix(metadataPrefix) else {
            return nil
        }
        
        let startIndex = metadataIdentifier.index(
            metadataIdentifier.startIndex,
            offsetBy: metadataPrefix.count
        )
        return String(metadataIdentifier[startIndex...])
    }
    
    /**
     Stores metadata for a key.
     
     - Parameters:
       - metadata: The key metadata to store
     - Throws: If storing the metadata fails
     */
    public func storeKeyMetadata(_ metadata: KeyMetadata) async throws {
        let metadataId = metadataIdentifier(for: metadata.id)
        let bytes = try metadata.serialise()
        
        let result = await self.secureStorage.storeData(bytes, withIdentifier: metadataId)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw KeyMetadataError.metadataError(
                details: "Failed to store key metadata: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Retrieves metadata for a key.
     
     - Parameter keyIdentifier: The key identifier
     - Returns: The key metadata, or nil if not found
     - Throws: If retrieving the metadata fails
     */
    public func getKeyMetadata(for keyIdentifier: String) async throws -> KeyMetadata? {
        let metadataId = metadataIdentifier(for: keyIdentifier)
        let result = await self.secureStorage.retrieveData(withIdentifier: metadataId)
        
        switch result {
        case .success(let bytes):
            return try KeyMetadata.deserialise(from: bytes)
        case .failure(let error):
            if case .keyNotFound = error {
                return nil
            }
            throw KeyMetadataError.metadataError(
                details: "Failed to retrieve key metadata: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Deletes metadata for a key.
     
     - Parameter keyIdentifier: The key identifier
     - Throws: If deleting the metadata fails
     */
    public func deleteKeyMetadata(for keyIdentifier: String) async throws {
        let metadataId = metadataIdentifier(for: keyIdentifier)
        let result = await self.secureStorage.deleteData(withIdentifier: metadataId)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            if case .keyNotFound = error {
                return
            }
            throw KeyMetadataError.metadataError(
                details: "Failed to delete key metadata: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Retrieves metadata for all keys.
     
     - Returns: Array of key metadata objects
     - Throws: If retrieving the metadata fails
     */
    public func getAllKeyMetadata() async throws -> [KeyMetadata] {
        let result = await self.secureStorage.listDataIdentifiers()
        
        switch result {
        case .success(let identifiers):
            var metadataList: [KeyMetadata] = []
            
            for identifier in identifiers {
                // Only process metadata entries
                guard let keyId = keyIdentifier(from: identifier) else {
                    continue
                }
                
                if let metadata = try await getKeyMetadata(for: keyId) {
                    metadataList.append(metadata)
                }
            }
            
            return metadataList
            
        case .failure(let error):
            throw KeyMetadataError.metadataError(
                details: "Failed to list key metadata: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Retrieves all key identifiers from the metadata store.
     
     - Returns: A list of key identifiers
     - Throws: If retrieving the identifiers fails
     */
    public func getAllKeyIdentifiers() async throws -> [String] {
        let metadata = try await getAllKeyMetadata()
        return metadata.map { $0.id }
    }
}

/// Errors specific to key metadata operations
public extension KeyMetadataError {
    /// Error related to metadata storage operations for backward compatibility
    static func metadataStorageError(details: String) -> KeyMetadataError {
        return .metadataError(details: details)
    }
}
