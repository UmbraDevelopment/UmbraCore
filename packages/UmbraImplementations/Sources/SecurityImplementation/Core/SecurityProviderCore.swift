import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Core implementation of the security provider using a modular command-based architecture.
 
 This actor is responsible for facilitating security operations through a command pattern,
 providing enhanced maintainability, testability, and adherence to the Alpha Dot Five
 architecture principles.
 */
public actor SecurityProviderCore: SecurityProviderProtocol {
    // MARK: - Dependencies
    
    /// Operation handler for standardised execution patterns
    private let operationHandler: SecurityOperationHandler
    
    /// Factory for creating operation-specific commands
    private let commandFactory: SecurityCommandFactory
    
    /// Logger for operation tracking and auditing
    private let logger: LoggingProtocol
    
    /// The security provider type
    private let providerType: SecurityProviderType
    
    // MARK: - Initialisation
    
    /**
     Initialises a new security provider core.
     
     - Parameters:
        - cryptoService: Service for cryptographic operations
        - logger: Logger for operation tracking and auditing
        - providerType: The type of security provider
     */
    public init(
        cryptoService: CryptoServiceProtocol,
        logger: LoggingProtocol,
        providerType: SecurityProviderType = .basic
    ) {
        self.logger = logger
        self.providerType = providerType
        self.operationHandler = SecurityOperationHandler(logger: logger)
        self.commandFactory = SecurityCommandFactory(
            cryptoService: cryptoService,
            logger: logger
        )
    }
    
    // MARK: - Security Operations
    
    /**
     Performs a generic security operation.
     
     - Parameters:
        - operation: The security operation to perform
        - config: Configuration for the operation
     - Returns: The result of the security operation
     - Throws: SecurityError if the operation fails
     */
    public func performSecureOperation(
        operation: SecurityOperation,
        config: SecurityConfigDTO
    ) async throws -> SecurityResultDTO {
        return try await operationHandler.executeOperation(
            operation: operation.rawValue,
            component: "SecurityProvider"
        ) { context, operationID in
            // Create and execute the appropriate command
            let command = try commandFactory.createCommand(for: operation, config: config)
            return try await command.execute(context: context, operationID: operationID)
        }.result
    }
    
    /**
     Encrypts data according to the specified configuration.
     
     - Parameter config: Configuration for the encryption operation
     - Returns: The result containing the encrypted data
     - Throws: SecurityError if encryption fails
     */
    public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        return try await performSecureOperation(
            operation: .encrypt,
            config: config
        )
    }
    
    /**
     Decrypts data according to the specified configuration.
     
     - Parameter config: Configuration for the decryption operation
     - Returns: The result containing the decrypted data
     - Throws: SecurityError if decryption fails
     */
    public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        return try await performSecureOperation(
            operation: .decrypt,
            config: config
        )
    }
    
    /**
     Hashes data according to the specified configuration.
     
     - Parameter config: Configuration for the hashing operation
     - Returns: The result containing the hash data
     - Throws: SecurityError if hashing fails
     */
    public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        return try await performSecureOperation(
            operation: .hash,
            config: config
        )
    }
    
    /**
     Verifies a hash according to the specified configuration.
     
     - Parameter config: Configuration for the hash verification operation
     - Returns: The result containing the verification status
     - Throws: SecurityError if verification fails
     */
    public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        return try await performSecureOperation(
            operation: .verifyHash,
            config: config
        )
    }
    
    /**
     Generates a cryptographic key according to the specified configuration.
     
     - Parameter config: Configuration for the key generation operation
     - Returns: The result containing the generated key identifier
     - Throws: SecurityError if key generation fails
     */
    public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        return try await performSecureOperation(
            operation: .generateKey,
            config: config
        )
    }
    
    /**
     Derives a cryptographic key according to the specified configuration.
     
     - Parameter config: Configuration for the key derivation operation
     - Returns: The result containing the derived key identifier
     - Throws: SecurityError if key derivation fails
     */
    public func deriveKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        return try await performSecureOperation(
            operation: .deriveKey,
            config: config
        )
    }
    
    /**
     Creates a security configuration with default settings.
     
     - Parameter options: Optional configuration options
     - Returns: A standardised security configuration
     */
    public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
        // Create a configuration with sensible defaults and the current provider type
        return SecurityConfigDTO(
            encryptionAlgorithm: .aes256CBC,
            hashAlgorithm: .sha256,
            providerType: providerType,
            options: options
        )
    }
}
