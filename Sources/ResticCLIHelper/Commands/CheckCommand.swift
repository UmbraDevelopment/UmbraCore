import Foundation
import ResticTypes

/// Command for checking repository integrity
public final class CheckCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let readData: Bool
  private let checkUnused: Bool

  public var commandName: String { "check" }

  public var commandArguments: [String] {
    var args=[String]()

    if readData {
      args.append("--read-data")
    }

    if checkUnused {
      args.append("--check-unused")
    }

    return args
  }

  public init(
    options: CommonOptions,
    readData: Bool=false,
    checkUnused: Bool=false
  ) {
    self.options=options
    self.readData=readData
    self.checkUnused=checkUnused
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
