import Foundation
import RepositoryInterfaces

/**
 Extensions to Repository protocol to provide metadata access methods
 */
public extension RepositoryProtocol {
    /**
     Gets the name of the repository.
     
     - Returns: The repository name or nil if not set
     */
    func getName() async throws -> String? {
        guard let metadata = try await getMetadata() else {
            return nil
        }
        
        return metadata["name"] as? String
    }
    
    /**
     Gets the creation date of the repository.
     
     - Returns: The repository creation date or nil if not set
     */
    func getCreationDate() async throws -> Date? {
        guard let metadata = try await getMetadata() else {
            return nil
        }
        
        if let dateString = metadata["creation_date"] as? String {
            return DateFormatter().date(from: dateString)
        }
        
        return nil
    }
    
    /**
     Gets the last access date of the repository.
     
     - Returns: The repository last access date or nil if not set
     */
    func getLastAccessDate() async throws -> Date? {
        guard let metadata = try await getMetadata() else {
            return nil
        }
        
        if let dateString = metadata["last_access_date"] as? String {
            return DateFormatter().date(from: dateString)
        }
        
        return nil
    }
    
    /**
     Sets the name of the repository.
     
     - Parameter name: The name to set
     */
    func setName(_ name: String) async throws {
        var metadata = try await getMetadata() ?? [:]
        metadata["name"] = name
        try await setMetadata(metadata)
    }
    
    /**
     Gets the metadata of the repository.
     
     - Returns: The repository metadata or nil if not available
     */
    func getMetadata() async throws -> [String: Any]? {
        // In a real implementation, this would be stored in the repository
        // For now, we'll return nil as this is just a placeholder
        return nil
    }
    
    /**
     Sets the metadata of the repository.
     
     - Parameter metadata: The metadata to set
     */
    func setMetadata(_ metadata: [String: Any]) async throws {
        // In a real implementation, this would store the metadata in the repository
        // For now, this is just a placeholder
    }
}
