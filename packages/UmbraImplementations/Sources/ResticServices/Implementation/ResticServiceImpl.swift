import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/// Thread-safe implementation of the ResticServiceProtocol using Swift concurrency.
///
/// This actor-based implementation provides proper isolation for concurrent operations,
/// ensuring thread safety while maintaining high performance for Restic operations.
public actor ResticServiceImpl: ResticServiceProtocol {
  /// The path to the Restic executable
  public let executablePath: String

  /// The default repository location, if set
  private var _defaultRepository: String?
  
  /// Progress reporting delegate for receiving operation updates
  private var _progressDelegate: (any ResticProgressReporting)?
  
  /// The logger for operation tracking
  private let logger: any LoggingProtocol

  /// The progress parser for tracking operation progress
  private var progressParser: ResticProgressParser?
  
  /// The secure credential manager for repository passwords
  private let credentialManager: any ResticCredentialManager

  /// Creates a new ResticServiceImpl instance with secure credential management.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable
  ///   - defaultRepository: Optional default repository location
  ///   - credentialManager: The secure credential manager for repository access
  ///   - progressDelegate: Optional delegate for progress reporting
  ///   - logger: Logger for operation tracking
  /// - Throws: ResticError if the executable cannot be found or accessed
  public init(
    executablePath: String,
    defaultRepository: String? = nil,
    credentialManager: any ResticCredentialManager,
    progressDelegate: (any ResticProgressReporting)? = nil,
    logger: any LoggingProtocol
  ) throws {
    self.executablePath = executablePath
    self._defaultRepository = defaultRepository
    self._progressDelegate = progressDelegate
    self.logger = logger
    self.credentialManager = credentialManager

    if let progressDelegate {
      self.progressParser = ResticProgressParser(delegate: progressDelegate)
    }

    // Validate that the executable exists and is accessible
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: executablePath) else {
      throw ResticError.executableNotFound(executablePath)
    }

    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: executablePath, isDirectory: &isDirectory),
          !isDirectory.boolValue else {
      throw ResticError.invalidParameter("Restic executable path is a directory")
    }

    await logger.info(
      "Initialised ResticServiceImpl with executable: \(executablePath)",
      metadata: [
        "executable": .string(executablePath),
        "default_repository": defaultRepository.map { .string($0) } ?? .null,
        "using_secure_credentials": .boolean(true)
      ],
      source: "ResticService"
    )
  }
  
  // MARK: - Private Types
  
  /// Domain-specific logging context for backup operations
  private struct BackupLogContext: LoggingTypes.LogContextDTO {
    let source: String
    let metadata: LoggingTypes.LogMetadata?
    let correlationID: LoggingTypes.LogIdentifier
    let timestamp: LoggingTypes.LogTimestamp
    let repository: String
    let paths: [String]
    let tag: String?
    
    init(
      repository: String,
      paths: [String],
      tag: String?,
      metadata: LoggingTypes.LogMetadata? = nil
    ) {
      self.source = "ResticService.Backup"
      self.metadata = metadata
      self.correlationID = LoggingTypes.LogIdentifier.unique()
      self.timestamp = LoggingTypes.LogTimestamp(secondsSinceEpoch: Date().timeIntervalSince1970)
      self.repository = repository
      self.paths = paths
      self.tag = tag
    }
  }
  
  /// Domain-specific logging context for restore operations
  private struct RestoreLogContext: LoggingTypes.LogContextDTO {
    let source: String
    let metadata: LoggingTypes.LogMetadata?
    let correlationID: LoggingTypes.LogIdentifier
    let timestamp: LoggingTypes.LogTimestamp
    let repository: String
    let snapshot: String
    let target: String
    
    init(
      repository: String,
      snapshot: String,
      target: String,
      metadata: LoggingTypes.LogMetadata? = nil
    ) {
      self.source = "ResticService.Restore"
      self.metadata = metadata
      self.correlationID = LoggingTypes.LogIdentifier.unique()
      self.timestamp = LoggingTypes.LogTimestamp(secondsSinceEpoch: Date().timeIntervalSince1970)
      self.repository = repository
      self.snapshot = snapshot
      self.target = target
    }
  }
  
  /// Domain-specific logging context for maintenance operations
  private struct MaintenanceLogContext: LoggingTypes.LogContextDTO {
    let source: String
    let metadata: LoggingTypes.LogMetadata?
    let correlationID: LoggingTypes.LogIdentifier
    let timestamp: LoggingTypes.LogTimestamp
    let repository: String
    let operationType: String
    
    init(
      repository: String,
      operationType: String,
      metadata: LoggingTypes.LogMetadata? = nil
    ) {
      self.source = "ResticService.Maintenance"
      self.metadata = metadata
      self.correlationID = LoggingTypes.LogIdentifier.unique()
      self.timestamp = LoggingTypes.LogTimestamp(secondsSinceEpoch: Date().timeIntervalSince1970)
      self.repository = repository
      self.operationType = operationType
    }
  }

  // MARK: - Property Accessors
  
  /// Get the default repository
  public func getDefaultRepository() -> String? {
    return _defaultRepository
  }
  
  /// Set the default repository
  public func setDefaultRepository(_ repository: String?) {
    _defaultRepository = repository
  }
  
  /// Get the progress delegate
  public func getProgressDelegate() -> (any ResticProgressReporting)? {
    return _progressDelegate
  }
  
  /// Set the progress delegate
  public func setProgressDelegate(_ delegate: (any ResticProgressReporting)?) {
    _progressDelegate = delegate
    if let delegate {
      self.progressParser = ResticProgressParser(delegate: delegate)
    } else {
      self.progressParser = nil
    }
  }

  /// Represents the setup for a Restic process execution
  private struct ProcessSetup {
    let process: Process
    let outputPipe: Pipe
    let errorPipe: Pipe
  }

  /// Execute a ResticCommand with proper error handling
  ///
  /// - Parameter command: The command to execute
  /// - Returns: The raw output string from the command
  /// - Throws: ResticError if the command fails
  public func execute(_ command: ResticCommand) async throws -> String {
    try command.validate()

    await logger.info(
      "Executing Restic command: \(command.commandString)",
      metadata: [
        "command": .string(command.commandString),
        "arguments": .array(command.arguments.map { .string($0) })
      ],
      source: "ResticService"
    )

    // Create and configure the process
    let process=Process()
    process.executableURL=URL(fileURLWithPath: executablePath)
    process.arguments=command.arguments

    // Set environment variables
    var environment=ProcessInfo.processInfo.environment
    if let password=command.password {
      environment["RESTIC_PASSWORD"]=password
    } else if let repository = command.repository, let credentials = try await credentialManager.getCredentials(for: repository) {
      environment["RESTIC_PASSWORD"] = credentials.password
    }
    process.environment=environment

    // Configure output pipes
    let outputPipe=Pipe()
    let errorPipe=Pipe()
    process.standardOutput=outputPipe
    process.standardError=errorPipe

    // Track progress if requested and delegate is available
    if command.trackProgress, let progressParser {
      // Configure progress parsing here
    }

    // Start the process
    let startTime=Date()
    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      await logger.error(
        error,
        privacyLevel: .public,
        source: "ResticService",
        metadata: [
          "command": .string(command.commandString)
        ]
      )
      throw ResticError.executionFailed("Failed to execute Restic: \(error.localizedDescription)")
    }

    // Read output
    let outputData=outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData=errorPipe.fileHandleForReading.readDataToEndOfFile()
    
    let output=String(data: outputData, encoding: .utf8) ?? ""
    let errorOutput=String(data: errorData, encoding: .utf8) ?? ""
    
    // Check exit status
    let exitCode=Int(process.terminationStatus)
    let duration=Date().timeIntervalSince(startTime)
    
    // Log completion
    await logger.debug(
      "Restic command completed with exit code \(exitCode) in \(String(format: "%.2f", duration))s",
      metadata: [
        "command": .string(command.commandString),
        "exitCode": .number(Double(exitCode)),
        "duration": .number(duration)
      ],
      source: "ResticService"
    )
    
    if exitCode != 0 {
      // Log the error output with appropriate privacy controls
      await logger.error(
        "Restic command failed with exit code \(exitCode)",
        metadata: [
          "command": .string(command.commandString),
          "exitCode": .number(Double(exitCode)),
          "errorOutput": .string(errorOutput)
        ],
        source: "ResticService"
      )
      
      throw ResticError.commandFailed(
        exitCode: exitCode,
        output: errorOutput.isEmpty ? output : errorOutput
      )
    }
    
    return output
  }

  /// Initialises a new repository
  ///
  /// - Parameters:
  ///   - location: The location where the repository should be created
  ///   - password: The password to use for the repository (if nil, uses default)
  /// - Returns: The result of the initialisation command
  /// - Throws: ResticError if the repository cannot be initialised
  public func initRepository(
    at location: String,
    password: String? = nil
  ) async throws -> ResticCommandResult {
    let startTime=Date()
    
    // Check if repository already exists
    if try await checkIfRepositoryExists(at: location) {
      throw ResticError.repositoryExists(location)
    }
    
    // Create init command with provided or default password
    let repoPassword: String
    if let password {
      repoPassword = password
    } else {
      // Try to get from credential manager if repository already registered
      do {
        let credentials = try await credentialManager.getCredentials(for: location)
        repoPassword = credentials.password
      } catch {
        throw ResticError.credentialError("No password provided and no default password available")
      }
    }
    
    let command=ResticCommand(
      action: .init,
      repository: location,
      password: repoPassword
    )
    
    // Execute the command
    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)
    
    // Store the credentials securely for future access
    if !await credentialManager.hasCredentials(for: location) {
      try await credentialManager.storeCredentials(
        ResticCredentials(
          repositoryIdentifier: location,
          password: repoPassword
        ),
        for: location
      )
      
      await logger.info(
        "Stored credentials for new repository",
        metadata: [
          "repository": .string(location)
        ],
        source: "ResticService"
      )
    }
    
    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": .string(location)
      ]
    )
  }

  /// Checks repository health
  ///
  /// - Parameter location: Optional repository location (uses default if nil)
  /// - Returns: Result of the repository check
  /// - Throws: ResticError if the check fails
  public func checkRepository(at location: String?) async throws -> ResticCommandResult {
    let startTime=Date()

    let repoLocation=location ?? getDefaultRepository()
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location is required")
    }

    let options=ResticCommonOptions(
      repository: repoLocation,
      password: nil,
      jsonOutput: true
    )

    let command=ResticCheckCommandImpl(
      readData: false,
      commonOptions: options
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: ["repository": .string(repoLocation)]
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

    let repoLocation=location ?? getDefaultRepository()
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location is required")
    }

    let options=ResticCommonOptions(
      repository: repoLocation,
      password: nil,
      jsonOutput: true
    )

    let command=ResticSnapshotsCommandImpl(
      tag: tag,
      commonOptions: options
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": .string(repoLocation),
        "tag": .string(tag)
      ]
    )
  }

  /// Performs a backup of the specified paths
  ///
  /// - Parameters:
  ///   - paths: Paths to back up
  ///   - repository: Optional repository location (uses default if nil)
  ///   - tag: Optional tag to attach to the backup
  ///   - excludes: Paths to exclude from the backup
  /// - Returns: Result of the backup command
  /// - Throws: ResticError if the backup fails
  public func backup(
    paths: [String],
    to repository: String? = nil,
    tag: String? = nil,
    excludes: [String] = []
  ) async throws -> ResticCommandResult {
    let startTime = Date()
    
    // Determine repository location
    let repoLocation = repository ?? getDefaultRepository()
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location not specified and no default set")
    }
    
    // Get password from credential manager if available
    let repoPassword: String?
    if await credentialManager.hasCredentials(for: repoLocation) {
      // Get from credential manager if available
      do {
        let credentials = try await credentialManager.getCredentials(for: repoLocation)
        repoPassword = credentials.password
      } catch {
        await logger.error(
          error,
          privacyLevel: .sensitive,
          source: "ResticService.Backup",
          metadata: ["repository": .string(repoLocation)]
        )
        repoPassword = nil
      }
    } else {
      repoPassword = nil
    }
    
    // Create backup command
    let command = ResticCommand(
      action: .backup,
      repository: repoLocation,
      password: repoPassword,
      arguments: paths,
      options: buildBackupOptions(tag: tag, excludes: excludes)
    )
    
    // Create backup context for logging
    let logContext = BackupLogContext(
      repository: repoLocation,
      paths: paths,
      tag: tag
    )
    
    await logger.info(
      "Starting backup operation",
      metadata: [
        "repository": .string(repoLocation),
        "paths": .array(paths.map { .string($0) }),
        "excludes": .array(excludes.map { .string($0) })
      ],
      context: logContext
    )
    
    // Execute backup command
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)
    
    // Store credentials if successful and not already stored
    if let repoPassword = repoPassword, 
       !await credentialManager.hasCredentials(for: repoLocation) {
      try? await credentialManager.storeCredentials(
        ResticCredentials(
          repositoryIdentifier: repoLocation,
          password: repoPassword
        ),
        for: repoLocation
      )
    }

    await logger.info(
      "Backup completed",
      metadata: [
        "repository": .string(repoLocation),
        "paths": .array(paths.map { .string($0) }),
        "tag": tag.map { .string($0) } ?? .null,
        "excludes": .array(excludes.map { .string($0) }),
        "duration": .number(duration)
      ],
      context: logContext
    )

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": .string(repoLocation),
        "paths": .array(paths.map { .string($0) }),
        "tag": tag.map { .string($0) } ?? .null
      ]
    )
  }
  
  /// Restores files from a snapshot
  ///
  /// - Parameters:
  ///   - snapshot: Snapshot ID to restore from
  ///   - target: Target directory to restore to
  ///   - repository: Optional repository location (uses default if nil)
  ///   - paths: Optional specific paths to restore (restores all if nil)
  /// - Returns: Result of the restore command
  /// - Throws: ResticError if the restore fails
  public func restore(
    snapshot: String,
    to target: String,
    from repository: String? = nil,
    paths: [String] = []
  ) async throws -> ResticCommandResult {
    let startTime = Date()
    
    // Determine repository location
    let repoLocation = repository ?? getDefaultRepository()
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location not specified and no default set")
    }
    
    // Get password from credential manager if available
    let repoPassword: String?
    if await credentialManager.hasCredentials(for: repoLocation) {
      // Get from credential manager if available
      do {
        let credentials = try await credentialManager.getCredentials(for: repoLocation)
        repoPassword = credentials.password
      } catch {
        await logger.error(
          error,
          privacyLevel: .sensitive,
          source: "ResticService.Restore",
          metadata: ["repository": .string(repoLocation)]
        )
        repoPassword = nil
      }
    } else {
      repoPassword = nil
    }
    
    // Create context for logging
    let logContext = RestoreLogContext(
      repository: repoLocation,
      snapshot: snapshot,
      target: target
    )
    
    await logger.info(
      "Starting restore operation",
      metadata: [
        "repository": .string(repoLocation),
        "snapshot": .string(snapshot),
        "target": .string(target),
        "paths": .array(paths.map { .string($0) })
      ],
      context: logContext
    )
    
    // Create and execute restore command
    let command = ResticCommand(
      action: .restore,
      repository: repoLocation,
      password: repoPassword,
      arguments: [snapshot],
      options: buildRestoreOptions(target: target, paths: paths)
    )
    
    let output = try await execute(command)
    let duration = Date().timeIntervalSince(startTime)

    await logger.info(
      "Restore completed",
      metadata: [
        "repository": .string(repoLocation),
        "snapshot": .string(snapshot),
        "target": .string(target),
        "paths": .array(paths.map { .string($0) }),
        "duration": .number(duration)
      ],
      context: logContext
    )

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": .string(repoLocation),
        "snapshot": .string(snapshot),
        "target": .string(target),
        "paths": .array(paths.map { .string($0) })
      ]
    )
  }

  /// Performs repository maintenance
  ///
  /// - Parameter type: Type of maintenance operation
  /// - Returns: Result with maintenance information
  /// - Throws: ResticError if the maintenance fails
  public func maintenance(type: ResticMaintenanceType) async throws -> ResticCommandResult {
    let startTime=Date()

    let repoLocation=getDefaultRepository()
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location is required")
    }

    let options=ResticCommonOptions(
      repository: repoLocation,
      password: nil,
      jsonOutput: true
    )

    let command=ResticMaintenanceCommandImpl(
      maintenanceType: type,
      commonOptions: options
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    await logger.info(
      "Maintenance completed",
      metadata: [
        "repository": .string(repoLocation),
        "maintenance_type": .string(type.rawValue)
      ],
      context: MaintenanceLogContext(
        repository: repoLocation,
        operationType: type.rawValue
      )
    )

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": .string(repoLocation),
        "maintenance_type": .string(type.rawValue)
      ]
    )
  }

  // MARK: - Helper Methods
  
  /// Builds options for a backup command
  /// 
  /// - Parameters:
  ///   - tag: Optional tag to associate with the backup
  ///   - excludes: Paths to exclude from the backup
  /// - Returns: Dictionary of options for the backup command
  private func buildBackupOptions(tag: String?, excludes: [String]) -> [String: String] {
    var options: [String: String] = ["json": "true"]
    
    if let tag = tag {
      options["tag"] = tag
    }
    
    excludes.forEach { excludePath in
      options["exclude"] = (options["exclude"] ?? "") + "\(excludePath),"
    }
    
    // Remove trailing comma from excludes if present
    if let excludeString = options["exclude"], excludeString.hasSuffix(",") {
      options["exclude"] = String(excludeString.dropLast())
    }
    
    return options
  }
  
  /// Builds options for a restore command
  /// 
  /// - Parameters:
  ///   - target: Target directory to restore to
  ///   - paths: Optional specific paths to restore
  /// - Returns: Dictionary of options for the restore command
  private func buildRestoreOptions(target: String, paths: [String]) -> [String: String] {
    var options: [String: String] = [
      "json": "true",
      "target": target
    ]
    
    if !paths.isEmpty {
      options["include"] = paths.joined(separator: ",")
    }
    
    return options
  }
  
  /// Checks if a repository exists at the given location
  /// 
  /// - Parameter location: The location to check
  /// - Returns: True if the repository exists, false otherwise
  private func checkIfRepositoryExists(at location: String) async throws -> Bool {
    do {
      let command = ResticCommand(
        action: .check,
        repository: location,
        password: nil
      )
      
      _ = try await execute(command)
      return true
    } catch {
      // If we get a specific error indicating the repository doesn't exist,
      // return false. Otherwise, rethrow the error.
      if let resticError = error as? ResticError,
         case .commandFailed(let exitCode, let output) = resticError,
         exitCode != 0 && output.contains("repository not found") {
        return false
      }
      
      // Credential errors or other errors that don't specifically indicate
      // the repository doesn't exist should be rethrown
      if let resticError = error as? ResticError,
         case .credentialError(_) = resticError {
        throw error
      }
      
      // Otherwise, assume the repository doesn't exist
      return false
    }
  }
}
