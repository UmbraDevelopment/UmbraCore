import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # File Sandboxing Factory
 
 Factory for creating file sandboxing instances that handle secure sandboxed
 file system operations.
 
 This factory provides methods for creating sandboxed file system services with
 different configurations, ensuring all file operations are restricted to specific
 directories for enhanced security.
 
 ## Alpha Dot Five Architecture
 
 This factory follows the Alpha Dot Five architecture principles:
 - Provides dependency injection
 - Follows factory pattern for service creation
 - Uses British spelling in documentation
 - Creates properly configured services with appropriate logging
 */
public enum FileSandboxingFactory {
    /**
     Creates a standard file sandboxing service that restricts operations
     to the specified root directory.
     
     - Parameter rootDirectory: The directory to restrict operations to
     - Parameter logger: Optional logger for recording operations
     - Returns: A sandboxed file system service
     */
    public static func createStandardSandbox(
        rootDirectory: String,
        logger: (any LoggingProtocol)? = nil
    ) -> any FileSandboxingProtocol {
        let sandbox = FileSandboxingImpl(rootDirectoryPath: rootDirectory, logger: logger)
        return sandbox
    }
    
    /**
     Creates a test file sandboxing service that restricts operations
     to the specified test directory, with optional test-specific logging.
     
     - Parameters:
        - testRootDirectory: The directory to restrict operations to for testing
        - logger: Optional logger for test-specific logging
     - Returns: A sandboxed file system service for testing
     */
    public static func createTestSandbox(
        testRootDirectory: String,
        logger: (any LoggingProtocol)? = nil
    ) -> any FileSandboxingProtocol {
        let sandbox = FileSandboxingImpl(rootDirectoryPath: testRootDirectory, logger: logger)
        return sandbox
    }
    
    /**
     Creates a privacy-aware file sandboxing service with comprehensive logging.
     
     - Parameters:
        - rootDirectory: The directory to restrict operations to
        - logger: The privacy-aware logger to use for recording operations
     - Returns: A sandboxed file system service with privacy-aware logging
     */
    public static func createPrivacyAwareSandbox(
        rootDirectory: String,
        logger: any LoggingProtocol
    ) -> any FileSandboxingProtocol {
        let sandbox = FileSandboxingImpl(rootDirectoryPath: rootDirectory, logger: logger)
        return sandbox
    }
}
