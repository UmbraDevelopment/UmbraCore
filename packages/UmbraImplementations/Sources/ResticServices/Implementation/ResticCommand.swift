import Foundation
import ResticInterfaces

/// Represents a Restic command action type
public enum ResticCommandAction: String, Sendable {
  case backup
  case restore
  case check
  case stats
  case snapshots
  case list
  case find
  case prune
  case forget
  case mount
  case unlock
  case `init`
}

/// A structured representation of a Restic command
public struct ResticCommand: ResticInterfaces.ResticCommand, Sendable {
  /// The command action to execute
  public let action: ResticCommandAction

  /// The repository to operate on
  public let repository: String

  /// The password for the repository (if not using credential manager)
  public let password: String?

  /// Additional command arguments
  public let arguments: [String]

  /// Command options in the form of key-value pairs
  public let options: [String: String]

  /// Whether to track progress for this command
  public let trackProgress: Bool

  /// Environment variables for the command
  public var environment: [String: String] {
    [:] // Default implementation returns empty dictionary
  }

  /// Constructs the full command string including all arguments and options
  public var commandString: String {
    var parts=[action.rawValue]

    // Add repository
    parts.append("--repo")
    parts.append(repository)

    // Add options
    for (key, value) in options {
      if key.count == 1 {
        parts.append("-\(key)")
      } else {
        parts.append("--\(key)")
      }

      if !value.isEmpty && value != "true" {
        parts.append(value)
      }
    }

    // Add arguments
    parts.append(contentsOf: arguments)

    return parts.joined(separator: " ")
  }

  /// Initialises a new ResticCommand
  ///
  /// - Parameters:
  ///   - action: The command action to execute
  ///   - repository: The repository to operate on
  ///   - password: Optional password for the repository (if not using credential manager)
  ///   - arguments: Additional command arguments
  ///   - options: Command options in the form of key-value pairs
  ///   - trackProgress: Whether to track progress for this command
  public init(
    action: ResticCommandAction,
    repository: String,
    password: String?=nil,
    arguments: [String]=[],
    options: [String: String]=[:],
    trackProgress: Bool=false
  ) {
    self.action=action
    self.repository=repository
    self.password=password
    self.arguments=arguments
    self.options=options
    self.trackProgress=trackProgress
  }

  /// Validates that the command is correctly configured
  ///
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    if repository.isEmpty, action != .`init` {
      throw ResticError.missingParameter("Repository is required for all commands except init")
    }

    // Action-specific validation
    switch action {
      case .backup:
        if arguments.isEmpty {
          throw ResticError.missingParameter("Backup paths are required")
        }
      case .restore:
        if arguments.isEmpty {
          throw ResticError.missingParameter("Snapshot ID is required for restore")
        }
        guard options["target"] != nil else {
          throw ResticError.missingParameter("Target path is required for restore")
        }
      case .`init`:
        // The repository might not exist yet for init, so no repository validation
        break
      default:
        // Basic validation only
        break
    }
  }
}
