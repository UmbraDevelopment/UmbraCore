import Foundation
import ResticTypes

/// Command for creating backups
///
/// BackupCommand provides a flexible interface for backing up files and directories to a Restic
/// repository.
/// It supports various options including tags, host specification, and exclusion patterns.
///
/// Example usage:
/// ```swift
/// let command = BackupCommand(options: commonOptions)
///     .addPath("/path/to/backup")
///     .tag("daily")
///     .exclude("*.tmp")
///     .withProgress()
/// ```
public final class BackupCommand: ResticCommand, @unchecked Sendable {
  private var paths: [String]=[]
  private var tags: [String]=[]
  private var host: String?
  private var excludePatterns: [String]=[]
  public private(set) var enableProgress: Bool=false
  private var parentPID: Int?
  public private(set) var options: CommonOptions

  public var commandName: String { "backup" }

  public var commandArguments: [String] {
    var args=[String]()

    // Add paths
    args.append(contentsOf: paths)

    // Add tags
    for tag in tags {
      args.append("--tag")
      args.append(tag)
    }

    // Add host
    if let host {
      args.append("--host")
      args.append(host)
    }

    // Add exclude patterns
    for pattern in excludePatterns {
      args.append("--exclude")
      args.append(pattern)
    }

    // Add progress reporting
    if enableProgress {
      args.append("--json")
      args.append("--verbose")
    }

    // Add parent process ID for proper cancellation handling
    if let pid=parentPID {
      args.append("--parent")
      args.append(String(pid))
    }

    return args
  }

  /// Create a backup command with the specified options
  ///
  /// - Parameters:
  ///   - paths: Paths to backup
  ///   - excludes: Paths to exclude
  ///   - tags: Tags to apply to the backup
  ///   - options: Common options for the command
  public init(
    paths: [String],
    excludes: [String]=[],
    tags: [String]=[],
    options: CommonOptions
  ) {
    self.paths=paths
    excludePatterns=excludes
    self.tags=tags
    self.options=options
  }

  /// Add a path to backup
  @discardableResult
  public func addPath(_ path: String) -> Self {
    paths.append(path)
    return self
  }

  /// Add multiple paths to backup
  @discardableResult
  public func addPaths(_ paths: [String]) -> Self {
    self.paths.append(contentsOf: paths)
    return self
  }

  /// Add a tag
  @discardableResult
  public func tag(_ tag: String) -> Self {
    tags.append(tag)
    return self
  }

  /// Set the host
  @discardableResult
  public func host(_ host: String) -> Self {
    self.host=host
    return self
  }

  /// Add an exclude pattern
  @discardableResult
  public func exclude(_ pattern: String) -> Self {
    excludePatterns.append(pattern)
    return self
  }

  /// Add multiple exclude patterns
  @discardableResult
  public func excludePatterns(_ patterns: [String]) -> Self {
    excludePatterns.append(contentsOf: patterns)
    return self
  }

  /// Enable progress reporting
  @discardableResult
  public func withProgress() -> Self {
    enableProgress=true
    return self
  }

  /// Set the cache path
  @discardableResult
  public func setCachePath(_ path: String) -> Self {
    var env=options.environmentVariables
    env["RESTIC_CACHE_DIR"]=path
    options=CommonOptions(
      repository: options.repository,
      password: options.password,
      cachePath: options.cachePath,
      validateCredentials: options.validateCredentials,
      quiet: options.quiet,
      jsonOutput: options.jsonOutput,
      environmentVariables: env,
      arguments: options.arguments
    )
    return self
  }

  /// Set the parent process ID
  ///
  /// This helps Restic properly handle cancellation when the parent process is terminated.
  @discardableResult
  public func setParentPID(_ pid: Int) -> Self {
    parentPID=pid
    return self
  }

  public var environment: [String: String] {
    var env=options.environmentVariables
    env["RESTIC_REPOSITORY"]=options.repository
    env["RESTIC_PASSWORD"]=options.password
    if let cachePath=options.cachePath {
      env["RESTIC_CACHE_DIR"]=cachePath
    }
    return env
  }

  public func validate() throws {
    guard !options.repository.isEmpty else {
      throw ResticError.missingParameter("Repository path must not be empty")
    }
    if options.validateCredentials, options.password.isEmpty {
      throw ResticError.missingParameter("Password must not be empty when validation is enabled")
    }
    guard !paths.isEmpty else {
      throw ResticError.missingParameter("At least one backup path must be specified")
    }

    // Validate paths exist
    for path in paths {
      guard FileManager.default.fileExists(atPath: path) else {
        throw ResticError.invalidParameter("Backup path does not exist: \(path)")
      }
    }

    // Validate tags
    for tag in tags {
      guard tag.range(of: "^[a-zA-Z0-9][a-zA-Z0-9_.-]*$", options: .regularExpression) != nil else {
        throw ResticError.invalidParameter(
          "Invalid tag format: \(tag). " +
            "Tags must start with alphanumeric and contain only alphanumeric, underscore, dot, or hyphen"
        )
      }
    }
  }

  /// Run the backup command
  ///
  /// - Throws: ResticError if validation fails or command execution fails
  public func run() throws {
    try validate()
    try execute()
  }

  /// Execute the backup command
  ///
  /// - Throws: ResticError if the command fails
  public func execute() throws {
    let process=Process()
    process.executableURL=URL(fileURLWithPath: "/usr/bin/env")
    process.arguments=["restic", commandName] + commandArguments
    process.environment=environment

    let pipe=Pipe()
    process.standardOutput=pipe
    process.standardError=pipe

    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
      let data=try pipe.fileHandleForReading.readToEnd() ?? Data()
      let output=String(data: data, encoding: .utf8) ?? ""
      throw ResticError.executionFailed(output)
    }
  }
}
