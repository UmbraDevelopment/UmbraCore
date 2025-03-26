import Errors
import Types
import UmbraCoreTypes

/// Top-level protocol defining a complete security provider in a FoundationIndependent manner.
/// This protocol consolidates cryptographic operations, key management, and security configuration
/// into a cohesive interface for secure operations.
public protocol SecurityProviderProtocol: Sendable {
  // MARK: - Service Access

  /// Access to cryptographic service implementation
  var cryptoService: CryptoServiceProtocol { get }

  /// Access to key management service implementation
  var keyManager: KeyManagementProtocol { get }

  // MARK: - Convenience Methods

  /// Perform a secure operation with appropriate error handling
  /// - Parameters:
  ///   - operation: The security operation to perform
  ///   - config: Configuration options
  /// - Returns: Result of the operation
  func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Create a secure configuration with appropriate defaults
  /// - Parameter options: Optional dictionary of configuration options
  /// - Returns: A properly configured SecurityConfigDTO
  func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO
}
