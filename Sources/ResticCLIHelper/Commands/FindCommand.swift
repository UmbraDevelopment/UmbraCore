import Foundation
import ResticTypes

/// Command for finding files in snapshots
public final class FindCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let patterns: [String]
  private let snapshotID: String?
  private let ignoreCase: Bool
  private let longFormat: Bool

  public var commandName: String { "find" }

  public var commandArguments: [String] {
    var args=[String]()

    // Add patterns
    args.append(contentsOf: patterns)

    // Add snapshot ID if specified
    if let snapshotID {
      args.append("--snapshot")
      args.append(snapshotID)
    }

    // Add flags
    if ignoreCase {
      args.append("--ignore-case")
    }

    if longFormat {
      args.append("--long")
    }

    return args
  }

  public init(
    options: CommonOptions,
    patterns: [String],
    snapshotID: String?=nil,
    ignoreCase: Bool=false,
    longFormat: Bool=false
  ) {
    self.options=options
    self.patterns=patterns
    self.snapshotID=snapshotID
    self.ignoreCase=ignoreCase
    self.longFormat=longFormat
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
    guard !patterns.isEmpty else {
      throw ResticError.missingParameter("At least one search pattern must be specified")
    }
  }
}
