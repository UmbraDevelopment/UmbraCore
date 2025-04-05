import Foundation
import UmbraErrors
import UmbraErrorsCore

extension UmbraErrors {
  /// Crypto error domain
  public enum Crypto {
    /// Core cryptographic errors
    public enum Core: Error, UmbraError {
      // Cryptographic operation errors
      case operationFailed(reason: String)
      case invalidAlgorithm(name: String)
      case invalidKey(reason: String)
      case invalidData(reason: String)

      // Hash errors
      case hashingFailed(reason: String)
      case signatureVerificationFailed(reason: String)

      // MARK: - UmbraError Protocol Implementation

      public var domain: String {
        "UmbraErrors.Crypto.Core"
      }

      public var code: String {
        let intCode=switch self {
          case .operationFailed: 2001
          case .invalidAlgorithm: 2002
          case .invalidKey: 2003
          case .invalidData: 2004
          case .hashingFailed: 2011
          case .signatureVerificationFailed: 2012
        }
        return String(intCode)
      }

      public var errorDescription: String {
        switch self {
          case let .operationFailed(reason):
            "Crypto operation failed: \(reason)"
          case let .invalidAlgorithm(name):
            "Invalid crypto algorithm: \(name)"
          case let .invalidKey(reason):
            "Invalid crypto key: \(reason)"
          case let .invalidData(reason):
            "Invalid crypto data: \(reason)"
          case let .hashingFailed(reason):
            "Hashing operation failed: \(reason)"
          case let .signatureVerificationFailed(reason):
            "Signature verification failed: \(reason)"
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
          operation: "crypto_operation",
          details: errorDescription
        )
      }

      public var errorDomain: String {
        domain
      }

      public var errorCode: Int {
        Int(code) ?? 0
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
