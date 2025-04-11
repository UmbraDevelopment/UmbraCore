import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces

/**
 Factory for creating security operation command objects.
 
 This factory creates appropriate command objects for different security
 operations, enabling a more modular and testable architecture while
 maintaining the same functionality.
 */
public struct SecurityCommandFactory {
    /// The crypto service for operations
    private let cryptoService: CryptoServiceProtocol
    
    /// Logger for operation auditing and tracking
    private let logger: LoggingProtocol
    
    /**
     Initialises a new security command factory.
     
     - Parameters:
        - cryptoService: The service for cryptographic operations
        - logger: Logger for operation tracking and auditing
     */
    public init(cryptoService: CryptoServiceProtocol, logger: LoggingProtocol) {
        self.cryptoService = cryptoService
        self.logger = logger
    }
    
    /**
     Creates the appropriate command for a security operation.
     
     - Parameters:
        - operation: The security operation to execute
        - config: Configuration for the operation
     - Returns: A command object that can execute the requested operation
     - Throws: SecurityError if the operation is not supported
     */
    public func createCommand(
        for operation: SecurityOperation,
        config: SecurityConfigDTO
    ) throws -> SecurityOperationCommand {
        switch operation {
        case .encrypt:
            return EncryptCommand(
                config: config,
                cryptoService: cryptoService,
                logger: logger
            )
            
        case .decrypt:
            return DecryptCommand(
                config: config,
                cryptoService: cryptoService,
                logger: logger
            )
            
        case .hash:
            return HashCommand(
                config: config,
                cryptoService: cryptoService,
                logger: logger
            )
            
        case .verifyHash:
            return VerifyHashCommand(
                config: config,
                cryptoService: cryptoService,
                logger: logger
            )
            
        case .generateKey:
            return GenerateKeyCommand(
                config: config,
                cryptoService: cryptoService,
                logger: logger
            )
            
        case .deriveKey:
            return DeriveKeyCommand(
                config: config,
                cryptoService: cryptoService,
                logger: logger
            )
            
        default:
            throw CoreSecurityTypes.SecurityError.unsupportedOperation(
                reason: "No command available for operation: \(operation.rawValue)"
            )
        }
    }
}
