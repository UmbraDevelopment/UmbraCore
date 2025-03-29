import Foundation
import LoggingInterfaces
import ResticInterfaces

/// Factory implementation for creating Restic service instances.
///
/// This factory provides methods for creating ResticService instances with
/// various configurations, facilitating dependency injection and testability.
public struct ResticServiceFactoryImpl: ResticServiceFactory {
  private let logger: any LoggingProtocol

  /// Creates a new ResticServiceFactory instance.
  ///
  /// - Parameter logger: The logger to use for created services
  public init(logger: any LoggingProtocol) {
    self.logger=logger
  }

  /// Creates a new ResticService instance with the specified configuration.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default repository password
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created
  public func createResticService(
    executablePath: String,
    defaultRepository: String?,
    defaultPassword: String?,
    progressDelegate: ResticProgressReporting?
  ) throws -> any ResticServiceProtocol {
    try ResticServiceImpl(
      executablePath: executablePath,
      defaultRepository: defaultRepository,
      defaultPassword: defaultPassword,
      progressDelegate: progressDelegate,
      logger: logger
    )
  }

  /// Creates a new ResticService instance with the system's default Restic executable.
  ///
  /// - Parameters:
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default repository password
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created or the Restic executable cannot be
  /// found
  public func createDefaultResticService(
    defaultRepository: String?,
    defaultPassword: String?,
    progressDelegate: ResticProgressReporting?
  ) throws -> any ResticServiceProtocol {
    // Try to find Restic in common locations
    let possiblePaths=[
      "/usr/local/bin/restic",
      "/usr/bin/restic",
      "/opt/homebrew/bin/restic"
    ]

    for path in possiblePaths {
      if FileManager.default.fileExists(atPath: path) {
        return try createResticService(
          executablePath: path,
          defaultRepository: defaultRepository,
          defaultPassword: defaultPassword,
          progressDelegate: progressDelegate
        )
      }
    }

    // If we couldn't find Restic, try to use the PATH environment
    let task=Process()
    task.executableURL=URL(fileURLWithPath: "/usr/bin/which")
    task.arguments=["restic"]

    let outputPipe=Pipe()
    task.standardOutput=outputPipe

    do {
      try task.run()
      task.waitUntilExit()

      if task.terminationStatus == 0 {
        if
          let data=try outputPipe.fileHandleForReading.readToEnd(),
          let path=String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !path.isEmpty
        {
          return try createResticService(
            executablePath: path,
            defaultRepository: defaultRepository,
            defaultPassword: defaultPassword,
            progressDelegate: progressDelegate
          )
        }
      }
    } catch {
      // Ignore errors from the which command
    }

    throw ResticError
      .invalidConfiguration(
        "Restic executable not found in standard paths. Please provide an explicit path."
      )
  }
}
