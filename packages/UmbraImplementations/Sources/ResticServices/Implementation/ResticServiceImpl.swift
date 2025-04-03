import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/// Implementation of the Restic service for interfacing with the Restic command-line tool.
///
/// This actor-based implementation provides proper isolation for concurrent operations,
/// ensuring thread safety while maintaining high performance for Restic operations.
@preconcurrency public actor ResticServiceImpl: ResticServiceProtocol {
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
  
  /// The default repository location
  public var defaultRepository: String? {
    get { _defaultRepository }
    set { _defaultRepository = newValue }
  }
  
  /// Private storage for default password
  private var _defaultPassword: String?
  
  /// The default password for repositories
  public var defaultPassword: String? {
    get { _defaultPassword }
    set { _defaultPassword = newValue }
  }
  
  /// Private storage for progress delegate
  private var _progressDelegate: ResticProgressReporting?
  
  /// Progress delegate for tracking operations
  public var progressDelegate: ResticProgressReporting? {
    get { _progressDelegate }
    set { _progressDelegate = newValue }
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
    self.resticLogger = ResticLogger(logger: logger)
    self.credentialManager = credentialManager
    self._defaultRepository = defaultRepository
    self._defaultPassword = defaultPassword
    self._progressDelegate = progressDelegate
    
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
    let startTime = Date()
    
    // Create init command
    let command = ResticCommand(
      action: .init,
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
  
  /// Executes a Restic command
  ///
  /// - Parameter command: The command to execute
  /// - Returns: The command output as a string
  /// - Throws: ResticError if the command fails
  public func execute(_ command: ResticCommand) async throws -> String {
    guard let command = command as? ResticCommand else {
      throw ResticError.invalidCommand("Command must be a ResticCommand instance")
    }
    
    // Validate the command
    try validateCommand(command)
    
    // Log command execution with privacy protection
    await resticLogger.debug(
      "Executing Restic command: \(command.action.rawValue)",
      metadata: PrivacyMetadata([
        "command": (value: command.action.rawValue, privacy: .public),
        "repository": (value: command.repository, privacy: .private)
      ]),
      source: "ResticServiceImpl"
    )
    
    // Build the command line
    var arguments = [command.action.rawValue]
    
    // Add repository
    if !command.repository.isEmpty {
      arguments.append("--repo")
      arguments.append(command.repository)
    } else if let defaultRepo = defaultRepository, !defaultRepo.isEmpty {
      arguments.append("--repo")
      arguments.append(defaultRepo)
    }
    
    // Add password
    if let cmdPassword = command.password, !cmdPassword.isEmpty {
      arguments.append("--password")
      arguments.append(cmdPassword)
    } else if let defaultPwd = defaultPassword, !defaultPwd.isEmpty {
      arguments.append("--password")
      arguments.append(defaultPwd)
    }
    
    // Add any additional arguments
    if !command.arguments.isEmpty {
      arguments.append(contentsOf: command.arguments)
    }
    
    // Add options
    for (key, value) in command.options {
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
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = arguments
    
    // Set up pipes for output
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    // Launch process
    do {
      try process.run()
    } catch {
      await resticLogger.error(
        "Failed to launch Restic process",
        metadata: PrivacyMetadata([
          "command": (value: command.action.rawValue, privacy: .public),
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
    let outputData = try outputPipe.fileHandleForReading.readToEnd() ?? Data()
    let errorData = try errorPipe.fileHandleForReading.readToEnd() ?? Data()
    
    // Convert to strings
    let output = String(data: outputData, encoding: .utf8) ?? ""
    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
    
    // Check for errors
    if process.terminationStatus != 0 {
      await resticLogger.error(
        "Restic command failed with exit code \(process.terminationStatus)",
        metadata: PrivacyMetadata([
          "command": (value: command.action.rawValue, privacy: .public),
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
        "command": (value: command.action.rawValue, privacy: .public)
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
    let startTime = Date()
    
    // Use provided repository or default
    let repoLocation = location ?? defaultRepository
    
    // Ensure we have a repository location
    guard let repoLocation = repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location provided")
    }
    
    // Create check command
    let command = ResticCommand(
      action: .check,
      repository: repoLocation,
      password: defaultPassword,
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
  public func listSnapshots(at location: String?, tag: String?) async throws -> ResticCommandResult {
    let startTime = Date()
    
    // Use provided repository or default
    let repoLocation = location ?? defaultRepository
    
    // Ensure we have a repository location
    guard let repoLocation = repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location provided")
    }
    
    // Build arguments
    var arguments: [String] = ["--json"]
    
    // Add tag filter if provided
    if let tag = tag, !tag.isEmpty {
      arguments.append("--tag")
      arguments.append(tag)
    }
    
    // Create snapshots command
    let command = ResticCommand(
      action: .snapshots,
      repository: repoLocation,
      password: defaultPassword,
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
  public func backup(paths: [String], tag: String?, excludes: [String]?) async throws -> ResticCommandResult {
    let startTime = Date()
    
    // Ensure we have paths to back up
    guard !paths.isEmpty else {
      throw ResticError.invalidParameter("No paths provided for backup")
    }
    
    // Use provided repository or default
    let repoLocation = defaultRepository
    
    // Ensure we have a repository location
    guard let repoLocation = repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location provided")
    }
    
    // Build arguments for backup
    var arguments = paths
    
    // Add tag if provided
    if let tag = tag, !tag.isEmpty {
      arguments.append("--tag")
      arguments.append(tag)
    }
    
    // Add exclude patterns if provided
    if let excludes = excludes, !excludes.isEmpty {
      for pattern in excludes {
        arguments.append("--exclude")
        arguments.append(pattern)
      }
    }
    
    // Create backup command
    let command = ResticCommand(
      action: .backup,
      repository: repoLocation,
      password: defaultPassword,
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
  public func restore(snapshot: String, to target: String, paths: [String]?) async throws -> ResticCommandResult {
    let startTime = Date()
    
    // Use default repository
    let repoLocation = defaultRepository
    
    // Ensure we have a repository location
    guard let repoLocation = repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location provided")
    }
    
    // Build arguments for restore
    var arguments = [
      snapshot,
      "--target", target
    ]
    
    // Add specific paths to restore if provided
    if let paths = paths, !paths.isEmpty {
      for path in paths {
        arguments.append("--include")
        arguments.append(path)
      }
    }
    
    // Create restore command
    let command = ResticCommand(
      action: .restore,
      repository: repoLocation,
      password: defaultPassword,
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
    let repoLocation = defaultRepository
    
    // Ensure we have a repository location
    guard let repoLocation = repoLocation, !repoLocation.isEmpty else {
      throw ResticError.invalidParameter("No repository location provided")
    }
    
    // Map maintenance type to command and arguments
    let (action, arguments) = mapMaintenanceTypeToCommand(type)
    
    // Create maintenance command
    let command = ResticCommand(
      action: action,
      repository: repoLocation,
      password: defaultPassword,
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
  
  /// Maps maintenance type to command and arguments
  ///
  /// - Parameter type: The maintenance operation type
  /// - Returns: Tuple with command action and arguments
  private func mapMaintenanceTypeToCommand(_ type: ResticMaintenanceType) -> (ResticCommandAction, [String]) {
    switch type {
    case .prune:
      return (.prune, [])
    case .check:
      return (.check, [])
    case .rebuildIndex:
      return (.check, ["--rebuild-index"])
    }
  }
  
  /// Validates a command before execution
  ///
  /// - Parameter command: The command to validate
  /// - Throws: ResticError if validation fails
  private func validateCommand(_ command: ResticCommand) throws {
    // Ensure the repository is valid
    if command.repository.isEmpty && (defaultRepository == nil || defaultRepository!.isEmpty) {
      throw ResticError.invalidParameter("No repository specified and no default repository set")
    }
    
    // Ensure we have a password (when not using init command)
    if command.action != .init && command.password == nil && defaultPassword == nil {
      throw ResticError.invalidParameter("No password specified and no default password set")
    }
  }
}
