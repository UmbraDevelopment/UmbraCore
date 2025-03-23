import Foundation
import ResticTypes

/// Command for removing snapshots from a repository
public final class ForgetCommand: ResticCommand, @unchecked Sendable {
  public private(set) var options: CommonOptions
  private let snapshotIDs: [String]
  private let keepLast: Int?
  private let keepHourly: Int?
  private let keepDaily: Int?
  private let keepWeekly: Int?
  private let keepMonthly: Int?
  private let keepYearly: Int?
  private let prune: Bool

  public var commandName: String { "forget" }

  public var commandArguments: [String] {
    var args = [String]()

    // Add snapshot IDs if specified
    args.append(contentsOf: snapshotIDs)

    // Add keep policy flags
    if let keepLast {
      args.append("--keep-last")
      args.append(String(keepLast))
    }

    if let keepHourly {
      args.append("--keep-hourly")
      args.append(String(keepHourly))
    }

    if let keepDaily {
      args.append("--keep-daily")
      args.append(String(keepDaily))
    }

    if let keepWeekly {
      args.append("--keep-weekly")
      args.append(String(keepWeekly))
    }

    if let keepMonthly {
      args.append("--keep-monthly")
      args.append(String(keepMonthly))
    }

    if let keepYearly {
      args.append("--keep-yearly")
      args.append(String(keepYearly))
    }

    if prune {
      args.append("--prune")
    }

    return args
  }

  public init(
    options: CommonOptions,
    snapshotIDs: [String] = [],
    keepLast: Int? = nil,
    keepHourly: Int? = nil,
    keepDaily: Int? = nil,
    keepWeekly: Int? = nil,
    keepMonthly: Int? = nil,
    keepYearly: Int? = nil,
    prune: Bool = false
  ) {
    self.options = options
    self.snapshotIDs = snapshotIDs
    self.keepLast = keepLast
    self.keepHourly = keepHourly
    self.keepDaily = keepDaily
    self.keepWeekly = keepWeekly
    self.keepMonthly = keepMonthly
    self.keepYearly = keepYearly
    self.prune = prune
  }

  public var environment: [String: String] {
    var env = options.environmentVariables
    env["RESTIC_REPOSITORY"] = options.repository
    env["RESTIC_PASSWORD"] = options.password
    if let cachePath = options.cachePath {
      env["RESTIC_CACHE_DIR"] = cachePath
    }
    return env
  }

  public func validate() throws {
    guard !options.repository.isEmpty else {
      throw ResticError.missingParameter("Repository path must not be empty")
    }
    if options.validateCredentials && options.password.isEmpty {
      throw ResticError.missingParameter("Password must not be empty when validation is enabled")
    }

    // Ensure at least one keep policy or snapshot ID is specified
    let hasKeepPolicy = keepLast != nil || keepHourly != nil || keepDaily != nil ||
      keepWeekly != nil || keepMonthly != nil || keepYearly != nil
    guard hasKeepPolicy || !snapshotIDs.isEmpty else {
      throw ResticError.missingParameter("Must specify either snapshot IDs or a keep policy")
    }
  }
}
