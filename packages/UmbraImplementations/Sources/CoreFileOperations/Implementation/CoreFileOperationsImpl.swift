import Foundation
import FileSystemInterfaces
import LoggingInterfaces

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
 - Provides comprehensive logging
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
        self.logger = logger ?? NullLogger()
    }
    
    /**
     Reads the contents of a file at the specified path.
     
     - Parameter path: The path to the file to read
     - Returns: The file contents as Data and operation result
     - Throws: If the read operation fails
     */
    public func readFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
        await logger.debug("Reading file at \(path)", metadata: ["path": path])
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", metadata: ["path": path, "error": "\(error)"])
                throw error
            }
            
            // Read the file data
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: ["operation": "readFile", "fileSize": "\(data.count)"]
            )
            
            await logger.debug("Successfully read file at \(path)", metadata: ["path": path, "size": "\(data.count)"])
            return (data, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.readError(path: path, reason: error.localizedDescription)
            await logger.error("Failed to read file: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
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
        await logger.debug("Reading file as string at \(path)", metadata: ["path": path, "encoding": "\(encoding)"])
        
        do {
            let (data, result) = try await readFile(at: path)
            
            guard let string = String(data: data, encoding: encoding) else {
                let error = FileSystemError.readError(
                    path: path,
                    reason: "Could not convert data to string with encoding \(encoding)"
                )
                await logger.error("Failed to convert data to string", metadata: ["path": path, "encoding": "\(encoding)"])
                throw error
            }
            
            let stringResult = FileOperationResultDTO(
                status: result.status,
                path: result.path,
                errorMessage: result.errorMessage,
                metadata: result.metadata,
                context: (result.context ?? [:]).merging(["encoding": "\(encoding)"]) { (_, new) in new }
            )
            
            await logger.debug("Successfully read file as string at \(path)", metadata: ["path": path, "encoding": "\(encoding)"])
            return (string, stringResult)
        } catch {
            await logger.error("Failed to read file as string: \(error.localizedDescription)", metadata: ["path": path, "encoding": "\(encoding)"])
            throw error
        }
    }
    
    /**
     Checks if a file exists at the specified path.
     
     - Parameter path: The path to check
     - Returns: True if the file exists, false otherwise, along with operation result
     */
    public func fileExists(at path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Checking if file exists at \(path)", metadata: ["path": path])
        
        let exists = fileManager.fileExists(atPath: path)
        
        let result = FileOperationResultDTO.success(
            path: path,
            context: ["operation": "fileExists", "exists": "\(exists)"]
        )
        
        await logger.debug("File exists check result: \(exists)", metadata: ["path": path, "exists": "\(exists)"])
        return (exists, result)
    }
    
    /**
     Checks if a path points to a file (not a directory).
     
     - Parameter path: The path to check
     - Returns: True if the path points to a file, false otherwise, along with operation result
     */
    public func isFile(at path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Checking if path is a file at \(path)", metadata: ["path": path])
        
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        let isFile = exists && !isDir.boolValue
        
        let result = FileOperationResultDTO.success(
            path: path,
            context: ["operation": "isFile", "isFile": "\(isFile)"]
        )
        
        await logger.debug("Is file check result: \(isFile)", metadata: ["path": path, "isFile": "\(isFile)"])
        return (isFile, result)
    }
    
    /**
     Checks if a path points to a directory.
     
     - Parameter path: The path to check
     - Returns: True if the path points to a directory, false otherwise, along with operation result
     */
    public func isDirectory(at path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Checking if path is a directory at \(path)", metadata: ["path": path])
        
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        let isDirectory = exists && isDir.boolValue
        
        let result = FileOperationResultDTO.success(
            path: path,
            context: ["operation": "isDirectory", "isDirectory": "\(isDirectory)"]
        )
        
        await logger.debug("Is directory check result: \(isDirectory)", metadata: ["path": path, "isDirectory": "\(isDirectory)"])
        return (isDirectory, result)
    }
    
    /**
     Writes data to a file at the specified path.
     
     - Parameters:
        - data: The data to write
        - path: The path to write to
        - options: Optional write options
     - Returns: Operation result
     - Throws: If the write operation fails
     */
    public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Writing data to file at \(path)", metadata: ["path": path, "size": "\(data.count)"])
        
        do {
            // Create intermediate directories if needed
            if options?.createIntermediateDirectories == true {
                let dirPath = (path as NSString).deletingLastPathComponent
                if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                    try fileManager.createDirectory(
                        atPath: dirPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            }
            
            // Determine write options based on append flag
            let writeOptions: Data.WritingOptions = options?.append == true ? .atomic : .atomicWrite
            
            // Write the data
            try data.write(to: URL(fileURLWithPath: path), options: writeOptions)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: ["operation": "writeFile", "fileSize": "\(data.count)"]
            )
            
            await logger.debug("Successfully wrote data to file at \(path)", metadata: ["path": path, "size": "\(data.count)"])
            return result
        } catch {
            let fileError = FileSystemError.writeError(path: path, reason: error.localizedDescription)
            await logger.error("Failed to write file: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
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
        await logger.debug("Writing string to file at \(path)", metadata: ["path": path, "encoding": "\(encoding)"])
        
        guard let data = string.data(using: encoding) else {
            let error = FileSystemError.writeError(
                path: path,
                reason: "Could not convert string to data with encoding \(encoding)"
            )
            await logger.error("Failed to convert string to data", metadata: ["path": path, "encoding": "\(encoding)"])
            throw error
        }
        
        let result = try await writeFile(data: data, to: path, options: options)
        
        let stringResult = FileOperationResultDTO(
            status: result.status,
            path: result.path,
            errorMessage: result.errorMessage,
            metadata: result.metadata,
            context: (result.context ?? [:]).merging(["encoding": "\(encoding)"]) { (_, new) in new }
        )
        
        await logger.debug("Successfully wrote string to file at \(path)", metadata: ["path": path, "encoding": "\(encoding)"])
        return stringResult
    }
    
    /**
     Normalises a file path according to system rules.
     
     - Parameter path: The path to normalise
     - Returns: The normalised path string
     */
    public func normalisePath(_ path: String) async -> String {
        await logger.debug("Normalising path: \(path)", metadata: ["path": path])
        
        let normalised = (path as NSString).standardizingPath
        
        await logger.debug("Normalised path result: \(normalised)", metadata: ["path": path, "normalised": normalised])
        return normalised
    }
    
    /**
     Gets the path to the temporary directory.
     
     - Returns: The path to the temporary directory
     */
    public func temporaryDirectoryPath() async -> String {
        await logger.debug("Getting temporary directory path")
        
        let tempPath = fileManager.temporaryDirectory.path
        
        await logger.debug("Temporary directory path: \(tempPath)")
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
        await logger.debug("Creating unique filename", metadata: [
            "directory": directory,
            "prefix": prefix ?? "nil",
            "extension": `extension` ?? "nil"
        ])
        
        let uuid = UUID().uuidString
        let prefixString = prefix ?? ""
        let extensionString = `extension` != nil ? ".\(`extension`!)" : ""
        let filename = "\(prefixString)\(uuid)\(extensionString)"
        
        let fullPath = directory.hasSuffix("/") ? "\(directory)\(filename)" : "\(directory)/\(filename)"
        
        await logger.debug("Created unique filename: \(filename)", metadata: ["fullPath": fullPath])
        return fullPath
    }
}
