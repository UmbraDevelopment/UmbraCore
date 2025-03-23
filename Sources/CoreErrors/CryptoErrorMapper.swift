import Foundation

/// Mapper for CryptoError to canonical UmbraErrors.Crypto.Core
public struct CryptoErrorMapper {

    /// Maps a CryptoError to a canonical UmbraErrors.Crypto.Core error
    /// - Parameter error: The CryptoError to map
    /// - Returns: Mapped UmbraErrors.Crypto.Core error
    public static func mapToCryptoCoreError(_ error: CryptoError) -> Error {
        return CryptoError(
            type: error.type,
            description: error.description
        )
    }

    /// Maps a canonical UmbraErrors.Crypto.Core error to a CryptoError
    /// - Parameter error: The canonical error to map
    /// - Returns: Mapped CryptoError
    public static func mapFromCryptoCoreError(_ error: Error) -> CryptoError {
        if let cryptoError = error as? CryptoError {
            return cryptoError
        }
        return CryptoError(
            type: .operationFailed,
            description: "Unknown crypto error"
        )
    }
}
