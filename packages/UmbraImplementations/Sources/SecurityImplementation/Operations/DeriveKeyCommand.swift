import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command that executes key derivation operations.
 
 This command encapsulates the cryptographic key derivation logic in accordance
 with the command pattern, providing clean separation of concerns.
 */
public class DeriveKeyCommand: BaseSecurityCommand, SecurityOperationCommand {
    /// The crypto service for performing the key derivation
    private let cryptoService: CryptoServiceProtocol
    
    /**
     Initialises a new key derivation command.
     
     - Parameters:
        - config: Security configuration for the key derivation
        - cryptoService: The service to perform the key derivation
        - logger: Logger for operation tracking and auditing
     */
    public init(config: SecurityConfigDTO, cryptoService: CryptoServiceProtocol, logger: LoggingProtocol) {
        self.cryptoService = cryptoService
        super.init(config: config, logger: logger)
    }
    
    /**
     Executes the key derivation operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The key derivation result
     - Throws: SecurityError if key derivation fails
     */
    public func execute(context: LogContextDTO, operationID: String) async throws -> SecurityResultDTO {
        await logDebug("Preparing to derive cryptographic key", context: context)
        
        // Extract required data from configuration
        let extractor = metadataExtractor()
        
        do {
            // Extract source key identifier
            let sourceKeyIdentifier = try extractor.requiredIdentifier(
                forKey: "sourceKeyIdentifier",
                errorMessage: "Source key identifier is required for key derivation"
            )
            
            // Extract salt if provided
            let salt = extractor.optionalData(forKey: "salt")
            
            // Extract info if provided
            let info = extractor.optionalData(forKey: "info")
            
            // Extract key type
            let keyTypeString = try extractor.requiredString(
                forKey: "keyType",
                errorMessage: "Key type is required for key derivation"
            )
            
            guard let keyType = KeyType(rawValue: keyTypeString) else {
                throw CoreSecurityTypes.SecurityError.invalidInput(
                    reason: "Invalid key type: \(keyTypeString)"
                )
            }
            
            // Extract target key identifier if provided (for overwriting an existing key)
            let targetKeyIdentifier = extractor.optionalString(forKey: "targetKeyIdentifier")
            
            // Prepare enhanced context for logging
            let enhancedContext = context
                .adding(key: "keyType", value: keyType.rawValue, privacyLevel: .public)
                .adding(key: "sourceKeyIdentifier", value: sourceKeyIdentifier, privacyLevel: .private)
            
            await logDebug(
                "Deriving \(keyType.rawValue) key from source key",
                context: enhancedContext
            )
            
            // Perform the key derivation
            let result = try await cryptoService.deriveKey(
                fromKey: sourceKeyIdentifier,
                salt: salt != nil ? [UInt8](salt!) : nil,
                info: info != nil ? [UInt8](info!) : nil,
                keyType: keyType,
                targetIdentifier: targetKeyIdentifier
            )
            
            // Process the result
            switch result {
            case .success(let derivedKey):
                // Record successful key derivation
                let resultContext = enhancedContext.adding(
                    key: "keyIdentifier",
                    value: derivedKey.identifier,
                    privacyLevel: .private
                )
                
                await logInfo(
                    "Successfully derived \(keyType.rawValue) key",
                    context: resultContext
                )
                
                // Create result metadata
                let resultMetadata: [String: String] = [
                    "keyType": keyType.rawValue,
                    "keyIdentifier": derivedKey.identifier,
                    "sourceKeyIdentifier": sourceKeyIdentifier,
                    "operationID": operationID
                ]
                
                // Return result with derived key identifier
                return createSuccessResult(
                    data: Data(derivedKey.identifier.utf8),
                    duration: 0, // Duration will be calculated by the operation handler
                    metadata: resultMetadata
                )
                
            case .failure(let error):
                throw error
            }
        } catch let securityError as SecurityStorageError {
            // Log specific key derivation errors
            await logError(
                "Key derivation failed due to storage error: \(securityError)",
                context: context
            )
            throw securityError
        } catch {
            // Log unexpected errors
            await logError(
                "Key derivation failed with unexpected error: \(error.localizedDescription)",
                context: context
            )
            throw CoreSecurityTypes.SecurityError.keyDerivationFailed(
                reason: "Key derivation operation failed: \(error.localizedDescription)"
            )
        }
    }
}
