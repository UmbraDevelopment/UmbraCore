import Foundation
import ResticTypes

/// Command for listing files in Restic snapshots
public struct ListCommand: ResticCommand {
  /// Common options for the command
  public let options: CommonOptions

  /// Snapshot ID to list files from
  public let snapshotID: String

  /// Paths to filter by (optional)
  public let paths: [String]

  /// Whether to list files recursively
  public let recursive: Bool

  /// Whether to use long format
  public let longFormat: Bool

  /// Whether to use NCDU format
  public let ncduFormat: Bool

  /// Host to filter by (only applies when using 'latest' as snapshotID)
  public let host: String?

  public var commandName: String { "list" }

  public var environment: [String: String] {
    var env=options.environmentVariables
    env["RESTIC_PASSWORD"]=options.password
    env["RESTIC_REPOSITORY"]=options.repository
    return env
  }

  public var commandArguments: [String] {
    var args=options.arguments
    args.append("--json")

    // Add snapshot ID
    args.append(snapshotID)

    // Add format flags
    if longFormat {
      args.append("--long")
    }

    if ncduFormat {
      args.append("--ncdu")
    }

    // Add recursive flag
    if recursive {
      args.append("--recursive")
    }

    // Add host filter for latest snapshot
    if snapshotID == "latest", let host {
      args.append("--host")
      args.append(host)
    }

    // Add paths to filter by
    args.append(contentsOf: paths)

    return args
  }

  public func validate() throws {
    // Validate snapshot ID
    guard !snapshotID.isEmpty else {
      throw ResticError.missingParameter("Snapshot ID is required")
    }

    // Validate paths
    for path in paths {
      guard !path.isEmpty else {
        throw ResticError.invalidParameter("Path cannot be empty")
      }

      // Paths must be absolute
      guard path.hasPrefix("/") else {
        throw ResticError.invalidParameter("Path must be absolute: \(path)")
      }
    }

    // Validate host when using latest
    if snapshotID == "latest", let host {
      guard !host.isEmpty else {
        throw ResticError.invalidParameter("Host cannot be empty when filtering latest snapshot")
      }
    }
  }
}

/// Builder for creating ListCommand instances
public class ListCommandBuilder {
  private var options: CommonOptions
  private var snapshotID: String
  private var paths: [String]=[]
  private var recursive: Bool=false
  private var longFormat: Bool=false
  private var ncduFormat: Bool=false
  private var host: String?

  public init(repository: String, password: String, snapshotID: String) {
    options=CommonOptions(repository: repository, password: password)
    self.snapshotID=snapshotID
  }

  /// Add a path to filter by
  @discardableResult
  public func addPath(_ path: String) -> Self {
    paths.append(path)
    return self
  }

  /// Add multiple paths to filter by
  @discardableResult
  public func addPaths(_ paths: [String]) -> Self {
    self.paths.append(contentsOf: paths)
    return self
  }

  /// Set whether to list files recursively
  @discardableResult
  public func setRecursive(_ recursive: Bool) -> Self {
    self.recursive=recursive
    return self
  }

  /// Set whether to use long format
  @discardableResult
  public func setLongFormat(_ longFormat: Bool) -> Self {
    self.longFormat=longFormat
    return self
  }

  /// Set whether to use NCDU format
  @discardableResult
  public func setNcduFormat(_ ncduFormat: Bool) -> Self {
    self.ncduFormat=ncduFormat
    return self
  }

  /// Set host to filter by (only applies when using 'latest' as snapshotID)
  @discardableResult
  public func setHost(_ host: String) -> Self {
    self.host=host
    return self
  }

  /// Set the cache directory
  @discardableResult
  public func setCachePath(_ path: String) -> Self {
    options=CommonOptions(
      repository: options.repository,
      password: options.password,
      cachePath: path,
      quiet: options.quiet,
      jsonOutput: options.jsonOutput
    )
    return self
  }

  /// Enable or disable quiet mode
  @discardableResult
  public func setQuiet(_ quiet: Bool) -> Self {
    options=CommonOptions(
      repository: options.repository,
      password: options.password,
      cachePath: options.cachePath,
      quiet: quiet,
      jsonOutput: options.jsonOutput
    )
    return self
  }

  /// Enable or disable JSON output
  @discardableResult
  public func setJsonOutput(_ enabled: Bool) -> Self {
    options=CommonOptions(
      repository: options.repository,
      password: options.password,
      cachePath: options.cachePath,
      quiet: options.quiet,
      jsonOutput: enabled
    )
    return self
  }

  /// Build the list command
  public func build() -> ListCommand {
    ListCommand(
      options: options,
      snapshotID: snapshotID,
      paths: paths,
      recursive: recursive,
      longFormat: longFormat,
      ncduFormat: ncduFormat,
      host: host
    )
  }
}
