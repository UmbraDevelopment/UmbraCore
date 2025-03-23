import Foundation
import ResticTypes

/// Command for copying snapshots between repositories
public final class CopyCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let snapshotIDs: [String]
  private let targetRepository: String
  private let targetPassword: String
  private let validateTargetCredentials: Bool

  public var commandName: String { "copy" }

  public var commandArguments: [String] {
    var args=[String]()

    // Add snapshot IDs
    args.append(contentsOf: snapshotIDs)

    // Add target repository
    args.append("--repo2")
    args.append(targetRepository)

    // Add insecure flag if validation is disabled
    if !validateTargetCredentials {
      args.append("--insecure-no-password")
    }

    return args
  }

  public init(
    options: CommonOptions,
    snapshotIDs: [String],
    targetRepository: String,
    targetPassword: String,
    validateTargetCredentials: Bool=true
  ) {
    self.options=options
    self.snapshotIDs=snapshotIDs
    self.targetRepository=targetRepository
    self.targetPassword=targetPassword
    self.validateTargetCredentials=validateTargetCredentials
  }

  public var environment: [String: String] {
    var env=options.environmentVariables
    env["RESTIC_REPOSITORY"]=options.repository
    env["RESTIC_PASSWORD"]=options.password
    env["RESTIC_REPOSITORY2"]=targetRepository
    env["RESTIC_PASSWORD2"]=targetPassword
    if let cachePath=options.cachePath {
      env["RESTIC_CACHE_DIR"]=cachePath
    }
    return env
  }

  public func validate() throws {
    guard !options.repository.isEmpty else {
      throw ResticError.missingParameter("Source repository path must not be empty")
    }
    guard !targetRepository.isEmpty else {
      throw ResticError.missingParameter("Target repository path must not be empty")
    }
    if options.validateCredentials, options.password.isEmpty {
      throw ResticError
        .missingParameter("Source password must not be empty when validation is enabled")
    }
    if validateTargetCredentials, targetPassword.isEmpty {
      throw ResticError
        .missingParameter("Target password must not be empty when validation is enabled")
    }
    guard !snapshotIDs.isEmpty else {
      throw ResticError.missingParameter("At least one snapshot ID must be specified")
    }
  }

  /// Set quiet mode
  @discardableResult
  public func setQuiet(_ quiet: Bool) -> Self {
    options=CommonOptions(
      repository: options.repository,
      password: options.password,
      cachePath: options.cachePath,
      quiet: quiet,
      jsonOutput: options.jsonOutput
    )
    return self
  }

  /// Enable or disable JSON output
  @discardableResult
  public func setJsonOutput(_ jsonOutput: Bool) -> Self {
    options=CommonOptions(
      repository: options.repository,
      password: options.password,
      cachePath: options.cachePath,
      quiet: options.quiet,
      jsonOutput: jsonOutput
    )
    return self
  }
}

/// Builder for CopyCommand
public class CopyCommandBuilder {
  private var options: CommonOptions
  private var snapshotIDs: [String]=[]
  private var targetRepository: String
  private var targetPassword: String
  private var validateTargetCredentials: Bool=true

  public init(options: CommonOptions, targetRepository: String, targetPassword: String) {
    self.options=options
    self.targetRepository=targetRepository
    self.targetPassword=targetPassword
  }

  /// Add a snapshot ID to copy
  @discardableResult
  public func addSnapshotID(_ id: String) -> Self {
    snapshotIDs.append(id)
    return self
  }

  /// Add multiple snapshot IDs to copy
  @discardableResult
  public func addSnapshotIDs(_ ids: [String]) -> Self {
    snapshotIDs.append(contentsOf: ids)
    return self
  }

  /// Disable password validation
  @discardableResult
  public func disablePasswordValidation() -> Self {
    validateTargetCredentials=false
    return self
  }

  /// Build the CopyCommand
  public func build() -> CopyCommand {
    CopyCommand(
      options: options,
      snapshotIDs: snapshotIDs,
      targetRepository: targetRepository,
      targetPassword: targetPassword,
      validateTargetCredentials: validateTargetCredentials
    )
  }
}
