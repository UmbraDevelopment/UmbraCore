import Foundation

/// Extension to provide common error handling functionality
extension Error {
  /// Get a localized description of the error
  public var localizedDescription: String {
    if let customError = self as? LocalizedError {
      return customError.errorDescription ?? String(describing: self)
    }
    return String(describing: self)
  }

  /// Get the failure reason for the error
  public var failureReason: String? {
    (self as? LocalizedError)?.failureReason
  }

  /// Get a recovery suggestion for the error
  public var recoverySuggestion: String? {
    (self as? LocalizedError)?.recoverySuggestion
  }

  /// Get help anchor for the error
  public var helpAnchor: String? {
    (self as? LocalizedError)?.helpAnchor
  }

  /// Get the underlying error if this is a wrapper error
  public var underlyingError: Error? {
    (self as? CustomNSError)?.underlyingError
  }

  /// Get the error domain
  public var domain: String {
    if let customError = self as? CustomNSError {
      return type(of: customError).errorDomain
    }
    return String(describing: type(of: self))
  }

  /// Get the error code
  public var code: Int {
    (self as? CustomNSError)?.errorCode ?? 0
  }

  /// Get user info dictionary
  public var userInfo: [String: Any] {
    (self as? CustomNSError)?.errorUserInfo ?? [:]
  }
}
