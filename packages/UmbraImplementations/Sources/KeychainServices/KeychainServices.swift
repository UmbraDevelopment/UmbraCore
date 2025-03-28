/// # KeychainServices Module
///
/// Provides concrete implementations of the keychain system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module contains:
/// - Default keychain service implementation
/// - In-memory implementation for testing
/// - Factory for service creation
///
/// Following Alpha Dot Five principles, this module:
/// - Contains only implementation code
/// - Implements interfaces defined in KeychainInterfaces
/// - Uses types defined in KeychainTypes
/// - Uses actor-based concurrency for thread safety
/// - Follows the Swift Concurrency model
///
/// ## Main Components
///
/// ```swift
/// KeychainServiceImpl
/// InMemoryKeychainServiceImpl
/// KeychainServiceFactory
/// ```
///
/// ## Factory Usage
///
/// ```swift
/// // Create with default settings
/// let keychainService = await KeychainServices.createService()
///
/// // Create with custom service ID
/// let customService = await KeychainServices.createService(
///     serviceIdentifier: "com.example.custom"
/// )
///
/// // Create in-memory implementation for testing
/// let testService = await KeychainServices.createInMemoryService()
/// ```
///
/// ## Thread Safety
///
/// All implementations use Swift actors to ensure thread safety and proper
/// isolation of state.

import Foundation
import KeychainInterfaces
import LoggingInterfaces

/// Convenience access to KeychainServiceFactory
public enum KeychainServices {
  /**
   Creates a KeychainServiceProtocol implementation with default configuration.

   - Parameters:
      - serviceIdentifier: Optional custom service identifier
      - logger: Optional custom logger

   - Returns: A configured KeychainServiceProtocol instance
   */
  public static func createService(
    serviceIdentifier: String=KeychainServiceFactory.defaultServiceIdentifier,
    logger: LoggingProtocol?=nil
  ) async -> KeychainServiceProtocol {
    await KeychainServiceFactory.createService(
      serviceIdentifier: serviceIdentifier,
      logger: logger
    )
  }

  /**
   Creates an in-memory KeychainServiceProtocol implementation for testing.

   - Parameters:
      - serviceIdentifier: Optional custom service identifier
      - logger: Optional custom logger

   - Returns: A configured in-memory KeychainServiceProtocol instance
   */
  public static func createInMemoryService(
    serviceIdentifier: String=KeychainServiceFactory.defaultServiceIdentifier,
    logger: LoggingProtocol?=nil
  ) async -> KeychainServiceProtocol {
    await KeychainServiceFactory.createInMemoryService(
      serviceIdentifier: serviceIdentifier,
      logger: logger
    )
  }
}
