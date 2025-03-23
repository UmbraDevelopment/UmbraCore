import Foundation
import ResticTypes

/// Command for showing differences between snapshots
public final class DiffCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let snapshotID1: String
  private let snapshotID2: String
  private let path: String?
  private let metadata: Bool

  public var commandName: String { "diff" }

  public var commandArguments: [String] {
    var args=[String]()

    // Add snapshot IDs
    args.append(snapshotID1)
    args.append(snapshotID2)

    // Add path if specified
    if let path {
      args.append(path)
    }

    // Add metadata flag
    if metadata {
      args.append("--metadata")
    }

    return args
  }

  public init(
    options: CommonOptions,
    snapshotID1: String,
    snapshotID2: String,
    path: String?=nil,
    metadata: Bool=false
  ) {
    self.options=options
    self.snapshotID1=snapshotID1
    self.snapshotID2=snapshotID2
    self.path=path
    self.metadata=metadata
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
    guard !snapshotID1.isEmpty else {
      throw ResticError.missingParameter("First snapshot ID must not be empty")
    }
    guard !snapshotID2.isEmpty else {
      throw ResticError.missingParameter("Second snapshot ID must not be empty")
    }
  }
}
