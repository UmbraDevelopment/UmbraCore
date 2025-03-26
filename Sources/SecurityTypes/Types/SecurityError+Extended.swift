import Foundation

/// Extended security error functionality
import SecurityTypes
extension SecurityError {
  /// Initialize with a reason and code
  public static func withReasonAndCode(reason: String, code: Int) -> SecurityError {
    SecurityError(description: reason)
  }
}
