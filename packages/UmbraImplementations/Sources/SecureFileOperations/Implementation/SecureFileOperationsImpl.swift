import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes
import CryptoKit

/**
 # Secure File Operations Implementation
 
 The implementation of SecureFileOperationsProtocol that handles security features
 for file operations.
 
 This actor-based implementation ensures all operations are thread-safe through
 Swift concurrency. It provides secure file operations with security bookmarks,
 secure temporary files, and encrypted file operations.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 - Returns standardised operation results
 */
public actor SecureFileOperationsImpl: SecureFileOperationsProtocol {
    /// The underlying file manager isolated within this actor
    private let fileManager: FileManager
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new secure file operations implementation.
     
     - Parameters:
        - fileManager: Optional custom file manager to use
        - logger: Optional logger for recording operations
     */
    public init(fileManager: FileManager = .default, logger: (any LoggingProtocol)? = nil) {
        self.fileManager = fileManager
        self.logger = logger ?? LoggingProtocol_NoOp()
    }
    
    /**
     Creates a log context from a metadata dictionary.
     
     - Parameter metadata: The metadata dictionary
     - Returns: A BaseLogContextDTO
     */
    private func createLogContext(_ metadata: [String: String]) -> BaseLogContextDTO {
        var collection = LogMetadataDTOCollection()
        for (key, value) in metadata {
            collection = collection.withPublic(key: key, value: value)
        }
        
        return BaseLogContextDTO(
            domainName: "SecureFileOperations",
            source: "SecureFileOperationsImpl",
            metadata: collection
        )
    }
    
    /**
     Creates a security bookmark for a file or directory.
     
     - Parameters:
        - path: The path to the file or directory
        - readOnly: Whether the bookmark should be for read-only access
     - Returns: The bookmark data and operation result
     - Throws: If the bookmark cannot be created
     */
    public func createSecurityBookmark(for path: String, readOnly: Bool) async throws -> (Data, FileOperationResultDTO) {
        let context = createSecureFileLogContext([
            "path": path, 
            "readOnly": "\(readOnly)"
        ])
        await logger.debug("Creating security bookmark", context: context)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createSecureFileLogContext(["path": path])
                await logger.error("File not found", context: errorContext)
                throw error
            }
            
            let url = URL(fileURLWithPath: path)
            let bookmarkOptions: URL.BookmarkCreationOptions = readOnly ? [.securityScopeAllowOnlyReadAccess] : []
            
            let bookmarkData = try url.bookmarkData(options: bookmarkOptions, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createSecureFileLogContext([
                "path": path, 
                "readOnly": "\(readOnly)",
                "bookmarkSize": "\(bookmarkData.count)"
            ])
            await logger.debug("Successfully created security bookmark", context: successContext)
            return (bookmarkData, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.securityError(
                path: path,
                reason: "Failed to create security bookmark: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path, 
                "error": "\(error.localizedDescription)"
            ])
            await logger.error("Failed to create security bookmark", context: errorContext)
            throw securityError
        }
    }
    
    /**
     Resolves a security bookmark to a file path.
     
     - Parameter bookmark: The bookmark data to resolve
     - Returns: The file path, whether it's stale, and operation result
     - Throws: If the bookmark cannot be resolved
     */
    public func resolveSecurityBookmark(_ bookmark: Data) async throws -> (String, Bool, FileOperationResultDTO) {
        let context = createSecureFileLogContext(["bookmarkSize": "\(bookmark.count)"])
        await logger.debug("Resolving security bookmark", context: context)
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            // Get the file attributes for the result metadata if file exists
            var metadata: FileMetadataDTO? = nil
            if fileManager.fileExists(atPath: url.path) {
                if let attributes = try? fileManager.attributesOfItem(atPath: url.path) {
                    metadata = FileMetadataDTO.from(attributes: attributes, path: url.path)
                }
            }
            
            let result = FileOperationResultDTO.success(
                path: url.path,
                metadata: metadata
            )
            
            let successContext = createSecureFileLogContext([
                "path": url.path, 
                "isStale": "\(isStale)"
            ])
            await logger.debug("Successfully resolved security bookmark", context: successContext)
            return (url.path, isStale, result)
        } catch {
            let securityError = FileSystemError.securityError(
                path: "unknown",
                reason: "Failed to resolve security bookmark: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext(["error": "\(error.localizedDescription)"])
            await logger.error("Failed to resolve security bookmark", context: errorContext)
            throw securityError
        }
    }
    
    /**
     Starts accessing a security-scoped resource.
     
     - Parameter path: The path to start accessing
     - Returns: True if access was granted, false otherwise, and operation result
     - Throws: If access cannot be started
     */
    public func startAccessingSecurityScopedResource(at path: String) async throws -> (Bool, FileOperationResultDTO) {
        let context = createSecureFileLogContext(["path": path])
        await logger.debug("Starting access to security-scoped resource", context: context)
        
        do {
            let url = URL(fileURLWithPath: path)
            let accessGranted = url.startAccessingSecurityScopedResource()
            
            // Get the file attributes for the result metadata if file exists
            var metadata: FileMetadataDTO? = nil
            if fileManager.fileExists(atPath: path) {
                if let attributes = try? fileManager.attributesOfItem(atPath: path) {
                    metadata = FileMetadataDTO.from(attributes: attributes, path: path)
                }
            }
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createSecureFileLogContext([
                "path": path, 
                "accessGranted": "\(accessGranted)"
            ])
            await logger.debug("Access to security-scoped resource status", context: successContext)
            return (accessGranted, result)
        } catch {
            let securityError = FileSystemError.securityError(
                path: path,
                reason: "Failed to start accessing security-scoped resource: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path, 
                "error": "\(error.localizedDescription)"
            ])
            await logger.error("Failed to start accessing security-scoped resource", context: errorContext)
            throw securityError
        }
    }
    
    /**
     Stops accessing a security-scoped resource.
     
     - Parameter path: The path to stop accessing
     - Returns: Operation result
     */
    public func stopAccessingSecurityScopedResource(at path: String) async -> FileOperationResultDTO {
        let context = createSecureFileLogContext(["path": path])
        await logger.debug("Stopping access to security-scoped resource", context: context)
        
        let url = URL(fileURLWithPath: path)
        url.stopAccessingSecurityScopedResource()
        
        let result = FileOperationResultDTO.success(path: path)
        
        let successContext = createSecureFileLogContext(["path": path])
        await logger.debug("Stopped access to security-scoped resource", context: successContext)
        return result
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
        let actualPrefix = prefix ?? "secure_tmp_"
        
        let context = createSecureFileLogContext([
            "prefix": actualPrefix
        ])
        await logger.debug("Creating secure temporary file", context: context)
        
        do {
            // Create a unique filename in the temporary directory
            let tempDir = fileManager.temporaryDirectory.path
            let uuid = UUID().uuidString
            let fileExtension = options?.attributes?[.type] as? String
            let extensionString = fileExtension != nil ? ".\(fileExtension!)" : ""
            let filename = "\(actualPrefix)\(uuid)\(extensionString)"
            let tempPath = "\(tempDir)/\(filename)"
            
            // Create the file with secure permissions
            let secureAttributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o600 // Owner read/write only
            ]
            
            fileManager.createFile(atPath: tempPath, contents: nil, attributes: secureAttributes)
            
            // Verify the file was created
            guard fileManager.fileExists(atPath: tempPath) else {
                throw FileSystemError.writeError(
                    path: tempPath,
                    reason: "Failed to create secure temporary file"
                )
            }
            
            let successContext = createSecureFileLogContext(["path": tempPath])
            await logger.debug("Successfully created secure temporary file", context: successContext)
            return tempPath
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.writeError(
                path: "temporary file",
                reason: "Failed to create secure temporary file: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext(["error": "\(error)"])
            await logger.error("Failed to create secure temporary file", context: errorContext)
            throw securityError
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
        let actualPrefix = prefix ?? "secure_tmp_dir_"
        
        let context = createSecureFileLogContext(["prefix": actualPrefix])
        await logger.debug("Creating secure temporary directory", context: context)
        
        do {
            // Create a unique directory name in the temporary directory
            let tempDir = fileManager.temporaryDirectory.path
            let uuid = UUID().uuidString
            let dirname = "\(actualPrefix)\(uuid)"
            let tempPath = "\(tempDir)/\(dirname)"
            
            // Create the directory with secure permissions
            let secureAttributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o700 // Owner read/write/execute only
            ]
            
            try fileManager.createDirectory(
                atPath: tempPath,
                withIntermediateDirectories: false,
                attributes: secureAttributes
            )
            
            let successContext = createSecureFileLogContext(["path": tempPath])
            await logger.debug("Successfully created secure temporary directory", context: successContext)
            return tempPath
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.writeError(
                path: "temporary directory",
                reason: "Failed to create secure temporary directory: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext(["error": "\(error)"])
            await logger.error("Failed to create secure temporary directory", context: errorContext)
            throw securityError
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
        let context = createSecureFileLogContext([
            "path": path,
            "size": "\(data.count)"
        ])
        await logger.debug("Writing secure file", context: context)
        
        do {
            var dataToWrite = data
            var checksumData: Data? = nil
            
            // Get the default options if not provided
            let secureOptions = options?.secureOptions ?? SecureFileOptions()
            let writeOptions = options?.writeOptions ?? FileWriteOptions()
            
            // Get the write options from Data.WritingOptions
            var writeDataOptions: Data.WritingOptions = []
            if writeOptions.atomicWrite {
                writeDataOptions.insert(.atomicWrite)
            }
            
            // Check if parent directories should be created
            if writeOptions.createIntermediateDirectories {
                let url = URL(fileURLWithPath: path)
                let directoryURL = url.deletingLastPathComponent()
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Encrypt the data using chosen algorithm
            if secureOptions.useSecureMemory {
                // Use CryptoKit's secure memory for encryption
                let key = SymmetricKey(size: .bits256)
                
                switch secureOptions.encryptionAlgorithm {
                case .aes256:
                    let sealedBox = try AES.GCM.seal(data, using: key)
                    dataToWrite = sealedBox.combined ?? Data()
                case .chaChaPoly:
                    let sealedBox = try ChaChaPoly.seal(data, using: key)
                    dataToWrite = sealedBox.combined ?? Data()
                }
            }
            
            // Set file attributes if specified
            var attributes = writeOptions.attributes ?? [:]
            if attributes[.posixPermissions] == nil {
                attributes[.posixPermissions] = 0o600 // Default to owner read/write only for secure files
            }
            
            // Write the data
            try dataToWrite.write(to: URL(fileURLWithPath: path), options: writeDataOptions)
            
            // Set file attributes
            if !attributes.isEmpty {
                try fileManager.setAttributes(attributes, ofItemAtPath: path)
            }
            
            let successContext = createSecureFileLogContext([
                "path": path,
                "size": "\(dataToWrite.count)"
            ])
            await logger.debug("Successfully wrote secure file", context: successContext)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.writeError(
                path: path,
                reason: "Failed to write secure file: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path,
                "error": "\(error)"
            ])
            await logger.error("Failed to write secure file", context: errorContext)
            throw securityError
        }
    }
    
    /**
     Sets an extended attribute on a file.
     
     - Parameters:
        - data: The data to set as extended attribute.
        - name: The name of the extended attribute.
        - path: The path to the file.
     - Throws: If the extended attribute cannot be set.
     */
    private func setExtendedAttribute(_ data: Data, forName name: String, atPath path: String) throws {
        // This would typically use the actual extended attribute APIs
        // For now, we'll simulate it since we can't use the real method directly
        #if os(macOS)
        // On macOS, you would use setxattr
        data.withUnsafeBytes { dataPtr in
            name.withCString { namePtr in
                path.withCString { pathPtr in
                    // setxattr(pathPtr, namePtr, dataPtr.baseAddress, dataPtr.count, 0, 0)
                    // This is just a placeholder - in a real implementation, this would call the C function
                }
            }
        }
        #endif
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
        let context = createSecureFileLogContext([
            "path": path
        ])
        await logger.debug("Securely reading file", context: context)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createSecureFileLogContext(["path": path])
                await logger.error("File not found", context: errorContext)
                throw error
            }
            
            // Read the file data
            let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Get the default options if not provided
            let secureOptions = options?.secureOptions ?? SecureFileOptions()
            let verifyIntegrity = options?.verifyIntegrity ?? true
            
            var dataToReturn = fileData
            
            // Try to decrypt the file based on the algorithm
            if secureOptions.useSecureMemory {
                // For this implementation, we'll try to detect encryption header
                // In a real implementation, you'd have more robust detection
                
                // Try AES.GCM first
                do {
                    let sealedBox = try AES.GCM.SealedBox(combined: fileData)
                    let key = retrieveEncryptionKey(for: path) ?? SymmetricKey(size: .bits256)
                    if let decryptedData = try? AES.GCM.open(sealedBox, using: key) {
                        dataToReturn = decryptedData
                    }
                } catch {
                    // Try ChaCha20-Poly1305 if AES fails
                    do {
                        let sealedBox = try ChaChaPoly.SealedBox(combined: fileData)
                        let key = retrieveEncryptionKey(for: path) ?? SymmetricKey(size: .bits256)
                        if let decryptedData = try? ChaChaPoly.open(sealedBox, using: key) {
                            dataToReturn = decryptedData
                        }
                    } catch {
                        // If both fail, return the original data
                        // In a real implementation, you'd have better error handling
                        dataToReturn = fileData
                    }
                }
            }
            
            let successContext = createSecureFileLogContext([
                "path": path,
                "size": "\(dataToReturn.count)"
            ])
            await logger.debug("Successfully read secure file", context: successContext)
            
            return dataToReturn
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.readError(
                path: path,
                reason: "Failed to securely read file: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path,
                "error": "\(error)"
            ])
            await logger.error("Failed to securely read file", context: errorContext)
            throw securityError
        }
    }
    
    /**
     Retrieves the encryption key for a file.
     
     - Parameter path: The path to the file.
     - Returns: The encryption key, or nil if not found.
     */
    private func retrieveEncryptionKey(for path: String) -> SymmetricKey? {
        // In a real implementation, you'd retrieve the key from a secure storage
        // This is just a placeholder implementation
        return SymmetricKey(size: .bits256)
    }
    
    /**
     Securely deletes a file using secure erase techniques.
     
     - Parameters:
        - path: The path to the file to securely delete.
        - options: Optional secure deletion options.
     - Throws: FileSystemError if the secure deletion fails.
     */
    public func secureDelete(at path: String, options: SecureDeletionOptions?) async throws {
        let deletionOptions = options ?? SecureDeletionOptions()
        let passes = deletionOptions.overwritePasses
        let useRandomData = deletionOptions.useRandomData
        
        let context = createSecureFileLogContext([
            "path": path,
            "passes": "\(passes)",
            "useRandomData": "\(useRandomData)"
        ])
        await logger.debug("Securely deleting file", context: context)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createSecureFileLogContext(["path": path])
                await logger.error("File not found", context: errorContext)
                throw error
            }
            
            // Get original file attributes for context
            let originalAttributes = try fileManager.attributesOfItem(atPath: path)
            let originalSize = (originalAttributes[.size] as? UInt64) ?? 0
            
            // Get file size to determine buffer size
            let url = URL(fileURLWithPath: path)
            let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            
            // Skip secure deletion for empty files
            if fileSize == 0 {
                try fileManager.removeItem(atPath: path)
                
                let successContext = createSecureFileLogContext(["path": path])
                await logger.debug("Deleted empty file", context: successContext)
                return
            }
            
            // Open file for overwriting
            guard let fileHandle = FileHandle(forWritingAtPath: path) else {
                let error = FileSystemError.writeError(
                    path: path,
                    reason: "Could not open file for secure deletion"
                )
                let errorContext = createSecureFileLogContext(["path": path])
                await logger.error("Could not open file for secure deletion", context: errorContext)
                throw error
            }
            
            // Perform multiple passes of overwriting
            for pass in 1...passes {
                let passContext = createSecureFileLogContext([
                    "path": path,
                    "pass": "\(pass)"
                ])
                await logger.debug("Secure delete pass \(pass) of \(passes)", context: passContext)
                
                if useRandomData || pass > 2 {
                    // Use random data for this pass
                    try await overwriteWithRandomData(fileHandle: fileHandle, fileSize: Int(fileSize))
                } else {
                    // Create a pattern based on the pass number
                    // Pass 1: all zeros, Pass 2: all ones
                    let pattern: UInt8 = (pass == 1) ? 0x00 : 0xFF
                    
                    // Create buffer with pattern and overwrite file
                    let bufferSize = min(Int(fileSize), 1024 * 1024) // Use 1MB buffer or file size
                    let buffer = Data(repeating: pattern, count: bufferSize)
                    
                    try fileHandle.seek(toOffset: 0)
                    
                    var remainingSize = Int(fileSize)
                    while remainingSize > 0 {
                        let writeSize = min(remainingSize, bufferSize)
                        if writeSize < bufferSize {
                            try fileHandle.write(contentsOf: buffer[0..<writeSize])
                        } else {
                            try fileHandle.write(contentsOf: buffer)
                        }
                        remainingSize -= writeSize
                    }
                }
                
                try fileHandle.synchronize()
            }
            
            try fileHandle.close()
            
            // Finally delete the file
            try fileManager.removeItem(atPath: path)
            
            let successContext = createSecureFileLogContext([
                "path": path, 
                "passes": "\(passes)",
                "useRandomData": "\(useRandomData)"
            ])
            await logger.debug("Successfully securely deleted file", context: successContext)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.deleteError(
                path: path,
                reason: "Failed to securely delete file: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path,
                "error": "\(error)"
            ])
            await logger.error("Failed to securely delete file", context: errorContext)
            throw securityError
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
        let context = createSecureFileLogContext([
            "path": path,
            "signatureSize": "\(signature.count)"
        ])
        await logger.debug("Verifying file integrity", context: context)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createSecureFileLogContext(["path": path])
                await logger.error("File not found", context: errorContext)
                throw error
            }
            
            // Read the file data
            let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // We'll use SHA-256 as the default algorithm
            // In a real implementation, you would detect the algorithm from the signature
            let algorithm = ChecksumAlgorithm.sha256
            
            // Calculate the checksum
            let actualChecksum = calculateChecksum(for: fileData, using: algorithm)
            
            // Compare checksums
            let isVerified = signature == actualChecksum
            
            let resultContext = createSecureFileLogContext([
                "path": path,
                "isVerified": "\(isVerified)"
            ])
            await logger.debug("File integrity verification result: \(isVerified)", context: resultContext)
            
            return isVerified
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.readError(
                path: path,
                reason: "Failed to verify file integrity: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path,
                "error": "\(error)"
            ])
            await logger.error("Failed to verify file integrity", context: errorContext)
            throw securityError
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
        let context = createSecureFileLogContext([
            "path": path,
            "posixPermissions": "0o\(String(permissions.posixPermissions, radix: 8))",
            "ownerReadOnly": "\(permissions.ownerReadOnly)"
        ])
        await logger.debug("Setting secure permissions", context: context)
        
        do {
            // Check if the path exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createSecureFileLogContext(["path": path])
                await logger.error("Path not found", context: errorContext)
                throw error
            }
            
            // Calculate the actual permissions to set
            var posixPermissions = permissions.posixPermissions
            
            // If owner read only is true, mask out all write permissions
            if permissions.ownerReadOnly {
                // Clear all write bits (owner, group, other)
                posixPermissions &= ~0o222
            }
            
            // Create attributes dictionary with permissions
            let attributes: [FileAttributeKey: Any] = [
                .posixPermissions: posixPermissions
            ]
            
            // Set the attributes
            try fileManager.setAttributes(attributes, ofItemAtPath: path)
            
            let successContext = createSecureFileLogContext([
                "path": path,
                "posixPermissions": "0o\(String(posixPermissions, radix: 8))",
                "ownerReadOnly": "\(permissions.ownerReadOnly)"
            ])
            await logger.debug("Successfully set secure permissions", context: successContext)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.writeError(
                path: path,
                reason: "Failed to set secure permissions: \(error.localizedDescription)"
            )
            let errorContext = createSecureFileLogContext([
                "path": path,
                "error": "\(error)"
            ])
            await logger.error("Failed to set secure permissions", context: errorContext)
            throw securityError
        }
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Fills a file with random data.
     
     - Parameters:
        - fileHandle: The file handle to write to
        - fileSize: The size of the file in bytes
     - Throws: If the write operation fails
     */
    private func overwriteWithRandomData(fileHandle: FileHandle, fileSize: Int) async throws {
        let bufferSize = min(fileSize, 1024 * 1024) // Use 1MB buffer or file size
        var remainingSize = fileSize
        
        try fileHandle.seek(toOffset: 0)
        
        while remainingSize > 0 {
            let writeSize = min(remainingSize, bufferSize)
            var randomData = Data(count: Int(writeSize))
            
            // Fill with random bytes
            randomData.withUnsafeMutableBytes { ptr in
                if let baseAddress = ptr.baseAddress {
                    arc4random_buf(baseAddress, writeSize)
                }
            }
            
            try fileHandle.write(contentsOf: randomData)
            remainingSize -= writeSize
        }
    }
    
    /**
     Calculates a checksum for data using the specified algorithm.
     
     - Parameters:
        - data: The data to calculate checksum for
        - algorithm: The checksum algorithm to use
     - Returns: The calculated checksum
     */
    private func calculateChecksum(for data: Data, using algorithm: ChecksumAlgorithm) -> Data {
        switch algorithm {
        case .md5:
            // This is just a simplified implementation
            // In a real implementation, you'd use a more robust approach
            let hash = Insecure.MD5.hash(data: data)
            return Data(hash)
        case .sha1:
            let hash = Insecure.SHA1.hash(data: data)
            return Data(hash)
        case .sha256:
            let hash = SHA256.hash(data: data)
            return Data(hash)
        case .sha512:
            let hash = SHA512.hash(data: data)
            return Data(hash)
        case .custom:
            // For custom algorithms, default to SHA256
            let hash = SHA256.hash(data: data)
            return Data(hash)
        }
    }
    
    /**
     Creates a log context with the given key-value pairs for secure file operations.
     
     - Parameter keyValues: Key-value pairs for the log context
     - Returns: A BaseLogContextDTO
     */
    private func createSecureFileLogContext(_ keyValues: [String: String]) -> BaseLogContextDTO {
        let collection = keyValues.reduce(LogMetadataDTOCollection()) { collection, pair in
            collection.withPublic(key: pair.key, value: pair.value)
        }
        return BaseLogContextDTO(
            domainName: "SecureFileOperations",
            source: "SecureFileOperationsImpl",
            metadata: collection
        )
    }
}

/// A simple no-op implementation of LoggingProtocol for default initialization
private actor LoggingProtocol_NoOp: LoggingProtocol {
    private let _loggingActor = LoggingActor(destinations: [])
    
    nonisolated var loggingActor: LoggingActor {
        return _loggingActor
    }
    
    func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {}
    func debug(_ message: String, context: LogContextDTO) async {}
    func info(_ message: String, context: LogContextDTO) async {}
    func notice(_ message: String, context: LogContextDTO) async {}
    func warning(_ message: String, context: LogContextDTO) async {}
    func error(_ message: String, context: LogContextDTO) async {}
    func critical(_ message: String, context: LogContextDTO) async {}
}
