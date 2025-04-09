import Foundation

/// Factory protocol for creating Restic service instances.
///
/// This factory allows the creation of ResticService instances with various configurations,
/// facilitating dependency injection and testability.
public protocol ResticServiceFactory: Sendable {
  /// Creates a new ResticService instance with the specified configuration.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default repository password
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created
  func createService(
    executablePath: String,
    defaultRepository: String?,
    defaultPassword: String?,
    progressDelegate: ResticProgressReporting?
  ) throws -> any ResticServiceProtocol

  /// Creates a new ResticService instance with the system's default Restic executable.
  ///
  /// - Parameters:
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default repository password
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created or the Restic executable cannot be
  /// found
  func createDefault(
    defaultRepository: String?,
    defaultPassword: String?,
    progressDelegate: ResticProgressReporting?
  ) throws -> any ResticServiceProtocol
}
