import Foundation

/// Extended security error functionality
import SecurityTypes

extension SecurityError {
  /// Initialize with a reason and code
  public static func withReasonAndCode(reason: String, code _: Int) -> SecurityError {
    SecurityError(description: reason)
  }
}
