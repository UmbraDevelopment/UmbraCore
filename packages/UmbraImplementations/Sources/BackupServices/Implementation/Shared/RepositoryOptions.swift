import Foundation

/// Options for checking a repository
public struct RepositoryCheckOptions: Sendable, Equatable {
  /// Whether to read and verify all data blobs
  public let readData: Bool

  /// Whether to check for unused blobs
  public let checkUnused: Bool

  /// Creates a new set of repository check options
  /// - Parameters:
  ///   - readData: Whether to read and verify all data blobs
  ///   - checkUnused: Whether to check for unused blobs
  public init(readData: Bool=false, checkUnused: Bool=false) {
    self.readData=readData
    self.checkUnused=checkUnused
  }
}
