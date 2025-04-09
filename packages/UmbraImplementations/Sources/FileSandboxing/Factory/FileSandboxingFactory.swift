import Foundation
import FileSystemInterfaces
import LoggingInterfaces

/**
 # File Sandboxing Factory
 
 A factory class for creating FileSandboxingProtocol instances.
 
 This factory provides a clean way to instantiate file sandboxing
 implementations with proper security constraints.
 
 ## Alpha Dot Five Architecture
 
 This factory follows the Alpha Dot Five architecture principles:
 - Provides dependency injection
 - Supports creation of both standard and testing instances
 - Follows British spelling in documentation
 */
public enum FileSandboxingFactory {
    /**
     Creates a standard implementation of FileSandboxingProtocol.
     
     - Parameters:
        - rootDirectory: The directory to sandbox operations to
        - logger: Optional logger for recording operations
     - Returns: A new FileSandboxingProtocol instance
     */
    public static func createStandardSandbox(
        rootDirectory: String,
        logger: (any LoggingProtocol)? = nil
    ) -> any FileSandboxingProtocol {
        let (sandbox, _) = FileSandboxingImpl.createSandboxed(rootDirectory: rootDirectory)
        return sandbox
    }
    
    /**
     Creates a test-friendly implementation of FileSandboxingProtocol.
     
     This method can be used in tests to create an implementation with
     a test sandbox directory and logger.
     
     - Parameters:
        - testRootDirectory: The test directory to sandbox operations to
        - logger: The test logger to use
     - Returns: A new FileSandboxingProtocol instance for testing
     */
    public static func createTestSandbox(
        testRootDirectory: String,
        logger: any LoggingProtocol
    ) -> any FileSandboxingProtocol {
        let (sandbox, _) = FileSandboxingImpl.createSandboxed(rootDirectory: testRootDirectory)
        return sandbox
    }
}
