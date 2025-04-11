import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command that executes key generation operations.
 
 This command encapsulates the cryptographic key generation logic in accordance
 with the command pattern, providing clean separation of concerns.
 */
public class GenerateKeyCommand: BaseSecurityCommand, SecurityOperationCommand {
    /// The crypto service for performing the key generation
    private let cryptoService: CryptoServiceProtocol
    
    /**
     Initialises a new key generation command.
     
     - Parameters:
        - config: Security configuration for the key generation
        - cryptoService: The service to perform the key generation
        - logger: Logger for operation tracking and auditing
     */
    public init(config: SecurityConfigDTO, cryptoService: CryptoServiceProtocol, logger: LoggingProtocol) {
        self.cryptoService = cryptoService
        super.init(config: config, logger: logger)
    }
    
    /**
     Executes the key generation operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The key generation result
     - Throws: SecurityError if key generation fails
     */
    public func execute(context: LogContextDTO, operationID: String) async throws -> SecurityResultDTO {
        await logDebug("Preparing to generate cryptographic key", context: context)
        
        // Extract required data from configuration
        let extractor = metadataExtractor()
        
        do {
            // Extract key identifier (can be nil for new key generation)
            let keyIdentifier = extractor.optionalString(forKey: "keyIdentifier")
            
            // Extract key type
            let keyTypeString = try extractor.requiredString(
                forKey: "keyType",
                errorMessage: "Key type is required for key generation"
            )
            
            guard let keyType = KeyType(rawValue: keyTypeString) else {
                throw CoreSecurityTypes.SecurityError.invalidInput(
                    reason: "Invalid key type: \(keyTypeString)"
                )
            }
            
            // Extract key size if provided
            let keySizeString = extractor.optionalString(forKey: "keySize")
            let keySize = keySizeString != nil ? Int(keySizeString!) : nil
            
            // Prepare enhanced context for logging
            let enhancedContext = context.adding(
                key: "keyType",
                value: keyType.rawValue,
                privacyLevel: .public
            )
            
            if let keySize = keySize {
                await logDebug(
                    "Generating \(keyType.rawValue) key with size \(keySize)",
                    context: enhancedContext.adding(
                        key: "keySize",
                        value: "\(keySize)",
                        privacyLevel: .public
                    )
                )
            } else {
                await logDebug(
                    "Generating \(keyType.rawValue) key with default size",
                    context: enhancedContext
                )
            }
            
            // Perform the key generation
            let result = try await cryptoService.generateKey(
                type: keyType,
                size: keySize,
                identifier: keyIdentifier
            )
            
            // Process the result
            switch result {
            case .success(let generatedKey):
                // Record successful key generation
                let resultContext = enhancedContext.adding(
                    key: "keyIdentifier",
                    value: generatedKey.identifier,
                    privacyLevel: .private
                )
                
                await logInfo(
                    "Successfully generated \(keyType.rawValue) key",
                    context: resultContext
                )
                
                // Create result metadata
                let resultMetadata: [String: String] = [
                    "keyType": keyType.rawValue,
                    "keyIdentifier": generatedKey.identifier,
                    "operationID": operationID
                ]
                
                if let keySize = keySize {
                    let updatedMetadata = resultMetadata.merging(
                        ["keySize": "\(keySize)"],
                        uniquingKeysWith: { current, _ in current }
                    )
                    
                    // Return result with key identifier
                    return createSuccessResult(
                        data: Data(generatedKey.identifier.utf8),
                        duration: 0, // Duration will be calculated by the operation handler
                        metadata: updatedMetadata
                    )
                } else {
                    // Return result with key identifier
                    return createSuccessResult(
                        data: Data(generatedKey.identifier.utf8),
                        duration: 0, // Duration will be calculated by the operation handler
                        metadata: resultMetadata
                    )
                }
                
            case .failure(let error):
                throw error
            }
        } catch let securityError as SecurityStorageError {
            // Log specific key generation errors
            await logError(
                "Key generation failed due to storage error: \(securityError)",
                context: context
            )
            throw securityError
        } catch {
            // Log unexpected errors
            await logError(
                "Key generation failed with unexpected error: \(error.localizedDescription)",
                context: context
            )
            throw CoreSecurityTypes.SecurityError.keyGenerationFailed(
                reason: "Key generation operation failed: \(error.localizedDescription)"
            )
        }
    }
}
