import Foundation

/// Protocol defining the interface for all Restic commands
public protocol ResticCommand: Sendable {
  /// Common options for all Restic commands
  var options: CommonOptions { get }

  /// Name of the Restic command (e.g., "backup", "restore", etc.)
  var commandName: String { get }

  /// Arguments specific to this command
  var arguments: [String] { get }

  /// Environment variables for this command
  var environment: [String: String] { get }

  /// Validates the command configuration
  func validate() throws
}

extension ResticCommand {
  /// Default implementation of command arguments
  public var arguments: [String] {
    var args=[String]()
    args.append(commandName)

    if options.quiet {
      args.append("--quiet")
    }
    if options.jsonOutput {
      args.append("--json")
    }

    args.append(contentsOf: options.arguments)
    return args
  }

  /// Default implementation of environment variables
  public var environment: [String: String] {
    var env=options.environmentVariables
    env["RESTIC_REPOSITORY"]=options.repository
    env["RESTIC_PASSWORD"]=options.password
    if let cachePath=options.cachePath {
      env["RESTIC_CACHE_DIR"]=cachePath
    }
    return env
  }

  /// Default implementation of validation
  public func validate() throws {
    if options.repository.isEmpty {
      throw ResticError.missingParameter("Repository path must not be empty")
    }
    if options.validateCredentials, options.password.isEmpty {
      throw ResticError.missingParameter("Password must not be empty when validation is enabled")
    }
  }
}
