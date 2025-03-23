import Foundation

/// Common options shared across all Restic commands
public struct CommonOptions: Sendable {
  /// Repository location
  public let repository: String

  /// Repository password
  public let password: String

  /// Optional cache directory path
  public let cachePath: String?

  /// Whether to validate credentials before executing commands
  public let validateCredentials: Bool

  /// Whether to suppress non-error output
  public let quiet: Bool

  /// Whether to output in JSON format
  public let jsonOutput: Bool

  /// Additional environment variables
  public let environmentVariables: [String: String]

  /// Additional command line arguments
  public let arguments: [String]

  /// Initializes common options for Restic commands
  /// - Parameters:
  ///   - repository: Repository location
  ///   - password: Repository password
  ///   - cachePath: Optional cache directory path
  ///   - validateCredentials: Whether to validate credentials before executing commands
  ///   - quiet: Whether to suppress non-error output
  ///   - jsonOutput: Whether to output in JSON format
  ///   - environmentVariables: Additional environment variables
  ///   - arguments: Additional command line arguments
  public init(
    repository: String,
    password: String,
    cachePath: String?=nil,
    validateCredentials: Bool=true,
    quiet: Bool=false,
    jsonOutput: Bool=false,
    environmentVariables: [String: String]=[:],
    arguments: [String]=[]
  ) {
    self.repository=repository
    self.password=password
    self.cachePath=cachePath
    self.validateCredentials=validateCredentials
    self.quiet=quiet
    self.jsonOutput=jsonOutput
    self.environmentVariables=environmentVariables
    self.arguments=arguments
  }
}
