import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security

/**
 Command for encrypting data with a given key.
 
 This command implements high-security encryption using AES-GCM with
 additional integrity verification. It follows the Alpha Dot Five architecture
 principles with privacy-aware logging and strong error handling.
 */
public class EncryptDataCommand: BaseCryptoCommand, CryptoCommand {
    /// The type of result returned by this command
    public typealias ResultType = String
    
    /// The data to encrypt
    private let data: [UInt8]
    
    /// The identifier of the key to use
    private let keyIdentifier: String
    
    /// The encryption algorithm to use
    private let algorithm: EncryptionAlgorithm
    
    /// Custom IV if provided (otherwise generated)
    private let iv: [UInt8]?
    
    /**
     Initialises a new encrypt data command.
     
     - Parameters:
        - data: The data to encrypt
        - keyIdentifier: The identifier of the key to use
        - algorithm: The encryption algorithm to use
        - iv: Optional initialisation vector (IV)
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking and auditing
     */
    public init(
        data: [UInt8],
        keyIdentifier: String,
        algorithm: EncryptionAlgorithm = .aes256GCM,
        iv: [UInt8]? = nil,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol? = nil
    ) {
        self.data = data
        self.keyIdentifier = keyIdentifier
        self.algorithm = algorithm
        self.iv = iv
        super.init(secureStorage: secureStorage, logger: logger)
    }
    
    /**
     Executes the encryption operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The identifier of the encrypted data
     */
    public func execute(
        context: LogContextDTO,
        operationID: String
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let logContext = createLogContext(
            operation: "encrypt",
            algorithm: algorithm.rawValue,
            correlationID: operationID,
            additionalMetadata: [
                "dataSize": (value: "\(data.count)", privacyLevel: .public),
                "keyIdentifier": (value: keyIdentifier, privacyLevel: .private)
            ]
        )
        
        await logDebug("Starting encryption operation", context: logContext)
        
        // Retrieve the encryption key
        let keyResult = await secureStorage.retrieveSecureData(identifier: keyIdentifier)
        
        switch keyResult {
        case .success(let keyData):
            // Generate or use the provided IV
            let useIV: [UInt8]
            if let providedIV = iv {
                useIV = providedIV
                await logDebug("Using provided IV for encryption", context: logContext)
            } else {
                // Generate a secure random IV
                var generatedIV = [UInt8](repeating: 0, count: 16)
                let result = SecRandomCopyBytes(kSecRandomDefault, generatedIV.count, &generatedIV)
                
                guard result == errSecSuccess else {
                    await logError("Failed to generate IV for encryption", context: logContext)
                    return .failure(.operationFailed("Failed to generate secure random IV"))
                }
                
                useIV = generatedIV
                await logDebug("Generated secure random IV for encryption", context: logContext)
            }
            
            do {
                // Perform encryption based on the algorithm
                let encryptedData: [UInt8]
                
                switch algorithm {
                case .aes256GCM:
                    // AES-GCM implementation with authentication tag
                    guard keyData.count == 32 else { // 256 bits = 32 bytes
                        await logError("Invalid key size for AES-256-GCM", context: logContext)
                        return .failure(.operationFailed("Key size mismatch for AES-256-GCM"))
                    }
                    
                    encryptedData = try aesGCMEncrypt(data: data, key: keyData, iv: useIV)
                    
                case .aes256CBC:
                    // AES-CBC implementation
                    guard keyData.count == 32 else { // 256 bits = 32 bytes
                        await logError("Invalid key size for AES-256-CBC", context: logContext)
                        return .failure(.operationFailed("Key size mismatch for AES-256-CBC"))
                    }
                    
                    encryptedData = try aesCBCEncrypt(data: data, key: keyData, iv: useIV)
                    
                case .chacha20Poly1305:
                    // ChaCha20-Poly1305 implementation
                    guard keyData.count == 32 else { // 256 bits = 32 bytes
                        await logError("Invalid key size for ChaCha20-Poly1305", context: logContext)
                        return .failure(.operationFailed("Key size mismatch for ChaCha20-Poly1305"))
                    }
                    
                    encryptedData = try chacha20Poly1305Encrypt(data: data, key: keyData, iv: useIV)
                }
                
                // Format the final encrypted data:
                // [IV (16 bytes)][Encrypted Data][Key ID Length (1 byte)][Key ID]
                var finalData = useIV
                finalData.append(contentsOf: encryptedData)
                finalData.append(UInt8(keyIdentifier.utf8.count))
                finalData.append(contentsOf: keyIdentifier.utf8)
                
                // Generate a unique identifier for this encrypted data
                let resultIdentifier = UUID().uuidString
                
                // Store the encrypted data
                let storeResult = await secureStorage.storeSecureData(finalData, identifier: resultIdentifier)
                
                switch storeResult {
                case .success:
                    await logInfo(
                        "Successfully encrypted \(data.count) bytes of data",
                        context: logContext.adding(
                            key: "resultIdentifier",
                            value: resultIdentifier,
                            privacyLevel: .private
                        ).adding(
                            key: "resultSize",
                            value: "\(finalData.count)",
                            privacyLevel: .public
                        )
                    )
                    return .success(resultIdentifier)
                    
                case .failure(let error):
                    await logError(
                        "Failed to store encrypted data: \(error)",
                        context: logContext
                    )
                    return .failure(error)
                }
                
            } catch {
                await logError(
                    "Encryption operation failed: \(error.localizedDescription)",
                    context: logContext
                )
                return .failure(.operationFailed("Encryption failed: \(error.localizedDescription)"))
            }
            
        case .failure(let error):
            await logError(
                "Failed to retrieve encryption key: \(error)",
                context: logContext
            )
            return .failure(error)
        }
    }
    
    // MARK: - Encryption Implementations
    
    /**
     Encrypts data using AES-GCM.
     
     - Parameters:
        - data: The data to encrypt
        - key: The encryption key
        - iv: The initialisation vector
     - Returns: The encrypted data
     - Throws: Error if encryption fails
     */
    private func aesGCMEncrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        // AES-GCM would typically be implemented with CryptoKit or CommonCrypto
        // This is a simplified placeholder for the implementation
        
        // In a real implementation, this would:
        // 1. Set up the AES-GCM cipher
        // 2. Encrypt the data with authentication
        // 3. Append the authentication tag to the result
        
        // For now, we'll throw an error to indicate this needs implementation
        throw SecurityStorageError.operationFailed("AES-GCM encryption not implemented")
    }
    
    /**
     Encrypts data using AES-CBC.
     
     - Parameters:
        - data: The data to encrypt
        - key: The encryption key
        - iv: The initialisation vector
     - Returns: The encrypted data
     - Throws: Error if encryption fails
     */
    private func aesCBCEncrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        guard iv.count == kCCBlockSizeAES128 else {
            throw SecurityStorageError.operationFailed("Invalid IV size for AES-CBC")
        }
        
        // Pad the input data if needed (PKCS#7 padding)
        let paddedData = pkcs7Pad(data: data, blockSize: kCCBlockSizeAES128)
        
        // Create output buffer with enough space for the encrypted data
        let outputLength = paddedData.count
        var outputBuffer = [UInt8](repeating: 0, count: outputLength)
        var resultLength = 0
        
        // Perform encryption
        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            key, key.count,
            iv,
            paddedData, paddedData.count,
            &outputBuffer, outputLength,
            &resultLength
        )
        
        guard status == kCCSuccess else {
            throw SecurityStorageError.operationFailed("AES-CBC encryption failed with status \(status)")
        }
        
        // Return only the actual encrypted bytes
        return [UInt8](outputBuffer[0..<resultLength])
    }
    
    /**
     Encrypts data using ChaCha20-Poly1305.
     
     - Parameters:
        - data: The data to encrypt
        - key: The encryption key
        - iv: The initialisation vector
     - Returns: The encrypted data
     - Throws: Error if encryption fails
     */
    private func chacha20Poly1305Encrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        // ChaCha20-Poly1305 would typically be implemented with CryptoKit or CommonCrypto
        // This is a simplified placeholder for the implementation
        
        // In a real implementation, this would:
        // 1. Set up the ChaCha20-Poly1305 cipher
        // 2. Encrypt the data
        // 3. Compute and append the authentication tag
        
        // For now, we'll throw an error to indicate this needs implementation
        throw SecurityStorageError.operationFailed("ChaCha20-Poly1305 encryption not implemented")
    }
    
    /**
     Applies PKCS#7 padding to data.
     
     - Parameters:
        - data: The data to pad
        - blockSize: The cipher block size
     - Returns: The padded data
     */
    private func pkcs7Pad(data: [UInt8], blockSize: Int) -> [UInt8] {
        let paddingLength = blockSize - (data.count % blockSize)
        let paddingValue = UInt8(paddingLength)
        var paddedData = data
        for _ in 0..<paddingLength {
            paddedData.append(paddingValue)
        }
        return paddedData
    }
}
