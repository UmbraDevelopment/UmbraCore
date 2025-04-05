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
      let semaphore=DispatchSemaphore(value: 0)
      var result: String?

      Task {
        result=await getDefaultRepository()
        semaphore.signal()
      }

      // Wait with a timeout to avoid potential deadlocks
      _=semaphore.wait(timeout: .now() + 0.1)
      return result
    }
    set { Task { await setDefaultRepository(newValue) } }
  }

  /// Internal method to set the default repository value in an isolated context
  private func setDefaultRepository(_ value: String?) {
    _defaultRepository=value
  }

  /// The default password for repositories
  public nonisolated var defaultPassword: String? {
    get {
      // Using a safer but less ideal synchronous approach - not recommended for production use
      let semaphore=DispatchSemaphore(value: 0)
      var result: String?

      Task {
        result=await getDefaultPassword()
        semaphore.signal()
      }

      // Wait with a timeout to avoid potential deadlocks
      _=semaphore.wait(timeout: .now() + 0.1)
      return result
    }
    set { Task { await setDefaultPassword(newValue) } }
  }

  /// Internal method to set the default password value in an isolated context
  private func setDefaultPassword(_ value: String?) {
    _defaultPassword=value
  }

  /// Progress delegate for tracking operations
  public nonisolated var progressDelegate: ResticProgressReporting? {
    get {
      // Using a safer but less ideal synchronous approach - not recommended for production use
      let semaphore=DispatchSemaphore(value: 0)
      var result: ResticProgressReporting?

      Task {
        result=await getProgressDelegate()
        semaphore.signal()
      }

      // Wait with a timeout to avoid potential deadlocks
      _=semaphore.wait(timeout: .now() + 0.1)
      return result
    }
    set { Task { await setProgressDelegate(newValue) } }
  }

  /// Internal method to set the progress delegate in an isolated context
  private func setProgressDelegate(_ value: ResticProgressReporting?) {
    _progressDelegate=value
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
    defaultRepository: String?=nil,
    defaultPassword: String?=nil,
    progressDelegate: ResticProgressReporting?=nil
  ) {
    self.executablePath=executablePath
    self.logger=logger
    resticLogger=ResticLogger(logger: logger)
    self.credentialManager=credentialManager
    _defaultRepository=defaultRepository
    _defaultPassword=defaultPassword
    _progressDelegate=progressDelegate

    // Log initialisation with privacy-aware metadata
    Task {
      await resticLogger.debug(
        "Initializing Restic service",
        metadata: PrivacyMetadata([
          "executablePath": (value: executablePath, privacy: .public),
          "defaultRepository": (value: defaultRepository ?? "none", privacy: .private),
          "hasDefaultPassword": (value: defaultPassword != nil ? "yes" : "no", privacy: .public),
          "hasProgressDelegate": (value: progressDelegate != nil ? "yes" : "no", privacy: .public)
        ]),
        source: "ResticServiceImpl"
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
    let startTime=Date()

    // Create init command
    let command=ResticCommand(
      action: .`init`,
      repository: location,
      password: password,
      arguments: [],
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output=try await execute(command as any ResticInterfaces.ResticCommand)
    let duration=Date().timeIntervalSince(startTime)

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

  /// Executes a Restic command
  ///
  /// - Parameter command: The command to execute
  /// - Returns: The command output as a string
  /// - Throws: ResticError if the command fails
  public func execute(_ command: any ResticInterfaces.ResticCommand) async throws -> String {
    // We only support our internal ResticCommand implementation
    guard let resticCommand=command as? ResticServices.ResticCommand else {
      throw ResticError.invalidCommand("Command must be a ResticServices.ResticCommand instance")
    }

    // Validate the command
    try await validateCommand(resticCommand)

    // Log command execution with privacy protection
    await resticLogger.debug(
      "Executing Restic command: \(resticCommand.action.rawValue)",
      metadata: PrivacyMetadata([
        "command": (value: resticCommand.action.rawValue, privacy: .public),
        "repository": (value: resticCommand.repository, privacy: .private)
      ]),
      source: "ResticServiceImpl"
    )

    // Build the command line
    var arguments=[resticCommand.action.rawValue]

    // Add repository
    if !resticCommand.repository.isEmpty {
      arguments.append("--repo")
      arguments.append(resticCommand.repository)
    } else {
      // Get isolated property once
      let defaultRepo=await getDefaultRepository()
      if let defaultRepo, !defaultRepo.isEmpty {
        arguments.append("--repo")
        arguments.append(defaultRepo)
      }
    }

    // Add password
    if let cmdPassword=resticCommand.password, !cmdPassword.isEmpty {
      arguments.append("--password")
      arguments.append(cmdPassword)
    } else {
      // Get isolated property once
      let defaultPwd=await getDefaultPassword()
      if let defaultPwd, !defaultPwd.isEmpty {
        arguments.append("--password")
        arguments.append(defaultPwd)
      }
    }

    // Add any additional arguments
    if !resticCommand.arguments.isEmpty {
      arguments.append(contentsOf: resticCommand.arguments)
    }

    // Add options
    for (key, value) in resticCommand.options {
      if key.count == 1 {
        arguments.append("-\(key)")
      } else {
        arguments.append("--\(key)")
      }

      if !value.isEmpty {
        arguments.append(value)
      }
    }

    // Create and configure process
    let process=Process()
    process.executableURL=URL(fileURLWithPath: executablePath)
    process.arguments=arguments

    // Set up pipes for output
    let outputPipe=Pipe()
    let errorPipe=Pipe()
    process.standardOutput=outputPipe
    process.standardError=errorPipe

    // Launch process
    do {
      try process.run()
    } catch {
      await resticLogger.error(
        "Failed to launch Restic process",
        metadata: PrivacyMetadata([
          "command": (value: resticCommand.action.rawValue, privacy: .public),
          "error": (value: error.localizedDescription, privacy: .private)
        ]),
        source: "ResticServiceImpl"
      )

      throw ResticError.commandFailed(
        exitCode: -1,
        output: "Failed to launch process: \(error.localizedDescription)"
      )
    }

    // Wait for process to complete
    process.waitUntilExit()

    // Read output and error data
    let outputData=try outputPipe.fileHandleForReading.readToEnd() ?? Data()
    let errorData=try errorPipe.fileHandleForReading.readToEnd() ?? Data()

    // Convert to strings
    let output=String(data: outputData, encoding: .utf8) ?? ""
    let errorOutput=String(data: errorData, encoding: .utf8) ?? ""

    // Check for errors
    if process.terminationStatus != 0 {
      await resticLogger.error(
        "Restic command failed with exit code \(process.terminationStatus)",
        metadata: PrivacyMetadata([
          "command": (value: resticCommand.action.rawValue, privacy: .public),
          "exitCode": (value: process.terminationStatus, privacy: .public),
          "error": (value: errorOutput, privacy: .private)
        ]),
        source: "ResticServiceImpl"
      )

      throw ResticError.commandFailed(
        exitCode: Int(process.terminationStatus),
        output: errorOutput
      )
    }

    // Log successful execution
    await resticLogger.debug(
      "Restic command executed successfully",
      metadata: PrivacyMetadata([
        "command": (value: resticCommand.action.rawValue, privacy: .public)
      ]),
      source: "ResticServiceImpl"
    )

    return output
  }

  /// Checks repository health
  ///
  /// - Parameter location: Optional repository location (uses default if nil)
  /// - Returns: Result of the repository check
  /// - Throws: ResticError if the check fails
  public func checkRepository(at location: String?) async throws -> ResticCommandResult {
    let startTime=Date()

    // Use provided repository or default
    let currentDefaultRepo=await getDefaultRepository()
    let repoLocation=location ?? currentDefaultRepo

    // Ensure we have a repository location
    guard let repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    let command=await ResticCommand(
      action: .check,
      repository: repoLocation,
      password: getDefaultPassword(),
      arguments: [],
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output=try await execute(command as any ResticInterfaces.ResticCommand)
    let duration=Date().timeIntervalSince(startTime)

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
    let startTime=Date()

    // Use provided repository or default
    let currentDefaultRepo=await getDefaultRepository()
    let repoLocation=location ?? currentDefaultRepo

    // Ensure we have a repository location
    guard let repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Build arguments
    var arguments: [String]=[]

    // Add tag filter if provided
    if let tag, !tag.isEmpty {
      arguments.append("--tag")
      arguments.append(tag)
    }

    let command=await ResticCommand(
      action: .snapshots,
      repository: repoLocation,
      password: getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output=try await execute(command as any ResticInterfaces.ResticCommand)
    let duration=Date().timeIntervalSince(startTime)

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
    let startTime=Date()

    // Validate input paths
    guard !paths.isEmpty else {
      throw ResticError.invalidParameter("No paths provided for backup")
    }

    // Use provided repository or default
    let currentDefaultRepo=await getDefaultRepository()

    // Ensure we have a repository location
    guard let repoLocation=currentDefaultRepo, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Build arguments
    var arguments=paths

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

    let command=await ResticCommand(
      action: .backup,
      repository: repoLocation,
      password: getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: true
    )

    // Execute the command
    let output=try await execute(command as any ResticInterfaces.ResticCommand)
    let duration=Date().timeIntervalSince(startTime)

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
    let startTime=Date()

    // Use default repository
    let currentDefaultRepo=await getDefaultRepository()

    // Ensure we have a repository location
    guard let repoLocation=currentDefaultRepo, !repoLocation.isEmpty else {
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
    var arguments=[snapshot]

    // Add target path
    arguments.append("--target")
    arguments.append(target)

    // Add specific paths if provided
    if let paths, !paths.isEmpty {
      arguments.append("--include")
      arguments.append(contentsOf: paths)
    }

    let command=await ResticCommand(
      action: .restore,
      repository: repoLocation,
      password: getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: true
    )

    // Execute the command
    let output=try await execute(command as any ResticInterfaces.ResticCommand)
    let duration=Date().timeIntervalSince(startTime)

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
    let startTime=Date()

    // Use default repository
    let currentDefaultRepo=await getDefaultRepository()

    // Ensure we have a repository location
    guard let repoLocation=currentDefaultRepo, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location specified")
    }

    // Determine action based on maintenance type
    let action: ResticCommandAction
    var arguments: [String]=[]

    switch type {
      case .prune:
        action = .prune
      case .check:
        action = .check
      case .rebuildIndex:
        action = .check
        arguments.append("--rebuild-index")
    }

    let command=await ResticCommand(
      action: action,
      repository: repoLocation,
      password: getDefaultPassword(),
      arguments: arguments,
      options: [:],
      trackProgress: false
    )

    // Execute the command
    let output=try await execute(command as any ResticInterfaces.ResticCommand)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult(
      output: output,
      exitCode: 0,
      duration: duration
    )
  }

  /// Maps maintenance type to command and arguments
  ///
  /// - Parameter type: The maintenance operation type
  /// - Returns: Tuple with command action and arguments
  private func mapMaintenanceTypeToCommand(_ type: ResticMaintenanceType)
  -> (ResticCommandAction, [String]) {
    switch type {
      case .prune:
        (.prune, [])
      case .check:
        (.check, [])
      case .rebuildIndex:
        (.check, ["--rebuild-index"])
    }
  }

  /// Validates a command before execution
  ///
  /// - Parameter command: The command to validate
  /// - Throws: ResticError if validation fails
  private func validateCommand(_ command: ResticCommand) async throws {
    // Get isolated state once to avoid multiple awaits in expressions
    let defaultRepo=await getDefaultRepository()
    let defaultPwd=await getDefaultPassword()

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
