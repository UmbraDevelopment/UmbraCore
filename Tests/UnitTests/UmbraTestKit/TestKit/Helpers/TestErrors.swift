import ErrorHandling
import Foundation

/// Test error type for security error handling tests
public enum SecTestError: Error, CustomStringConvertible, Equatable {
  case invalidInput(String)
  case invalidKey(String)
  case cryptoError(String)
  case invalidData(String)
  case accessDenied(reason: String)
  case itemNotFound(String)
  case invalidSecurityState(reason: String, state: String?=nil, expectedState: String?=nil)
  case bookmarkError(String)
  case operationFailed(String)
  case accessError(String)
  case internalError(String)

  public var description: String {
    switch self {
      case let .invalidInput(message):
        "Invalid input: \(message)"
      case let .invalidKey(message):
        "Invalid key: \(message)"
      case let .cryptoError(message):
        "Crypto error: \(message)"
      case let .invalidData(message):
        "Invalid data: \(message)"
      case let .accessDenied(reason):
        "Access denied: \(reason)"
      case let .itemNotFound(message):
        "Item not found: \(message)"
      case let .invalidSecurityState(reason, state, expectedState):
        if let state, let expectedState {
          "Invalid security state: current '\(state)', expected '\(expectedState)': \(reason)"
        } else {
          "Invalid security state: \(reason)"
        }
      case let .bookmarkError(message):
        "Bookmark error: \(message)"
      case let .operationFailed(message):
        "Operation failed: \(message)"
      case let .accessError(message):
        "Access error: \(message)"
      case let .internalError(message):
        "Internal error: \(message)"
    }
  }
}
