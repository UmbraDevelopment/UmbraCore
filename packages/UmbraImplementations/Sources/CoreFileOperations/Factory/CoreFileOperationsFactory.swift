import Foundation
import FileSystemInterfaces
import LoggingInterfaces

/**
 # Core File Operations Factory
 
 A factory class for creating CoreFileOperationsProtocol instances.
 
 This factory provides a clean way to instantiate core file operations
 implementations with proper dependencies.
 
 ## Alpha Dot Five Architecture
 
 This factory follows the Alpha Dot Five architecture principles:
 - Provides dependency injection
 - Supports creation of both standard and testing instances
 - Follows British spelling in documentation
 */
public enum CoreFileOperationsFactory {
    /**
     Creates a standard implementation of CoreFileOperationsProtocol.
     
     - Parameters:
        - fileManager: Optional custom file manager to use
        - logger: Optional logger for recording operations
     - Returns: A new CoreFileOperationsProtocol instance
     */
    public static func createStandardOperations(
        fileManager: FileManager = .default,
        logger: (any LoggingProtocol)? = nil
    ) -> any CoreFileOperationsProtocol {
        return CoreFileOperationsImpl(
            fileManager: fileManager,
            logger: logger
        )
    }
    
    /**
     Creates a test-friendly implementation of CoreFileOperationsProtocol.
     
     This method can be used in tests to create an implementation with
     a mock file manager and logger.
     
     - Parameters:
        - fileManager: The test file manager to use
        - logger: The test logger to use
     - Returns: A new CoreFileOperationsProtocol instance for testing
     */
    public static func createTestOperations(
        fileManager: FileManager,
        logger: any LoggingProtocol
    ) -> any CoreFileOperationsProtocol {
        return CoreFileOperationsImpl(
            fileManager: fileManager,
            logger: logger
        )
    }
}
