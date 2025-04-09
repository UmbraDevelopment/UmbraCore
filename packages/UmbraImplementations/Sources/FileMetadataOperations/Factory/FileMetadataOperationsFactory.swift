import Foundation
import FileSystemInterfaces
import LoggingInterfaces

/**
 # File Metadata Operations Factory
 
 A factory class for creating FileMetadataOperationsProtocol instances.
 
 This factory provides a clean way to instantiate file metadata operations
 implementations with proper dependencies.
 
 ## Alpha Dot Five Architecture
 
 This factory follows the Alpha Dot Five architecture principles:
 - Provides dependency injection
 - Supports creation of both standard and testing instances
 - Follows British spelling in documentation
 */
public enum FileMetadataOperationsFactory {
    /**
     Creates a standard implementation of FileMetadataOperationsProtocol.
     
     - Parameters:
        - fileManager: Optional custom file manager to use
        - logger: Optional logger for recording operations
     - Returns: A new FileMetadataOperationsProtocol instance
     */
    public static func createStandardOperations(
        fileManager: FileManager = .default,
        logger: (any LoggingProtocol)? = nil
    ) -> any FileMetadataOperationsProtocol {
        return FileMetadataOperationsImpl(
            fileManager: fileManager,
            logger: logger
        )
    }
    
    /**
     Creates a test-friendly implementation of FileMetadataOperationsProtocol.
     
     This method can be used in tests to create an implementation with
     a mock file manager and logger.
     
     - Parameters:
        - fileManager: The test file manager to use
        - logger: The test logger to use
     - Returns: A new FileMetadataOperationsProtocol instance for testing
     */
    public static func createTestOperations(
        fileManager: FileManager,
        logger: any LoggingProtocol
    ) -> any FileMetadataOperationsProtocol {
        return FileMetadataOperationsImpl(
            fileManager: fileManager,
            logger: logger
        )
    }
}
