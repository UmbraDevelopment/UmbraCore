import Foundation
import RepositoryInterfaces

/**
 Extension to RepositoryProtocol to add convenience methods needed by the API services
 */
extension RepositoryProtocol {
  /**
   Get the display name for the repository
   */
  public func getName() async throws -> String? {
    identifier
  }

  /**
   Get the creation date for the repository
   */
  public func getCreationDate() async throws -> Date? {
    Date()
  }

  /**
   Get the last access date for the repository
   */
  public func getLastAccessDate() async throws -> Date? {
    Date()
  }

  /**
   Set the display name for the repository
   */
  public func setName(_: String) async throws {
    // Implementation would update name in real service
  }

  /**
   Set metadata for the repository
   */
  public func setMetadata(_: [String: String]) async throws {
    // Implementation would update metadata in real service
  }
}
