import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityInterfaces

/**
 # SecurityServiceAdapter Protocol
 
 Defines an adapter interface for interacting with various security services.
 This allows the BasicSecurityProvider to interact with underlying security implementations
 without creating direct dependencies, enabling more flexible composition.
 
 Each service adapter handles a specific set of cryptographic operations and can be
 individually implemented, tested, and mocked.
 */
public protocol SecurityServiceAdapter: Sendable {
    /**
     Initializes the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol)
    
    /**
     Creates a log context with properly classified metadata.
     
     - Parameters:
        - metadata: Dictionary of metadata with privacy levels
        - domain: Domain for the log context
        - source: Source identifier for the log context
     - Returns: A log context with properly classified metadata
     */
    func createLogContext(
        _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
        domain: String,
        source: String
    ) -> BaseLogContextDTO
}

/**
 # EncryptionServiceAdapter Protocol
 
 Adapter interface for encryption and decryption operations.
 */
public protocol EncryptionServiceAdapter: SecurityServiceAdapter {
    /**
     Encrypts data using the specified configuration.
     
     - Parameter config: Security configuration with encryption parameters
     - Returns: Result containing encrypted data and metadata
     - Throws: If encryption fails
     */
    func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO
    
    /**
     Decrypts data using the specified configuration.
     
     - Parameter config: Security configuration with decryption parameters
     - Returns: Result containing decrypted data and metadata
     - Throws: If decryption fails
     */
    func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO
}

/**
 # HashingServiceAdapter Protocol
 
 Adapter interface for hashing operations.
 */
public protocol HashingServiceAdapter: SecurityServiceAdapter {
    /**
     Performs a hash operation on the provided data.
     
     - Parameter config: Security configuration with hashing parameters
     - Returns: Result containing the hash and metadata
     - Throws: If hashing fails
     */
    func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO
    
    /**
     Verifies a hash against the original data.
     
     - Parameter config: Security configuration with verification parameters
     - Returns: Result indicating whether the hash is valid
     - Throws: If verification fails
     */
    func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO
}

/**
 # KeyGenerationServiceAdapter Protocol
 
 Adapter interface for key generation operations.
 */
public protocol KeyGenerationServiceAdapter: SecurityServiceAdapter {
    /**
     Generates a cryptographic key with the specified parameters.
     
     - Parameter config: Security configuration with key generation parameters
     - Returns: Result containing the generated key
     - Throws: If key generation fails
     */
    func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO
}

/**
 # ConfigurationServiceAdapter Protocol
 
 Adapter interface for security configuration operations.
 */
public protocol ConfigurationServiceAdapter: SecurityServiceAdapter {
    /**
     Creates a security configuration with the specified options.
     
     - Parameter options: Security configuration options
     - Returns: A configured SecurityConfigDTO
     */
    func createSecureConfig(options: SecurityConfigOptions) -> SecurityConfigDTO
}

/**
 Base adapter class that provides common functionality for security service adapters.
 */
internal class BaseSecurityServiceAdapter {
  /// Logger for operation tracking and auditing
  let logger: LoggingProtocol
  
  /**
   Initializes the adapter with a logger.
   
   - Parameter logger: Logger instance for operation auditing
   */
  init(logger: LoggingProtocol) {
    self.logger = logger
  }
  
  /**
   Creates a log context with privacy metadata.
   
   - Parameter metadata: Dictionary of key-value pairs with privacy levels
   - Parameter domain: Optional domain for the log context
   - Parameter source: Source component identifier
   - Returns: A LogContextDTO object for logging
   */
  func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)] = [:],
    domain: String = "security",
    source: String
  ) -> BaseLogContextDTO {
    var contextMetadata: [String: LogMetadataEntry] = [:]
    
    for (key, value) in metadata {
      contextMetadata[key] = LogMetadataEntry(
        value: value.value,
        privacyLevel: value.privacy
      )
    }
    
    return BaseLogContextDTO(
      domain: domain,
      source: source,
      metadata: contextMetadata
    )
  }
}
