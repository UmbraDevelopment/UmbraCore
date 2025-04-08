import Foundation

/**
 * Protocol for Restic commands.
 *
 * This protocol defines the interface for commands that can be executed
 * by the Restic service.
 */
public protocol ResticCommand: Sendable {
  /// The command arguments
  var arguments: [String] { get }

  /// Whether the command requires a password
  var requiresPassword: Bool { get }

  /// Whether the command supports progress reporting
  var supportsProgress: Bool { get }

  /// The timeout for this command in seconds
  var timeout: TimeInterval { get }
}
