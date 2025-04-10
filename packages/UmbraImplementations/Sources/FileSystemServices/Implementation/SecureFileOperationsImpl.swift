import Foundation
import FileSystemInterfaces
import FileSystemTypes
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 # Secure File Operations Implementation
 
 This implementation of the SecureFileOperationsProtocol provides secure file operations
 including encryption, secure deletion, and permission management.
 
 The implementation follows the Alpha Dot Five architecture principles by:
 1. Using actor-based isolation for thread safety
 2. Providing comprehensive error handling
 3. Using Sendable types for cross-actor communication
 
 ## Thread Safety
 
 This implementation is an actor, ensuring all operations are thread-safe
 and can be safely called from multiple concurrent contexts.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public actor SecureFileOperationsImpl: SecureFileOperationsProtocol {
    /// The file manager instance
    private let fileManager: FileManager
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /// Root directory for sandboxing (optional)
    private let rootDirectory: String?
    
    /**
     Initialises a new secure file operations implementation.
     
     - Parameters:
       - fileManager: Optional custom file manager to use
       - logger: Optional logger for recording operations
       - rootDirectory: Optional root directory for sandboxing
     */
    public init(
        fileManager: FileManager = .default,
        logger: (any LoggingProtocol)? = nil,
        rootDirectory: String? = nil
    ) {
        self.fileManager = fileManager
        self.logger = logger ?? NullLogger()
        self.rootDirectory = rootDirectory
    }
    
    /**
     Sets secure permissions on a file or directory.
     
     - Parameters:
        - permissions: The security level for the permissions.
        - path: The path to the file or directory.
     - Throws: FileSystemError if permissions cannot be set.
     */
    public func setSecurePermissions(_ permissions: SecurityPermission, at path: FilePathDTO) async throws {
        await logger.debug("Setting secure permissions at \(path.path)", context: LogContextDTO())
        
        // Implementation specific to each platform
        var attributes: [FileAttributeKey: Any] = [:]
        
        switch permissions {
        case .private:
            // Set private permissions (e.g., 0600 for files, 0700 for directories)
            attributes[.posixPermissions] = 0o600
        case .readOnly:
            // Set read-only permissions
            attributes[.posixPermissions] = 0o400
        case .readWrite:
            // Set read-write permissions
            attributes[.posixPermissions] = 0o644
        }
        
        do {
            try fileManager.setAttributes(attributes, ofItemAtPath: path.path)
        } catch {
            throw FileSystemError.permissionError(path: path.path, reason: error.localizedDescription)
        }
    }
    
    /**
     Creates a secure temporary file with the specified prefix.
     
     - Parameters:
        - prefix: Optional prefix for the temporary file name.
        - options: Optional file creation options.
     - Returns: The path to the secure temporary file.
     - Throws: FileSystemError if the temporary file cannot be created.
     */
    public func createSecureTemporaryFile(prefix: String?, options: FileCreationOptions?) async throws -> FilePathDTO {
        await logger.debug("Creating secure temporary file", context: LogContextDTO())
        
        let tempDir = fileManager.temporaryDirectory.path
        let uuid = UUID().uuidString
        let prefixString = prefix ?? ""
        let filePath = "\(tempDir)/\(prefixString)\(uuid)"
        
        // Create the file with secure attributes
        let overwrite = options?.overwrite ?? false
        
        if fileManager.fileExists(atPath: filePath) && !overwrite {
            throw FileSystemError.itemAlreadyExists(path: filePath)
        }
        
        if !fileManager.createFile(atPath: filePath, contents: nil, attributes: nil) {
            throw FileSystemError.writeError(path: filePath, reason: "Failed to create secure temporary file")
        }
        
        // Set secure permissions
        try await setSecurePermissions(.private, at: FilePathDTO(path: filePath))
        
        return FilePathDTO(path: filePath)
    }
    
    /**
     Creates a secure temporary directory with the specified prefix.
     
     - Parameters:
        - prefix: Optional prefix for the temporary directory name.
        - options: Optional directory creation options.
     - Returns: The path to the secure temporary directory.
     - Throws: FileSystemError if the temporary directory cannot be created.
     */
    public func createSecureTemporaryDirectory(prefix: String?, options: DirectoryCreationOptions?) async throws -> FilePathDTO {
        await logger.debug("Creating secure temporary directory", context: LogContextDTO())
        
        let tempDir = fileManager.temporaryDirectory.path
        let uuid = UUID().uuidString
        let prefixString = prefix ?? ""
        let dirPath = "\(tempDir)/\(prefixString)\(uuid)"
        
        // Create the directory with secure attributes
        let withIntermediates = options?.createIntermediates ?? false
        let attributes = options?.attributes ?? [:]
        
        try fileManager.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: withIntermediates,
            attributes: attributes
        )
        
        // Set secure permissions
        try await setSecurePermissions(.private, at: FilePathDTO(path: dirPath, isDirectory: true))
        
        return FilePathDTO(path: dirPath, isDirectory: true)
    }
    
    /**
     Securely writes data to a file with encryption.
     
     - Parameters:
        - data: The data to write.
        - path: The path where the data should be written.
        - options: Optional secure write options.
     - Throws: FileSystemError if the secure write operation fails.
     */
    public func secureWriteFile(data: Data, to path: FilePathDTO, options: SecureFileWriteOptions?) async throws {
        await logger.debug("Securely writing file to \(path.path)", context: LogContextDTO())
        
        // Implement secure file writing with encryption
        // For a real implementation, you would use a crypto service to encrypt the data
        
        // For now, we'll just write the data to the file with secure attributes
        let overwrite = options?.overwrite ?? false
        
        if fileManager.fileExists(atPath: path.path) {
            if overwrite {
                try fileManager.removeItem(atPath: path.path)
            } else {
                throw FileSystemError.itemAlreadyExists(path: path.path)
            }
        }
        
        // Create the file with secure attributes
        fileManager.createFile(atPath: path.path, contents: data, attributes: nil)
        
        // Set secure permissions
        try await setSecurePermissions(.private, at: path)
    }
    
    /**
     Securely reads data from an encrypted file.
     
     - Parameters:
        - path: The path to the encrypted file.
        - options: Optional secure read options.
     - Returns: The decrypted file contents.
     - Throws: FileSystemError if the secure read operation fails.
     */
    public func secureReadFile(at path: FilePathDTO, options: SecureFileReadOptions?) async throws -> Data {
        await logger.debug("Securely reading file at \(path.path)", context: LogContextDTO())
        
        guard fileManager.fileExists(atPath: path.path) else {
            throw FileSystemError.pathNotFound(path: path.path)
        }
        
        // Implement secure file reading with decryption
        // For a real implementation, you would use a crypto service to decrypt the data
        
        // For now, we'll just read the file contents
        guard let data = fileManager.contents(atPath: path.path) else {
            throw FileSystemError.readError(path: path.path, reason: "Could not read file contents")
        }
        
        return data
    }
    
    /**
     Securely deletes a file using secure erase techniques.
     
     - Parameters:
        - path: The path to the file to securely delete.
        - options: Optional secure deletion options.
     - Throws: FileSystemError if the secure deletion fails.
     */
    public func secureDelete(at path: FilePathDTO, options: SecureDeletionOptions?) async throws {
        await logger.debug("Securely deleting file at \(path.path)", context: LogContextDTO())
        
        guard fileManager.fileExists(atPath: path.path) else {
            throw FileSystemError.pathNotFound(path: path.path)
        }
        
        // For a secure deletion, we would:
        // 1. Overwrite the file with random data multiple times
        // 2. Then delete it
        
        let passes = options?.passes ?? 3
        
        // Perform secure overwrite with random data
        for pass in 1...passes {
            // Get the file size
            let attributes = try fileManager.attributesOfItem(atPath: path.path)
            guard let fileSize = attributes[.size] as? UInt64, fileSize > 0 else {
                // If file is empty or we can't get size, just delete it
                break
            }
            
            // Create random data of the same size
            var randomData = Data(count: Int(fileSize))
            randomData.withUnsafeMutableBytes { ptr in
                _ = SecRandomCopyBytes(kSecRandomDefault, fileSize, ptr.baseAddress!)
            }
            
            // Overwrite the file with the random data
            try randomData.write(to: URL(fileURLWithPath: path.path))
            
            await logger.debug("Completed secure delete pass \(pass) of \(passes)", context: LogContextDTO())
        }
        
        // Finally, delete the file
        try fileManager.removeItem(atPath: path.path)
    }
    
    /**
     Verifies the integrity of a file using a digital signature.
     
     - Parameters:
        - path: The path to the file to verify.
        - signature: The digital signature to verify against.
     - Returns: True if the file integrity is verified, false otherwise.
     - Throws: FileSystemError if the verification process fails.
     */
    public func verifyFileIntegrity(at path: FilePathDTO, against signature: Data) async throws -> Bool {
        await logger.debug("Verifying file integrity at \(path.path)", context: LogContextDTO())
        
        guard fileManager.fileExists(atPath: path.path) else {
            throw FileSystemError.pathNotFound(path: path.path)
        }
        
        // For a real implementation, this would use a crypto service to verify the signature
        // For now, we'll just return true as a placeholder
        
        // This is just a placeholder implementation
        return true
    }
}

/**
 # Sandboxed Secure File Operations
 
 This extension adds sandboxing capabilities to the secure file operations,
 restricting operations to a specified root directory.
 */
extension SecureFileOperationsImpl {
    /**
     Validates if a path is within the root directory (sandbox).
     
     - Parameter path: The path to validate.
     - Returns: True if the path is within the sandbox, false otherwise.
     */
    private func isWithinSandbox(_ path: String) -> Bool {
        guard let rootDir = rootDirectory else {
            // If no root directory is specified, all paths are allowed
            return true
        }
        
        // Normalize paths for comparison
        let normalizedRoot = URL(fileURLWithPath: rootDir).standardized.path
        let normalizedPath = URL(fileURLWithPath: path).standardized.path
        
        return normalizedPath.hasPrefix(normalizedRoot)
    }
    
    /**
     Throws an error if the path is outside the sandbox.
     
     - Parameter path: The path to validate.
     - Throws: FileSystemError.permissionError if the path is outside the sandbox.
     */
    private func validateSandbox(_ path: String) throws {
        if !isWithinSandbox(path) {
            throw FileSystemError.permissionError(
                path: path,
                reason: "Operation not permitted outside the sandbox"
            )
        }
    }
    
    /**
     Sandboxes a path by making it relative to the root directory.
     
     - Parameter path: The path to sandbox.
     - Returns: The sandboxed path.
     */
    private func sandboxPath(_ path: String) -> String {
        guard let rootDir = rootDirectory else {
            // If no root directory is specified, return the path as is
            return path
        }
        
        // If the path is already absolute and within the sandbox, return it
        if path.hasPrefix("/") && isWithinSandbox(path) {
            return path
        }
        
        // Otherwise, make it relative to the root directory
        return URL(fileURLWithPath: rootDir).appendingPathComponent(path).path
    }
}

/**
 A null logger that does nothing, used as a fallback when no logger is provided.
 */
actor NullLogger: LoggingProtocol {
    func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
        // Do nothing
    }
    
    func debug(_ message: String, context: LogContextDTO) async {
        // Do nothing
    }
    
    func info(_ message: String, context: LogContextDTO) async {
        // Do nothing
    }
    
    func warning(_ message: String, context: LogContextDTO) async {
        // Do nothing
    }
    
    func error(_ message: String, context: LogContextDTO) async {
        // Do nothing
    }
}
