import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command that executes decryption operations.
 
 This command encapsulates the decryption logic in accordance with
 the command pattern, providing clean separation of concerns.
 */
public class DecryptCommand: BaseSecurityCommand, SecurityOperationCommand {
    /// The crypto service for performing the decryption
    private let cryptoService: CryptoServiceProtocol
    
    /**
     Initialises a new decrypt command.
     
     - Parameters:
        - config: Security configuration for the decryption
        - cryptoService: The service to perform the decryption
        - logger: Logger for operation tracking and auditing
     */
    public init(config: SecurityConfigDTO, cryptoService: CryptoServiceProtocol, logger: LoggingProtocol) {
        self.cryptoService = cryptoService
        super.init(config: config, logger: logger)
    }
    
    /**
     Executes the decryption operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The decryption result
     - Throws: SecurityError if decryption fails
     */
    public func execute(context: LogContextDTO, operationID: String) async throws -> SecurityResultDTO {
        await logDebug("Preparing to decrypt data", context: context)
        
        // Extract required data from configuration
        let extractor = metadataExtractor()
        
        do {
            // Extract encrypted data
            let encryptedData = try extractor.requiredData(
                forKey: "inputData",
                errorMessage: "Encrypted data is required for decryption"
            )
            
            // Extract key identifier
            let keyIdentifier = try extractor.requiredIdentifier(
                forKey: "keyIdentifier",
                errorMessage: "Key identifier is required for decryption"
            )
            
            // Log decryption details
            let enhancedContext = context.adding(
                key: "dataSize",
                value: "\(encryptedData.count) bytes",
                privacyLevel: .public
            ).adding(
                key: "algorithm",
                value: config.encryptionAlgorithm.rawValue,
                privacyLevel: .public
            )
            
            await logDebug("Decrypting data using \(config.encryptionAlgorithm.rawValue)", context: enhancedContext)
            
            // Perform the decryption
            let result = try await cryptoService.decrypt(
                data: [UInt8](encryptedData),
                keyIdentifier: keyIdentifier,
                algorithm: config.encryptionAlgorithm
            )
            
            // Process the result
            switch result {
            case .success(let decryptedBytes):
                // Convert result to Data
                let decryptedData = Data(decryptedBytes)
                
                // Record successful decryption
                await logInfo(
                    "Successfully decrypted \(encryptedData.count) bytes of data",
                    context: enhancedContext.adding(
                        key: "resultSize",
                        value: "\(decryptedData.count) bytes",
                        privacyLevel: .public
                    )
                )
                
                // Create result metadata
                let resultMetadata: [String: String] = [
                    "encryptedSize": "\(encryptedData.count)",
                    "decryptedSize": "\(decryptedData.count)",
                    "algorithm": config.encryptionAlgorithm.rawValue,
                    "operationID": operationID
                ]
                
                // Return successful result
                return createSuccessResult(
                    data: decryptedData,
                    duration: 0, // Duration will be calculated by the operation handler
                    metadata: resultMetadata
                )
                
            case .failure(let error):
                throw error
            }
        } catch let securityError as SecurityStorageError {
            // Log specific decryption errors
            await logError(
                "Decryption failed due to storage error: \(securityError)",
                context: context
            )
            throw securityError
        } catch {
            // Log unexpected errors
            await logError(
                "Decryption failed with unexpected error: \(error.localizedDescription)",
                context: context
            )
            throw CoreSecurityTypes.SecurityError.decryptionFailed(
                reason: "Decryption operation failed: \(error.localizedDescription)"
            )
        }
    }
}
