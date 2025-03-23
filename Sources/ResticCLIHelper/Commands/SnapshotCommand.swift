import Foundation
import ResticTypes

/// Command for managing repository snapshots
public struct SnapshotCommand: ResticCommand {
  /// Type of snapshot operation
  public enum Operation: Sendable {
    /// List snapshots
    case list
    /// Delete snapshots
    case delete([String])

    var commandName: String {
      switch self {
        case .list: "snapshots"
        case .delete: "forget"
      }
    }
  }

  /// Group by options for snapshot listing
  public enum GroupBy: String, Sendable {
    case host
    case paths
    case tags
  }

  /// Common options for the command
  public let options: CommonOptions

  /// Operation to perform
  public let operation: Operation

  /// Filter by paths
  public let paths: [String]

  /// Filter by tags
  public let tags: [String]

  /// Filter by host
  public let host: String?

  /// Group by option
  public let groupBy: GroupBy?

  public init(
    options: CommonOptions,
    operation: Operation,
    paths: [String]=[],
    tags: [String]=[],
    host: String?=nil,
    groupBy: GroupBy?=nil
  ) {
    self.options=options
    self.operation=operation
    self.paths=paths
    self.tags=tags
    self.host=host
    self.groupBy=groupBy
  }

  public var commandName: String {
    operation.commandName
  }

  public var environment: [String: String] {
    var env=options.environmentVariables
    env["RESTIC_PASSWORD"]=options.password
    env["RESTIC_REPOSITORY"]=options.repository
    return env
  }

  public var commandArguments: [String] {
    var args: [String]=[]

    if !options.validateCredentials, options.password.isEmpty {
      args.append("--insecure-no-password")
      args.append("--no-cache") // Avoid cache issues with empty passwords
    }

    switch operation {
      case .list:
        break // No additional arguments needed
      case let .delete(ids):
        args.append(contentsOf: ids)
    }

    if !paths.isEmpty {
      for path in paths {
        args.append("--path")
        args.append(path)
      }
    }

    if !tags.isEmpty {
      for tag in tags {
        args.append("--tag")
        args.append(tag)
      }
    }

    if let host {
      args.append("--host")
      args.append(host)
    }

    if let groupBy {
      args.append("--group-by")
      args.append(groupBy.rawValue)
    }

    return args
  }

  public func validate() throws {
    // Validate paths
    for path in paths {
      guard !path.isEmpty else {
        throw ResticError.invalidParameter("Path cannot be empty")
      }
    }

    // Validate tags
    for tag in tags {
      guard !tag.isEmpty else {
        throw ResticError.invalidParameter("Empty tag is not allowed")
      }
      guard !tag.contains(",") else {
        throw ResticError.invalidParameter("Tag cannot contain commas: \(tag)")
      }
    }

    // Validate snapshot IDs for delete operation
    if case let .delete(ids)=operation {
      guard !ids.isEmpty else {
        throw ResticError
          .missingParameter("At least one snapshot ID is required for delete operation")
      }
      for id in ids {
        guard !id.isEmpty else {
          throw ResticError.invalidParameter("Empty snapshot ID is not allowed")
        }
      }
    }
  }
}

/// Builder for creating SnapshotCommand instances
public class SnapshotCommandBuilder {
  private var options: CommonOptions
  private var operation: SnapshotCommand.Operation = .list
  private var paths: [String]=[]
  private var tags: [String]=[]
  private var host: String?
  private var groupBy: SnapshotCommand.GroupBy?

  public init(options: CommonOptions) {
    self.options=options
  }

  /// Set operation to list snapshots
  @discardableResult
  public func list() -> Self {
    operation = .list
    return self
  }

  /// Set operation to delete snapshots
  @discardableResult
  public func delete(ids: [String]) -> Self {
    operation = .delete(ids)
    return self
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

  /// Add a tag to filter by
  @discardableResult
  public func addTag(_ tag: String) -> Self {
    tags.append(tag)
    return self
  }

  /// Add multiple tags to filter by
  @discardableResult
  public func addTags(_ tags: [String]) -> Self {
    self.tags.append(contentsOf: tags)
    return self
  }

  /// Set host to filter by
  @discardableResult
  public func setHost(_ host: String) -> Self {
    self.host=host
    return self
  }

  /// Set group by option
  @discardableResult
  public func setGroupBy(_ groupBy: SnapshotCommand.GroupBy) -> Self {
    self.groupBy=groupBy
    return self
  }

  /// Build the snapshot command
  public func build() -> SnapshotCommand {
    SnapshotCommand(
      options: options,
      operation: operation,
      paths: paths,
      tags: tags,
      host: host,
      groupBy: groupBy
    )
  }
}
