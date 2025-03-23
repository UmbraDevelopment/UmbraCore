import CoreErrors
import Foundation
import UmbraCoreTypes
import UmbraLogging
import XPCProtocolsCore

/// Protocol for keychain operations using DTOs
public protocol KeychainXPCServiceProtocol: Sendable {
  /// Store data in the keychain
  /// - Parameter request: Store request
  /// - Returns: Result of the operation
  func storeData(_ request: KeychainXPCDTO.StoreRequest) async -> KeychainXPCDTO.OperationResult

  /// Retrieve data from the keychain
  /// - Parameter request: Retrieve request
  /// - Returns: Result of the operation with data
  func retrieveData(_ request: KeychainXPCDTO.RetrieveRequest) async -> KeychainXPCDTO
    .OperationResult

  /// Delete data from the keychain
  /// - Parameter request: Delete request
  /// - Returns: Result of the operation
  func deleteData(_ request: KeychainXPCDTO.DeleteRequest) async -> KeychainXPCDTO.OperationResult

  /// Generate random data of the specified length
  /// - Parameter length: Length of the data to generate
  /// - Returns: Result of the operation with data
  func generateRandomData(length: Int) async -> KeychainXPCDTO.OperationResult
}

/// Legacy XPC protocol for Keychain operations
/// This is used for compatibility with existing code
@objc
public protocol KeychainXPCProtocol: Sendable {
  /// Add an item to the keychain
  /// - Parameters:
  ///   - account: Account name
  ///   - service: Service identifier
  ///   - accessGroup: Access group (optional)
  ///   - data: Data to store
  ///   - reply: Result handler
  @objc
  func addItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data,
    reply: @escaping @Sendable (Error?) -> Void
  )

  /// Update an item in the keychain
  /// - Parameters:
  ///   - account: Account name
  ///   - service: Service identifier
  ///   - accessGroup: Access group (optional)
  ///   - data: Data to store
  ///   - reply: Result handler
  @objc
  func updateItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data,
    reply: @escaping @Sendable (Error?) -> Void
  )

  /// Get an item from the keychain
  /// - Parameters:
  ///   - account: Account name
  ///   - service: Service identifier
  ///   - accessGroup: Access group (optional)
  ///   - reply: Result handler with data
  @objc
  func getItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Data?, Error?) -> Void
  )

  /// Delete an item from the keychain
  /// - Parameters:
  ///   - account: Account name
  ///   - service: Service identifier
  ///   - accessGroup: Access group (optional)
  ///   - reply: Result handler
  @objc
  func deleteItem(
    account: String,
    service: String,
    accessGroup: String?,
    reply: @escaping @Sendable (Error?) -> Void
  )
}

extension KeychainXPCProtocol {
  func addItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      addItem(
        account: account,
        service: service,
        accessGroup: accessGroup,
        data: data
      ) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }

  func updateItem(
    account: String,
    service: String,
    accessGroup: String?,
    data: Data
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      updateItem(
        account: account,
        service: service,
        accessGroup: accessGroup,
        data: data
      ) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }

  func removeItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      deleteItem(
        account: account,
        service: service,
        accessGroup: accessGroup
      ) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }

  func containsItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws -> Bool {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
      getItem(
        account: account,
        service: service,
        accessGroup: accessGroup
      ) { data, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let _=data {
          continuation.resume(returning: true)
        } else {
          continuation.resume(returning: false)
        }
      }
    }
  }

  func retrieveItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws -> Data {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
      getItem(
        account: account,
        service: service,
        accessGroup: accessGroup
      ) { data, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let data {
          continuation.resume(returning: data)
        } else {
          continuation.resume(throwing: KeychainXPCError.itemNotFound)
        }
      }
    }
  }
}

extension KeychainXPCProtocol {
  func synchroniseKeys(_: Data) async throws {
    // This is a placeholder implementation - in a real implementation, we would
    // use the actual keychain to perform key synchronization
  }
}

/// An error that can occur during keychain operations
public enum KeychainXPCError: Error, LocalizedError, Sendable {
  case duplicateItem
  case itemNotFound
  case authenticationFailed
  case serviceUnavailable
  case unhandledError(status: OSStatus)
  case other(String)

  public var errorDescription: String? {
    switch self {
      case .duplicateItem:
        "A duplicate item was found"
      case .itemNotFound:
        "The item could not be found"
      case .authenticationFailed:
        "Authentication failed"
      case .serviceUnavailable:
        "The keychain service is unavailable"
      case let .unhandledError(status):
        "Unhandled error with status: \(status)"
      case let .other(message):
        message
    }
  }
}
