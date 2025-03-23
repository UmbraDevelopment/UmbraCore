import Foundation
import ResticTypes

/// Command for retrieving repository statistics
public final class StatsCommand: ResticCommand, @unchecked Sendable {
  /// Mode for stats command
  public enum Mode: String, Sendable {
    case restoreSize="restore-size"
    case rawData="raw-data"
    case blobs
  }

  private var mode: Mode?
  private var tag: String?
  private var paths: [String]=[]
  private var snapshotID: String?
  public private(set) var options: CommonOptions
  private var host: String?

  public var commandName: String { "stats" }

  /// Command-specific arguments
  public var commandArguments: [String] {
    var args=[String]()

    if let snapshotID {
      args.append(snapshotID)
    }

    if let mode {
      args.append("--mode=\(mode.rawValue)")
    }

    if let host {
      args.append("--host=\(host)")
    }

    if let tag {
      args.append("--tag=\(tag)")
    }

    // Add all paths to arguments
    args.append(contentsOf: paths)

    return args
  }

  /// Override the arguments property to include both common and command-specific arguments
  public var arguments: [String] {
    var args=[String]()

    // Add command-specific arguments
    args.append(contentsOf: commandArguments)

    // Add common arguments from options
    if options.quiet {
      args.append("--quiet")
    }
    if options.jsonOutput {
      args.append("--json")
    }

    args.append(contentsOf: options.arguments)
    return args
  }

  public init(options: CommonOptions) {
    self.options=options
  }

  /// Set the mode for the stats command
  @discardableResult
  public func mode(_ mode: Mode) -> Self {
    self.mode=mode
    return self
  }

  /// Set the host filter
  @discardableResult
  public func host(_ host: String) -> Self {
    self.host=host
    return self
  }

  /// Set the tag filter
  @discardableResult
  public func tag(_ tag: String) -> Self {
    self.tag=tag
    return self
  }

  /// Add a path filter
  @discardableResult
  public func path(_ path: String) -> Self {
    var newPaths=paths
    newPaths.append(path)

    // Since this is a final class, we can use self.init to create a new instance
    let newCommand=StatsCommand(options: options)
    newCommand.mode=mode
    newCommand.tag=tag
    newCommand.host=host
    newCommand.snapshotID=snapshotID
    newCommand.paths=newPaths

    // Use 'as! Self' to satisfy the return type
    return newCommand as! Self
  }

  /// Set the snapshot ID
  @discardableResult
  public func snapshot(_ id: String) -> Self {
    snapshotID=id
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
  }
}
