// CryptoKit removed - cryptography will be handled in ResticBar
import ErrorHandling
import ErrorHandlingDomains
import Foundation
import SecurityBridgeTypes
import SecurityProtocolsCore
import UmbraCoreTypes
import XPCProtocolsCore

/// Manages secure storage and retrieval of credentials
public actor CredentialManager {
  private let keychain: any SecureStorageProtocol
  private let config: CryptoConfig

  public init(service: String, config: CryptoConfig) {
    keychain=KeychainAccess(service: service)
    self.config=config
  }

  /// Save a credential securely
  /// - Parameters:
  ///   - identifier: Identifier for the credential
  ///   - data: Data to store
  public func save(_ data: Data, forIdentifier identifier: String) async throws {
    let secureBytes=SecureBytes(bytes: [UInt8](data))
    let result=await keychain.storeSecurely(data: secureBytes, identifier: identifier)

    switch result {
      case .success:
        return
      case let .failure(error):
        throw mapKeyStorageError(error)
      @unknown default:
        throw UmbraErrors.Security.Core.secureStorageFailed(
          operation: "save",
          reason: "Unknown result state"
        )
    }
  }

  /// Retrieve a credential
  /// - Parameter identifier: Identifier for the credential
  /// - Returns: Stored data
  public func retrieve(forIdentifier identifier: String) async throws -> Data {
    let result=await keychain.retrieveSecurely(identifier: identifier)

    switch result {
      case let .success(secureBytes):
        // Convert SecureBytes to Data using Array initializer
        return Data(Array(secureBytes))
      case let .failure(error):
        throw mapKeyStorageError(error)
      @unknown default:
        throw UmbraErrors.Security.Core.secureStorageFailed(
          operation: "retrieve",
          reason: "Unknown result state"
        )
    }
  }

  /// Delete a credential
  /// - Parameter identifier: Identifier for the credential
  public func delete(forIdentifier identifier: String) async throws {
    let result=await keychain.deleteSecurely(identifier: identifier)

    switch result {
      case .success:
        return
      case let .failure(error):
        throw mapKeyStorageError(error)
      @unknown default:
        throw UmbraErrors.Security.Core.secureStorageFailed(
          operation: "delete",
          reason: "Unknown result state"
        )
    }
  }

  /// Maps KeyStorageError to UmbraErrors.Security.Core
  private func mapKeyStorageError(_ error: KeyStorageError) -> Error {
    switch error {
      case .keyNotFound:
        return UmbraErrors.Security.Core.secureStorageFailed(
          operation: "retrieval",
          reason: "Key not found"
        )
      case .storageFailure:
        return UmbraErrors.Security.Core.secureStorageFailed(
          operation: "storage",
          reason: "Storage operation failed"
        )
      case .unknown:
        return UmbraErrors.Security.Core.secureStorageFailed(
          operation: "unknown",
          reason: "Unknown error occurred"
        )
      @unknown default:
        return UmbraErrors.Security.Core.secureStorageFailed(
          operation: "unknown",
          reason: "Unhandled error type: \(error)"
        )
    }
  }

  /// Maps ErrorHandlingDomains.UmbraErrors.Security.Protocols to UmbraErrors.Security.Core
  private func mapXPCError(_ error: ErrorHandlingDomains.UmbraErrors.Security.Protocols) -> Error {
    switch error {
      case let .serviceError(message):
        return UmbraErrors.Security.Core.internalError(reason: "Service error: \(message)")

      case let .invalidInput(message):
        return UmbraErrors.Security.Core.internalError(reason: "Invalid input: \(message)")

      case let .encryptionFailed(message):
        return UmbraErrors.Security.Core.secureStorageFailed(
          operation: "encryption",
          reason: message
        )

      case let .decryptionFailed(message):
        return UmbraErrors.Security.Core.secureStorageFailed(
          operation: "decryption",
          reason: message
        )

      case let .invalidFormat(reason):
        return UmbraErrors.Security.Core.internalError(reason: "Invalid format: \(reason)")

      case let .invalidState(state, expectedState):
        return UmbraErrors.Security.Core
          .internalError(reason: "Invalid state: \(state), expected: \(expectedState)")

      case let .internalError(message):
        return UmbraErrors.Security.Core.internalError(reason: message)

      case let .missingProtocolImplementation(protocolName):
        return UmbraErrors.Security.Core.internalError(reason: "Missing protocol: \(protocolName)")

      case let .unsupportedOperation(name):
        return UmbraErrors.Security.Core.internalError(reason: "Unsupported operation: \(name)")

      case let .incompatibleVersion(version):
        return UmbraErrors.Security.Core.internalError(reason: "Incompatible version: \(version)")

      case let .storageOperationFailed(message):
        return UmbraErrors.Security.Core
          .internalError(reason: "Storage operation failed: \(message)")

      case let .randomGenerationFailed(message):
        return UmbraErrors.Security.Core
          .internalError(reason: "Random generation failed: \(message)")

      case let .notImplemented(message):
        return UmbraErrors.Security.Core.internalError(reason: "Not implemented: \(message)")

      @unknown default:
        return UmbraErrors.Security.Core.internalError(reason: "Unknown error")
    }
  }
}

/// Access to the system keychain
private actor KeychainAccess: SecureStorageProtocol {
  private let service: String
  private var items: [String: (data: SecureBytes, metadata: [String: String]?)]=[:]

  init(service: String) {
    self.service=service
  }

  func storeSecurely(data: SecureBytes, identifier: String) async -> KeyStorageResult {
    items[identifier]=(data: data, metadata: nil)
    return .success
  }

  func retrieveSecurely(identifier: String) async -> KeyRetrievalResult {
    guard let item=items[identifier] else {
      return .failure(.keyNotFound)
    }
    return .success(item.data)
  }

  func deleteSecurely(identifier: String) async -> KeyDeletionResult {
    guard items.removeValue(forKey: identifier) != nil else {
      return .failure(.keyNotFound)
    }
    return .success
  }
}
