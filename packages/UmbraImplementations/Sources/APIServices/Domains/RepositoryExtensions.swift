import Foundation
import RepositoryInterfaces

/**
 Extensions to the RepositoryProtocol to add functionality needed for the API services.
 */
extension RepositoryProtocol {
    /**
     * Get the name of the repository.
     *
     * @return The name of the repository or nil if not set
     * @throws If the operation fails
     */
    func getName() async throws -> String? {
        // Retrieve from metadata or return identifier if not set
        if let metadata = try await getMetadata(),
           let name = metadata["name"] as? String {
            return name
        }
        return identifier
    }
    
    /**
     * Get the creation date of the repository.
     *
     * @return The creation date or nil if not set
     * @throws If the operation fails
     */
    func getCreationDate() async throws -> Date? {
        if let metadata = try await getMetadata(),
           let creationDateString = metadata["creation_date"] as? String,
           let creationDate = Date(creationDateString) {
            return creationDate
        }
        return nil
    }
    
    /**
     * Get the last access date of the repository.
     *
     * @return The last access date or nil if not set
     * @throws If the operation fails
     */
    func getLastAccessDate() async throws -> Date? {
        if let metadata = try await getMetadata(),
           let accessDateString = metadata["last_access_date"] as? String,
           let accessDate = Date(accessDateString) {
            return accessDate
        }
        return nil
    }
    
    /**
     * Set the name of the repository.
     *
     * @param name The name to set
     * @throws If the operation fails
     */
    func setName(_ name: String) async throws {
        var metadata = try await getMetadata() ?? [:]
        metadata["name"] = name
        try await setMetadata(metadata)
    }
    
    /**
     * Set metadata for the repository.
     *
     * @param metadata The metadata to set
     * @throws If the operation fails
     */
    func setMetadata(_ metadata: [String: Any]) async throws {
        // Implementation would depend on the actual repository interface
        // For now, we'll use a no-op as this is just adding extension methods
    }
    
    /**
     * Get metadata for the repository.
     *
     * @return The metadata or nil if not set
     * @throws If the operation fails
     */
    func getMetadata() async throws -> [String: Any]? {
        // Implementation would depend on the actual repository interface
        // For now, we'll return nil to add extension methods
        return nil
    }
}

// Helper extension for Date to parse from a string
private extension Date {
    init?(_ dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            self = date
            return
        }
        return nil
    }
}
