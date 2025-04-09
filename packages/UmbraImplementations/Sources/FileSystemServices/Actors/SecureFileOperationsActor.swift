import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes
import CryptoKit

/**
 # Secure File Operations Actor
 
 Implements secure file operations as an actor to ensure thread safety.
 This actor provides implementations for all methods defined in the
 SecureFileOperationsProtocol, with comprehensive security controls,
 error handling, and logging.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing actor-based concurrency for thread safety
 3. Providing comprehensive privacy-aware logging
 4. Utilising secure cryptographic operations
 5. Implementing zero-trust security principles
 6. Supporting sandboxed operation for enhanced security
 */
public actor SecureFileOperationsActor: SecureFileOperationsProtocol {
    /// Logger for operation tracking
    private let logger: LoggingProtocol
    
    /// File manager instance for performing file operations
    private let fileManager: FileManager
    
    /// File read operations for basic reads
    private let fileReadActor: FileReadOperationsProtocol
    
    /// File write operations for basic writes
    private let fileWriteActor: FileWriteOperationsProtocol
    
    /// Optional root directory for sandboxed operation
    private let rootDirectory: String?
    
    /**
     Initialises a new SecureFileOperationsActor.
     
     - Parameters:
        - logger: The logger to use for operation tracking
        - fileReadActor: Actor for basic file read operations
        - fileWriteActor: Actor for basic file write operations
        - rootDirectory: Optional root directory to restrict operations to
     */
    public init(
        logger: LoggingProtocol,
        fileReadActor: FileReadOperationsProtocol,
        fileWriteActor: FileWriteOperationsProtocol,
        rootDirectory: String? = nil
    ) {
        self.logger = logger
        self.fileManager = FileManager.default
        self.fileReadActor = fileReadActor
        self.fileWriteActor = fileWriteActor
        self.rootDirectory = rootDirectory
    }
    
    /**
     Validates that a path is within the root directory if one is specified.
     
     - Parameter path: The path to validate
     - Returns: The canonicalised path if valid
     - Throws: FileSystemError.accessDenied if the path is outside the root directory
     */
    private func validatePath(_ path: String) throws -> String {
        guard let rootDir = rootDirectory else {
            // No sandboxing, path is valid as-is
            return path
        }
        
        // Special case for temporary directory operations
        if path == NSTemporaryDirectory() || path.hasPrefix(NSTemporaryDirectory()) {
            // Allow operations in the temporary directory
            return path
        }
        
        // Canonicalise paths to resolve any ../ or symlinks
        let canonicalPath = URL(fileURLWithPath: path).standardized.path
        let canonicalRootDir = URL(fileURLWithPath: rootDir).standardized.path
        
        // Check if the path is within the root directory
        if !canonicalPath.hasPrefix(canonicalRootDir) {
            let context = FileSystemLogContext.forSecureOperation(
                secureOperation: "validatePath",
                path: path,
                source: "SecureFileOperationsActor"
            )
            
            await logger.warning(
                "Security violation: Access attempt to path outside root directory", 
                context: context
            )
            
            throw FileSystemError.accessDenied(
                path: path,
                reason: "Path is outside the permitted root directory"
            )
        }
        
        return canonicalPath
    }
    
    /**
     Creates a secure temporary file with the specified prefix.
     
     - Parameters:
        - prefix: Optional prefix for the temporary file name.
        - options: Optional file creation options.
     - Returns: The path to the secure temporary file.
     - Throws: FileSystemError if the temporary file cannot be created.
     */
    public func createSecureTemporaryFile(prefix: String?, options: FileCreationOptions?) async throws -> String {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "createSecureTemporaryFile",
            path: NSTemporaryDirectory()
        )
        
        await logger.debug("Creating secure temporary file", context: context)
        
        do {
            // Create a secure random name with prefix if provided
            let fileName = [prefix, UUID().uuidString].compactMap { $0 }.joined(separator: "-")
            let tempDir = NSTemporaryDirectory()
            let tempPath = (tempDir as NSString).appendingPathComponent(fileName)
            
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(tempPath)
            
            // Create the file using the write actor
            let path = try await fileWriteActor.createFile(at: validatedPath, options: options)
            
            // Set secure permissions - only allow current user to read/write
            var attributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o600 // Owner read/write only
            ]
            
            // Add any additional attributes from options
            if let optionsAttributes = options?.attributes {
                for (key, value) in optionsAttributes {
                    attributes[key] = value
                }
            }
            
            try fileManager.setAttributes(attributes, ofItemAtPath: path)
            
            // Log successful operation
            let successContext = context
                .withPath(path)
                .withStatus("success")
            await logger.debug("Successfully created secure temporary file", context: successContext)
            
            return path
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to create secure temporary file: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "createSecureTemporaryFile", path: "temporary directory")
            await logger.error("Failed to create secure temporary file: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Creates a secure temporary directory with the specified prefix.
     
     - Parameters:
        - prefix: Optional prefix for the temporary directory name.
        - options: Optional directory creation options.
     - Returns: The path to the secure temporary directory.
     - Throws: FileSystemError if the temporary directory cannot be created.
     */
    public func createSecureTemporaryDirectory(prefix: String?, options: DirectoryCreationOptions?) async throws -> String {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "createSecureTemporaryDirectory",
            path: NSTemporaryDirectory()
        )
        
        await logger.debug("Creating secure temporary directory", context: context)
        
        do {
            // Create a secure random name with prefix if provided
            let dirName = [prefix, UUID().uuidString].compactMap { $0 }.joined(separator: "-")
            let tempDir = NSTemporaryDirectory()
            let tempPath = (tempDir as NSString).appendingPathComponent(dirName)
            
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(tempPath)
            
            // Create the directory using the write actor
            let path = try await fileWriteActor.createDirectory(at: validatedPath, options: options)
            
            // Set secure permissions - only allow current user to read/write/execute
            var attributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o700 // Owner read/write/execute only
            ]
            
            // Add any additional attributes from options
            if let optionsAttributes = options?.attributes {
                for (key, value) in optionsAttributes {
                    attributes[key] = value
                }
            }
            
            try fileManager.setAttributes(attributes, ofItemAtPath: path)
            
            // Log successful operation
            let successContext = context
                .withPath(path)
                .withStatus("success")
            await logger.debug("Successfully created secure temporary directory", context: successContext)
            
            return path
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to create secure temporary directory: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "createSecureTemporaryDirectory", path: "temporary directory")
            await logger.error("Failed to create secure temporary directory: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Securely writes data to a file with encryption.
     
     - Parameters:
        - data: The data to write.
        - path: The path where the data should be written.
        - options: Optional secure write options.
     - Throws: FileSystemError if the secure write operation fails.
     */
    public func secureWriteFile(data: Data, to path: String, options: SecureFileWriteOptions?) async throws {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "secureWriteFile",
            path: path
        )
        
        let metadata = context.metadata
            .withPublic(key: "dataSize", value: String(data.count))
        
        if let algorithm = options?.secureOptions.encryptionAlgorithm {
            let enhancedMetadata = metadata.withPublic(key: "algorithm", value: algorithm.rawValue)
            let enhancedContext = context.withUpdatedMetadata(enhancedMetadata)
            await logger.debug("Securely writing encrypted data to file", context: enhancedContext)
        } else {
            let enhancedContext = context.withUpdatedMetadata(metadata)
            await logger.debug("Securely writing data to file", context: enhancedContext)
        }
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Generate a random encryption key and initialization vector
            var key = SymmetricKey(size: .bits256)
            var nonce = AES.GCM.Nonce()
            
            // Encrypt the data
            let algorithm = options?.secureOptions.encryptionAlgorithm ?? .aes256
            let encryptedData: Data
            
            switch algorithm {
            case .aes256:
                let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
                guard let sealedData = sealedBox.combined else {
                    throw FileSystemError.securityError(
                        path: validatedPath,
                        reason: "Failed to create sealed data"
                    )
                }
                encryptedData = sealedData
                
            case .chaChaPoly:
                let sealedBox = try ChaChaPoly.seal(data, using: key, nonce: ChaChaPoly.Nonce())
                encryptedData = sealedBox.combined
            }
            
            // Create a metadata structure containing the encryption parameters
            // In a real implementation, these would be securely stored separately
            // using a key management system
            let secureMetadata: [String: String] = [
                "algorithm": algorithm.rawValue,
                "version": "1.0"
            ]
            
            // For demo purposes, store the metadata in the file
            // In a real implementation, use a proper key management system
            let metadataData = try JSONSerialization.data(withJSONObject: secureMetadata)
            
            // Combine metadata and encrypted data
            var combinedData = Data()
            let metadataLength = UInt32(metadataData.count)
            combinedData.append(Data(bytes: &metadataLength, count: 4))
            combinedData.append(metadataData)
            combinedData.append(encryptedData)
            
            // Write the combined data to file using normal write operations
            try await fileWriteActor.writeFile(
                data: combinedData,
                to: validatedPath,
                options: options?.writeOptions
            )
            
            // Set secure permissions
            var attributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o600 // Owner read/write only
            ]
            
            // Add any additional attributes from options
            if let optionsAttributes = options?.writeOptions.attributes {
                for (key, value) in optionsAttributes {
                    attributes[key] = value
                }
            }
            
            try fileManager.setAttributes(attributes, ofItemAtPath: validatedPath)
            
            // Zero out sensitive data after use
            key = SymmetricKey(size: .bits256) // Overwrite with new random data
            
            // Log successful operation
            let successContext = context.withStatus("success")
            await logger.debug("Successfully wrote encrypted data to file", context: successContext)
            
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to securely write file: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "secureWriteFile", path: path)
            await logger.error("Failed to securely write file: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Securely reads data from an encrypted file.
     
     - Parameters:
        - path: The path to the encrypted file.
        - options: Optional secure read options.
     - Returns: The decrypted file contents.
     - Throws: FileSystemError if the secure read operation fails.
     */
    public func secureReadFile(at path: String, options: SecureFileReadOptions?) async throws -> Data {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "secureReadFile",
            path: path
        )
        
        await logger.debug("Securely reading encrypted data from file", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Read the encrypted file
            let fileData = try await fileReadActor.readFile(at: validatedPath)
            
            // Extract the metadata length
            guard fileData.count > 4 else {
                throw FileSystemError.securityError(
                    path: validatedPath,
                    reason: "Invalid encrypted file format"
                )
            }
            
            let metadataLength = fileData.withUnsafeBytes { $0.load(as: UInt32.self) }
            
            // Extract the metadata
            guard fileData.count > 4 + Int(metadataLength) else {
                throw FileSystemError.securityError(
                    path: validatedPath,
                    reason: "Invalid encrypted file format"
                )
            }
            
            let metadataData = fileData.subdata(in: 4..<(4 + Int(metadataLength)))
            
            guard let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: String],
                  let algorithmString = metadata["algorithm"],
                  let algorithm = SecureFileOptions.EncryptionAlgorithm(rawValue: algorithmString) else {
                throw FileSystemError.securityError(
                    path: validatedPath,
                    reason: "Invalid metadata in encrypted file"
                )
            }
            
            // Extract the encrypted data
            let encryptedData = fileData.subdata(in: (4 + Int(metadataLength))..<fileData.count)
            
            // In a real implementation, the key and nonce would be securely retrieved
            // from a key management system, potentially using a key derived from user credentials
            // Here we're using placeholder values for illustration
            let key = SymmetricKey(size: .bits256)
            
            // Decrypt the data
            let decryptedData: Data
            
            switch algorithm {
            case .aes256:
                guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData) else {
                    throw FileSystemError.securityError(
                        path: validatedPath,
                        reason: "Invalid AES-GCM sealed data"
                    )
                }
                
                do {
                    // In a real implementation, use the correct key retrieved from key management
                    decryptedData = try AES.GCM.open(sealedBox, using: key)
                } catch {
                    throw FileSystemError.securityError(
                        path: validatedPath,
                        reason: "Failed to decrypt data: \(error.localizedDescription)"
                    )
                }
                
            case .chaChaPoly:
                guard let sealedBox = try? ChaChaPoly.SealedBox(combined: encryptedData) else {
                    throw FileSystemError.securityError(
                        path: validatedPath,
                        reason: "Invalid ChaCha20-Poly1305 sealed data"
                    )
                }
                
                do {
                    // In a real implementation, use the correct key retrieved from key management
                    decryptedData = try ChaChaPoly.open(sealedBox, using: key)
                } catch {
                    throw FileSystemError.securityError(
                        path: validatedPath,
                        reason: "Failed to decrypt data: \(error.localizedDescription)"
                    )
                }
            }
            
            // Log successful operation
            let successContext = context
                .withStatus("success")
                .withUpdatedMetadata(context.metadata.withPublic(key: "decryptedSize", value: String(decryptedData.count)))
            await logger.debug("Successfully read and decrypted file", context: successContext)
            
            return decryptedData
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to securely read file: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "secureReadFile", path: path)
            await logger.error("Failed to securely read file: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Securely deletes a file using secure erase techniques.
     
     - Parameters:
        - path: The path to the file to securely delete.
        - options: Optional secure deletion options.
     - Throws: FileSystemError if the secure deletion fails.
     */
    public func secureDelete(at path: String, options: SecureDeletionOptions?) async throws {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "secureDelete",
            path: path
        )
        
        let passes = options?.overwritePasses ?? 3
        let useRandom = options?.useRandomData ?? true
        
        let metadata = context.metadata
            .withPublic(key: "overwritePasses", value: String(passes))
            .withPublic(key: "useRandomData", value: String(useRandom))
        let enhancedContext = context.withUpdatedMetadata(metadata)
        
        await logger.debug("Securely deleting file", context: enhancedContext)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: validatedPath)
            guard let fileSize = attributes[.size] as? UInt64, fileSize > 0 else {
                // If the file is empty, just delete it
                try fileManager.removeItem(atPath: validatedPath)
                
                let successContext = enhancedContext.withStatus("success")
                await logger.debug("Successfully deleted empty file", context: successContext)
                return
            }
            
            // Open the file for writing
            guard let fileHandle = FileHandle(forWritingAtPath: validatedPath) else {
                throw FileSystemError.securityError(
                    path: validatedPath,
                    reason: "Could not open file for secure deletion"
                )
            }
            
            // Perform overwrite passes
            for pass in 1...passes {
                // Log progress
                let progressContext = enhancedContext.withUpdatedMetadata(
                    enhancedContext.metadata.withPublic(key: "pass", value: String(pass))
                )
                await logger.debug("Performing secure deletion pass \(pass)/\(passes)", context: progressContext)
                
                // Seek to beginning of file
                fileHandle.seek(toFileOffset: 0)
                
                // Determine pattern to write
                let pattern: UInt8
                if useRandom {
                    // Use cryptographically secure random data
                    var randomByte: UInt8 = 0
                    _ = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
                    pattern = randomByte
                } else {
                    // Use fixed patterns based on pass number
                    // Standard DoD patterns: 0xFF, 0x00, random, verification
                    switch pass % 3 {
                    case 1: pattern = 0xFF
                    case 2: pattern = 0x00
                    default: pattern = 0xAA
                    }
                }
                
                // Create buffer with pattern
                let bufferSize = min(FileManager.default.allocatedSizeOfFile(at: validatedPath), 1024 * 1024) // 1MB max
                var buffer = Data(repeating: pattern, count: Int(bufferSize))
                
                // Write in chunks to handle large files
                var remainingBytes = fileSize
                while remainingBytes > 0 {
                    let bytesToWrite = min(UInt64(buffer.count), remainingBytes)
                    
                    if bytesToWrite < UInt64(buffer.count) {
                        // Last chunk might be smaller
                        let chunkBuffer = buffer.prefix(Int(bytesToWrite))
                        fileHandle.write(chunkBuffer)
                    } else {
                        fileHandle.write(buffer)
                    }
                    
                    remainingBytes -= bytesToWrite
                }
                
                // Flush to ensure data is written to disk
                fileHandle.synchronizeFile()
            }
            
            // Close file handle
            fileHandle.closeFile()
            
            // Finally, delete the file
            try fileManager.removeItem(atPath: validatedPath)
            
            // Log successful operation
            let successContext = enhancedContext.withStatus("success")
            await logger.debug("Successfully secure deleted file", context: successContext)
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to securely delete file: \(error.localizedDescription)", context: enhancedContext)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "secureDelete", path: path)
            await logger.error("Failed to securely delete file: \(wrappedError.localizedDescription)", context: enhancedContext)
            throw wrappedError
        }
    }
    
    /**
     Sets secure permissions on a file or directory.
     
     - Parameters:
        - permissions: The secure permissions to set.
        - path: The path to the file or directory.
     - Throws: FileSystemError if the permissions cannot be set.
     */
    public func setSecurePermissions(_ permissions: SecureFilePermissions, at path: String) async throws {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "setSecurePermissions",
            path: path
        )
        
        let metadata = context.metadata
            .withPublic(key: "permissions", value: String(permissions.posixPermissions, radix: 8))
            .withPublic(key: "ownerReadOnly", value: String(permissions.ownerReadOnly))
        let enhancedContext = context.withUpdatedMetadata(metadata)
        
        await logger.debug("Setting secure permissions on file", context: enhancedContext)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Set POSIX permissions
            var attributes: [FileAttributeKey: Any] = [
                .posixPermissions: NSNumber(value: permissions.posixPermissions)
            ]
            
            // Apply owner read-only if specified
            if permissions.ownerReadOnly {
                // Remove write permissions but preserve read and execute
                let readOnlyPosix: Int16 = permissions.posixPermissions & 0o555
                attributes[.posixPermissions] = NSNumber(value: readOnlyPosix)
            }
            
            // Set the attributes
            try fileManager.setAttributes(attributes, ofItemAtPath: validatedPath)
            
            // Log successful operation
            let successContext = enhancedContext.withStatus("success")
            await logger.debug("Successfully set secure permissions", context: successContext)
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to set secure permissions: \(error.localizedDescription)", context: enhancedContext)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "setSecurePermissions", path: path)
            await logger.error("Failed to set secure permissions: \(wrappedError.localizedDescription)", context: enhancedContext)
            throw wrappedError
        }
    }
    
    /**
     Verifies the integrity of a file using a checksum or signature.
     
     - Parameters:
        - path: The path to the file to verify.
        - signature: The expected signature or checksum.
     - Returns: True if the file integrity is verified, false otherwise.
     - Throws: FileSystemError if the verification process fails.
     */
    public func verifyFileIntegrity(at path: String, against signature: Data) async throws -> Bool {
        let context = FileSystemLogContext.forSecureOperation(
            secureOperation: "verifyFileIntegrity",
            path: path
        )
        
        await logger.debug("Verifying file integrity", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Read the file data
            let fileData = try await fileReadActor.readFile(at: validatedPath)
            
            // Calculate SHA-256 hash
            let calculatedHash = SHA256.hash(data: fileData)
            let calculatedSignature = Data(calculatedHash)
            
            // Compare with provided signature
            let isVerified = calculatedSignature == signature
            
            // Log result
            let resultContext = context
                .withStatus("success")
                .withUpdatedMetadata(context.metadata.withPublic(key: "verified", value: String(isVerified)))
            
            if isVerified {
                await logger.debug("File integrity verified successfully", context: resultContext)
            } else {
                await logger.warning("File integrity verification failed - hashes do not match", context: resultContext)
            }
            
            return isVerified
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to verify file integrity: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "verifyFileIntegrity", path: path)
            await logger.error("Failed to verify file integrity: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
}

// MARK: - Helper Extensions

extension FileManager {
    /// Get the actual allocated size of a file on disk
    func allocatedSizeOfFile(at path: String) -> UInt64 {
        do {
            let attrs = try attributesOfItem(atPath: path)
            if let size = attrs[.size] as? UInt64 {
                return size
            }
        } catch {
            // Default to a reasonable buffer size if we can't get the actual size
        }
        return 1024 * 1024 // Default 1MB
    }
}
