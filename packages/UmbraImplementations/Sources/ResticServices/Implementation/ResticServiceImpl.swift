import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/// Implementation of the Restic service for interfacing with the Restic command-line tool.
///
/// This actor-based implementation provides proper isolation for concurrent operations,
/// ensuring thread safety while maintaining high performance for Restic operations.
@preconcurrency
public actor ResticServiceImpl: ResticServiceProtocol {
  /// The path to the Restic executable
  public let executablePath: String

  /// The logger for the service
  private let logger: any LoggingProtocol

  /// Restic-specific logger for formatted logging
  private let resticLogger: ResticLogger

  /// Credential manager for repository passwords
  private let credentialManager: ResticCredentialManager

  /// Private storage for default repository
  private var _defaultRepository: String?

  /// Gets the default repository location in an async context
  /// - Returns: The default repository location if set
  private func getDefaultRepository() async -> String? {
    _defaultRepository
  }

  /// Private storage for default password
  private var _defaultPassword: String?

  /// Gets the default password in an async context
  /// - Returns: The default password if set
  private func getDefaultPassword() async -> String? {
    _defaultPassword
  }

  /// Private storage for progress delegate
  private var _progressDelegate: ResticProgressReporting?

  /// Gets the progress delegate in an async context
  /// - Returns: The progress delegate if set
  private func getProgressDelegate() async -> ResticProgressReporting? {
    _progressDelegate
  }

  /// The default repository location
  public nonisolated var defaultRepository: String? {
    get {
      // Using a safer but less ideal synchronous approach - not recommended for production use
      // For a production app, a better approach would be to use a shared actor or properly
      // design the architecture to avoid blocking synchronous access to actor state
      let semaphore = DispatchSemaphore(value: 0)
      var result: String?

      Task {
        result = await getDefaultRepository()
        semaphore.signal()
      }

      // Wait with a timeout to avoid potential deadlocks
      _ = semaphore.wait(timeout: .now() + 0.1)
      return result
    }
    set { Task { await setDefaultRepository(newValue) } }
  }

  /// Internal method to set the default repository value in an isolated context
  private func setDefaultRepository(_ value: String?) {
    _defaultRepository = value
  }

  /// The default password for repositories
  public nonisolated var defaultPassword: String? {
    get {
      // Using a safer but less ideal synchronous approach - not recommended for production use
      let semaphore = DispatchSemaphore(value: 0)
      var result: String?

      Task {
        result = await getDefaultPassword()
        semaphore.signal()
      }

      // Wait with a timeout to avoid potential deadlocks
      _ = semaphore.wait(timeout: .now() + 0.1)
      return result
    }
    set { Task { await setDefaultPassword(newValue) } }
  }

  /// Internal method to set the default password value in an isolated context
  private func setDefaultPassword(_ value: String?) {
    _defaultPassword = value
  }

  /// Progress delegate for tracking operations
  public nonisolated var progressDelegate: ResticProgressReporting? {
    get {
      // Using a safer but less ideal synchronous approach - not recommended for production use
      let semaphore = DispatchSemaphore(value: 0)
      var result: ResticProgressReporting?

      Task {
        result = await getProgressDelegate()
        semaphore.signal()
      }

      // Wait with a timeout to avoid potential deadlocks
      _ = semaphore.wait(timeout: .now() + 0.1)
      return result
    }
    set { Task { await setProgressDelegate(newValue) } }
  }

  /// Internal method to set the progress delegate in an isolated context
  private func setProgressDelegate(_ value: ResticProgressReporting?) {
    _progressDelegate = value
  }
  
  /**
   Creates a BaseLogContextDTO from a metadata dictionary.
   
   - Parameter metadata: The metadata dictionary with values
   - Returns: A BaseLogContextDTO
   */
  private nonisolated func createLogContext(_ metadata: [String: String]) -> BaseLogContextDTO {
    var collection = LogMetadataDTOCollection()
    
    for (key, value) in metadata {
      if key == "repository" || key == "error" || key == "errorOutput" {
        collection = collection.withPrivate(key: key, value: value)
      } else {
        collection = collection.withPublic(key: key, value: value)
      }
    }
    
    return BaseLogContextDTO(
      domainName: "ResticServices",
      source: "ResticServiceImpl",
      metadata: collection
    )
  }

  /// Creates a new Restic service with the specified configuration
  ///
  /// - Parameters:
  ///   - executablePath: Path to the Restic executable
  ///   - logger: Logger for operation logs
  ///   - credentialManager: Manager for repository credentials
  ///   - defaultRepository: Optional default repository
  ///   - defaultPassword: Optional default repository password
  ///   - progressDelegate: Optional delegate for progress reporting
  public init(
    executablePath: String,
    logger: any LoggingProtocol,
    credentialManager: ResticCredentialManager,
    defaultRepository: String? = nil,
    defaultPassword: String? = nil,
    progressDelegate: ResticProgressReporting? = nil
  ) {
    self.executablePath = executablePath
    self.logger = logger
    resticLogger = ResticLogger(logger: logger)
    self.credentialManager = credentialManager
    _defaultRepository = defaultRepository
    _defaultPassword = defaultPassword
    _progressDelegate = progressDelegate

    // Log initialisation with privacy-aware metadata
    Task {
      // Create the context directly without calling the actor isolated method
      let context = self.createLogContext([
        "executablePath": executablePath,
        "defaultRepository": defaultRepository ?? "none",
        "hasDefaultPassword": defaultPassword != nil ? "yes" : "no",
        "hasProgressDelegate": progressDelegate != nil ? "yes" : "no"
      ])
      
      await self.resticLogger.debug(
        "Initializing Restic service",
        context: context
      )
    }
  }
  
  /// Initialises a new repository
  ///
  /// - Parameters:
  ///   - location: Repository location (path or URL)
  ///   - password: Repository password
  /// - Returns: Result of the initialisation
  /// - Throws: ResticError if initialisation fails
  public func initialiseRepository(
    at location: String,
    password: String
  ) async throws -> ResticCommandResult {
    let startTime = Date()

    // Create init command
    let command = ResticCommand(
      action: .`init`,
      repository: location,
      password: password,
      arguments: [],
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    // Store the credentials for future use
    try await credentialManager.storeCredentials(
      ResticCredentials(
        repositoryIdentifier: location,
        password: password
      ),
      for: location
    )

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  /// Checks repository health
  ///
  /// - Parameter location: Optional repository location (uses default if nil)
  /// - Returns: Result of the repository check
  /// - Throws: ResticError if the check fails
  public func checkRepository(at location: String?) async throws -> ResticCommandResult {
    let startTime = Date()

    // Use provided repository or default
    let currentDefaultRepo = await getDefaultRepository()
    let repoLocation = location ?? currentDefaultRepo

    // Ensure we have a repository location
    guard let repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    let command = ResticCommand(
      action: .check,
      repository: repoLocation,
      password: await getDefaultPassword(),
      arguments: [],
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  /// Lists snapshots in the repository
  ///
  /// - Parameters:
  ///   - location: Optional repository location (uses default if nil)
  ///   - tag: Optional tag to filter snapshots
  /// - Returns: Result containing snapshot information
  /// - Throws: ResticError if the listing fails
  public func listSnapshots(
    at location: String?,
    tag: String?
  ) async throws -> ResticCommandResult {
    let startTime = Date()

    // Use provided repository or default
    let currentDefaultRepo = await getDefaultRepository()
    let repoLocation = location ?? currentDefaultRepo

    // Ensure we have a repository location
    guard let repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Build arguments
    var arguments: [String] = []

    // Add tag filter if provided
    if let tag, !tag.isEmpty {
      arguments.append("--tag")
      arguments.append(tag)
    }

    let command = ResticCommand(
      action: .snapshots,
      repository: repoLocation,
      password: await getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  /// Creates a backup
  ///
  /// - Parameters:
  ///   - paths: Array of paths to backup
  ///   - tag: Optional tag for the backup
  ///   - excludes: Optional array of exclude patterns
  /// - Returns: Result with backup information
  /// - Throws: ResticError if the backup fails
  public func backup(
    paths: [String],
    tag: String?,
    excludes: [String]?
  ) async throws -> ResticCommandResult {
    let startTime = Date()

    // Validate input paths
    guard !paths.isEmpty else {
      throw ResticError.invalidParameter("No paths provided for backup")
    }

    // Use provided repository or default
    let currentDefaultRepo = await getDefaultRepository()

    // Ensure we have a repository location
    guard let repoLocation = currentDefaultRepo, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Build arguments
    var arguments = paths

    // Add tag if provided
    if let tag, !tag.isEmpty {
      arguments.append("--tag")
      arguments.append(tag)
    }

    // Add excludes if provided
    if let excludes, !excludes.isEmpty {
      for exclude in excludes {
        arguments.append("--exclude")
        arguments.append(exclude)
      }
    }

    let command = ResticCommand(
      action: .backup,
      repository: repoLocation,
      password: await getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: true
    )

    // Execute the command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  /// Restores from a backup
  ///
  /// - Parameters:
  ///   - snapshot: Snapshot ID to restore from
  ///   - target: Target path for restoration
  ///   - paths: Optional specific paths to restore
  /// - Returns: Result with restore information
  /// - Throws: ResticError if the restore fails
  public func restore(
    snapshot: String,
    to target: String,
    paths: [String]?
  ) async throws -> ResticCommandResult {
    let startTime = Date()

    // Use default repository
    let currentDefaultRepo = await getDefaultRepository()

    // Ensure we have a repository location
    guard let repoLocation = currentDefaultRepo, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Validate snapshot ID
    guard !snapshot.isEmpty else {
      throw ResticError.invalidParameter("Snapshot ID cannot be empty")
    }

    // Validate target path
    guard !target.isEmpty else {
      throw ResticError.invalidParameter("Target path cannot be empty")
    }

    // Build arguments
    var arguments = [snapshot]

    // Add target path
    arguments.append("--target")
    arguments.append(target)

    // Add specific paths if provided
    if let paths, !paths.isEmpty {
      arguments.append("--include")
      arguments.append(contentsOf: paths)
    }

    let command = ResticCommand(
      action: .restore,
      repository: repoLocation,
      password: await getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: true
    )

    // Execute the command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  /// Performs repository maintenance
  ///
  /// - Parameter type: Type of maintenance operation
  /// - Returns: Result with maintenance information
  /// - Throws: ResticError if the maintenance fails
  public func maintenance(type: ResticMaintenanceType) async throws -> ResticCommandResult {
    let startTime = Date()

    // Use default repository
    let currentDefaultRepo = await getDefaultRepository()

    // Ensure we have a repository location
    guard let repoLocation = currentDefaultRepo, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Determine action based on maintenance type
    let action: ResticCommandAction
    var arguments: [String] = []

    switch type {
    case .prune:
      action = .prune
    case .check:
      action = .check
    case .rebuildIndex:
      action = .check
      arguments.append("--rebuild-index")
    }

    let command = ResticCommand(
      action: action,
      repository: repoLocation,
      password: await getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  public func execute(_ command: any ResticInterfaces.ResticCommand) async throws -> String {
    // We only support our internal ResticCommand implementation
    guard let resticCommand = command as? ResticServices.ResticCommand else {
      throw ResticError.invalidCommand("Command must be a ResticServices.ResticCommand instance")
    }
    
    // Create context directly inline to avoid asynchronous call to actor method
    let context = createLogContext([
      "command": resticCommand.action.rawValue,
      "repository": resticCommand.repository
    ])
    
    await resticLogger.debug(
      "Executing Restic command: \(resticCommand.action.rawValue)",
      context: context
    )
    
    // Execute Restic command
    // This is a stub implementation. In a real implementation, we would:
    // 1. Create and configure a Process
    // 2. Set up stdin/stdout/stderr pipes
    // 3. Run the process and capture output
    // 4. Handle errors and return results
    
    // For now, just simulate failure to demonstrate error handling
    throw ResticError.commandFailed(
      exitCode: 1,
      output: "Command implementation not completed"
    )
  }
  
  /// Validates a command before execution
  ///
  /// - Parameter command: The command to validate
  /// - Throws: ResticError if validation fails
  private func validateCommand(_ command: ResticCommand) async throws {
    // Get isolated state once to avoid multiple awaits in expressions
    let defaultRepo = await getDefaultRepository()
    let defaultPwd = await getDefaultPassword()

    // Ensure the repository is valid
    if command.repository.isEmpty && (defaultRepo == nil || defaultRepo!.isEmpty) {
      throw ResticError.invalidParameter("No repository specified and no default repository set")
    }

    // Ensure we have a password (when not using init command)
    if command.action != .`init` && command.password == nil && defaultPwd == nil {
      throw ResticError.invalidParameter("No password specified and no default password set")
    }
  }
}
