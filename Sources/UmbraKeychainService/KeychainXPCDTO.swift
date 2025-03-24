


import UmbraErrors
import UmbraErrorsCore
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import XPCProtocolsCore

/// DTOs used for KeychainXPCService operations
public enum KeychainXPCDTO {
  /// Request to store data in keychain
  public struct StoreRequest: Codable, Sendable {
    /// Service identifier
    public let service: String
    /// Data identifier
    public let identifier: String
    /// Access group (optional for testing)
    public let accessGroup: String?
    /// Data to store
    public let data: SecureBytes

    /// Initialise a store request
    /// - Parameters:
    ///   - service: Service identifier
    ///   - identifier: Data identifier
    ///   - accessGroup: Access group (optional for testing)
    ///   - data: Data to store
    public init(service: String, identifier: String, accessGroup: String?=nil, data: SecureBytes) {
      self.service=service
      self.identifier=identifier
      self.accessGroup=accessGroup
      self.data=data
    }
  }

  /// Request to retrieve data from keychain
  public struct RetrieveRequest: Codable, Sendable {
    /// Service identifier
    public let service: String
    /// Data identifier
    public let identifier: String
    /// Access group (optional for testing)
    public let accessGroup: String?

    /// Initialise a retrieve request
    /// - Parameters:
    ///   - service: Service identifier
    ///   - identifier: Data identifier
    ///   - accessGroup: Access group (optional for testing)
    public init(service: String, identifier: String, accessGroup: String?=nil) {
      self.service=service
      self.identifier=identifier
      self.accessGroup=accessGroup
    }
  }

  /// Request to delete data from keychain
  public struct DeleteRequest: Codable, Sendable {
    /// Service identifier
    public let service: String
    /// Data identifier
    public let identifier: String
    /// Access group (optional for testing)
    public let accessGroup: String?

    /// Initialise a delete request
    /// - Parameters:
    ///   - service: Service identifier
    ///   - identifier: Data identifier
    ///   - accessGroup: Access group (optional for testing)
    public init(service: String, identifier: String, accessGroup: String?=nil) {
      self.service=service
      self.identifier=identifier
      self.accessGroup=accessGroup
    }
  }

  /// Result of a keychain operation
  public enum OperationResult: Sendable {
    /// Operation succeeded
    case success
    /// Operation succeeded with data
    case successWithData(SecureBytes)
    /// Operation failed with error
    case failure(UmbraErrors.Security.Protocols)
  }

  /// Protocol extension to convert keychain errors to XPC errors
  extension UmbraErrors.Security.Protocols {
    /// Convert to keychain operation error
    /// - Returns: The keychain operation error
    public func toKeychainOperationError() -> UmbraErrors.Security.Protocols {
      self
    }
  }

  /// Extension to map KeyStorageError to KeychainOperationError
  extension KeyStorageError {
    /// Convert to KeychainXPCDTO.KeychainOperationError
    public func toKeychainOperationError() -> UmbraErrors.Security.Protocols {
      switch self {
        case .keyNotFound:
          return .missingProtocolImplementation(protocolName: "KeychainOperation")
        case .storageFailure:
          return .invalidInput("Authentication failed")
        case .unknown:
          return .internalError("Unknown storage error")
        @unknown default:
          return .internalError("Unexpected storage error")
      }
    }
  }
}
