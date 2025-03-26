import Foundation

/// Forward declarations of XPC protocols to break circular dependencies
/// This file contains minimal protocol declarations needed by CryptoTypes
/// without requiring a direct dependency on XPCProtocolsCore

/// Protocol for XPC service operations
public protocol XPCServiceProtocolComplete {
  /// Process data securely
  /// - Parameters:
  ///   - data: Data to process
  ///   - operation: Type of operation to perform
  ///   - parameters: Additional parameters for the operation
  /// - Returns: Result of the operation
  func processSecurely(data: Data, operation: String, parameters: [String: Any]?) async throws
    -> Data

  /// Check service status
  /// - Returns: True if service is available
  func isServiceAvailable() async -> Bool
}

/// Protocol for secure storage operations typically defined in XPCProtocolsCore
/// This is a minimalist version of the protocol needed by CryptoTypes
public protocol SecureStorageProtocol {
  /// Store data securely
  /// - Parameters:
  ///   - data: Data to store
  ///   - identifier: Identifier for the data
  /// - Returns: Result of the operation
  func storeSecurely(data: any Sendable, identifier: String) async -> Result<Void, Error>

  /// Retrieve data securely
  /// - Parameter identifier: Identifier for the data
  /// - Returns: Result containing the retrieved data or an error
  func retrieveSecurely(identifier: String) async -> Result<any Sendable, Error>

  /// Delete data securely
  /// - Parameter identifier: Identifier for the data
  /// - Returns: Result of the operation
  func deleteSecurely(identifier: String) async -> Result<Void, Error>
}
