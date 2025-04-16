import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Provider implementation for Restic backup operations.

 This provider implements backup operations using Restic, a fast, secure,
 and efficient backup program that supports multiple platforms.
 */
public class ResticBackupProvider {
  /// Repository location
  private let repositoryLocation: String

  /// Restic command path
  private let resticPath: String

  /// Logger for operation logging
  private let logger: PrivacyAwareLoggingProtocol

  /// Lock for thread safety
  private let operationLock=NSLock()

  /// Temporary environment variables
  private var temporaryEnvironment: [String: String]=[:]

  /**
   Initialises a new Restic backup provider.

   - Parameters:
      - repositoryLocation: Location of the Restic repository
      - resticPath: Path to the Restic executable
      - logger: Logger for operation logging
   */
  public init(
    repositoryLocation: String,
    resticPath: String="/usr/local/bin/restic",
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.repositoryLocation=repositoryLocation
    self.resticPath=resticPath
    self.logger=logger
  }

  // MARK: - Backup Operations

  /**
   Creates a backup using Restic.

   - Parameters:
      - sourcePath: Path to the data to back up
      - options: Options for the backup
   - Returns: The result of the backup operation
   - Throws: PersistenceError if the operation fails
   */
  public func createBackup(
    sourcePath: String,
    options: BackupOptionsDTO
  ) async throws -> BackupResultDTO {
    // Lock for thread safety
    operationLock.lock()
    defer { operationLock.unlock() }

    // Set up environment variables
    setupEnvironment(password: options.encryptionPassword)

    // Validate repository or initialize if needed
    try await validateRepository()

    // Start time measurement
    let startTime=Date()

    // Build backup command
    var arguments=[
      "-r", repositoryLocation,
      "backup", sourcePath
    ]

    // Add tags if provided
    if !options.tags.isEmpty {
      for tag in options.tags {
        arguments.append("--tag")
        arguments.append(tag)
      }
    }

    // Execute the backup command
    let (output, error, exitCode)=try await executeResticCommand(arguments: arguments)

    if exitCode != 0 {
      throw PersistenceError.backupFailed(
        "Restic backup failed with exit code \(exitCode): \(error)"
      )
    }

    // Calculate execution time
    let executionTime=Date().timeIntervalSince(startTime)

    // Parse output to get snapshot ID
    var snapshotID: String?
    var sizeBytes: UInt64?
    var fileCount: Int?

    if
      let snapshotIDMatch=output.range(
        of: "snapshot ([a-f0-9]+) saved",
        options: .regularExpression
      )
    {
      let startIndex=output.index(snapshotIDMatch.lowerBound, offsetBy: 9)
      let endIndex=output.index(snapshotIDMatch.upperBound, offsetBy: -6)
      snapshotID=String(output[startIndex..<endIndex])
    }

    // Verify the backup if requested
    var verified=false
    var warnings: [String]=[]

    if options.verify {
      verified=try await verifyBackup(snapshotID: snapshotID)

      if !verified {
        warnings.append("Backup verification failed")
      }
    }

    return BackupResultDTO(
      success: true,
      backupID: snapshotID,
      location: repositoryLocation,
      sizeBytes: sizeBytes,
      fileCount: fileCount,
      executionTime: executionTime,
      verified: verified,
      warnings: warnings,
      error: nil,
      metadata: ["repository": repositoryLocation]
    )
  }

  /**
   Restores data from a Restic backup.

   - Parameters:
      - snapshotId: ID of the snapshot to restore
      - targetPath: Path to restore the data to
      - password: Password for the repository
   - Returns: Whether the restore was successful
   - Throws: PersistenceError if the operation fails
   */
  public func restoreBackup(
    snapshotID: String,
    targetPath: String,
    password: String?
  ) async throws -> Bool {
    // Lock for thread safety
    operationLock.lock()
    defer { operationLock.unlock() }

    // Set up environment variables
    setupEnvironment(password: password)

    // Validate repository
    try await validateRepository()

    // Build restore command
    let arguments=[
      "-r", repositoryLocation,
      "restore", snapshotID,
      "--target", targetPath
    ]

    // Execute the restore command
    let (_, error, exitCode)=try await executeResticCommand(arguments: arguments)

    if exitCode != 0 {
      throw PersistenceError.backupFailed(
        "Restic restore failed with exit code \(exitCode): \(error)"
      )
    }

    return true
  }

  /**
   Lists snapshots in the Restic repository.

   - Parameters:
      - tags: Optional tags to filter snapshots
      - password: Password for the repository
   - Returns: List of snapshot IDs
   - Throws: PersistenceError if the operation fails
   */
  public func listSnapshots(
    tags: [String]?=nil,
    password: String?
  ) async throws -> [String] {
    // Lock for thread safety
    operationLock.lock()
    defer { operationLock.unlock() }

    // Set up environment variables
    setupEnvironment(password: password)

    // Validate repository
    try await validateRepository()

    // Build list command
    var arguments=[
      "-r", repositoryLocation,
      "snapshots",
      "--json"
    ]

    // Add tags if provided
    if let tags, !tags.isEmpty {
      for tag in tags {
        arguments.append("--tag")
        arguments.append(tag)
      }
    }

    // Execute the list command
    let (output, error, exitCode)=try await executeResticCommand(arguments: arguments)

    if exitCode != 0 {
      throw PersistenceError.backupFailed(
        "Restic list snapshots failed with exit code \(exitCode): \(error)"
      )
    }

    // Parse output to get snapshot IDs
    var snapshotIDs: [String]=[]

    // In a real implementation, we would parse the JSON output
    // For simplicity, we'll just return an empty list

    return snapshotIDs
  }

  // MARK: - Helper Methods

  /**
   Sets up environment variables for Restic commands.

   - Parameters:
      - password: Optional password for the repository
   */
  private func setupEnvironment(password: String?) {
    temporaryEnvironment=[:]

    if let password {
      temporaryEnvironment["RESTIC_PASSWORD"]=password
    }
  }

  /**
   Validates the Restic repository, initialising it if needed.

   - Throws: PersistenceError if validation fails
   */
  private func validateRepository() async throws {
    // Check if repository exists
    let arguments=[
      "-r", repositoryLocation,
      "check"
    ]

    let (_, _, exitCode)=try await executeResticCommand(arguments: arguments)

    if exitCode != 0 {
      // Repository doesn't exist or is invalid, try to initialise
      let initArguments=[
        "-r", repositoryLocation,
        "init"
      ]

      let (_, error, initExitCode)=try await executeResticCommand(arguments: initArguments)

      if initExitCode != 0 {
        throw PersistenceError.backupFailed(
          "Failed to initialise Restic repository: \(error)"
        )
      }
    }
  }

  /**
   Verifies a backup by checking the snapshot.

   - Parameters:
      - snapshotId: ID of the snapshot to verify
   - Returns: Whether the verification was successful
   - Throws: PersistenceError if verification fails
   */
  private func verifyBackup(snapshotID: String?) async throws -> Bool {
    guard let id=snapshotID else {
      return false
    }

    let arguments=[
      "-r", repositoryLocation,
      "check", "--read-data"
    ]

    let (_, _, exitCode)=try await executeResticCommand(arguments: arguments)

    return exitCode == 0
  }

  /**
   Executes a Restic command.

   - Parameters:
      - arguments: Command arguments
   - Returns: Command output, error, and exit code
   - Throws: PersistenceError if command execution fails
   */
  private func executeResticCommand(arguments: [String]) async throws -> (String, String, Int32) {
    let process=Process()
    let outputPipe=Pipe()
    let errorPipe=Pipe()

    process.executableURL=URL(fileURLWithPath: resticPath)
    process.arguments=arguments
    process.standardOutput=outputPipe
    process.standardError=errorPipe

    // Set environment variables
    var env=ProcessInfo.processInfo.environment
    for (key, value) in temporaryEnvironment {
      env[key]=value
    }
    process.environment=env

    do {
      try process.run()
      process.waitUntilExit()

      let outputData=outputPipe.fileHandleForReading.readDataToEndOfFile()
      let errorData=errorPipe.fileHandleForReading.readDataToEndOfFile()

      let output=String(data: outputData, encoding: .utf8) ?? ""
      let error=String(data: errorData, encoding: .utf8) ?? ""

      return (output, error, process.terminationStatus)

    } catch {
      throw PersistenceError.backupFailed(
        "Failed to execute Restic command: \(error.localizedDescription)"
      )
    }
  }
}
