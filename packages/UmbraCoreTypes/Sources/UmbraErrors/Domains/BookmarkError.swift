import Foundation
import UmbraErrorsCore

/**
 Error definitions for security bookmark operations.
 
 Following the Alpha Dot Five architecture pattern for domain-specific errors
 with detailed information and proper Sendable conformance for actor isolation.
 */
extension UmbraErrors {
    public enum Security {
        /**
         Security-scoped bookmark errors.
         */
        public enum Bookmark: Error, Equatable, Sendable {
            /// The bookmark is invalid and cannot be resolved
            case invalidBookmark(String)
            
            /// The bookmark is stale and needs to be recreated
            case staleBookmark(String)
            
            /// The URL cannot be resolved from the bookmark data
            case cannotResolveURL(String)
            
            /// Unable to create a bookmark for the URL
            case cannotCreateBookmark(String)
            
            /// The URL is not currently being accessed
            case notAccessing(String)
            
            /// Attempt to access a URL that is already being accessed
            case alreadyAccessing(String)
            
            /// The URL could not be accessed with security-scoped bookmark
            case accessDenied(String)
            
            /// A security operation failed with the given reason
            case operationFailed(String)
            
            /// Creates a human-readable description of the error
            public var localizedDescription: String {
                switch self {
                    case let .invalidBookmark(message):
                        "Invalid security bookmark: \(message)"
                    case let .staleBookmark(message):
                        "Stale security bookmark: \(message)"
                    case let .cannotResolveURL(message):
                        "Cannot resolve URL from bookmark: \(message)"
                    case let .cannotCreateBookmark(message):
                        "Cannot create security bookmark: \(message)"
                    case let .notAccessing(message):
                        "Not accessing resource: \(message)"
                    case let .alreadyAccessing(message):
                        "Already accessing resource: \(message)"
                    case let .accessDenied(message):
                        "Access denied to resource: \(message)"
                    case let .operationFailed(message):
                        "Security bookmark operation failed: \(message)"
                }
            }
            
            /// Returns an error code for this error
            public var errorCode: String {
                switch self {
                    case .invalidBookmark: "BM001"
                    case .staleBookmark: "BM002"
                    case .cannotResolveURL: "BM003"
                    case .cannotCreateBookmark: "BM004"
                    case .notAccessing: "BM005"
                    case .alreadyAccessing: "BM006"
                    case .accessDenied: "BM007"
                    case .operationFailed: "BM008"
                }
            }
        }
    }
}
