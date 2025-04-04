import CoreSecurityTypes
import Foundation
import UmbraErrors

/**
 # KeyMetadataError

 Represents errors that can occur during key metadata operations.
 These errors provide detailed information about what went wrong during
 key metadata creation, storage, retrieval, or manipulation operations.

 Each error case includes detailed information to aid in diagnosis and resolution.
 */
public enum KeyMetadataError: Error, Sendable, Equatable {
  /// The key was not found with the specified identifier
  case keyNotFound(identifier: String)

  /// The key already exists with the specified identifier
  case keyAlreadyExists(identifier: String)

  /// The key data is invalid or corrupted
  case invalidKeyData(details: String)

  /// The key storage operation failed
  case keyStorageError(details: String)

  /// The key metadata storage operation failed
  case metadataError(details: String)

  /// A general key management error
  case keyManagementError(details: String)

  /**
   Converts this domain-specific error to a standardised SecurityProtocolError.

   - Returns: The equivalent SecurityProtocolError
   */
  public func toStandardError() -> SecurityProtocolError {
    switch self {
      case let .keyNotFound(identifier):
        .operationFailed(reason: "Key not found: \(identifier)")
      case let .keyAlreadyExists(identifier):
        .operationFailed(reason: "Key already exists: \(identifier)")
      case let .invalidKeyData(details):
        .operationFailed(reason: "Invalid key data: \(details)")
      case let .keyStorageError(details), let .metadataError(details),
           let .keyManagementError(details):
        .operationFailed(reason: details)
    }
  }
}
