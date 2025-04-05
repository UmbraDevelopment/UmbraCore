import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/// Factory implementation for creating Restic service instances.
///
/// This factory provides methods for creating ResticService instances with
/// various configurations, facilitating dependency injection and testability.
public final class ResticServiceFactoryImpl: ResticServiceFactory {
  private let logger: any LoggingProtocol
  private let keychain: any KeychainServiceProtocol

  /// Initialise the factory with dependencies
  ///
  /// - Parameters:
  ///   - logger: Logger to use for created services
  ///   - keychain: Keychain service for credential management
  public init(
    logger: any LoggingProtocol,
    keychain: any KeychainServiceProtocol
  ) {
    self.logger=logger
    self.keychain=keychain
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
    // Create a credential manager for the service
    let credentialManager=KeychainResticCredentialManager(
      keychain: keychain,
      logger: ResticLogger(logger: logger)
    )

    // Create the service
    return ResticServiceImpl(
      executablePath: executablePath,
      logger: logger,
      credentialManager: credentialManager,
      defaultRepository: defaultRepository,
      defaultPassword: defaultPassword,
      progressDelegate: progressDelegate
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

    throw ResticError.invalidConfiguration(
      "Restic executable not found in standard paths. Please provide an explicit path."
    )
  }
}
