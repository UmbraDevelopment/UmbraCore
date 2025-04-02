import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/// Thread-safe implementation of the ResticServiceProtocol using Swift concurrency.
///
/// This actor-based implementation provides proper isolation for concurrent operations,
/// ensuring thread safety while maintaining high performance for Restic operations.
@preconcurrency public actor ResticServiceImpl: ResticServiceProtocol {
  /// The path to the Restic executable
  public let executablePath: String

  /// The default repository location, if set
  public var defaultRepository: String? {
    get { _defaultRepository }
    set { _defaultRepository = newValue }
  }
  private var _defaultRepository: String?

  /// The default repository password, if set
  public var defaultPassword: String? {
    get { _defaultPassword }
    set { _defaultPassword = newValue }
  }
  private var _defaultPassword: String?

  /// Progress reporting delegate for receiving operation updates
  public var progressDelegate: (any ResticProgressReporting)? {
    get { _progressDelegate }
    set { _progressDelegate = newValue }
  }
  private var _progressDelegate: (any ResticProgressReporting)?

  /// The domain-specific logger for operation tracking
  private let resticLogger: ResticLogger

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
    defaultRepository: String?=nil,
    credentialManager: any ResticCredentialManager,
    progressDelegate: (any ResticProgressReporting)?=nil,
    logger: any LoggingProtocol
  ) throws {
    self.executablePath=executablePath
    _defaultRepository=defaultRepository
    _defaultPassword=nil
    _progressDelegate=progressDelegate
    self.resticLogger=ResticLogger(logger: logger)
    self.credentialManager=credentialManager

    if let progressDelegate {
      self.progressParser=ResticProgressParser(delegate: progressDelegate)
    }

    // Validate executable exists
    let fileManager=FileManager.default
    if !fileManager.fileExists(atPath: executablePath) {
      throw ResticError.executableNotFound(executablePath)
    }

    var isDirectory: ObjCBool=false
    guard
      fileManager.fileExists(atPath: executablePath, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      throw ResticError.invalidParameter("Restic executable path is a directory")
    }

    await resticLogger.info(
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
    let domainName: String = "ResticService"
    let source: String?
    let metadata: LoggingTypes.LogMetadataDTOCollection
    let correlationID: String?
    let repository: String
    let paths: [String]
    let tag: String?
    
    init(
      repository: String,
      paths: [String],
      tag: String?,
      metadata: LoggingTypes.LogMetadataDTOCollection = LoggingTypes.LogMetadataDTOCollection()
    ) {
      source = "ResticService.Backup"
      self.metadata = metadata
      correlationID = UUID().uuidString
      self.repository = repository
      self.paths = paths
      self.tag = tag
    }
    
    func toPrivacyMetadata() -> LoggingTypes.PrivacyMetadata {
      return metadata.toPrivacyMetadata()
    }
    
    func getSource() -> String {
      return source ?? "ResticService.Backup"
    }
    
    func toMetadata() -> LoggingTypes.LogMetadataDTOCollection {
      var result = metadata
        .withPrivate(key: "repository", value: repository)
      
      // Add paths as a comma-separated string
      if !paths.isEmpty {
        result = result.withPrivate(key: "paths", value: paths.joined(separator: ", "))
      }
      
      // Add tag if available
      if let tag = tag {
        result = result.withPrivate(key: "tag", value: tag)
      }
      
      return result
    }
    
    func withUpdatedMetadata(_ metadata: LoggingTypes.LogMetadataDTOCollection) -> BackupLogContext {
      return BackupLogContext(
        repository: repository,
        paths: paths,
        tag: tag,
        metadata: self.metadata.merging(with: metadata)
      )
    }
  }

  /// Domain-specific logging context for restore operations
  private struct RestoreLogContext: LoggingTypes.LogContextDTO {
    let domainName: String = "ResticService"
    let source: String?
    let metadata: LoggingTypes.LogMetadataDTOCollection
    let correlationID: String?
    let repository: String
    let snapshot: String
    let target: String
    
    init(
      repository: String,
      snapshot: String,
      target: String,
      metadata: LoggingTypes.LogMetadataDTOCollection = LoggingTypes.LogMetadataDTOCollection()
    ) {
      source = "ResticService.Restore"
      self.metadata = metadata
      correlationID = UUID().uuidString
      self.repository = repository
      self.snapshot = snapshot
      self.target = target
    }
    
    func toPrivacyMetadata() -> LoggingTypes.PrivacyMetadata {
      return metadata.toPrivacyMetadata()
    }
    
    func getSource() -> String {
      return source ?? "ResticService.Restore"
    }
    
    func toMetadata() -> LoggingTypes.LogMetadataDTOCollection {
      return metadata
        .withPrivate(key: "repository", value: repository)
        .withPrivate(key: "snapshot", value: snapshot)
        .withPrivate(key: "target", value: target)
    }
    
    func withUpdatedMetadata(_ metadata: LoggingTypes.LogMetadataDTOCollection) -> RestoreLogContext {
      return RestoreLogContext(
        repository: repository,
        snapshot: snapshot,
        target: target,
        metadata: self.metadata.merging(with: metadata)
      )
    }
  }

  /// Domain-specific logging context for maintenance operations
  private struct MaintenanceLogContext: LoggingTypes.LogContextDTO {
    let domainName: String = "ResticService"
    let source: String?
    let metadata: LoggingTypes.LogMetadataDTOCollection
    let correlationID: String?
    let repository: String
    let operationType: String
    
    init(
      repository: String,
      operationType: String,
      metadata: LoggingTypes.LogMetadataDTOCollection = LoggingTypes.LogMetadataDTOCollection()
    ) {
      source = "ResticService.Maintenance"
      self.metadata = metadata
      correlationID = UUID().uuidString
      self.repository = repository
      self.operationType = operationType
    }
    
    func toPrivacyMetadata() -> LoggingTypes.PrivacyMetadata {
      return metadata.toPrivacyMetadata()
    }
    
    func getSource() -> String {
      return source ?? "ResticService.Maintenance"
    }
    
    func toMetadata() -> LoggingTypes.LogMetadataDTOCollection {
      return metadata
        .withPrivate(key: "repository", value: repository)
        .withPrivate(key: "operationType", value: operationType)
    }
    
    func withUpdatedMetadata(_ metadata: LoggingTypes.LogMetadataDTOCollection) -> MaintenanceLogContext {
      return MaintenanceLogContext(
        repository: repository,
        operationType: operationType,
        metadata: self.metadata.merging(with: metadata)
      )
    }
  }

  // MARK: - Property Accessors

  /// Get the progress delegate
  public func getProgressDelegate() -> (any ResticProgressReporting)? {
    _progressDelegate
  }

  /// Set the progress delegate
  public func setProgressDelegate(_ delegate: (any ResticProgressReporting)?) {
    _progressDelegate=delegate
    if let delegate {
      progressParser=ResticProgressParser(delegate: delegate)
    } else {
      progressParser=nil
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

    let arguments = command.arguments
    let commandString = arguments.joined(separator: " ")
    
    await resticLogger.info(
      "Executing Restic command: \(commandString)",
      metadata: PrivacyMetadata([
        "command": (value: commandString, privacy: .private),
        "arguments": (value: arguments.joined(separator: " "), privacy: .private)
      ]),
      source: "ResticService"
    )

    // Create and configure the process
    let process=Process()
    process.executableURL=URL(fileURLWithPath: executablePath)
    process.arguments=arguments

    // Set environment variables
    var environment=ProcessInfo.processInfo.environment
    if let password=command.password {
      environment["RESTIC_PASSWORD"]=password
    } else if
      let repository=command.repository,
      let credentials=try await credentialManager.getCredentials(for: repository)
    {
      environment["RESTIC_PASSWORD"]=credentials.password
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
      await resticLogger.error(
        "Restic command failed to launch",
        privacyLevel: .public,
        source: "ResticService",
        metadata: PrivacyMetadata([
          "command": (value: commandString, privacy: .private)
        ])
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
    await resticLogger.debug(
      "Restic command completed with exit code \(exitCode) in \(String(format: "%.2f", duration))s",
      metadata: PrivacyMetadata([
        "command": (value: commandString, privacy: .private),
        "exitCode": (value: exitCode, privacy: .public),
        "duration": (value: duration, privacy: .public)
      ]),
      source: "ResticService"
    )

    if exitCode != 0 {
      // Log the error output with appropriate privacy controls
      await resticLogger.error(
        "Restic command failed with exit code \(exitCode)",
        metadata: PrivacyMetadata([
          "command": (value: commandString, privacy: .private),
          "exitCode": (value: exitCode, privacy: .public),
          "errorOutput": (value: errorOutput, privacy: .sensitive)
        ]),
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
    password: String?=nil
  ) async throws -> ResticCommandResult {
    let startTime=Date()

    // Check if repository already exists
    if try await checkIfRepositoryExists(at: location) {
      throw ResticError.repositoryExists(location)
    }

    // Create init command with provided or default password
    let repoPassword: String
    if let password {
      repoPassword=password
    } else {
      // Try to get from credential manager if repository already registered
      do {
        let credentials=try await credentialManager.getCredentials(for: location)
        repoPassword=credentials.password
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
    if ! await credentialManager.hasCredentials(for: location) {
      try await credentialManager.storeCredentials(
        ResticCredentials(
          repositoryIdentifier: location,
          password: repoPassword
        ),
        for: location
      )

      await resticLogger.info(
        "Stored credentials for new repository",
        metadata: PrivacyMetadata([
          "repository": (value: location, privacy: .private)
        ]),
        source: "ResticService"
      )
    }

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: convertToResticData(PrivacyMetadata([
        "repository": (value: location, privacy: .private)
      ]))
    )
  }

  /// Checks repository health
  ///
  /// - Parameter location: Optional repository location (uses default if nil)
  /// - Returns: Result of the repository check
  /// - Throws: ResticError if the check fails
  public func checkRepository(at location: String?) async throws -> ResticCommandResult {
    let startTime=Date()

    let repoLocation=location ?? defaultRepository
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
      data: convertToResticData(PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private)
      ]))
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

    let repoLocation=location ?? defaultRepository
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
      data: convertToResticData(PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "tag": (value: tag ?? "none", privacy: .public)
      ]))
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
    to repository: String?=nil,
    tag: String?=nil,
    excludes: [String]=[]
  ) async throws -> ResticCommandResult {
    let startTime=Date()

    // Determine repository location
    let repoLocation=repository ?? defaultRepository
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location not specified and no default set")
    }

    // Get password from credential manager if available
    let repoPassword: String?
    if await credentialManager.hasCredentials(for: repoLocation) {
      // Get from credential manager if available
      do {
        let credentials=try await credentialManager.getCredentials(for: repoLocation)
        repoPassword=credentials.password
      } catch let resticError as ResticError {
        await resticLogger.error(
          "Failed to retrieve credentials",
          metadata: PrivacyMetadata([
            "repository": (value: repoLocation, privacy: .private),
            "errorDescription": (value: resticError.logDescription, privacy: .sensitive)
          ]),
          source: "ResticService.Backup"
        )
        repoPassword=nil
      } catch {
        await resticLogger.error(
          "Unexpected error retrieving credentials",
          metadata: PrivacyMetadata([
            "repository": (value: repoLocation, privacy: .private),
            "errorDescription": (value: error.localizedDescription, privacy: .sensitive)
          ]),
          source: "ResticService.Backup"
        )
        repoPassword=nil
      }
    } else {
      repoPassword=nil
    }

    // Create backup command
    let command=ResticCommand(
      action: .backup,
      repository: repoLocation,
      password: repoPassword,
      arguments: paths,
      options: buildBackupOptions(tag: tag, excludes: excludes)
    )

    // Create backup context for logging
    let logContext=BackupLogContext(
      repository: repoLocation,
      paths: paths,
      tag: tag
    )

    await resticLogger.info(
      "Starting backup operation",
      metadata: [
        "repository": .string(repoLocation),
        "paths": .array(paths.map { .string($0) }),
        "excludes": .array(excludes.map { .string($0) })
      ],
      context: logContext
    )

    // Execute backup command
    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    // Store credentials if successful and not already stored
    if
      let repoPassword,
      ! await credentialManager.hasCredentials(for: repoLocation)
    {
      try? await credentialManager.storeCredentials(
        ResticCredentials(
          repositoryIdentifier: repoLocation,
          password: repoPassword
        ),
        for: repoLocation
      )
    }

    await resticLogger.info(
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
      data: convertToResticData(PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "paths": (value: paths, privacy: .public),
        "tag": (value: tag ?? "none", privacy: .public)
      ]))
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
    from repository: String?=nil,
    paths: [String]=[]
  ) async throws -> ResticCommandResult {
    let startTime=Date()

    // Determine repository location
    let repoLocation=repository ?? defaultRepository
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location not specified and no default set")
    }

    // Get password from credential manager if available
    let repoPassword: String?
    if await credentialManager.hasCredentials(for: repoLocation) {
      // Get from credential manager if available
      do {
        let credentials=try await credentialManager.getCredentials(for: repoLocation)
        repoPassword=credentials.password
      } catch let resticError as ResticError {
        await resticLogger.error(
          "Failed to retrieve credentials for restore",
          metadata: PrivacyMetadata([
            "repository": (value: repoLocation, privacy: .private),
            "errorDescription": (value: resticError.logDescription, privacy: .sensitive)
          ]),
          source: "ResticService.Restore"
        )
        repoPassword=nil
      } catch {
        await resticLogger.error(
          "Unexpected error retrieving credentials for restore",
          metadata: PrivacyMetadata([
            "repository": (value: repoLocation, privacy: .private),
            "errorDescription": (value: error.localizedDescription, privacy: .sensitive)
          ]),
          source: "ResticService.Restore"
        )
        repoPassword=nil
      }
    } else {
      repoPassword=nil
    }

    // Create context for logging
    let logContext=RestoreLogContext(
      repository: repoLocation,
      snapshot: snapshot,
      target: target
    )

    await resticLogger.info(
      "Starting restore operation",
      metadata: PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "snapshot": (value: snapshot, privacy: .public),
        "target": (value: target, privacy: .public),
        "paths": (value: paths?.joined(separator: ", ") ?? "all", privacy: .public)
      ]),
      source: "ResticService.Restore"
    )

    // Create and execute restore command
    let command=ResticCommand(
      action: .restore,
      repository: repoLocation,
      password: repoPassword,
      arguments: [snapshot],
      options: buildRestoreOptions(target: target, paths: paths)
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    await resticLogger.info(
      "Restore completed",
      metadata: PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "snapshot": (value: snapshot, privacy: .public),
        "target": (value: target, privacy: .public),
        "paths": (value: paths?.joined(separator: ", ") ?? "all", privacy: .public),
        "duration": (value: duration, privacy: .public)
      ]),
      source: "ResticService.Restore"
    )

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: convertToResticData(PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "snapshot": (value: snapshot, privacy: .public),
        "target": (value: target, privacy: .public),
        "paths": (value: paths, privacy: .public)
      ]))
    )
  }

  /// Performs repository maintenance
  ///
  /// - Parameter type: Type of maintenance operation
  /// - Returns: Result with maintenance information
  /// - Throws: ResticError if the maintenance fails
  public func maintenance(type: ResticMaintenanceType) async throws -> ResticCommandResult {
    let startTime=Date()

    let repoLocation=defaultRepository
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

    await resticLogger.info(
      "Maintenance completed",
      metadata: PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "maintenance_type": (value: type.rawValue, privacy: .public)
      ]),
      source: "ResticService.Maintenance"
    )

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: convertToResticData(PrivacyMetadata([
        "repository": (value: repoLocation, privacy: .private),
        "maintenance_type": (value: type.rawValue, privacy: .public)
      ]))
    )
  }

  // MARK: - Helper Methods

  /// Converts PrivacyMetadata to the format required by ResticCommandResult
  ///
  /// - Parameter metadata: The privacy metadata to convert
  /// - Returns: Dictionary in the format expected by ResticCommandResult
  private func convertToResticData(_ metadata: PrivacyMetadata) -> [String: ResticDataValue] {
    var result: [String: ResticDataValue] = [:]
    
    for (key, entry) in metadata.entries {
      // Extract the value and convert it to ResticDataValue
      switch entry.value {
      case let stringValue as String:
        result[key] = .string(stringValue)
      case let intValue as Int:
        result[key] = .number(Double(intValue))
      case let doubleValue as Double:
        result[key] = .number(doubleValue)
      case let boolValue as Bool:
        result[key] = .boolean(boolValue)
      case let arrayValue as [String]:
        result[key] = .array(arrayValue.map { .string($0) })
      case let optionalString as String?:
        if let string = optionalString {
          result[key] = .string(string)
        } else {
          result[key] = .null
        }
      default:
        result[key] = .string(String(describing: entry.value))
      }
    }
    
    return result
  }

  /// Builds options for a backup command
  ///
  /// - Parameters:
  ///   - tag: Optional tag to associate with the backup
  ///   - excludes: Paths to exclude from the backup
  /// - Returns: Dictionary of options for the backup command
  private func buildBackupOptions(tag: String?, excludes: [String]) -> [String: String] {
    var options=["json": "true"]

    if let tag {
      options["tag"]=tag
    }

    for excludePath in excludes {
      options["exclude"]=(options["exclude"] ?? "") + "\(excludePath),"
    }

    // Remove trailing comma from excludes if present
    if let excludeString=options["exclude"], excludeString.hasSuffix(",") {
      options["exclude"]=String(excludeString.dropLast())
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
    var options: [String: String]=[
      "json": "true",
      "target": target
    ]

    if !paths.isEmpty {
      options["include"]=paths.joined(separator: ",")
    }

    return options
  }

  /// Checks if a repository exists at the given location
  ///
  /// - Parameter location: The location to check
  /// - Returns: True if the repository exists, false otherwise
  private func checkIfRepositoryExists(at location: String) async throws -> Bool {
    do {
      let command=ResticCommand(
        action: .check,
        repository: location,
        password: nil
      )

      _=try await execute(command)
      return true
    } catch {
      // If we get a specific error indicating the repository doesn't exist,
      // return false. Otherwise, rethrow the error.
      if
        let resticError=error as? ResticError,
        case let .commandFailed(exitCode, output)=resticError,
        exitCode != 0 && output.contains("repository not found")
      {
        return false
      }

      // Credential errors or other errors that don't specifically indicate
      // the repository doesn't exist should be rethrown
      if
        let resticError=error as? ResticError,
        case .credentialError=resticError
      {
        throw error
      }

      // Otherwise, assume the repository doesn't exist
      return false
    }
  }
}
