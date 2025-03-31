import Foundation

/// Wrapper for security core errors
public struct SecurityCoreErrorWrapper: Error, CustomStringConvertible {
  /// Description of the error
  public var description: String

  /// Initialize with a description
  public init(description: String) {
    self.description=description
  }
}
