import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// Factory for creating RepositoryService instances
public enum RepositoryServiceFactory {
  /// Shared instance of the repository service
  private static var sharedInstance: RepositoryServiceProtocol?

  /// Creates a new repository service instance
  ///
  /// - Parameter logger: Optional logger to use for the service. If not provided, a default logger
  /// will be created.
  /// - Returns: A new repository service instance
  public static func create(logger: LoggingProtocol?=nil) -> RepositoryServiceProtocol {
    let actualLogger=logger ?? UmbraLoggingAdapters.createLogger()
    return RepositoryServiceImpl(logger: actualLogger)
  }

  /// Gets or creates a shared repository service instance
  ///
  /// - Parameter logger: Optional logger to use for the service. If not provided, a default logger
  /// will be created.
  /// - Returns: The shared repository service instance
  public static func createSharedInstance(logger: LoggingProtocol?=nil)
  -> RepositoryServiceProtocol {
    if let existing=sharedInstance {
      return existing
    }

    let service=create(logger: logger)
    sharedInstance=service
    return service
  }

  /// Resets the shared repository service instance
  ///
  /// This method is primarily useful for testing purposes.
  public static func resetSharedInstance() {
    sharedInstance=nil
  }
}
