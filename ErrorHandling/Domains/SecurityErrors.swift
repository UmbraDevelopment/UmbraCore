import Foundation
import UmbraErrors
import UmbraErrorsCore

extension UmbraErrors {
  /// Security error domain
  public enum Security {
    /// Core security errors related to authentication, authorisation, encryption, etc.
    public enum Core: Error, UmbraError {
      // Authentication errors
      case authenticationFailed(reason: String)
      case invalidToken(reason: String)
      case accessDenied(reason: String)

      // Security operation errors
      case operationFailed(reason: String)
      case invalidParameter(name: String, reason: String)
      case internalError(description: String)

      // Key and certificate errors
      case invalidKey(reason: String)
      case invalidCertificate(reason: String)
      case invalidSignature(reason: String)
      case invalidContext(reason: String)

      // Authorization errors
      case missingEntitlement(reason: String)
      case notAuthorized(reason: String)

      // MARK: - UmbraError Protocol Implementation

      public var domain: String {
        "UmbraErrors.Security.Core"
      }

      public var code: String {
        let intCode=switch self {
          case .authenticationFailed: 1001
          case .invalidToken: 1002
          case .accessDenied: 1003
          case .operationFailed: 1004
          case .invalidParameter: 1005
          case .internalError: 1006
          case .invalidKey: 1007
          case .invalidCertificate: 1008
          case .invalidSignature: 1009
          case .invalidContext: 1010
          case .missingEntitlement: 1011
          case .notAuthorized: 1012
        }
        return String(intCode)
      }

      public var errorDescription: String {
        switch self {
          case let .authenticationFailed(reason):
            "Authentication failed: \(reason)"
          case let .invalidToken(reason):
            "Invalid token: \(reason)"
          case let .accessDenied(reason):
            "Access denied: \(reason)"
          case let .operationFailed(reason):
            "Operation failed: \(reason)"
          case let .invalidParameter(name, reason):
            "Invalid parameter '\(name)': \(reason)"
          case let .internalError(description):
            "Internal error: \(description)"
          case let .invalidKey(reason):
            "Invalid key: \(reason)"
          case let .invalidCertificate(reason):
            "Invalid certificate: \(reason)"
          case let .invalidSignature(reason):
            "Invalid signature: \(reason)"
          case let .invalidContext(reason):
            "Invalid context: \(reason)"
          case let .missingEntitlement(reason):
            "Missing entitlement: \(reason)"
          case let .notAuthorized(reason):
            "Not authorized: \(reason)"
        }
      }

      public var description: String {
        errorDescription
      }

      public var source: ErrorSource? {
        nil
      }

      public var underlyingError: Error? {
        nil
      }

      public var context: ErrorContext {
        ErrorContext(
          source: domain,
          operation: "security_operation",
          details: errorDescription
        )
      }

      public func with(context _: ErrorContext) -> Self {
        // Since these are enum cases, simply return self
        self
      }

      public func with(underlyingError _: Error) -> Self {
        // Since these are enum cases, simply return self
        self
      }

      public func with(source _: ErrorSource) -> Self {
        // Since these are enum cases, simply return self
        self
      }
    }
  }
}
