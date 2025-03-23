import Foundation

/// Wrapper for application core errors
public struct ApplicationCoreErrorWrapper: Error, CustomStringConvertible {
  /// Description of the error
  public var description: String

  /// Initialize with a description
  public init(description: String) {
    self.description = description
  }
}
