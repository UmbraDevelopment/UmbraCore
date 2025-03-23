import Foundation
import ResticTypes

/// Command for restoring data from a repository
public final class RestoreCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let snapshotID: String
  private let targetPath: String
  private let includePaths: [String]
  private let excludePaths: [String]
  private let verify: Bool

  public var commandName: String { "restore" }

  public var commandArguments: [String] {
    var args=[String]()

    // Add snapshot ID first
    args.append(snapshotID)

    // Add target path
    args.append("--target")
    args.append(targetPath)

    // Add included paths
    // Note: paths must match exactly how they were backed up
    for path in includePaths where !path.isEmpty {
      args.append("--include")
      // Strip any trailing slashes to match backup format
      let normalizedPath=path.hasSuffix("/") ? String(path.dropLast()) : path
      args.append(normalizedPath)
    }

    // Add exclude paths
    for path in excludePaths where !path.isEmpty {
      args.append("--exclude")
      // Strip any trailing slashes to match backup format
      let normalizedPath=path.hasSuffix("/") ? String(path.dropLast()) : path
      args.append(normalizedPath)
    }

    // Add verify flag
    if verify {
      args.append("--verify")
    }

    return args
  }

  public init(
    options: CommonOptions,
    snapshotID: String,
    targetPath: String,
    includePaths: [String]=[],
    excludePaths: [String]=[],
    verify: Bool=false
  ) {
    self.options=options
    self.snapshotID=snapshotID
    self.targetPath=targetPath
    self.includePaths=includePaths
    self.excludePaths=excludePaths
    self.verify=verify
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
    guard !snapshotID.isEmpty else {
      throw ResticError.missingParameter("Snapshot ID must not be empty")
    }
    guard !targetPath.isEmpty else {
      throw ResticError.missingParameter("Target path must not be empty")
    }
  }
}
