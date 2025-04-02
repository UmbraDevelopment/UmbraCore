import Foundation
import KeychainInterfaces
import KeychainServices
import LoggingInterfaces
import LoggingServices
import ResticInterfaces

/// Factory implementation for creating Restic service instances.
///
/// This factory provides methods for creating ResticService instances with
/// various configurations, facilitating dependency injection and testability.
public struct ResticServiceFactoryImpl: ResticServiceFactory {
  private let logger: any LoggingProtocol
  private let keychain: any KeychainSecurityProtocol

  /// Creates a new ResticServiceFactory instance.
  ///
  /// - Parameters:
  ///   - logger: The logger to use for created services
  ///   - keychain: The keychain security service for credential management
  public init(
    logger: any LoggingProtocol,
    keychain: any KeychainSecurityProtocol
  ) {
    self.logger = logger
    self.keychain = keychain
  }

  /// Creates a new ResticService instance with the specified configuration.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default password for the repository
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created
  public func createResticService(
    executablePath: String,
    defaultRepository: String? = nil,
    defaultPassword: String? = nil,
    progressDelegate: ResticProgressReporting? = nil
  ) throws -> any ResticServiceProtocol {
    // Create the credential manager
    let credentialManager = KeychainResticCredentialManager(
      keychain: keychain,
      logger: logger
    )
    
    // If default password is provided, store it for the default repository
    if let defaultRepository = defaultRepository, let defaultPassword = defaultPassword {
      try Task {
        if !(await credentialManager.hasCredentials(for: defaultRepository)) {
          try await credentialManager.storeCredentials(
            ResticCredentials(
              repositoryIdentifier: defaultRepository,
              password: defaultPassword
            ),
            for: defaultRepository
          )
        }
      }.value
    }
    
    // Create domain-specific logger for the Restic service
    let resticLogger = ResticLogger(
      underlyingLogger: logger
    )
    
    // Create the service with domain-specific logger
    return try ResticServiceImpl(
      executablePath: executablePath,
      defaultRepository: defaultRepository,
      credentialManager: credentialManager,
      progressDelegate: progressDelegate,
      logger: resticLogger
    )
  }

  /// Creates a new ResticService instance with the system's default Restic executable.
  ///
  /// - Parameters:
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default password for the repository
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created or the Restic executable cannot be
  /// found
  public func createDefaultResticService(
    defaultRepository: String? = nil,
    defaultPassword: String? = nil,
    progressDelegate: ResticProgressReporting? = nil
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

  /// Creates a simple file-based Restic service for testing or development.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default password for the repository
  ///   - progressDelegate: Optional delegate for progress reporting
  /// - Returns: A new ResticService instance
  /// - Throws: ResticError if the service cannot be created
  public func createSimpleResticService(
    executablePath: String,
    defaultRepository: String? = nil,
    defaultPassword: String? = nil,
    progressDelegate: ResticProgressReporting? = nil
  ) throws -> any ResticServiceProtocol {
    // Create an in-memory credential manager for testing
    let credentialManager = InMemoryResticCredentialManager()
    
    // If default password is provided, store it for the default repository
    if let defaultRepository = defaultRepository, let defaultPassword = defaultPassword {
      try Task {
        if !(await credentialManager.hasCredentials(for: defaultRepository)) {
          try await credentialManager.storeCredentials(
            ResticCredentials(
              repositoryIdentifier: defaultRepository,
              password: defaultPassword
            ),
            for: defaultRepository
          )
        }
      }.value
    }
    
    // Create domain-specific logger for the Restic service
    let resticLogger = ResticLogger(
      underlyingLogger: logger
    )
    
    // Create the service with domain-specific logger
    return try ResticServiceImpl(
      executablePath: executablePath,
      defaultRepository: defaultRepository,
      credentialManager: credentialManager,
      progressDelegate: progressDelegate,
      logger: resticLogger
    )
  }
}
