import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # SecurityProvider Operations Extension
 
 This extension adds higher-level operations to the SecurityProviderImpl,
 combining multiple atomic operations for common security tasks.
 
 ## Combined Operations
 
 - Encrypt and store: Encrypts data and stores it in a single operation
 - Retrieve and decrypt: Retrieves and decrypts data in a single operation
 - Batch operations: Processes multiple items with the same security operation
 */
extension SecurityProviderImpl {
    /**
     Encrypts data and stores it securely in a single operation.
     
     - Parameters:
       - data: The data to encrypt and store
       - config: Configuration for the encryption operation
     - Returns: Result containing the storage identifier
     */
    public func encryptAndStore(data: SecureBytes, config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.encryptAndStore
        
        do {
            // Log operation start
            await logger.info("Starting combined encrypt and store operation", metadata: nil)
            
            // Create encryption config
            var encryptionConfig = config
            
            // Convert SecureBytes to base64 string for options
            let dataString = data.extractData().base64EncodedString()
            encryptionConfig.options["inputData"] = dataString
            
            if encryptionConfig.options["keyIdentifier"] == nil {
                throw UmbraErrors.Security.Core.invalidInput("No key identifier provided for encryption")
            }
            
            // Encrypt the data
            let encryptResult = await encrypt(config: encryptionConfig)
            
            if !encryptResult.success {
                return encryptResult
            }
            
            // Create storage config
            var storageConfig = SecurityConfigDTO(
                keySize: config.keySize,
                algorithm: config.algorithm,
                hashAlgorithm: config.hashAlgorithm,
                options: [:]
            )
            
            // Use the encrypted data for storage
            storageConfig.options["storeData"] = encryptResult.result
            
            // Generate a storage identifier if not provided
            let storageIdentifier = config.options["storageIdentifier"] ?? UUID().uuidString
            storageConfig.options["storageIdentifier"] = storageIdentifier
            
            // Store the encrypted data
            let storeResult = await secureStore(config: storageConfig)
            
            if !storeResult.success {
                return storeResult
            }
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            // Log success
            await logger.info("Combined encrypt and store operation completed successfully", 
                              metadata: ["durationMs": String(format: "%.2f", duration)])
            
            // Return success with the storage identifier
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: storageIdentifier,
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            // Log failure
            await logger.error("Combined encrypt and store operation failed: \(error.localizedDescription)", 
                               metadata: ["durationMs": String(format: "%.2f", duration)])
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Retrieves and decrypts data in a single operation.
     
     - Parameters:
       - identifier: The identifier for the stored encrypted data
       - config: Configuration for the decryption operation
     - Returns: Result containing the decrypted data
     */
    public func retrieveAndDecrypt(identifier: String, config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.retrieveAndDecrypt
        
        do {
            // Log operation start
            await logger.info("Starting combined retrieve and decrypt operation", metadata: nil)
            
            // Create retrieval config
            var retrievalConfig = SecurityConfigDTO(
                keySize: config.keySize,
                algorithm: config.algorithm,
                hashAlgorithm: config.hashAlgorithm,
                options: [:]
            )
            retrievalConfig.options["storageIdentifier"] = identifier
            
            // Retrieve the encrypted data
            let retrieveResult = await secureRetrieve(config: retrievalConfig)
            
            if !retrieveResult.success {
                return retrieveResult
            }
            
            // Create decryption config
            var decryptionConfig = config
            
            // Use the retrieved data for decryption
            guard let retrievedData = retrieveResult.result else {
                throw UmbraErrors.Security.Core.operationFailed("Retrieved data is missing")
            }
            
            decryptionConfig.options["inputData"] = retrievedData
            
            if decryptionConfig.options["keyIdentifier"] == nil {
                throw UmbraErrors.Security.Core.invalidInput("No key identifier provided for decryption")
            }
            
            // Decrypt the data
            let decryptResult = await decrypt(config: decryptionConfig)
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            if decryptResult.success {
                // Log success
                await logger.info("Combined retrieve and decrypt operation completed successfully", 
                                 metadata: ["durationMs": String(format: "%.2f", duration)])
            } else {
                // Log failure
                await logger.error("Decryption failed after successful retrieval", 
                                   metadata: ["durationMs": String(format: "%.2f", duration)])
            }
            
            return decryptResult
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            // Log failure
            await logger.error("Combined retrieve and decrypt operation failed: \(error.localizedDescription)", 
                               metadata: ["durationMs": String(format: "%.2f", duration)])
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Performs batch encryption on multiple data items.
     
     - Parameters:
       - dataItems: Array of data items to encrypt
       - config: Base configuration for encryption
     - Returns: Array of results, one for each item
     */
    public func batchEncrypt(dataItems: [SecureBytes], config: SecurityConfigDTO) async -> [SecurityResultDTO] {
        var results: [SecurityResultDTO] = []
        
        await logger.info("Starting batch encryption of \(dataItems.count) items", metadata: nil)
        
        for (index, item) in dataItems.enumerated() {
            var itemConfig = config
            
            // Create unique identifier for each item if none provided
            if itemConfig.options["keyIdentifier"] == nil {
                itemConfig.options["keyIdentifier"] = "\(config.options["keyIdentifier"] ?? "batch")-\(index)"
            }
            
            // Add the data to the config
            itemConfig.options["inputData"] = item.extractData().base64EncodedString()
            
            // Encrypt the item
            let result = await encrypt(config: itemConfig)
            results.append(result)
            
            // Break early if any encryption fails
            if !result.success {
                await logger.error("Batch encryption failed at item \(index + 1)", metadata: nil)
                break
            }
        }
        
        let successCount = results.filter { $0.success }.count
        await logger.info("Batch encryption completed: \(successCount)/\(dataItems.count) successful", metadata: nil)
        
        return results
    }
    
    /**
     Performs batch decryption on multiple data items.
     
     - Parameters:
       - dataItems: Array of encrypted data items
       - config: Base configuration for decryption
     - Returns: Array of results, one for each item
     */
    public func batchDecrypt(dataItems: [SecureBytes], config: SecurityConfigDTO) async -> [SecurityResultDTO] {
        var results: [SecurityResultDTO] = []
        
        await logger.info("Starting batch decryption of \(dataItems.count) items", metadata: nil)
        
        for (index, item) in dataItems.enumerated() {
            var itemConfig = config
            
            // Create unique identifier for each item if needed
            if itemConfig.options["keyIdentifier"] == nil {
                itemConfig.options["keyIdentifier"] = "\(config.options["keyIdentifier"] ?? "batch")-\(index)"
            }
            
            // Add the data to the config
            itemConfig.options["inputData"] = item.extractData().base64EncodedString()
            
            // Decrypt the item
            let result = await decrypt(config: itemConfig)
            results.append(result)
            
            // Break early if any decryption fails
            if !result.success {
                await logger.error("Batch decryption failed at item \(index + 1)", metadata: nil)
                break
            }
        }
        
        let successCount = results.filter { $0.success }.count
        await logger.info("Batch decryption completed: \(successCount)/\(dataItems.count) successful", metadata: nil)
        
        return results
    }
    
    /**
     Securely generates random data of the specified length.
     
     - Parameter length: The length of random data to generate in bytes
     - Returns: Result containing the secure random data
     */
    public func generateRandomData(length: Int) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        
        do {
            // Log operation start
            await logger.info("Generating secure random data of \(length) bytes", metadata: nil)
            
            // Use KeyManager to generate random bytes
            let randomBytes = try await keyManager.generateRandomBytes(length: length)
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            // Log success
            await logger.info("Random data generation completed successfully", 
                              metadata: ["durationMs": String(format: "%.2f", duration)])
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: randomBytes.extractData().base64EncodedString(),
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            // Log failure
            await logger.error("Random data generation failed: \(error.localizedDescription)", 
                               metadata: ["durationMs": String(format: "%.2f", duration)])
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
}
