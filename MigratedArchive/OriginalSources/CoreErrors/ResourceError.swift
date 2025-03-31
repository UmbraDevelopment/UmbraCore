import Foundation

/// ResourceError error type
public enum ResourceError: Error {
  case acquisitionFailed
  case invalidState
  case poolExhausted
  case resourceNotFound
  case operationFailed
}
