import Foundation

/// Key manager error type for CoreErrors module
public struct KeyManagerError: Error, Equatable {
    /// Error description
    public let description: String

    /// Initialize with a description
    public init(description: String) {
        self.description = description
    }

    /// Compare two KeyManagerErrors
    public static func == (lhs: KeyManagerError, rhs: KeyManagerError) -> Bool {
        return lhs.description == rhs.description
    }
}
