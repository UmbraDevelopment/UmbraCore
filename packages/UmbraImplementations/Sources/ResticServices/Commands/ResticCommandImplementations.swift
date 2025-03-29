import Foundation
import ResticInterfaces

/// Implementation of the ResticInitCommand protocol
public struct ResticInitCommandImpl: ResticInitCommand {
  /// Repository location (path or URL)
  public let location: String

  /// Repository password
  public let password: String

  /// Common options for the command
  public let commonOptions: ResticCommonOptions?

  /// Creates a new init command.
  ///
  /// - Parameters:
  ///   - location: Repository location (path or URL)
  ///   - password: Repository password
  ///   - commonOptions: Common options for the command
  public init(
    location: String,
    password: String,
    commonOptions: ResticCommonOptions?
  ) {
    self.location=location
    self.password=password
    self.commonOptions=commonOptions
  }

  /// Arguments for the command
  public var arguments: [String] {
    var args=["init"]

    if let commonOptions {
      args.append(contentsOf: commonOptions.buildArguments())
    }

    args.append(contentsOf: ["-r", location])

    return args
  }

  /// Environment variables for the command
  public var environment: [String: String] {
    var env=ProcessInfo.processInfo.environment
    env["RESTIC_PASSWORD"]=password

    if let commonOptions {
      for (key, value) in commonOptions.buildEnvironment() {
        env[key]=value
      }
    }

    return env
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    if location.isEmpty {
      throw ResticError.missingParameter("Repository location is required")
    }

    if password.isEmpty {
      throw ResticError.missingParameter("Repository password is required")
    }
  }
}

/// Implementation of the ResticBackupCommand protocol
public struct ResticBackupCommandImpl: ResticBackupCommand {
  /// Paths to backup
  public let paths: [String]

  /// Optional tag for the backup
  public let tag: String?

  /// Patterns to exclude from backup
  public let excludes: [String]?

  /// Common options for the command
  public let commonOptions: ResticCommonOptions?

  /// Creates a new backup command.
  ///
  /// - Parameters:
  ///   - paths: Paths to backup
  ///   - tag: Optional tag for the backup
  ///   - excludes: Patterns to exclude from backup
  ///   - commonOptions: Common options for the command
  public init(
    paths: [String],
    tag: String?,
    excludes: [String]?,
    commonOptions: ResticCommonOptions?
  ) {
    self.paths=paths
    self.tag=tag
    self.excludes=excludes
    self.commonOptions=commonOptions
  }

  /// Arguments for the command
  public var arguments: [String] {
    var args=["backup"]

    if let commonOptions {
      args.append(contentsOf: commonOptions.buildArguments())
    }

    if let tag {
      args.append(contentsOf: ["--tag", tag])
    }

    if let excludes {
      for exclude in excludes {
        args.append(contentsOf: ["--exclude", exclude])
      }
    }

    args.append(contentsOf: paths)

    return args
  }

  /// Environment variables for the command
  public var environment: [String: String] {
    var env=ProcessInfo.processInfo.environment

    if let commonOptions {
      for (key, value) in commonOptions.buildEnvironment() {
        env[key]=value
      }
    }

    return env
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    if paths.isEmpty {
      throw ResticError.missingParameter("At least one backup path is required")
    }

    for path in paths {
      if !FileManager.default.fileExists(atPath: path) {
        throw ResticError.invalidParameter("Path does not exist: \(path)")
      }
    }
  }
}

/// Implementation of the ResticRestoreCommand protocol
public struct ResticRestoreCommandImpl: ResticRestoreCommand {
  /// Snapshot ID to restore from
  public let snapshotID: String

  /// Target path for restoration
  public let targetPath: String

  /// Specific paths to restore (nil for all)
  public let paths: [String]?

  /// Common options for the command
  public let commonOptions: ResticCommonOptions?

  /// Creates a new restore command.
  ///
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to restore from
  ///   - targetPath: Target path for restoration
  ///   - paths: Specific paths to restore (nil for all)
  ///   - commonOptions: Common options for the command
  public init(
    snapshotID: String,
    targetPath: String,
    paths: [String]?,
    commonOptions: ResticCommonOptions?
  ) {
    self.snapshotID=snapshotID
    self.targetPath=targetPath
    self.paths=paths
    self.commonOptions=commonOptions
  }

  /// Arguments for the command
  public var arguments: [String] {
    var args=["restore", snapshotID]

    if let commonOptions {
      args.append(contentsOf: commonOptions.buildArguments())
    }

    args.append(contentsOf: ["--target", targetPath])

    if let paths {
      for path in paths {
        args.append(contentsOf: ["--include", path])
      }
    }

    return args
  }

  /// Environment variables for the command
  public var environment: [String: String] {
    var env=ProcessInfo.processInfo.environment

    if let commonOptions {
      for (key, value) in commonOptions.buildEnvironment() {
        env[key]=value
      }
    }

    return env
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    if snapshotID.isEmpty {
      throw ResticError.missingParameter("Snapshot ID is required")
    }

    if targetPath.isEmpty {
      throw ResticError.missingParameter("Target path is required")
    }
  }
}

/// Implementation of the ResticSnapshotsCommand protocol
public struct ResticSnapshotsCommandImpl: ResticSnapshotsCommand {
  /// Optional tag to filter snapshots
  public let tag: String?

  /// Common options for the command
  public let commonOptions: ResticCommonOptions?

  /// Creates a new snapshots command.
  ///
  /// - Parameters:
  ///   - tag: Optional tag to filter snapshots
  ///   - commonOptions: Common options for the command
  public init(
    tag: String?,
    commonOptions: ResticCommonOptions?
  ) {
    self.tag=tag
    self.commonOptions=commonOptions
  }

  /// Arguments for the command
  public var arguments: [String] {
    var args=["snapshots"]

    if let commonOptions {
      args.append(contentsOf: commonOptions.buildArguments())
    }

    if let tag {
      args.append(contentsOf: ["--tag", tag])
    }

    return args
  }

  /// Environment variables for the command
  public var environment: [String: String] {
    var env=ProcessInfo.processInfo.environment

    if let commonOptions {
      for (key, value) in commonOptions.buildEnvironment() {
        env[key]=value
      }
    }

    return env
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    // No validation required for this command
  }
}

/// Implementation of the ResticMaintenanceCommand protocol
public struct ResticMaintenanceCommandImpl: ResticMaintenanceCommand {
  /// Type of maintenance to perform
  public let maintenanceType: ResticMaintenanceType

  /// Common options for the command
  public let commonOptions: ResticCommonOptions?

  /// Creates a new maintenance command.
  ///
  /// - Parameters:
  ///   - maintenanceType: Type of maintenance to perform
  ///   - commonOptions: Common options for the command
  public init(
    maintenanceType: ResticMaintenanceType,
    commonOptions: ResticCommonOptions?
  ) {
    self.maintenanceType=maintenanceType
    self.commonOptions=commonOptions
  }

  /// Arguments for the command
  public var arguments: [String] {
    var args=[maintenanceType.rawValue]

    if let commonOptions {
      args.append(contentsOf: commonOptions.buildArguments())
    }

    return args
  }

  /// Environment variables for the command
  public var environment: [String: String] {
    var env=ProcessInfo.processInfo.environment

    if let commonOptions {
      for (key, value) in commonOptions.buildEnvironment() {
        env[key]=value
      }
    }

    return env
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    // No validation required for this command
  }
}

/// Implementation of the ResticCheckCommand protocol
public struct ResticCheckCommandImpl: ResticCheckCommand {
  /// Whether to read all data blobs
  public let readData: Bool

  /// Common options for the command
  public let commonOptions: ResticCommonOptions?

  /// Creates a new check command.
  ///
  /// - Parameters:
  ///   - readData: Whether to read all data blobs
  ///   - commonOptions: Common options for the command
  public init(
    readData: Bool,
    commonOptions: ResticCommonOptions?
  ) {
    self.readData=readData
    self.commonOptions=commonOptions
  }

  /// Arguments for the command
  public var arguments: [String] {
    var args=["check"]

    if let commonOptions {
      args.append(contentsOf: commonOptions.buildArguments())
    }

    if readData {
      args.append("--read-data")
    }

    return args
  }

  /// Environment variables for the command
  public var environment: [String: String] {
    var env=ProcessInfo.processInfo.environment

    if let commonOptions {
      for (key, value) in commonOptions.buildEnvironment() {
        env[key]=value
      }
    }

    return env
  }

  /// Validates the command before execution
  /// - Throws: ResticError if the command is invalid
  public func validate() throws {
    // No validation required for this command
  }
}
