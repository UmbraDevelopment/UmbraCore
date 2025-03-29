import Foundation
import LoggingInterfaces
import ResticInterfaces

/// Thread-safe implementation of the ResticServiceProtocol using Swift concurrency.
///
/// This actor-based implementation provides proper isolation for concurrent operations,
/// ensuring thread safety while maintaining high performance for Restic operations.
@preconcurrency
public actor ResticServiceImpl: ResticServiceProtocol {
  /// The path to the Restic executable
  public let executablePath: String

  /// The default repository location, if set
  public nonisolated(unsafe) var defaultRepository: String?

  /// The default repository password, if set
  public nonisolated(unsafe) var defaultPassword: String?

  /// Progress reporting delegate for receiving operation updates
  public nonisolated(unsafe) var progressDelegate: ResticProgressReporting?

  /// The logger for operation tracking
  private let logger: any LoggingProtocol

  /// The progress parser for tracking operation progress
  private var progressParser: ResticProgressParser?

  /// Creates a new ResticServiceImpl instance.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable
  ///   - defaultRepository: Optional default repository location
  ///   - defaultPassword: Optional default repository password
  ///   - progressDelegate: Optional delegate for progress reporting
  ///   - logger: Logger for operation tracking
  /// - Throws: ResticError if the executable cannot be found or accessed
  public init(
    executablePath: String,
    defaultRepository: String?=nil,
    defaultPassword: String?=nil,
    progressDelegate: ResticProgressReporting?=nil,
    logger: any LoggingProtocol
  ) throws {
    self.executablePath=executablePath
    self.defaultRepository=defaultRepository
    self.defaultPassword=defaultPassword
    self.progressDelegate=progressDelegate
    self.logger=logger

    if let progressDelegate {
      progressParser=ResticProgressParser(delegate: progressDelegate)
    }

    // Validate executable
    let fileManager=FileManager.default
    guard fileManager.fileExists(atPath: executablePath) else {
      throw ResticError.invalidConfiguration("Restic executable not found at \(executablePath)")
    }

    var isDirectory: ObjCBool=false
    guard
      fileManager.fileExists(atPath: executablePath, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      throw ResticError.invalidConfiguration("Path is a directory: \(executablePath)")
    }
  }

  /// Represents the setup for a Restic process execution
  private struct ProcessSetup {
    let process: Process
    let outputPipe: Pipe
    let errorPipe: Pipe
  }

  /// Sets up a Process object for executing a Restic command
  ///
  /// - Parameter command: The command to execute
  /// - Returns: A ProcessSetup containing the process and pipes
  private func setupProcess(for command: ResticCommand) -> ProcessSetup {
    let outputPipe=Pipe()
    let errorPipe=Pipe()

    let process=Process()
    process.executableURL=URL(fileURLWithPath: executablePath)
    process.arguments=command.arguments
    process.environment=command.environment
    process.standardOutput=outputPipe
    process.standardError=errorPipe

    return ProcessSetup(
      process: process,
      outputPipe: outputPipe,
      errorPipe: errorPipe
    )
  }

  /// Handles process execution errors
  ///
  /// - Parameters:
  ///   - error: The error that occurred
  ///   - stderr: Standard error output from the process
  /// - Throws: ResticError with context about what went wrong
  private func handleProcessError(_ error: Error, stderr: String) throws -> Never {
    if let error=error as? POSIXError {
      switch error.code {
        case .ENOENT:
          throw ResticError
            .executionFailed("Restic executable not found at path: \(executablePath)")
        case .EACCES:
          throw ResticError.permissionDenied(path: executablePath)
        default:
          throw ResticError
            .executionFailed("Failed to execute Restic: \(error.localizedDescription)")
      }
    }

    if !stderr.isEmpty {
      throw ResticError.executionFailed(stderr)
    }

    throw ResticError.executionFailed("Unknown error occurred while executing Restic")
  }

  /// Processes command output and checks for errors
  ///
  /// - Parameters:
  ///   - output: Standard output from the process
  ///   - stderr: Standard error output from the process
  /// - Returns: Processed output if successful
  /// - Throws: ResticError if command execution failed
  private func processOutput(_ output: String, _ stderr: String) throws -> String {
    if !stderr.isEmpty {
      // Check for known error patterns
      if stderr.contains("wrong password") {
        throw ResticError.invalidPassword
      }
      if stderr.contains("permission denied") {
        throw ResticError.permissionDenied(path: stderr)
      }
      if stderr.contains("repository not found") {
        throw ResticError.repositoryNotFound(path: stderr)
      }
      throw ResticError.executionFailed(stderr)
    }
    return output
  }

  /// Executes a Restic command and returns its output.
  ///
  /// - Parameter command: The command to execute
  /// - Returns: The command output as a string
  /// - Throws: ResticError if the command fails
  public func execute(_ command: ResticCommand) async throws -> String {
    try command.validate()

    await logger.info("Executing Restic command: \(type(of: command))", metadata: nil)

    let setup=setupProcess(for: command)

    do {
      try setup.process.run()

      let outputData=try await setup.outputPipe.fileHandleForReading.bytes
        .reduce(into: Data()) { $0.append($1) }
      let errorData=try await setup.errorPipe.fileHandleForReading.bytes
        .reduce(into: Data()) { $0.append($1) }

      setup.process.waitUntilExit()

      let output=String(data: outputData, encoding: .utf8) ?? ""
      let stderr=String(data: errorData, encoding: .utf8) ?? ""

      if let progressParser {
        // Try to parse progress output lines
        let outputLines=output.components(separatedBy: .newlines)
        for line in outputLines {
          _=progressParser.parseLine(line)
        }
      }

      return try processOutput(output, stderr)
    } catch {
      let errorData=try? setup.errorPipe.fileHandleForReading.readToEnd()
      let stderr=errorData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
      try handleProcessError(error, stderr: stderr)
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

    let command=ResticInitCommandImpl(
      location: location,
      password: password,
      commonOptions: nil
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: ["location": location]
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
      password: defaultPassword,
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
      data: ["repository": repoLocation]
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
      password: defaultPassword,
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
        "repository": repoLocation,
        "tag": tag as Any
      ]
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

    guard !paths.isEmpty else {
      throw ResticError.missingParameter("At least one backup path is required")
    }

    let repoLocation=defaultRepository
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location is required")
    }

    let options=ResticCommonOptions(
      repository: repoLocation,
      password: defaultPassword,
      jsonOutput: true
    )

    let command=ResticBackupCommandImpl(
      paths: paths,
      tag: tag,
      excludes: excludes,
      commonOptions: options
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": repoLocation,
        "paths": paths,
        "tag": tag as Any,
        "excludes": excludes as Any
      ]
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

    let repoLocation=defaultRepository
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location is required")
    }

    let options=ResticCommonOptions(
      repository: repoLocation,
      password: defaultPassword,
      jsonOutput: true
    )

    let command=ResticRestoreCommandImpl(
      snapshotID: snapshot,
      targetPath: target,
      paths: paths,
      commonOptions: options
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": repoLocation,
        "snapshot": snapshot,
        "target": target,
        "paths": paths as Any
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

    let repoLocation=defaultRepository
    guard let repoLocation else {
      throw ResticError.missingParameter("Repository location is required")
    }

    let options=ResticCommonOptions(
      repository: repoLocation,
      password: defaultPassword,
      jsonOutput: true
    )

    let command=ResticMaintenanceCommandImpl(
      maintenanceType: type,
      commonOptions: options
    )

    let output=try await execute(command)
    let duration=Date().timeIntervalSince(startTime)

    return ResticCommandResult.success(
      output: output,
      duration: duration,
      data: [
        "repository": repoLocation,
        "maintenance_type": type.rawValue
      ]
    )
  }
}
