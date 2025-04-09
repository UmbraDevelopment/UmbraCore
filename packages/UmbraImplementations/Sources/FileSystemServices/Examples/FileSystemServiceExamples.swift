import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # File System Service Examples
 
 This file contains examples of how to use the actor-based file system services.
 These examples demonstrate the recommended patterns for:
 
 1. Getting an appropriate file system service from the factory
 2. Performing various file operations using the actor-based APIs
 3. Handling errors properly
 4. Ensuring proper privacy controls in logging
 
 ## Alpha Dot Five Architecture
 
 The examples follow the Alpha Dot Five architecture principles:
 1. Using actor-based concurrency for thread safety
 2. Implementing comprehensive error handling
 3. Using proper British spelling in documentation
 4. Ensuring privacy-aware logging
 5. Following Swift concurrency best practices
 */

/// Examples of basic file system operations
public enum FileSystemServiceExamples {
    
    /**
     Demonstrates basic file reading and writing operations.
     
     This example shows:
     - Getting a standard actor-based file system service
     - Writing a string to a file
     - Reading the file back as a string
     - Proper error handling and cleanup
     */
    public static func basicReadWriteExample() async {
        // Get a logger using LoggingServiceFactory (privacy-aware)
        let logger = await LoggingServiceFactory.shared.createPrivacyAwareLogger(
            source: "FileSystemExamples",
            category: .fileSystem,
            privacyLevel: .moderate
        )
        
        // Get a file system service using our actor-based implementation
        let fileSystem = await FileSystemServiceFactory.shared.createActorBasedService(
            logger: logger
        )
        
        let tempFile = await fileSystem.createUniqueFilename(
            in: await fileSystem.temporaryDirectoryPath(),
            prefix: "example",
            extension: "txt"
        )
        
        do {
            // Write content to the file
            let content = "Hello, World! This is an example file."
            try await fileSystem.writeString(
                content,
                to: tempFile,
                encoding: .utf8,
                options: FileWriteOptions(overwrite: true)
            )
            
            // Read the content back
            let readContent = try await fileSystem.readFileAsString(
                at: tempFile,
                encoding: .utf8
            )
            
            await logger.info("Successfully wrote and read file content: \(readContent.count) characters", context: nil)
            
            // Clean up
            try await fileSystem.delete(at: tempFile)
        } catch {
            // Log and handle errors properly
            if let fileError = error as? FileSystemError {
                await logger.error("File operation failed: \(fileError.localizedDescription)", context: nil)
            } else {
                await logger.error("Unexpected error: \(error.localizedDescription)", context: nil)
            }
        }
    }
    
    /**
     Demonstrates secure file operations.
     
     This example shows:
     - Getting a secure actor-based file system service
     - Creating a secure temporary file
     - Writing encrypted content to the file
     - Reading and decrypting the content
     - Securely deleting the file when done
     */
    public static func secureFileOperationsExample() async {
        // Get a logger using LoggingServiceFactory (privacy-aware)
        let logger = await LoggingServiceFactory.shared.createPrivacyAwareLogger(
            source: "FileSystemExamples",
            category: .security,
            privacyLevel: .high
        )
        
        // Get a secure file system service using our actor-based implementation
        let fileSystem = await FileSystemServiceFactory.shared.createSecureActorBasedService(
            securityLevel: .high,
            logger: logger
        )
        
        // Access secure operations interface
        let secureOps = fileSystem.secureOperations
        
        do {
            // Create a secure temporary file
            let secureFile = try await secureOps.createSecureTemporaryFile(
                prefix: "secure-example",
                options: FileCreationOptions(attributes: [.posixPermissions: 0o600])
            )
            
            // Prepare sensitive data
            let sensitiveData = "This is confidential information that should be properly secured.".data(using: .utf8)!
            
            // Write data securely with encryption
            try await secureOps.secureWriteFile(
                data: sensitiveData,
                to: secureFile,
                options: SecureFileWriteOptions(
                    secureOptions: SecureFileOptions(encryptionAlgorithm: .aes256),
                    writeOptions: FileWriteOptions(overwrite: true)
                )
            )
            
            // Read data securely with decryption
            let decryptedData = try await secureOps.secureReadFile(
                at: secureFile,
                options: SecureFileReadOptions()
            )
            
            // Verify data integrity
            let decryptedString = String(data: decryptedData, encoding: .utf8)
            await logger.info(
                "Successfully processed secure data of \(decryptedData.count) bytes",
                context: nil
            )
            
            // Securely delete the file when done
            try await secureOps.secureDelete(
                at: secureFile,
                options: SecureDeletionOptions(
                    overwritePasses: 3,
                    useRandomData: true
                )
            )
        } catch {
            // Log and handle errors properly
            if let fileError = error as? FileSystemError {
                await logger.error("Secure file operation failed: \(fileError.localizedDescription)", context: nil)
            } else {
                await logger.error("Unexpected error in secure operations: \(error.localizedDescription)", context: nil)
            }
        }
    }
    
    /**
     Demonstrates file metadata operations.
     
     This example shows:
     - Getting a standard actor-based file system service
     - Creating a file with specific attributes
     - Setting and getting attributes
     - Working with extended attributes for custom metadata
     */
    public static func metadataOperationsExample() async {
        // Get a logger using LoggingServiceFactory (privacy-aware)
        let logger = await LoggingServiceFactory.shared.createPrivacyAwareLogger(
            source: "FileSystemExamples",
            category: .fileSystem,
            privacyLevel: .moderate
        )
        
        // Get a file system service
        let fileSystem = await FileSystemServiceFactory.shared.createActorBasedService(
            logger: logger
        )
        
        let tempFile = await fileSystem.createUniqueFilename(
            in: await fileSystem.temporaryDirectoryPath(),
            prefix: "metadata-example",
            extension: "txt"
        )
        
        do {
            // Create a file with specific attributes
            try await fileSystem.writeString(
                "File with custom metadata",
                to: tempFile,
                encoding: .utf8,
                options: FileWriteOptions(
                    overwrite: true,
                    attributes: [.posixPermissions: 0o644]
                )
            )
            
            // Get file attributes
            let attrs = try await fileSystem.getAttributes(at: tempFile)
            let fileSize = try await fileSystem.getFileSize(at: tempFile)
            let creationDate = try await fileSystem.getCreationDate(at: tempFile)
            
            await logger.info(
                "File metadata: size=\(fileSize) bytes, created=\(creationDate.timeIntervalSince1970)",
                context: nil
            )
            
            // Set an extended attribute
            let metadata = "Custom file metadata".data(using: .utf8)!
            try await fileSystem.setExtendedAttribute(
                metadata,
                withName: "com.example.customMetadata",
                onItemAtPath: tempFile
            )
            
            // List all extended attributes
            let xattrs = try await fileSystem.listExtendedAttributes(atPath: tempFile)
            await logger.info("Extended attributes: \(xattrs.joined(separator: ", "))", context: nil)
            
            // Read back the extended attribute
            let readMetadata = try await fileSystem.getExtendedAttribute(
                withName: "com.example.customMetadata",
                fromItemAtPath: tempFile
            )
            
            if let metadataString = String(data: readMetadata, encoding: .utf8) {
                await logger.info("Retrieved metadata: \(metadataString)", context: nil)
            }
            
            // Clean up
            try await fileSystem.delete(at: tempFile)
        } catch {
            if let fileError = error as? FileSystemError {
                await logger.error("Metadata operation failed: \(fileError.localizedDescription)", context: nil)
            } else {
                await logger.error("Unexpected error: \(error.localizedDescription)", context: nil)
            }
        }
    }
    
    /**
     Demonstrates high-performance file operations for large files.
     
     This example shows:
     - Getting a high-performance actor-based file system service
     - Working with large files efficiently
     - Proper resource management and cleanup
     */
    public static func highPerformanceExample() async {
        // Get a logger using LoggingServiceFactory (privacy-aware)
        let logger = await LoggingServiceFactory.shared.createPrivacyAwareLogger(
            source: "FileSystemExamples",
            category: .fileSystem,
            privacyLevel: .low
        )
        
        // Get a high-performance file system service
        let fileSystem = await FileSystemServiceFactory.shared.createHighPerformanceActorBasedService(
            logger: logger
        )
        
        let largeTempFile = await fileSystem.createUniqueFilename(
            in: await fileSystem.temporaryDirectoryPath(),
            prefix: "large-file",
            extension: "dat"
        )
        
        do {
            // Generate a somewhat large dataset (10MB for example)
            let dataSize = 10 * 1024 * 1024 // 10MB
            var largeData = Data(count: dataSize)
            
            // Fill with random bytes (optional)
            largeData.withUnsafeMutableBytes { ptr in
                let buffer = ptr.bindMemory(to: UInt8.self)
                for i in 0..<buffer.count {
                    buffer[i] = UInt8.random(in: 0...255)
                }
            }
            
            await logger.info("Writing \(dataSize) bytes to large file", context: nil)
            
            // Time the operation
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Write the large data
            try await fileSystem.writeFile(
                data: largeData,
                to: largeTempFile,
                options: FileWriteOptions(overwrite: true)
            )
            
            // Read it back to verify
            let readData = try await fileSystem.readFile(at: largeTempFile)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let elapsedTime = endTime - startTime
            
            // Verify integrity
            let dataMatches = readData.count == largeData.count
            
            await logger.info(
                "High-performance operation completed in \(elapsedTime) seconds, data integrity: \(dataMatches)",
                context: nil
            )
            
            // Clean up
            try await fileSystem.delete(at: largeTempFile)
        } catch {
            if let fileError = error as? FileSystemError {
                await logger.error("High-performance operation failed: \(fileError.localizedDescription)", context: nil)
            } else {
                await logger.error("Unexpected error: \(error.localizedDescription)", context: nil)
            }
        }
    }
}
