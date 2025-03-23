/**
 # UmbraCore Security Provider Core

 This file implements the core functionality of the security provider, serving as the central
 component that coordinates between the cryptographic services and key management systems.

 ## Responsibilities

 * Route security operations to the appropriate specialised handlers
 * Coordinate between cryptographic and key management services
 * Provide configuration building and validation
 * Handle errors and ensure consistent error reporting

 ## Design Pattern

 This class follows the Facade design pattern, providing a simpler interface to the complex
 security subsystem by coordinating between different components:

 * ConfigBuilder: Creates and validates security configurations
 * OperationsHandler: Routes operations to the appropriate service
 * CryptoService: Handles cryptographic operations
 * KeyManager: Handles key management operations

 ## Security Considerations

 * Centralised security validation ensures consistent security policies
 * Error handling preserves security context without leaking sensitive information
 * Operations are routed based on explicit operation types rather than complex logic
 */

import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// SecurityProviderCore is the central implementation of security provider functionality,
/// coordinating between cryptographic services and key management to handle
/// security operations.
final class SecurityProviderCore: @unchecked Sendable {
  // MARK: - Properties

  /// The crypto service for cryptographic operations
  private let cryptoService: CryptoServiceProtocol

  /// The key manager for key operations
  private let keyManager: KeyManagementProtocol

  /// The operations handler for routing security operations
  private let operationsHandler: OperationsHandler

  /// The configuration builder for creating and validating configurations
  private let configBuilder: ConfigBuilder

  // MARK: - Initialisation

  /// Creates a new SecurityProviderCore with the specified services
  /// - Parameters:
  ///   - cryptoService: The crypto service to use
  ///   - keyManager: The key manager to use
  init(cryptoService: CryptoServiceProtocol, keyManager: KeyManagementProtocol) {
    self.cryptoService=cryptoService
    self.keyManager=keyManager
    configBuilder=ConfigBuilder()
    operationsHandler=OperationsHandler(
      cryptoService: cryptoService,
      keyManager: keyManager
    )
  }

  // MARK: - Core Provider Operations

  /// Perform a secure operation with appropriate error handling
  /// - Parameters:
  ///   - operation: The security operation to perform
  ///   - config: Configuration options
  /// - Returns: Result of the operation
  func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Use the operations handler to route the operation
    await operationsHandler.handleOperation(operation: operation, config: config)
  }

  /// Create a secure configuration with appropriate defaults
  /// - Parameter options: Optional dictionary of configuration options
  /// - Returns: A properly configured SecurityConfigDTO
  func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO {
    configBuilder.createConfig(options: options)
  }
}
