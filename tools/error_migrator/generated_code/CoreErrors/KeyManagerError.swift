import Foundation

/// KeyManagerError error type
public enum KeyManagerError: Error {
  case keyNotFound
  case unsupportedStorageLocation
  case synchronisationError
  case operationFailed
  case keyExpired
}
