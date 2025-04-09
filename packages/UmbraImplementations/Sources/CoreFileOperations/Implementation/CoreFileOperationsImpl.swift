import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # Core File Operations Implementation
 
 The implementation of CoreFileOperationsProtocol that provides the fundamental
 file system operations.
 
 This actor-based implementation ensures all operations are thread-safe through
 Swift concurrency. It provides the core functionality for file reading, writing,
 and basic file system queries.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 - Returns standardised operation results
 */
public actor CoreFileOperationsImpl: CoreFileOperationsProtocol {
    /// The underlying file manager isolated within this actor
    private let fileManager: FileManager
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new core file operations implementation.
     
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
            domainName: "CoreFileOperations",
            source: "CoreFileOperationsImpl",
            metadata: collection
        )
    }

    /**
     Reads the contents of a file at the specified path.
     
     - Parameter path: The path to the file to read
     - Returns: The file contents as Data and operation result
     - Throws: If the read operation fails
     */
    public func readFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Reading file at \(path)", context: context)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createLogContext(["path": path, "error": "\(error)"])
                await logger.error("File not found: \(path)", context: errorContext)
                throw error
            }
            
            // Read the file data
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path, "size": "\(data.count)"])
            await logger.debug("Successfully read file", context: successContext)
            return (data, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.readError(path: path, reason: error.localizedDescription)
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to read file: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Reads the contents of a file at the specified path as a string.
     
     - Parameters:
        - path: The path to the file to read
        - encoding: The string encoding to use
     - Returns: The file contents as a String and operation result
     - Throws: If the read operation fails
     */
    public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext(["path": path, "encoding": "\(encoding)"])
        await logger.debug("Reading file as string", context: context)
        
        do {
            let (data, result) = try await readFile(at: path)
            
            guard let string = String(data: data, encoding: encoding) else {
                let error = FileSystemError.readError(
                    path: path,
                    reason: "Could not decode data with encoding \(encoding)"
                )
                let errorContext = createLogContext(["path": path, "encoding": "\(encoding)"])
                await logger.error("Failed to decode file content with specified encoding", context: errorContext)
                throw error
            }
            
            let successContext = createLogContext(["path": path, "encoding": "\(encoding)", "length": "\(string.count)"])
            await logger.debug("Successfully read file as string", context: successContext)
            return (string, result)
        } catch {
            throw error // Pass through any errors from readFile
        }
    }
    
    /**
     Checks if a file exists at the specified path.
     
     - Parameter path: The path to check
     - Returns: True if the file exists, false otherwise, along with operation result
     */
    public func fileExists(at path: String) async -> (Bool, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Checking if file exists", context: context)
        
        let exists = fileManager.fileExists(atPath: path)
        
        var metadata: FileMetadataDTO? = nil
        if exists {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            } catch {
                let errorContext = createLogContext(["path": path, "error": "\(error)"])
                await logger.warning("File exists but failed to get attributes", context: errorContext)
            }
        }
        
        let result = FileOperationResultDTO.success(
            path: path,
            metadata: metadata
        )
        
        let successContext = createLogContext(["path": path, "exists": "\(exists)"])
        await logger.debug("File exists check result", context: successContext)
        return (exists, result)
    }
    
    /**
     Checks if a path points to a file (not a directory).
     
     - Parameter path: The path to check
     - Returns: True if the path points to a file, false otherwise, along with operation result
     */
    public func isFile(at path: String) async -> (Bool, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Checking if path is a file", context: context)
        
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        let isFile = exists && !isDir.boolValue
        
        var metadata: FileMetadataDTO? = nil
        if exists {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            } catch {
                let errorContext = createLogContext(["path": path, "error": "\(error)"])
                await logger.warning("Path exists but failed to get attributes", context: errorContext)
            }
        }
        
        let result = FileOperationResultDTO.success(
            path: path,
            metadata: metadata
        )
        
        let successContext = createLogContext(["path": path, "isFile": "\(isFile)"])
        await logger.debug("Is file check result", context: successContext)
        return (isFile, result)
    }
    
    /**
     Checks if a path points to a directory.
     
     - Parameter path: The path to check
     - Returns: True if the path points to a directory, false otherwise, along with operation result
     */
    public func isDirectory(at path: String) async -> (Bool, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Checking if path is a directory", context: context)
        
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        let isDirectory = exists && isDir.boolValue
        
        var metadata: FileMetadataDTO? = nil
        if exists {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            } catch {
                let errorContext = createLogContext(["path": path, "error": "\(error)"])
                await logger.warning("Path exists but failed to get attributes", context: errorContext)
            }
        }
        
        let result = FileOperationResultDTO.success(
            path: path,
            metadata: metadata
        )
        
        let successContext = createLogContext(["path": path, "isDirectory": "\(isDirectory)"])
        await logger.debug("Is directory check result", context: successContext)
        return (isDirectory, result)
    }
    
    /**
     Writes data to a file at the specified path.
     
     - Parameters:
        - data: The data to write
        - path: The path where the data should be written
        - options: Optional write options
     - Returns: The operation result
     - Throws: If the write operation fails
     */
    public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path, "size": "\(data.count)"])
        await logger.debug("Writing file", context: context)
        
        do {
            // Create intermediate directories if needed
            if options?.createIntermediateDirectories == true {
                let directoryPath = (path as NSString).deletingLastPathComponent
                try fileManager.createDirectory(
                    atPath: directoryPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            
            // Write the file
            if options?.append == true {
                // Append to existing file
                let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                // Write or overwrite the file
                try data.write(to: URL(fileURLWithPath: path), options: options?.atomicWrite == true ? .atomic : [])
            }
            
            // Set attributes if specified
            if let attributes = options?.attributes {
                try fileManager.setAttributes(attributes, ofItemAtPath: path)
            }
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path, "size": "\(data.count)"])
            await logger.debug("Successfully wrote file", context: successContext)
            return result
        } catch {
            let fileError = FileSystemError.writeError(path: path, reason: error.localizedDescription)
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to write file: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Writes a string to a file at the specified path.
     
     - Parameters:
        - string: The string to write
        - path: The path to write to
        - encoding: The string encoding to use
        - options: Optional write options
     - Returns: Operation result
     - Throws: If the write operation fails
     */
    public func writeString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path, "encoding": "\(encoding)"])
        await logger.debug("Writing string to file", context: context)
        
        guard let data = string.data(using: encoding) else {
            let error = FileSystemError.writeError(
                path: path,
                reason: "Could not convert string to data with encoding \(encoding)"
            )
            let errorContext = createLogContext(["path": path, "encoding": "\(encoding)"])
            await logger.error("Failed to convert string to data", context: errorContext)
            throw error
        }
        
        let result = try await writeFile(data: data, to: path, options: options)
        
        let successContext = createLogContext(["path": path, "encoding": "\(encoding)"])
        await logger.debug("Successfully wrote string to file", context: successContext)
        return result
    }
    
    /**
     Writes a string to a file at the specified path.
     
     - Parameters:
        - string: The string to write
        - path: The path where the string should be written
        - encoding: The string encoding to use
        - options: Optional write options
     - Returns: The operation result
     - Throws: If the write operation fails
     */
    public func writeFileFromString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path, "encoding": "\(encoding)", "length": "\(string.count)"])
        await logger.debug("Writing string to file", context: context)
        
        guard let data = string.data(using: encoding) else {
            let error = FileSystemError.writeError(
                path: path,
                reason: "Could not encode string with encoding \(encoding)"
            )
            let errorContext = createLogContext(["path": path, "encoding": "\(encoding)"])
            await logger.error("Failed to encode string with specified encoding", context: errorContext)
            throw error
        }
        
        return try await writeFile(data: data, to: path, options: options)
    }
    
    /**
     Gets the URLs of all files in a directory.
     
     - Parameter path: Path to the directory
     - Returns: A tuple containing an array of file URLs and the operation result
     - Throws: FileSystemError if the directory cannot be read
     */
    public func getFileURLs(in path: String) async throws -> ([URL], FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Getting file URLs in directory", context: context)
        
        do {
            // Check if directory exists
            var isDir: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
            
            guard exists else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createLogContext(["path": path])
                await logger.error("Directory not found", context: errorContext)
                throw error
            }
            
            guard isDir.boolValue else {
                let error = FileSystemError.readError(path: path, reason: "Path is not a directory")
                let errorContext = createLogContext(["path": path])
                await logger.error("Path is not a directory", context: errorContext)
                throw error
            }
            
            // Get contents of directory
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            let urls = contents.map { URL(fileURLWithPath: path).appendingPathComponent($0) }
            
            // Get directory attributes for result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path, "count": "\(urls.count)"])
            await logger.debug("Retrieved file URLs", context: successContext)
            return (urls, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let dirError = FileSystemError.readError(path: path, reason: error.localizedDescription)
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to get file URLs: \(error.localizedDescription)", context: errorContext)
            throw dirError
        }
    }
    
    /**
     Creates a directory at the specified path.
     
     - Parameters:
        - path: Path where the directory should be created
        - options: Optional directory creation options
     - Returns: A tuple containing the created directory path and the operation result
     - Throws: FileSystemError if directory creation fails
     */
    public func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Creating directory", context: context)
        
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true, // Always create intermediate directories
                attributes: options?.attributes
            )
            
            // Get directory attributes for result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path])
            await logger.debug("Successfully created directory", context: successContext)
            return (path, result)
        } catch {
            let dirError = FileSystemError.writeError(
                path: path,
                reason: "Failed to create directory: \(error.localizedDescription)"
            )
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to create directory: \(error.localizedDescription)", context: errorContext)
            throw dirError
        }
    }
    
    /**
     Creates a file at the specified path.
     
     - Parameters:
        - path: Path where the file should be created
        - options: Optional file creation options
     - Returns: A tuple containing the created file path and the operation result
     - Throws: FileSystemError if file creation fails
     */
    public func createFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Creating file", context: context)
        
        do {
            // Check if file already exists and shouldOverwrite is false
            let shouldOverwrite = options?.shouldOverwrite ?? false
            if fileManager.fileExists(atPath: path) && !shouldOverwrite {
                let error = FileSystemError.writeError(
                    path: path,
                    reason: "File already exists and overwrite not allowed"
                )
                let errorContext = createLogContext(["path": path])
                await logger.error("File already exists and overwrite not allowed", context: errorContext)
                throw error
            }
            
            // Create parent directories if needed
            let directoryPath = (path as NSString).deletingLastPathComponent
            if !fileManager.fileExists(atPath: directoryPath) {
                try fileManager.createDirectory(
                    atPath: directoryPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            
            // Create the file
            let success = fileManager.createFile(
                atPath: path,
                contents: nil,
                attributes: options?.attributes
            )
            
            guard success else {
                let error = FileSystemError.writeError(
                    path: path,
                    reason: "Failed to create file"
                )
                let errorContext = createLogContext(["path": path])
                await logger.error("Failed to create file", context: errorContext)
                throw error
            }
            
            // Get file attributes for result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path])
            await logger.debug("Successfully created file", context: successContext)
            return (path, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.writeError(
                path: path,
                reason: "Failed to create file: \(error.localizedDescription)"
            )
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to create file: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Deletes a file or directory at the specified path.
     
     - Parameter path: Path to the file or directory to delete
     - Returns: The operation result
     - Throws: FileSystemError if the delete operation fails
     */
    public func delete(at path: String) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path])
        await logger.debug("Deleting item", context: context)
        
        do {
            // Check if the path exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createLogContext(["path": path])
                await logger.error("Path not found for deletion", context: errorContext)
                throw error
            }
            
            // Get attributes before deletion for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            // Delete the item
            try fileManager.removeItem(atPath: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path])
            await logger.debug("Successfully deleted item", context: successContext)
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let deleteError = FileSystemError.deleteError(path: path, reason: error.localizedDescription)
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to delete item: \(error.localizedDescription)", context: errorContext)
            throw deleteError
        }
    }
    
    /**
     Moves a file or directory from one path to another.
     
     - Parameters:
        - sourcePath: Path to the file or directory to move
        - destinationPath: Path where the file or directory should be moved
        - options: Optional move options
     - Returns: The operation result
     - Throws: FileSystemError if the move operation fails
     */
    public func move(from sourcePath: String, to destinationPath: String, options: FileMoveOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext([
            "sourcePath": sourcePath,
            "destinationPath": destinationPath
        ])
        await logger.debug("Moving item", context: context)
        
        do {
            // Check if source exists
            guard fileManager.fileExists(atPath: sourcePath) else {
                let error = FileSystemError.pathNotFound(path: sourcePath)
                let errorContext = createLogContext(["path": sourcePath])
                await logger.error("Source path not found for move operation", context: errorContext)
                throw error
            }
            
            // Create parent directory for destination if needed
            let destinationDir = (destinationPath as NSString).deletingLastPathComponent
            if !fileManager.fileExists(atPath: destinationDir) {
                try fileManager.createDirectory(
                    atPath: destinationDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            
            // Check if destination exists and should overwrite
            let shouldOverwrite = options?.shouldOverwrite ?? false
            if fileManager.fileExists(atPath: destinationPath) && !shouldOverwrite {
                let error = FileSystemError.moveError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Destination already exists and overwrite not allowed"
                )
                let errorContext = createLogContext([
                    "sourcePath": sourcePath,
                    "destinationPath": destinationPath
                ])
                await logger.error("Destination already exists and overwrite not allowed", context: errorContext)
                throw error
            }
            
            // Remove destination if it exists and we're overwriting
            if fileManager.fileExists(atPath: destinationPath) && shouldOverwrite {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Move the item
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
            
            // Get attributes after move
            let attributes = try fileManager.attributesOfItem(atPath: destinationPath)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: destinationPath)
            
            let result = FileOperationResultDTO.success(
                path: destinationPath,
                metadata: metadata
            )
            
            let successContext = createLogContext([
                "sourcePath": sourcePath,
                "destinationPath": destinationPath
            ])
            await logger.debug("Successfully moved item", context: successContext)
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let moveError = FileSystemError.moveError(
                source: sourcePath,
                destination: destinationPath,
                reason: error.localizedDescription
            )
            let errorContext = createLogContext([
                "sourcePath": sourcePath,
                "destinationPath": destinationPath,
                "error": "\(error)"
            ])
            await logger.error("Failed to move item: \(error.localizedDescription)", context: errorContext)
            throw moveError
        }
    }
    
    /**
     Copies a file or directory from one path to another.
     
     - Parameters:
        - sourcePath: Path to the file or directory to copy
        - destinationPath: Path where the file or directory should be copied
        - options: Optional copy options
     - Returns: The operation result
     - Throws: FileSystemError if the copy operation fails
     */
    public func copy(from sourcePath: String, to destinationPath: String, options: FileCopyOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext([
            "sourcePath": sourcePath,
            "destinationPath": destinationPath
        ])
        await logger.debug("Copying item", context: context)
        
        do {
            // Check if source exists
            guard fileManager.fileExists(atPath: sourcePath) else {
                let error = FileSystemError.pathNotFound(path: sourcePath)
                let errorContext = createLogContext(["path": sourcePath])
                await logger.error("Source path not found for copy operation", context: errorContext)
                throw error
            }
            
            // Create parent directory for destination if needed
            let destinationDir = (destinationPath as NSString).deletingLastPathComponent
            if !fileManager.fileExists(atPath: destinationDir) {
                try fileManager.createDirectory(
                    atPath: destinationDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            
            // Check if destination exists and should overwrite
            let shouldOverwrite = options?.shouldOverwrite ?? false
            if fileManager.fileExists(atPath: destinationPath) && !shouldOverwrite {
                let error = FileSystemError.copyError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Destination already exists and overwrite not allowed"
                )
                let errorContext = createLogContext([
                    "sourcePath": sourcePath,
                    "destinationPath": destinationPath
                ])
                await logger.error("Destination already exists and overwrite not allowed", context: errorContext)
                throw error
            }
            
            // Remove destination if it exists and we're overwriting
            if fileManager.fileExists(atPath: destinationPath) && shouldOverwrite {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Copy the item
            try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
            
            // Get attributes after copy
            let attributes = try fileManager.attributesOfItem(atPath: destinationPath)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: destinationPath)
            
            let result = FileOperationResultDTO.success(
                path: destinationPath,
                metadata: metadata
            )
            
            let successContext = createLogContext([
                "sourcePath": sourcePath,
                "destinationPath": destinationPath
            ])
            await logger.debug("Successfully copied item", context: successContext)
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let copyError = FileSystemError.copyError(
                source: sourcePath,
                destination: destinationPath,
                reason: error.localizedDescription
            )
            let errorContext = createLogContext([
                "sourcePath": sourcePath,
                "destinationPath": destinationPath,
                "error": "\(error)"
            ])
            await logger.error("Failed to copy item: \(error.localizedDescription)", context: errorContext)
            throw copyError
        }
    }
    
    /**
     Gets a list of all files and directories in a directory, recursively.
     
     - Parameter path: Path to the directory
     - Returns: A tuple containing an array of paths and the operation result
     - Throws: FileSystemError if the directory cannot be read
     */
    public func listDirectoryRecursively(at path: String) async throws -> ([String], FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Listing directory recursively", context: context)
        
        do {
            // Check if directory exists
            var isDir: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
            
            guard exists else {
                let error = FileSystemError.pathNotFound(path: path)
                let errorContext = createLogContext(["path": path])
                await logger.error("Directory not found", context: errorContext)
                throw error
            }
            
            guard isDir.boolValue else {
                let error = FileSystemError.readError(path: path, reason: "Path is not a directory")
                let errorContext = createLogContext(["path": path])
                await logger.error("Path is not a directory", context: errorContext)
                throw error
            }
            
            // Function to recursively enumerate directory
            func enumerateDirectory(_ dirPath: String) throws -> [String] {
                let contents = try fileManager.contentsOfDirectory(atPath: dirPath)
                var allPaths: [String] = []
                
                for item in contents {
                    let fullPath = (dirPath as NSString).appendingPathComponent(item)
                    allPaths.append(fullPath)
                    
                    var isItemDir: ObjCBool = false
                    if fileManager.fileExists(atPath: fullPath, isDirectory: &isItemDir) && isItemDir.boolValue {
                        let subDirContents = try enumerateDirectory(fullPath)
                        allPaths.append(contentsOf: subDirContents)
                    }
                }
                
                return allPaths
            }
            
            // Get all paths recursively
            let allPaths = try enumerateDirectory(path)
            
            // Get attributes for result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = createLogContext(["path": path, "count": "\(allPaths.count)"])
            await logger.debug("Successfully listed directory recursively", context: successContext)
            return (allPaths, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let dirError = FileSystemError.readError(path: path, reason: error.localizedDescription)
            let errorContext = createLogContext(["path": path, "error": "\(error)"])
            await logger.error("Failed to list directory: \(error.localizedDescription)", context: errorContext)
            throw dirError
        }
    }
    
    /**
     Normalises a file path according to system rules.
     
     - Parameter path: The path to normalise
     - Returns: The normalised path string
     */
    public func normalisePath(_ path: String) async -> String {
        let context = createLogContext(["path": path])
        await logger.debug("Normalising path", context: context)
        
        let normalised = (path as NSString).standardizingPath
        
        let successContext = createLogContext(["path": path, "normalised": normalised])
        await logger.debug("Normalised path result", context: successContext)
        return normalised
    }
    
    /**
     Gets the path to the temporary directory.
     
     - Returns: The path to the temporary directory
     */
    private func temporaryDirectoryPath() async -> String {
        let context = createLogContext([:])
        await logger.debug("Getting temporary directory path", context: context)
        
        let tempPath = fileManager.temporaryDirectory.path
        
        let resultContext = createLogContext(["tempPath": tempPath])
        await logger.debug("Temporary directory path: \(tempPath)", context: resultContext)
        return tempPath
    }
    
    /**
     Creates a unique filename in the specified directory.
     
     - Parameters:
        - directory: The directory to create the filename in
        - prefix: Optional prefix for the filename
        - extension: Optional file extension
     - Returns: The unique filename
     */
    public func createUniqueFilename(in directory: String, prefix: String?, extension: String?) async -> String {
        let context = createLogContext([
            "directory": directory,
            "prefix": prefix ?? "nil",
            "extension": `extension` ?? "nil"
        ])
        await logger.debug("Creating unique filename", context: context)
        
        let uuid = UUID().uuidString
        let prefixString = prefix ?? ""
        let extensionString = `extension` != nil ? ".\(`extension`!)" : ""
        let filename = "\(prefixString)\(uuid)\(extensionString)"
        
        let fullPath = directory.hasSuffix("/") ? "\(directory)\(filename)" : "\(directory)/\(filename)"
        
        let successContext = createLogContext(["fullPath": fullPath])
        await logger.debug("Created unique filename", context: successContext)
        return fullPath
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
