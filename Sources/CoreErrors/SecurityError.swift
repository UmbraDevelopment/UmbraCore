import Foundation

/// Security error type for CoreErrors module
public struct SecurityError: Error, Equatable {
    /// Error description
    public let description: String

    /// Initialize with a description
    public init(description: String) {
        self.description = description
    }

    /// Compare two SecurityErrors
    public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
        return lhs.description == rhs.description
    }
}
