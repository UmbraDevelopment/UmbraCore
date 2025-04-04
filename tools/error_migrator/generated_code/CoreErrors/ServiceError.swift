import Foundation

/// ServiceError error type
public enum ServiceError: Error {
  case initialisationFailed
  case invalidState
  case configurationError
  case dependencyError
  case operationFailed
}
