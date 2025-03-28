import Foundation

/// Protocol defining the requirements for a Restic command
public protocol ResticCommand: Sendable {
  /// Arguments for the command
  var arguments: [String] { get }
  
  /// Environment variables for the command
  var environment: [String: String] { get }
  
  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  func validate() throws
}

/// Protocol defining the core functionality of the Restic service
///
/// The ResticService provides a Swift interface to interact with the Restic command-line tool
/// for backup and restore operations. It abstracts the complexity of command construction,
/// execution, and output parsing into a clean, type-safe API.
///
/// Key features:
/// - Repository initialisation and management
/// - Backup creation with filtering options
/// - Snapshot management and restoration
/// - Repository maintenance
/// - Progress reporting during long-running operations
///
/// All operations are thread-safe and support Swift concurrency with async/await patterns.
public protocol ResticServiceProtocol: Sendable {
  /// The path to the Restic executable
  var executablePath: String { get }
  
  /// The default repository location, if set
  var defaultRepository: String? { get set }
  
  /// The default repository password, if set
  var defaultPassword: String? { get set }
  
  /// Progress reporting delegate for receiving operation updates
  var progressDelegate: ResticProgressReporting? { get set }
  
  /// Executes a Restic command and returns its output
  /// - Parameter command: The command to execute
  /// - Returns: The command output as a string
  /// - Throws: ResticError if the command fails
  func execute(_ command: ResticCommand) async throws -> String
  
  /// Initialises a new repository
  /// - Parameters:
  ///   - location: Repository location (path or URL)
  ///   - password: Repository password
  /// - Returns: Result of the initialisation
  /// - Throws: ResticError if initialisation fails
  func initialiseRepository(at location: String, password: String) async throws -> ResticCommandResult
  
  /// Checks repository health
  /// - Parameter location: Optional repository location (uses default if nil)
  /// - Returns: Result of the repository check
  /// - Throws: ResticError if the check fails
  func checkRepository(at location: String?) async throws -> ResticCommandResult
  
  /// Lists snapshots in the repository
  /// - Parameters:
  ///   - location: Optional repository location (uses default if nil)
  ///   - tag: Optional tag to filter snapshots
  /// - Returns: Result containing snapshot information
  /// - Throws: ResticError if the listing fails
  func listSnapshots(at location: String?, tag: String?) async throws -> ResticCommandResult
  
  /// Creates a backup
  /// - Parameters:
  ///   - paths: Array of paths to backup
  ///   - tag: Optional tag for the backup
  ///   - excludes: Optional array of exclude patterns
  /// - Returns: Result with backup information
  /// - Throws: ResticError if the backup fails
  func backup(paths: [String], tag: String?, excludes: [String]?) async throws -> ResticCommandResult
  
  /// Restores from a backup
  /// - Parameters:
  ///   - snapshot: Snapshot ID to restore from
  ///   - target: Target path for restoration
  ///   - paths: Optional specific paths to restore
  /// - Returns: Result with restore information
  /// - Throws: ResticError if the restore fails
  func restore(snapshot: String, to target: String, paths: [String]?) async throws -> ResticCommandResult
  
  /// Performs repository maintenance
  /// - Parameter type: Type of maintenance operation
  /// - Returns: Result with maintenance information
  /// - Throws: ResticError if the maintenance fails
  func maintenance(type: ResticMaintenanceType) async throws -> ResticCommandResult
}
