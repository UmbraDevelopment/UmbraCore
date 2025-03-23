import Foundation

/// Extended security error functionality
public extension SecurityError {
    /// Initialize with a reason and code
    static func withReasonAndCode(reason: String, code: Int) -> SecurityError {
        return SecurityError(description: reason)
    }
}
