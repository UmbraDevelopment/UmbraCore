import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for verifying cryptographic hashes.
 
 This command implements hash verification operations with multiple algorithm
 options. It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class VerifyHashCommand: BaseCryptoCommand, CryptoCommand {
    /// The type of result returned by this command
    public typealias ResultType = Bool
    
    /// The data to verify
    private let data: [UInt8]
    
    /// The expected hash value
    private let expectedHash: [UInt8]
    
    /// The hash algorithm to use
    private let algorithm: HashAlgorithm
    
    /// Optional salt for the hash
    private let salt: [UInt8]?
    
    /**
     Initialises a new verify hash command.
     
     - Parameters:
        - data: The data to verify
        - expectedHash: The expected hash value
        - algorithm: The hash algorithm to use
        - salt: Optional salt to apply to the hash
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking and auditing
     */
    public init(
        data: [UInt8],
        expectedHash: [UInt8],
        algorithm: HashAlgorithm = .sha256,
        salt: [UInt8]? = nil,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol? = nil
    ) {
        self.data = data
        self.expectedHash = expectedHash
        self.algorithm = algorithm
        self.salt = salt
        super.init(secureStorage: secureStorage, logger: logger)
    }
    
    /**
     Executes the hash verification operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: True if the hash matches, false otherwise
     */
    public func execute(
        context: LogContextDTO,
        operationID: String
    ) async -> Result<Bool, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let logContext = createLogContext(
            operation: "verifyHash",
            algorithm: algorithm.rawValue,
            correlationID: operationID,
            additionalMetadata: [
                "dataSize": (value: "\(data.count)", privacyLevel: .public),
                "expectedHashSize": (value: "\(expectedHash.count)", privacyLevel: .public),
                "saltUsed": (value: salt != nil ? "true" : "false", privacyLevel: .public)
            ]
        )
        
        await logDebug("Starting hash verification operation", context: logContext)
        
        // Create a hash command to compute the actual hash
        let hashCommand = HashDataCommand(
            data: data,
            algorithm: algorithm,
            salt: salt,
            secureStorage: secureStorage,
            logger: logger
        )
        
        // Compute the actual hash
        let hashResult = await hashCommand.execute(context: logContext, operationID: operationID)
        
        switch hashResult {
        case .success(let computedHash):
            // Compare the computed hash with the expected hash
            let hashesMatch = expectedHash.count == computedHash.count && 
                              constantTimeEquals(computedHash, expectedHash)
            
            if hashesMatch {
                await logInfo(
                    "Hash verification successful",
                    context: logContext
                )
            } else {
                await logWarning(
                    "Hash verification failed: computed hash does not match expected hash",
                    context: logContext
                )
            }
            
            return .success(hashesMatch)
            
        case .failure(let error):
            await logError(
                "Hash verification failed: could not compute hash: \(error)",
                context: logContext
            )
            return .failure(error)
        }
    }
    
    /**
     Compares two byte arrays in constant time to prevent timing attacks.
     
     - Parameters:
        - lhs: First byte array
        - rhs: Second byte array
     - Returns: True if arrays are equal, false otherwise
     */
    private func constantTimeEquals(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        
        var result: UInt8 = 0
        
        for i in 0..<lhs.count {
            result |= lhs[i] ^ rhs[i]
        }
        
        return result == 0
    }
}
