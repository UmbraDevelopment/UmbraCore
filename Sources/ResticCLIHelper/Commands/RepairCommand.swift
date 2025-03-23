import Foundation
import ResticTypes

/// Command for repairing repository inconsistencies
public final class RepairCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions

  public var commandName: String { "repair" }

  public var commandArguments: [String] { [] }

  public init(options: CommonOptions) {
    self.options=options
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
