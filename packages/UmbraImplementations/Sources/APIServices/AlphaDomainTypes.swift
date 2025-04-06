import APIInterfaces
import Foundation

/**
 # Alpha Domain Types

 Common types and protocols for the Alpha Dot Five architecture API implementation.
 This file defines shared types used across domain handlers and API services.

 ## Domain Handler Protocol

 The `DomainHandler` protocol defines the contract that all domain-specific handlers
 must implement to participate in the API service's operation routing system.

 ## API Domains

 The `APIDomain` enumeration defines all available API domains in the system,
 allowing for proper routing of operations to their appropriate handlers.
 */

/// Defines domains for API operations
public enum APIDomain: String, Codable, Sendable, Hashable, CaseIterable {
  /// Security-related operations (encryption, key management)
  case security = "security"

  /// Repository management operations
  case repository = "repository"

  /// Backup and snapshot operations
  case backup = "backup"

  /// System-related operations
  case system = "system"

  /// Notification-related operations
  case notification

  /// Scheduling operations
  case schedule

  /// Network and connectivity operations
  case network

  /// User preferences and settings operations
  case user
}

/// Protocol that all domain-specific operation handlers must implement
public protocol DomainHandler {
  /**
   Executes the specified operation within this domain.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation, which will be cast to the appropriate type by the caller
   - Throws: APIError if the operation fails
   */
  func execute<T: APIOperation>(_ operation: T) async throws -> Any

  /**
   Checks if this handler supports the specified operation.

   - Parameter operation: The operation to check
   - Returns: True if the operation is supported, false otherwise
   */
  func supports(_ operation: some APIOperation) -> Bool
}

/// Protocol marker for backup-related API operations
public protocol BackupAPIOperation: APIOperation {}

// MARK: - Operation Types

/// Security operation types
public enum SecurityOperationType: String, Sendable, Codable, CaseIterable {
  /// Data encryption
  case encrypt

  /// Data decryption
  case decrypt

  /// Key generation
  case generateKey

  /// Key retrieval
  case retrieveKey

  /// Key storage
  case storeKey

  /// Key deletion
  case deleteKey

  /// Data hashing
  case hashData

  /// Secret storage
  case storeSecret
  
  /// Secret retrieval
  case retrieveSecret
  
  /// Secret deletion
  case deleteSecret
}
