import Foundation
import APIInterfaces

/**
 * Extensions to RepositoryProtocol to provide the methods needed
 * for the Alpha Dot Five architecture implementation.
 *
 * These extensions provide convenience methods that weren't available
 * in the original protocol definition.
 */
public extension RepositoryProtocol {
    /**
     * Gets the display name for the repository
     * 
     * - Returns: The repository name or nil if not available
     */
    func getName() async throws -> String? {
        return identifier
    }
    
    /**
     * Gets the creation date for the repository
     * 
     * - Returns: The creation date or nil if not available
     */
    func getCreationDate() async throws -> Date? {
        // Try to get creation date from state or metadata
        // For now, returning nil as a placeholder
        return nil
    }
    
    /**
     * Gets the last access date for the repository
     * 
     * - Returns: The last access date or nil if not available
     */
    func getLastAccessDate() async throws -> Date? {
        // Try to get last access date from state or metadata
        // For now, returning nil as a placeholder
        return nil
    }
    
    /**
     * Sets the display name for the repository
     * 
     * - Parameter name: The name to set
     */
    func setName(_ name: String) async throws {
        // This would be implemented to store the name in repository metadata
    }
    
    /**
     * Sets metadata for the repository
     * 
     * - Parameter metadata: The metadata to set
     */
    func setMetadata(_ metadata: [String: String]) async throws {
        // This would store the metadata in the repository
    }
}
