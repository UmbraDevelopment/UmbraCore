
import UmbraErrors
import UmbraErrorsCore
import Foundation

extension UmbraErrors.Security {
  /// Protocol-friendly security errors without Foundation dependencies
  public enum Protocols: Error, UmbraError {
    // Basic error types for cross-process boundary
    case invalidInput(String)
    case operationFailed(String)
    case timeout(String)
    case notFound(String)
    case notAvailable(String)
    case invalidState(String)
    case randomGenerationFailed(String)
    case notImplemented(String)

    // MARK: - UmbraError Protocol Implementation

    public var domain: String {
      "UmbraErrors.Security.Protocols"
    }

    public var code: String {
      let intCode=switch self {
        case .invalidInput: 2001
        case .operationFailed: 2002
        case .timeout: 2003
        case .notFound: 2004
        case .notAvailable: 2005
        case .invalidState: 2006
        case .randomGenerationFailed: 2007
        case .notImplemented: 2008
      }
      return String(intCode)
    }

    public var errorDescription: String {
      switch self {
        case let .invalidInput(message):
          "Invalid input: \(message)"
        case let .operationFailed(message):
          "Operation failed: \(message)"
        case let .timeout(message):
          "Timeout: \(message)"
        case let .notFound(message):
          "Not found: \(message)"
        case let .notAvailable(message):
          "Not available: \(message)"
        case let .invalidState(message):
          "Invalid state: \(message)"
        case let .randomGenerationFailed(message):
          "Random generation failed: \(message)"
        case let .notImplemented(message):
          "Not implemented: \(message)"
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
        operation: "security_protocol_operation",
        details: errorDescription
      )
    }

    public func with(context _: ErrorContext) -> Self {
      self
    }

    public func with(underlyingError _: Error) -> Self {
      self
    }

    public func with(source _: ErrorSource) -> Self {
      self
    }
  }
}
