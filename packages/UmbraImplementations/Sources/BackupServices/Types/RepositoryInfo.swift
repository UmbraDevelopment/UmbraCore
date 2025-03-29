import BackupInterfaces
import Foundation

/// A structure representing information about a backup repository
///
/// This type provides essential metadata about a repository that
/// can be used by backup services to connect to and authenticate
/// with the repository.
public struct RepositoryInfo: Sendable, Equatable {
  /// The physical location of the repository
  public let location: String

  /// The unique identifier for the repository
  public let id: String

  /// Optional password used to secure the repository
  public let password: String?

  /// Optional description of the repository
  public let description: String?

  /// Creates a new repository information object
  /// - Parameters:
  ///   - location: The physical location of the repository
  ///   - id: The unique identifier for the repository
  ///   - password: Optional password used to secure the repository
  ///   - description: Optional description of the repository
  public init(
    location: String,
    id: String,
    password: String?=nil,
    description: String?=nil
  ) {
    self.location=location
    self.id=id
    self.password=password
    self.description=description
  }
}
