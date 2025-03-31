import Foundation

/// Common options that can be applied to multiple Restic commands.
///
/// This struct provides a collection of options that can be used across different
/// Restic commands, ensuring consistent configuration and reducing duplication.
public struct ResticCommonOptions: Sendable {
  /// The repository location (path or URL)
  public let repository: String?

  /// The repository password
  public let password: String?

  /// Quiet mode (minimal output)
  public let quiet: Bool

  /// Verbose mode (detailed output)
  public let verbose: Bool

  /// JSON output format
  public let jsonOutput: Bool

  /// Cache directory path
  public let cacheDirectory: String?

  /// Limit upload bandwidth in KiB/s
  public let limitUpload: Int?

  /// Limit download bandwidth in KiB/s
  public let limitDownload: Int?

  /// Number of parallel operations to use
  public let parallelOperations: Int?

  /// Creates a new set of common options.
  ///
  /// - Parameters:
  ///   - repository: The repository location (path or URL)
  ///   - password: The repository password
  ///   - quiet: Quiet mode (minimal output)
  ///   - verbose: Verbose mode (detailed output)
  ///   - jsonOutput: JSON output format
  ///   - cacheDirectory: Cache directory path
  ///   - limitUpload: Limit upload bandwidth in KiB/s
  ///   - limitDownload: Limit download bandwidth in KiB/s
  ///   - parallelOperations: Number of parallel operations to use
  public init(
    repository: String?=nil,
    password: String?=nil,
    quiet: Bool=false,
    verbose: Bool=false,
    jsonOutput: Bool=false,
    cacheDirectory: String?=nil,
    limitUpload: Int?=nil,
    limitDownload: Int?=nil,
    parallelOperations: Int?=nil
  ) {
    self.repository=repository
    self.password=password
    self.quiet=quiet
    self.verbose=verbose
    self.jsonOutput=jsonOutput
    self.cacheDirectory=cacheDirectory
    self.limitUpload=limitUpload
    self.limitDownload=limitDownload
    self.parallelOperations=parallelOperations
  }

  /// Builds an array of command-line arguments from these options.
  ///
  /// - Returns: An array of command-line arguments
  public func buildArguments() -> [String] {
    var args: [String]=[]

    if let repository {
      args.append(contentsOf: ["-r", repository])
    }

    if quiet {
      args.append("-q")
    }

    if verbose {
      args.append("-v")
    }

    if jsonOutput {
      args.append("--json")
    }

    if let cacheDirectory {
      args.append(contentsOf: ["--cache-dir", cacheDirectory])
    }

    if let limitUpload {
      args.append(contentsOf: ["--limit-upload", "\(limitUpload)"])
    }

    if let limitDownload {
      args.append(contentsOf: ["--limit-download", "\(limitDownload)"])
    }

    if let parallelOperations {
      args.append(contentsOf: ["--parallel", "\(parallelOperations)"])
    }

    return args
  }

  /// Builds an environment dictionary from these options.
  ///
  /// - Returns: An environment dictionary
  public func buildEnvironment() -> [String: String] {
    var env: [String: String]=[:]

    if let password {
      env["RESTIC_PASSWORD"]=password
    }

    return env
  }
}
