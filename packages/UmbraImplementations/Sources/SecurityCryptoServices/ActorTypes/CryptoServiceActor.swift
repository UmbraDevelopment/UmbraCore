import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import LoggingInterfaces
import LoggingTypes
import UmbraErrors
import ProviderFactories

/**
 # CryptoServiceActor
 
 A Swift actor that provides thread-safe access to cryptographic operations
 using the pluggable security provider architecture.
 
 This actor fully embraces Swift's structured concurrency model, offering
 asynchronous methods for all cryptographic operations while ensuring proper
 isolation of mutable state.
 
 ## Usage
 
 ```swift
 // Create the actor with a specific provider type
 let cryptoService = CryptoServiceActor(providerType: .apple, logger: logger)
 
 // Perform operations asynchronously
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```
 
 ## Thread Safety
 
 All methods are automatically thread-safe due to Swift's actor isolation rules.
 Mutable state is properly contained within the actor and cannot be accessed from
 outside except through the defined async interfaces.
 */
public actor CryptoServiceActor {
    // MARK: - Properties
    
    /// The underlying security provider implementation
    private var provider: EncryptionProviderProtocol
    
    /// Logger for recording operations
    private let logger: LoggingProtocol
    
    /// Configuration options for cryptographic operations
    private var defaultConfig: SecurityConfigDTO
    
    // MARK: - Initialisation
    
    /**
     Initialises a new crypto service actor with the specified provider type.
     
     - Parameters:
        - providerType: The type of security provider to use
        - logger: Logger for recording operations
     */
    public init(providerType: SecurityProviderType? = nil, logger: LoggingProtocol) {
        self.logger = logger ?? DefaultLogger()
        
        do {
            if let providerType = providerType {
                self.provider = try SecurityProviderFactoryImpl.createProvider(type: providerType)
            } else {
                self.provider = try SecurityProviderFactoryImpl.createBestAvailableProvider()
            }
            
            // If the provider successfully initialises, set the default config
            if let providerType = providerType {
                self.defaultConfig = SecurityConfigDTO.aesEncryption(providerType: providerType)
            } else {
                self.defaultConfig = SecurityConfigDTO.aesEncryption(providerType: .basic)
            }
            
            Task {
                await logger.info("Initialised CryptoServiceActor with provider: \(self.provider.providerType.rawValue)", metadata: nil)
            }
        } catch {
            // Fall back to basic provider if there's an issue
            self.provider = SecurityProviderFactoryImpl.createDefaultProvider()
            self.defaultConfig = SecurityConfigDTO.aesEncryption(providerType: .basic)
            
            // Log the error but don't crash
            await self.logger.warning("Failed to initialise security provider: \(error). Using basic provider instead.")
        }
    }
    
    /**
     Changes the active security provider.
     
     - Parameter type: The provider type to switch to
     - Returns: True if the provider was successfully changed, false otherwise
     */
    public func setProviderType(_ type: SecurityProviderType) async throws {
        do {
            let newProvider = try SecurityProviderFactoryImpl.createProvider(type: type)
            self.provider = newProvider
            self.defaultConfig = SecurityConfigDTO.aesEncryption(providerType: type)
            await self.logger.info("Security provider changed to: \(type)")
        } catch {
            await self.logger.error("Failed to change security provider: \(error)")
            throw SecurityServiceError.providerError(error.localizedDescription)
        }
    }
    
    // MARK: - Encryption Operations
    
    /**
     Encrypts data using the configured provider.
     
     - Parameters:
        - data: The data to encrypt
        - key: The encryption key
        - config: Optional configuration override
     - Returns: Encrypted data wrapped in SecureBytes
     - Throws: SecurityProtocolError if encryption fails
     */
    public func encrypt(
        data: SecureBytes,
        using key: SecureBytes,
        config: SecurityConfigDTO? = nil
    ) async throws -> SecureBytes {
        let dataBytes = data.extractUnderlyingData()
        let keyBytes = key.extractUnderlyingData()
        
        // Generate IV using the provider
        let iv: Data
        do {
            iv = try provider.generateIV(size: 16)
        } catch {
            await logger.error("Failed to generate IV: \(error.localizedDescription)", metadata: nil)
            throw SecurityProtocolError.cryptographicError("Failed to generate IV: \(error.localizedDescription)")
        }
        
        // Use provided config or default
        let operationConfig = config ?? defaultConfig
        
        // Encrypt data
        do {
            let encryptedData = try provider.encrypt(
                plaintext: dataBytes,
                key: keyBytes,
                iv: iv,
                config: operationConfig
            )
            
            // Prepend IV to encrypted data for later decryption
            var result = Data(capacity: iv.count + encryptedData.count)
            result.append(iv)
            result.append(encryptedData)
            
            return SecureBytes(data: result)
        } catch {
            await logger.error("Encryption failed: \(error.localizedDescription)", metadata: nil)
            
            if let secError = error as? SecurityProtocolError {
                throw secError
            } else {
                throw SecurityProtocolError.cryptographicError("Encryption failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Decrypts data using the configured provider.
     
     - Parameters:
        - data: The data to decrypt (IV + ciphertext)
        - key: The decryption key
        - config: Optional configuration override
     - Returns: Decrypted data wrapped in SecureBytes
     - Throws: SecurityProtocolError if decryption fails
     */
    public func decrypt(
        data: SecureBytes,
        using key: SecureBytes,
        config: SecurityConfigDTO? = nil
    ) async throws -> SecureBytes {
        let dataBytes = data.extractUnderlyingData()
        let keyBytes = key.extractUnderlyingData()
        
        // Validate minimum length (IV + at least some ciphertext)
        guard dataBytes.count > 16 else {
            await logger.error("Encrypted data too short, must include IV", metadata: nil)
            throw SecurityProtocolError.invalidInput("Encrypted data too short, must include IV")
        }
        
        // Extract IV and ciphertext
        let iv = dataBytes.prefix(16)
        let ciphertext = dataBytes.dropFirst(16)
        
        // Use provided config or default
        let operationConfig = config ?? defaultConfig
        
        // Decrypt data
        do {
            let decryptedData = try provider.decrypt(
                ciphertext: ciphertext,
                key: keyBytes,
                iv: Data(iv),
                config: operationConfig
            )
            
            return SecureBytes(data: decryptedData)
        } catch {
            await logger.error("Decryption failed: \(error.localizedDescription)", metadata: nil)
            
            if let secError = error as? SecurityProtocolError {
                throw secError
            } else {
                throw SecurityProtocolError.cryptographicError("Decryption failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Key Management
    
    /**
     Generates a cryptographic key of the specified size.
     
     - Parameters:
        - size: Key size in bits (128, 192, or 256 for AES)
        - config: Optional configuration override
     - Returns: Generated key wrapped in SecureBytes
     - Throws: SecurityProtocolError if key generation fails
     */
    public func generateKey(
        size: Int,
        config: SecurityConfigDTO? = nil
    ) async throws -> SecureBytes {
        // Use provided config or default
        let operationConfig = config ?? defaultConfig
        
        do {
            let keyData = try provider.generateKey(size: size, config: operationConfig)
            return SecureBytes(data: keyData)
        } catch {
            await logger.error("Key generation failed: \(error.localizedDescription)", metadata: nil)
            
            if let secError = error as? SecurityProtocolError {
                throw secError
            } else {
                throw SecurityProtocolError.cryptographicError("Key generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Hashing Operations
    
    /**
     Creates a cryptographic hash of the input data.
     
     - Parameters:
        - data: The data to hash
        - algorithm: Hash algorithm to use (SHA256, SHA384, SHA512)
     - Returns: Hash value wrapped in SecureBytes
     - Throws: SecurityProtocolError if hashing fails
     */
    public func hash(
        data: SecureBytes,
        algorithm: String = "SHA256"
    ) async throws -> SecureBytes {
        let dataBytes = data.extractUnderlyingData()
        
        do {
            let hashData = try provider.hash(data: dataBytes, algorithm: algorithm)
            return SecureBytes(data: hashData)
        } catch {
            await logger.error("Hashing failed: \(error.localizedDescription)", metadata: nil)
            
            if let secError = error as? SecurityProtocolError {
                throw secError
            } else {
                throw SecurityProtocolError.cryptographicError("Hashing failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Verifies that a hash matches the expected value.
     
     - Parameters:
        - hash: The hash to verify
        - expected: The expected hash value
     - Returns: True if the hashes match, false otherwise
     */
    public func verifyHash(_ hash: SecureBytes, matches expected: SecureBytes) -> Bool {
        return hash == expected
    }
    
    // MARK: - Parallel Processing
    
    /**
     Encrypts multiple data items in parallel using task groups.
     
     - Parameters:
        - dataItems: Array of data items to encrypt
        - key: The encryption key to use for all items
        - config: Optional configuration override
     - Returns: Array of encrypted data items in the same order
     - Throws: SecurityProtocolError if any encryption operation fails
     */
    public func encryptBatch(
        dataItems: [SecureBytes],
        using key: SecureBytes,
        config: SecurityConfigDTO? = nil
    ) async throws -> [SecureBytes] {
        return try await withThrowingTaskGroup(of: (Int, SecureBytes).self) { group in
            // Add each encryption task to the group
            for (index, data) in dataItems.enumerated() {
                group.addTask {
                    let encryptedData = try await self.encrypt(data: data, using: key, config: config)
                    return (index, encryptedData)
                }
            }
            
            // Collect results and maintain original order
            var results = [(Int, SecureBytes)]()
            for try await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    /**
     Decrypts multiple data items in parallel using task groups.
     
     - Parameters:
        - dataItems: Array of encrypted data items to decrypt
        - key: The decryption key to use for all items
        - config: Optional configuration override
     - Returns: Array of decrypted data items in the same order
     - Throws: SecurityProtocolError if any decryption operation fails
     */
    public func decryptBatch(
        dataItems: [SecureBytes],
        using key: SecureBytes,
        config: SecurityConfigDTO? = nil
    ) async throws -> [SecureBytes] {
        return try await withThrowingTaskGroup(of: (Int, SecureBytes).self) { group in
            // Add each decryption task to the group
            for (index, data) in dataItems.enumerated() {
                group.addTask {
                    let decryptedData = try await self.decrypt(data: data, using: key, config: config)
                    return (index, decryptedData)
                }
            }
            
            // Collect results and maintain original order
            var results = [(Int, SecureBytes)]()
            for try await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}
