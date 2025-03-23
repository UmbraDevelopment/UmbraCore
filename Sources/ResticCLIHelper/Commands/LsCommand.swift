import Foundation
import ResticTypes

/// Command for listing directory contents in snapshots
public final class LsCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let snapshotID: String
  private let path: String?
  private let longFormat: Bool
  private let recursive: Bool

  public var commandName: String { "ls" }

  public var commandArguments: [String] {
    var args=[String]()

    // Add snapshot ID
    args.append(snapshotID)

    // Add path if specified
    if let path {
      args.append(path)
    }

    // Add flags
    if longFormat {
      args.append("--long")
    }

    if recursive {
      args.append("--recursive")
    }

    return args
  }

  public init(
    options: CommonOptions,
    snapshotID: String,
    path: String?=nil,
    longFormat: Bool=false,
    recursive: Bool=false
  ) {
    self.options=options
    self.snapshotID=snapshotID
    self.path=path
    self.longFormat=longFormat
    self.recursive=recursive
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
  }
}
