import Foundation

/**
 # File Operation Result DTO
 
 A data transfer object that represents the result of a file system operation.
 
 This standardised result format makes error handling more consistent across
 the file system operations and provides a richer context about the operation
 outcome.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Implements Sendable for safe concurrent access
 - Provides clear, well-documented properties
 - Uses British spelling in documentation
 */
public struct FileOperationResultDTO: Sendable, Equatable {
    /// Status of the file operation
    public enum Status: String, Sendable, Equatable {
        /// Operation completed successfully
        case success
        
        /// Operation failed to complete
        case failure
        
        /// Operation completed with warnings
        case partialSuccess
    }
    
    /// Status of the operation
    public let status: Status
    
    /// Path to the file or directory involved in the operation
    public let path: String
    
    /// Error message if the operation failed
    public let errorMessage: String?
    
    /// Optional metadata about the file or directory
    public let metadata: FileMetadataDTO?
    
    /// Optional additional context about the operation
    public let context: [String: String]?
    
    /**
     Creates a new file operation result DTO.
     
     - Parameters:
        - status: Status of the operation
        - path: Path to the file or directory
        - errorMessage: Error message if the operation failed
        - metadata: Optional metadata about the file or directory
        - context: Optional additional context about the operation
     */
    public init(
        status: Status,
        path: String,
        errorMessage: String? = nil,
        metadata: FileMetadataDTO? = nil,
        context: [String: String]? = nil
    ) {
        self.status = status
        self.path = path
        self.errorMessage = errorMessage
        self.metadata = metadata
        self.context = context
    }
    
    /**
     Creates a success result.
     
     - Parameters:
        - path: Path to the file or directory
        - metadata: Optional metadata about the file or directory
        - context: Optional additional context about the operation
     - Returns: A success result DTO
     */
    public static func success(
        path: String,
        metadata: FileMetadataDTO? = nil,
        context: [String: String]? = nil
    ) -> FileOperationResultDTO {
        return FileOperationResultDTO(
            status: .success,
            path: path,
            errorMessage: nil,
            metadata: metadata,
            context: context
        )
    }
    
    /**
     Creates a failure result.
     
     - Parameters:
        - path: Path to the file or directory
        - errorMessage: Error message describing the failure
        - metadata: Optional metadata about the file or directory
        - context: Optional additional context about the operation
     - Returns: A failure result DTO
     */
    public static func failure(
        path: String,
        errorMessage: String,
        metadata: FileMetadataDTO? = nil,
        context: [String: String]? = nil
    ) -> FileOperationResultDTO {
        return FileOperationResultDTO(
            status: .failure,
            path: path,
            errorMessage: errorMessage,
            metadata: metadata,
            context: context
        )
    }
    
    /**
     Creates a partial success result.
     
     - Parameters:
        - path: Path to the file or directory
        - warningMessage: Warning message describing the issues
        - metadata: Optional metadata about the file or directory
        - context: Optional additional context about the operation
     - Returns: A partial success result DTO
     */
    public static func partialSuccess(
        path: String,
        warningMessage: String,
        metadata: FileMetadataDTO? = nil,
        context: [String: String]? = nil
    ) -> FileOperationResultDTO {
        return FileOperationResultDTO(
            status: .partialSuccess,
            path: path,
            errorMessage: warningMessage,
            metadata: metadata,
            context: context
        )
    }
}
