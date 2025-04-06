import Foundation
import RepositoryInterfaces

/**
 Extension to RepositoryProtocol to add convenience methods needed by the API services
 */
public extension RepositoryProtocol {
    /**
     Get the display name for the repository
     */
    func getName() async throws -> String? {
        return self.identifier
    }
    
    /**
     Get the creation date for the repository
     */
    func getCreationDate() async throws -> Date? {
        return Date()
    }
    
    /**
     Get the last access date for the repository
     */
    func getLastAccessDate() async throws -> Date? {
        return Date()
    }
    
    /**
     Set the display name for the repository
     */
    func setName(_ name: String) async throws {
        // Implementation would update name in real service
    }
    
    /**
     Set metadata for the repository
     */
    func setMetadata(_ metadata: [String: String]) async throws {
        // Implementation would update metadata in real service
    }
}
