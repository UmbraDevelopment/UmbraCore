import Foundation
import FileSystemInterfaces
import LoggingInterfaces
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
        self.logger = logger ?? NullLogger()
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
        await logger.debug("Creating security bookmark for \(path)", metadata: ["path": path, "readOnly": "\(readOnly)"])
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", metadata: ["path": path])
                throw error
            }
            
            let url = URL(fileURLWithPath: path)
            let bookmarkOptions: URL.BookmarkCreationOptions = readOnly ? [.securityScopeAllowOnlyReadAccess] : []
            
            let bookmarkData = try url.bookmarkData(options: bookmarkOptions, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: [
                    "operation": "createSecurityBookmark",
                    "readOnly": "\(readOnly)",
                    "bookmarkSize": "\(bookmarkData.count)"
                ]
            )
            
            await logger.debug("Successfully created security bookmark for \(path)", metadata: ["path": path, "readOnly": "\(readOnly)"])
            return (bookmarkData, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.securityBookmarkError(
                reason: "Failed to create security bookmark: \(error.localizedDescription)"
            )
            await logger.error("Failed to create security bookmark: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
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
        await logger.debug("Resolving security bookmark", metadata: ["bookmarkSize": "\(bookmark.count)"])
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            // Get the file attributes for the result metadata if file exists
            var metadata: FileMetadataDTO? = nil
            if fileManager.fileExists(atPath: url.path) {
                if let attributes = try? fileManager.attributesOfItem(atPath: url.path) {
                    metadata = FileMetadataDTO.from(attributes: attributes)
                }
            }
            
            let result = FileOperationResultDTO.success(
                path: url.path,
                metadata: metadata,
                context: [
                    "operation": "resolveSecurityBookmark",
                    "isStale": "\(isStale)"
                ]
            )
            
            await logger.debug("Successfully resolved security bookmark to \(url.path)", metadata: ["path": url.path, "isStale": "\(isStale)"])
            return (url.path, isStale, result)
        } catch {
            let securityError = FileSystemError.securityBookmarkError(
                reason: "Failed to resolve security bookmark: \(error.localizedDescription)"
            )
            await logger.error("Failed to resolve security bookmark: \(error.localizedDescription)", metadata: ["error": "\(error)"])
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
        await logger.debug("Starting access to security-scoped resource at \(path)", metadata: ["path": path])
        
        do {
            let url = URL(fileURLWithPath: path)
            let accessGranted = url.startAccessingSecurityScopedResource()
            
            // Get the file attributes for the result metadata if file exists
            var metadata: FileMetadataDTO? = nil
            if fileManager.fileExists(atPath: path) {
                if let attributes = try? fileManager.attributesOfItem(atPath: path) {
                    metadata = FileMetadataDTO.from(attributes: attributes)
                }
            }
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: [
                    "operation": "startAccessingSecurityScopedResource",
                    "accessGranted": "\(accessGranted)"
                ]
            )
            
            await logger.debug("Access to security-scoped resource at \(path): \(accessGranted)", metadata: ["path": path, "accessGranted": "\(accessGranted)"])
            return (accessGranted, result)
        } catch {
            let securityError = FileSystemError.securityScopedResourceError(
                path: path,
                reason: "Failed to start accessing security-scoped resource: \(error.localizedDescription)"
            )
            await logger.error("Failed to start accessing security-scoped resource: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
            throw securityError
        }
    }
    
    /**
     Stops accessing a security-scoped resource.
     
     - Parameter path: The path to stop accessing
     - Returns: Operation result
     */
    public func stopAccessingSecurityScopedResource(at path: String) async -> FileOperationResultDTO {
        await logger.debug("Stopping access to security-scoped resource at \(path)", metadata: ["path": path])
        
        let url = URL(fileURLWithPath: path)
        url.stopAccessingSecurityScopedResource()
        
        let result = FileOperationResultDTO.success(
            path: path,
            context: ["operation": "stopAccessingSecurityScopedResource"]
        )
        
        await logger.debug("Stopped access to security-scoped resource at \(path)", metadata: ["path": path])
        return result
    }
    
    /**
     Creates a temporary file with secure permissions.
     
     - Parameter options: Optional options for creating the temporary file
     - Returns: The path to the created file and operation result
     - Throws: If the file cannot be created
     */
    public func createSecureTemporaryFile(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO) {
        let prefix = options?.prefix ?? "secure_tmp_"
        let extension = options?.extension
        
        await logger.debug("Creating secure temporary file", metadata: [
            "prefix": prefix,
            "extension": extension ?? "nil"
        ])
        
        do {
            // Create a unique filename in the temporary directory
            let tempDir = fileManager.temporaryDirectory.path
            let uuid = UUID().uuidString
            let extensionString = extension != nil ? ".\(extension!)" : ""
            let filename = "\(prefix)\(uuid)\(extensionString)"
            let tempPath = "\(tempDir)/\(filename)"
            
            // Create the file with secure permissions
            let secureAttributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o600 // Owner read/write only
            ]
            
            fileManager.createFile(atPath: tempPath, contents: nil, attributes: secureAttributes)
            
            // Verify the file was created
            guard fileManager.fileExists(atPath: tempPath) else {
                throw FileSystemError.createError(
                    path: tempPath,
                    reason: "Failed to create secure temporary file"
                )
            }
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: tempPath)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: tempPath,
                metadata: metadata,
                context: ["operation": "createSecureTemporaryFile"]
            )
            
            await logger.debug("Successfully created secure temporary file at \(tempPath)", metadata: ["path": tempPath])
            return (tempPath, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.createError(
                path: "temporary file",
                reason: "Failed to create secure temporary file: \(error.localizedDescription)"
            )
            await logger.error("Failed to create secure temporary file: \(error.localizedDescription)", metadata: ["error": "\(error)"])
            throw securityError
        }
    }
    
    /**
     Creates a temporary directory with secure permissions.
     
     - Parameter options: Optional options for creating the temporary directory
     - Returns: The path to the created directory and operation result
     - Throws: If the directory cannot be created
     */
    public func createSecureTemporaryDirectory(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO) {
        let prefix = options?.prefix ?? "secure_tmp_dir_"
        
        await logger.debug("Creating secure temporary directory", metadata: ["prefix": prefix])
        
        do {
            // Create a unique directory name in the temporary directory
            let tempDir = fileManager.temporaryDirectory.path
            let uuid = UUID().uuidString
            let dirname = "\(prefix)\(uuid)"
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
            
            // Get the directory attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: tempPath)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: tempPath,
                metadata: metadata,
                context: ["operation": "createSecureTemporaryDirectory"]
            )
            
            await logger.debug("Successfully created secure temporary directory at \(tempPath)", metadata: ["path": tempPath])
            return (tempPath, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.createDirectoryError(
                path: "temporary directory",
                reason: "Failed to create secure temporary directory: \(error.localizedDescription)"
            )
            await logger.error("Failed to create secure temporary directory: \(error.localizedDescription)", metadata: ["error": "\(error)"])
            throw securityError
        }
    }
    
    /**
     Securely writes data to a file with encryption.
     
     - Parameters:
        - data: The data to write
        - path: The path to write to
        - options: Optional secure write options
     - Returns: Operation result
     - Throws: If the write operation fails
     */
    public func writeSecureFile(data: Data, to path: String, options: SecureFileOptions?) async throws -> FileOperationResultDTO {
        let secureOptions = options ?? SecureFileOptions.default
        
        await logger.debug("Writing secure file to \(path)", metadata: [
            "path": path,
            "size": "\(data.count)",
            "encrypted": "\(secureOptions.encryptData)",
            "verifyIntegrity": "\(secureOptions.verifyIntegrity)"
        ])
        
        do {
            var dataToWrite = data
            var checksumData: Data? = nil
            var context: [String: String] = [
                "operation": "writeSecureFile",
                "fileSize": "\(data.count)"
            ]
            
            // Encrypt the data if requested
            if secureOptions.encryptData {
                if let encryptionKey = secureOptions.encryptionKey {
                    dataToWrite = try encryptData(data, withKey: encryptionKey)
                    context["encrypted"] = "true"
                } else {
                    // Generate a random key and encrypt
                    let key = SymmetricKey(size: .bits256)
                    let keyData = key.withUnsafeBytes { Data($0) }
                    dataToWrite = try encryptData(data, withKey: keyData)
                    context["encrypted"] = "true"
                    context["keyGenerated"] = "true"
                    
                    // Store the encryption key as an extended attribute if we generated it
                    // This is just for demo purposes - in a real implementation you'd store it securely
                    if fileManager.fileExists(atPath: path) {
                        try? fileManager.setExtendedAttribute(keyData, forName: "com.umbra.encryptionKey", atPath: path)
                    }
                }
            }
            
            // Calculate checksum for integrity verification if requested
            if secureOptions.verifyIntegrity, let algorithm = secureOptions.checksumAlgorithm {
                checksumData = calculateChecksum(for: data, using: algorithm)
                context["integrity"] = "true"
                context["checksumAlgorithm"] = algorithm.name
            }
            
            // Write the data atomically
            try dataToWrite.write(to: URL(fileURLWithPath: path), options: .atomicWrite)
            
            // Store the checksum as an extended attribute if we calculated it
            if let checksumData = checksumData, fileManager.fileExists(atPath: path) {
                try? fileManager.setExtendedAttribute(checksumData, forName: "com.umbra.checksum", atPath: path)
            }
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: context
            )
            
            await logger.debug("Successfully wrote secure file to \(path)", metadata: ["path": path, "size": "\(dataToWrite.count)"])
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.writeError(
                path: path,
                reason: "Failed to write secure file: \(error.localizedDescription)"
            )
            await logger.error("Failed to write secure file: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
            throw securityError
        }
    }
    
    /**
     Securely deletes a file by overwriting its contents before removal.
     
     - Parameters:
        - path: The path to the file to delete
        - passes: Number of overwrite passes (default is 3)
     - Returns: Operation result
     - Throws: If the secure delete operation fails
     */
    public func secureDelete(at path: String, passes: Int = 3) async throws -> FileOperationResultDTO {
        await logger.debug("Securely deleting file at \(path)", metadata: ["path": path, "passes": "\(passes)"])
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", metadata: ["path": path])
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
                
                let result = FileOperationResultDTO.success(
                    path: path,
                    context: [
                        "operation": "secureDelete",
                        "passes": "0",
                        "reason": "Empty file"
                    ]
                )
                
                await logger.debug("Deleted empty file at \(path)", metadata: ["path": path])
                return result
            }
            
            // Open file for overwriting
            guard let fileHandle = FileHandle(forWritingAtPath: path) else {
                let error = FileSystemError.permissionError(
                    path: path,
                    reason: "Could not open file for secure deletion"
                )
                await logger.error("Could not open file for secure deletion", metadata: ["path": path])
                throw error
            }
            
            // Perform multiple passes of overwriting
            for pass in 1...passes {
                await logger.debug("Secure delete pass \(pass) of \(passes)", metadata: ["path": path, "pass": "\(pass)"])
                
                // Create a pattern based on the pass number
                // Pass 1: all zeros, Pass 2: all ones, Pass 3+: random data
                var pattern: UInt8
                if pass == 1 {
                    pattern = 0x00
                } else if pass == 2 {
                    pattern = 0xFF
                } else {
                    // For subsequent passes, use random data
                    try await overwriteWithRandomData(fileHandle: fileHandle, fileSize: fileSize)
                    continue
                }
                
                // Create buffer with pattern and overwrite file
                let bufferSize = min(fileSize, 1024 * 1024) // Use 1MB buffer or file size
                let buffer = Data(repeating: pattern, count: Int(bufferSize))
                
                try fileHandle.seekToOffset(0)
                
                var remainingSize = fileSize
                while remainingSize > 0 {
                    let writeSize = min(remainingSize, bufferSize)
                    if writeSize < bufferSize {
                        try fileHandle.write(contentsOf: buffer[0..<Int(writeSize)])
                    } else {
                        try fileHandle.write(contentsOf: buffer)
                    }
                    remainingSize -= writeSize
                }
                
                try fileHandle.synchronize()
            }
            
            try fileHandle.close()
            
            // Finally delete the file
            try fileManager.removeItem(atPath: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                context: [
                    "operation": "secureDelete",
                    "passes": "\(passes)",
                    "originalSize": "\(originalSize)"
                ]
            )
            
            await logger.debug("Successfully securely deleted file at \(path)", metadata: ["path": path, "passes": "\(passes)"])
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let securityError = FileSystemError.deleteError(
                path: path,
                reason: "Failed to securely delete file: \(error.localizedDescription)"
            )
            await logger.error("Failed to securely delete file: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
            throw securityError
        }
    }
    
    /**
     Verifies the integrity of a file using a checksum.
     
     - Parameters:
        - path: The path to the file to verify
        - expectedChecksum: The expected checksum
        - algorithm: The checksum algorithm to use
     - Returns: True if the file integrity is verified, false otherwise, and operation result
     - Throws: If the verification fails
     */
    public func verifyFileIntegrity(at path: String, expectedChecksum: Data, algorithm: ChecksumAlgorithm) async throws -> (Bool, FileOperationResultDTO) {
        await logger.debug("Verifying file integrity at \(path)", metadata: [
            "path": path,
            "algorithm": algorithm.name
        ])
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", metadata: ["path": path])
                throw error
            }
            
            // Read the file data
            let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Calculate the checksum
            let actualChecksum = calculateChecksum(for: fileData, using: algorithm)
            
            // Compare checksums
            let isVerified = expectedChecksum == actualChecksum
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: [
                    "operation": "verifyFileIntegrity",
                    "algorithm": algorithm.name,
                    "verified": "\(isVerified)",
                    "fileSize": "\(fileData.count)"
                ]
            )
            
            await logger.debug("File integrity verification result: \(isVerified)", metadata: [
                "path": path,
                "verified": "\(isVerified)"
            ])
            
            return (isVerified, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let integrityError = FileSystemError.integrityError(
                path: path,
                reason: "Failed to verify file integrity: \(error.localizedDescription)"
            )
            await logger.error("Failed to verify file integrity: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
            throw integrityError
        }
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Overwrites a file with random data.
     
     - Parameters:
        - fileHandle: The file handle
        - fileSize: The size of the file
     - Throws: If writing fails
     */
    private func overwriteWithRandomData(fileHandle: FileHandle, fileSize: Int) async throws {
        let bufferSize = min(fileSize, 1024 * 1024) // Use 1MB buffer or file size
        var remainingSize = fileSize
        
        try fileHandle.seekToOffset(0)
        
        while remainingSize > 0 {
            let writeSize = min(remainingSize, bufferSize)
            var randomData = Data(count: Int(writeSize))
            
            // Fill with random bytes
            _ = randomData.withUnsafeMutableBytes { ptr in
                if let baseAddress = ptr.baseAddress {
                    arc4random_buf(baseAddress, writeSize)
                }
            }
            
            try fileHandle.write(contentsOf: randomData)
            remainingSize -= writeSize
        }
        
        try fileHandle.synchronize()
    }
    
    /**
     Encrypts data using CryptoKit.
     
     - Parameters:
        - data: The data to encrypt
        - key: The encryption key
     - Returns: The encrypted data
     - Throws: If encryption fails
     */
    private func encryptData(_ data: Data, withKey key: Data) throws -> Data {
        // This is a simplified implementation for demonstration
        // In a real implementation, you'd use more robust encryption
        
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        
        return sealedBox.combined ?? Data()
    }
    
    /**
     Calculates a checksum for data using the specified algorithm.
     
     - Parameters:
        - data: The data to calculate checksum for
        - algorithm: The checksum algorithm to use
     - Returns: The checksum data
     */
    private func calculateChecksum(for data: Data, using algorithm: ChecksumAlgorithm) -> Data {
        switch algorithm {
        case .md5:
            let digest = Insecure.MD5.hash(data: data)
            return Data(digest)
            
        case .sha1:
            let digest = Insecure.SHA1.hash(data: data)
            return Data(digest)
            
        case .sha256:
            let digest = SHA256.hash(data: data)
            return Data(digest)
            
        case .sha512:
            let digest = SHA512.hash(data: data)
            return Data(digest)
            
        case .custom:
            // For custom algorithms, default to SHA256
            let digest = SHA256.hash(data: data)
            return Data(digest)
        }
    }
}
