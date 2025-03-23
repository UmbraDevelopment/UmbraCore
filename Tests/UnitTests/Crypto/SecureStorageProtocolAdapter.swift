import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import UmbraMocks

/// Adapter to bridge between the UmbraMocks.SecureStorageProtocol and the method names
/// expected by the CryptoTests. This helps with the consolidation of different protocol
/// implementations across the codebase.
public final class SecureStorageProtocolAdapter: @unchecked Sendable {
  private let storage: UmbraMocks.SecureStorageProtocol

  public init(storage: UmbraMocks.SecureStorageProtocol) {
    self.storage=storage
  }

  /// Store data securely
  /// - Parameters:
  ///   - data: The data to store
  ///   - identifier: The identifier to store it under
  ///   - metadata: Optional metadata to store with the data
  /// - Returns: Result of the storage operation
  public func storeData(
    _ data: UmbraCoreTypes.SecureBytes,
    identifier: String,
    metadata _: [String: String]
  ) async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=await storage.storeSecurely(data: data, identifier: identifier)

    switch result {
      case .success:
        return .success(())
      case let .failure(error):
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(
              message: "Failed to store data: \(error)"
            )
        )
      @unknown default:
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(
              message: "Unknown error storing data"
            )
        )
    }
  }

  /// Retrieve data securely
  /// - Parameter identifier: The identifier to retrieve
  /// - Returns: Result of the retrieval operation
  public func retrieveData(
    identifier: String
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=await storage.retrieveSecurely(identifier: identifier)

    switch result {
      case let .success(data):
        return .success(data)
      case let .failure(error):
        if case .keyNotFound=error {
          // Create a special error message that can be detected and mapped back to
          // CryptoError.keyNotFound
          return .failure(
            ErrorHandlingDomains.UmbraErrors.Security.Protocols
              .makeStorageOperationFailed(
                message: "Failed to retrieve data: keyNotFound"
              )
          )
        }
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(
              message: "Failed to retrieve data: \(error)"
            )
        )
      @unknown default:
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(
              message: "Unknown error retrieving data"
            )
        )
    }
  }

  /// Delete data securely
  /// - Parameter identifier: The identifier to delete
  /// - Returns: Result of the deletion operation
  public func deleteData(
    identifier: String
  ) async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let result=await storage.deleteSecurely(identifier: identifier)

    switch result {
      case .success:
        return .success(())
      case let .failure(error):
        if case .keyNotFound=error {
          // Create a special error message that can be detected and mapped back to
          // CryptoError.keyNotFound
          return .failure(
            ErrorHandlingDomains.UmbraErrors.Security.Protocols
              .makeStorageOperationFailed(
                message: "Failed to delete data: keyNotFound"
              )
          )
        }
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(
              message: "Failed to delete data: \(error)"
            )
        )
      @unknown default:
        return .failure(
          ErrorHandlingDomains.UmbraErrors.Security.Protocols
            .makeStorageOperationFailed(
              message: "Unknown error deleting data"
            )
        )
    }
  }

  /// Reset the storage
  public func reset() async {
    if let mockKeychain=storage as? MockKeychain {
      await mockKeychain.reset()
    }
  }
}
