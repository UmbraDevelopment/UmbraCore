import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import CoreFileOperations
import FileMetadataOperations
import SecureFileOperations
import FileSandboxing

/**
 # File System Service Factory

 Factory class for creating instances of CompositeFileSystemServiceProtocol with different configurations.
 This provides a centralised way to create file system services with consistent options
 using a domain-driven design approach.
 
 ## Alpha Dot Five Architecture
 
 This factory creates actor-based file system services in accordance with
 Alpha Dot Five architecture principles. The actor-based services provide enhanced thread
 safety, better modularisation, and improved error handling.
 */
public enum FileSystemServiceFactory {
  
  // MARK: - Factory Methods
  
  /**
   Creates a standard composite file system service.
   
   This is the recommended factory method for general-purpose file operations.
   It provides a thread-safe implementation suitable for most scenarios.
   
   - Parameters:
      - logger: Optional logger for operation tracking
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public static func createStandardService(
    logger: (any LoggingProtocol)? = nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Create subdomain implementations
    let coreOperations = CoreFileOperationsFactory.createStandardOperations(logger: logger)
    let metadataOperations = FileMetadataOperationsFactory.createStandardOperations(logger: logger)
    let secureOperations = SecureFileOperationsFactory.createStandardOperations(logger: logger)
    
    // Create a temporary sandbox in the user's home directory
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    let sandboxDirectory = "\(homeDirectory)/.umbra_sandbox"
    
    // Create the sandbox directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: sandboxDirectory) {
        try? FileManager.default.createDirectory(
            atPath: sandboxDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    let sandboxing = FileSandboxingFactory.createStandardSandbox(rootDirectory: sandboxDirectory, logger: logger)
    
    // Create the composite service
    return CompositeFileSystemServiceImpl(
        coreOperations: coreOperations,
        metadataOperations: metadataOperations,
        secureOperations: secureOperations,
        sandboxing: sandboxing,
        logger: logger
    )
  }
  
  /**
   Creates a secure composite file system service.
   
   This service prioritises security measures such as secure deletion,
   encryption, and permission verification. Use this when working with
   sensitive data or in security-critical contexts.
   
   - Parameters:
      - logger: Optional logger for operation tracking
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public static func createSecureService(
    logger: (any LoggingProtocol)? = nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Create subdomain implementations
    let coreOperations = CoreFileOperationsFactory.createStandardOperations(logger: logger)
    let metadataOperations = FileMetadataOperationsFactory.createStandardOperations(logger: logger)
    let secureOperations = SecureFileOperationsFactory.createStandardOperations(logger: logger)
    
    // Create a secure sandbox in the user's application support directory
    let appSupportDirectory = try? FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    ).path
    
    let sandboxDirectory = "\(appSupportDirectory ?? FileManager.default.temporaryDirectory.path)/umbra_secure_sandbox"
    
    // Create the sandbox directory with secure permissions if it doesn't exist
    if !FileManager.default.fileExists(atPath: sandboxDirectory) {
        try? FileManager.default.createDirectory(
            atPath: sandboxDirectory,
            withIntermediateDirectories: true,
            attributes: [FileAttributeKey.posixPermissions: 0o700] // Owner read/write/execute only
        )
    }
    
    let sandboxing = FileSandboxingFactory.createStandardSandbox(rootDirectory: sandboxDirectory, logger: logger)
    
    // Create the composite service
    return CompositeFileSystemServiceImpl(
        coreOperations: coreOperations,
        metadataOperations: metadataOperations,
        secureOperations: secureOperations,
        sandboxing: sandboxing,
        logger: logger
    )
  }
  
  /**
   Creates a sandboxed composite file system service.
   
   This service restricts all file operations to the specified directory,
   providing an additional layer of security and isolation.
   
   - Parameters:
      - rootDirectory: The directory to restrict operations to
      - logger: Optional logger for operation tracking
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public static func createSandboxedService(
    rootDirectory: String,
    logger: (any LoggingProtocol)? = nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Create subdomain implementations
    let coreOperations = CoreFileOperationsFactory.createStandardOperations(logger: logger)
    let metadataOperations = FileMetadataOperationsFactory.createStandardOperations(logger: logger)
    let secureOperations = SecureFileOperationsFactory.createStandardOperations(logger: logger)
    
    // Create the sandbox
    let sandboxing = FileSandboxingFactory.createStandardSandbox(rootDirectory: rootDirectory, logger: logger)
    
    // Create the composite service
    return CompositeFileSystemServiceImpl(
        coreOperations: coreOperations,
        metadataOperations: metadataOperations,
        secureOperations: secureOperations,
        sandboxing: sandboxing,
        logger: logger
    )
  }
  
  /**
   Creates a test implementation of the composite file system service.
   
   This service is specifically designed for unit testing, with mocked
   dependencies and predefined behaviors for test scenarios.
   
   - Parameters:
      - testRootDirectory: The test directory to use
      - logger: The test logger to use
   - Returns: An implementation of CompositeFileSystemServiceProtocol for testing
   */
  public static func createTestService(
    testRootDirectory: String,
    logger: any LoggingProtocol
  ) async -> any CompositeFileSystemServiceProtocol {
    // Create mocked test file manager
    let fileManager = FileManager()
    
    // Create test subdomain implementations
    let coreOperations = CoreFileOperationsFactory.createTestOperations(
        fileManager: fileManager,
        logger: logger
    )
    
    let metadataOperations = FileMetadataOperationsFactory.createTestOperations(
        fileManager: fileManager,
        logger: logger
    )
    
    let secureOperations = SecureFileOperationsFactory.createTestOperations(
        fileManager: fileManager,
        logger: logger
    )
    
    let sandboxing = FileSandboxingFactory.createTestSandbox(
        testRootDirectory: testRootDirectory,
        logger: logger
    )
    
    // Create the test composite service
    return CompositeFileSystemServiceImpl(
        coreOperations: coreOperations,
        metadataOperations: metadataOperations,
        secureOperations: secureOperations,
        sandboxing: sandboxing,
        logger: logger
    )
  }
}
