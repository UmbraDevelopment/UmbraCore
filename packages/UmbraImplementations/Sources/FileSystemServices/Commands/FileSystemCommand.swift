import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Base protocol for all file system operation commands.
 
 This protocol defines the contract that all file system command implementations
 must fulfil, following the command pattern to encapsulate file operations in
 discrete command objects with a consistent interface.
 */
public protocol FileSystemCommand {
    /// The type of result returned by this command when executed
    associatedtype ResultType
    
    /**
     Executes the file system operation.
     
     - Parameters:
        - context: The logging context for the operation
        - operationID: A unique identifier for this operation instance
     - Returns: The result of the operation
     */
    func execute(
        context: LogContextDTO,
        operationID: String
    ) async -> Result<ResultType, FileSystemError>
}

/**
 Base class for file system commands providing common functionality.
 
 This abstract base class provides shared functionality for all file system commands,
 including access to the file manager, standardised logging, and utility methods
 that are commonly needed across file operations.
 */
public class BaseFileSystemCommand {
    /// The file manager to use for operations
    protected let fileManager: FileManager
    
    /// Optional logger for operation tracking
    protected let logger: LoggingProtocol?
    
    /**
     Initialises a new base file system command.
     
     - Parameters:
        - fileManager: The file manager to use for operations
        - logger: Optional logger for tracking operations
     */
    public init(
        fileManager: FileManager = .default,
        logger: LoggingProtocol? = nil
    ) {
        self.fileManager = fileManager
        self.logger = logger
    }
    
    /**
     Creates a logging context with standardised metadata.
     
     - Parameters:
        - operation: The name of the operation
        - correlationID: Unique identifier for correlation
        - additionalMetadata: Additional metadata for the log context
     - Returns: A configured log context
     */
    protected func createLogContext(
        operation: String,
        correlationID: String,
        additionalMetadata: [(key: String, value: (value: String, privacyLevel: PrivacyLevel))] = []
    ) -> LogContextDTO {
        // Create a base context
        var metadata = LogMetadataDTOCollection()
            .withPublic(key: "operation", value: operation)
            .withPublic(key: "correlationID", value: correlationID)
            .withPublic(key: "component", value: "FileSystemService")
        
        // Add additional metadata with specified privacy levels
        for item in additionalMetadata {
            switch item.value.privacyLevel {
            case .public:
                metadata = metadata.withPublic(key: item.key, value: item.value.value)
            case .protected:
                metadata = metadata.withProtected(key: item.key, value: item.value.value)
            case .private:
                metadata = metadata.withPrivate(key: item.key, value: item.value.value)
            }
        }
        
        return LogContextDTO(metadata: metadata)
    }
    
    /**
     Logs a debug message with the given context.
     
     - Parameters:
        - message: The message to log
        - context: The logging context
     */
    protected func logDebug(_ message: String, context: LogContextDTO) async {
        await logger?.log(.debug, message, context: context)
    }
    
    /**
     Logs an info message with the given context.
     
     - Parameters:
        - message: The message to log
        - context: The logging context
     */
    protected func logInfo(_ message: String, context: LogContextDTO) async {
        await logger?.log(.info, message, context: context)
    }
    
    /**
     Logs a warning message with the given context.
     
     - Parameters:
        - message: The message to log
        - context: The logging context
     */
    protected func logWarning(_ message: String, context: LogContextDTO) async {
        await logger?.log(.warning, message, context: context)
    }
    
    /**
     Logs an error message with the given context.
     
     - Parameters:
        - message: The message to log
        - context: The logging context
     */
    protected func logError(_ message: String, context: LogContextDTO) async {
        await logger?.log(.error, message, context: context)
    }
    
    /**
     Handles normalisation of file paths for consistency.
     
     - Parameter path: The path to normalise
     - Returns: A normalised file path
     */
    protected func normalisePath(_ path: String) -> String {
        // Create an absolute path if not already
        var normalisedPath = path
        if !path.hasPrefix("/") && !path.hasPrefix("~") {
            // Convert to absolute path using current directory
            normalisedPath = fileManager.currentDirectoryPath + "/" + path
        }
        
        // Standardise path by resolving any relative components like ".." or "."
        return (normalisedPath as NSString).standardizingPath
    }
    
    /**
     Validates that a path exists and is of the expected type.
     
     - Parameters:
        - path: The path to validate
        - expectedType: The expected file type (file or directory)
     - Returns: Result with path if valid, error otherwise
     */
    protected func validatePath(
        _ path: String,
        expectedType: FileType
    ) -> Result<String, FileSystemError> {
        let normalisedPath = normalisePath(path)
        var isDirectory: ObjCBool = false
        
        // Check if path exists
        guard fileManager.fileExists(atPath: normalisedPath, isDirectory: &isDirectory) else {
            return .failure(.pathNotFound)
        }
        
        // Check if path is of expected type
        switch expectedType {
        case .file:
            if isDirectory.boolValue {
                return .failure(.invalidPathType(expectedType: .file, actualType: .directory))
            }
        case .directory:
            if !isDirectory.boolValue {
                return .failure(.invalidPathType(expectedType: .directory, actualType: .file))
            }
        }
        
        return .success(normalisedPath)
    }
}
