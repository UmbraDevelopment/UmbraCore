import Foundation

/// Crypto error type for CoreErrors module
public struct CryptoError: Error, Equatable {
    /// Error type
    public enum ErrorType: Equatable {
        /// Invalid key length
        case invalidKeyLength
        /// Invalid parameters
        case invalidParameters
        /// Operation failed
        case operationFailed
    }

    /// The type of error
    public let type: ErrorType
    /// Error description
    public let description: String

    /// Initialize with a type and description
    public init(type: ErrorType, description: String) {
        self.type = type
        self.description = description
    }

    /// Initialize with invalid key length
    public static func invalidKeyLength(expected: Int, got: Int) -> CryptoError {
        return CryptoError(
            type: .invalidKeyLength,
            description: "Invalid key length: expected \(expected), got \(got)"
        )
    }

    /// Initialize with invalid parameters
    public static func invalidParameters(reason: String) -> CryptoError {
        return CryptoError(type: .invalidParameters, description: reason)
    }

    /// Initialize with operation failed
    public static func operationFailed(reason: String) -> CryptoError {
        return CryptoError(type: .operationFailed, description: reason)
    }

    /// Compare two CryptoErrors
    public static func == (lhs: CryptoError, rhs: CryptoError) -> Bool {
        return lhs.type == rhs.type && lhs.description == rhs.description
    }
}
