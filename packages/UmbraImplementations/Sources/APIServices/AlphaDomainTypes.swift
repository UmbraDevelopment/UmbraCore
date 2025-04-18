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
  case security

  /// Repository management operations
  case repository

  /// Backup and snapshot operations
  case backup

  /// System-related operations
  case system

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
   The domain identifier this handler supports
   */
  var domain: String { get }

  /**
   Handles a domain-specific operation

   - Parameter operation: The operation to handle
   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  associatedtype OperationType: APIOperation
  func handleOperation<T: OperationType>(operation: T) async throws -> T.APIOperationResult
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
