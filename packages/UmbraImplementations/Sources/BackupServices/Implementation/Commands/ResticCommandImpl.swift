import Foundation
import ResticInterfaces

/// A simple implementation of the ResticCommand protocol for use in the BackupServices module
///
/// This struct provides a concrete implementation of ResticCommand that can be used
/// to construct commands for Restic operations.
public struct ResticCommandImpl: ResticCommand {
  /// Arguments for the command
  public var arguments: [String]

  /// Environment variables for the command
  public let environment: [String: String]

  /// Whether the command requires a password
  public var requiresPassword: Bool

  /// Whether the command supports progress reporting
  public var supportsProgress: Bool

  /// The timeout for this command in seconds
  public var timeout: TimeInterval

  /// Creates a new Restic command with the specified arguments and environment
  /// - Parameters:
  ///   - arguments: Command line arguments
  ///   - environment: Environment variables (defaults to current process environment)
  ///   - requiresPassword: Whether the command requires a password
  ///   - supportsProgress: Whether the command supports progress reporting
  ///   - timeout: The timeout for this command in seconds
  public init(
    arguments: [String],
    environment: [String: String]=ProcessInfo.processInfo.environment,
    requiresPassword: Bool=true,
    supportsProgress: Bool=false,
    timeout: TimeInterval=300 // 5 minutes default timeout
  ) {
    self.arguments=arguments
    self.environment=environment
    self.requiresPassword=requiresPassword
    self.supportsProgress=supportsProgress
    self.timeout=timeout
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    // Basic validation: ensure we have at least one argument
    guard !arguments.isEmpty else {
      throw ResticError.invalidParameter("Command must have at least one argument")
    }
  }
}
