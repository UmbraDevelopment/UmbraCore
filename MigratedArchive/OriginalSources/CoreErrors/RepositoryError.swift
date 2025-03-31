import Foundation

/// RepositoryError error type
public enum RepositoryError: Error {
  case notFound
  case repositoryNotFound
  case locked
  case notAccessible
  case invalidConfiguration
}
