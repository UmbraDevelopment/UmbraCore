import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingAdapters

/**
 # File System Service Factory

 Factory class for creating instances of FileSystemServiceProtocol with different configurations.
 This provides a centralised way to create file system services with consistent options.
 
 ## Alpha Dot Five Architecture
 
 This factory creates actor-based file system services in accordance with
 Alpha Dot Five architecture principles. The actor-based services provide enhanced thread
 safety, better modularisation, and improved error handling.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor FileSystemServiceFactory {
  /// Shared singleton instance
  public static let shared: FileSystemServiceFactory = .init()

  /// Private initialiser to enforce singleton pattern
  private init() {}

  // MARK: - Actor-Based Factory Methods
  
  /**
   Creates a standard actor-based file system service.
   
   This is the recommended factory method for general-purpose file operations.
   It provides a thread-safe implementation suitable for most scenarios.
   
   - Parameters:
      - logger: Optional privacy-aware logger for operation tracking
   - Returns: An actor-based implementation of FileSystemServiceProtocol
   */
  public func createStandardService(
    logger: (any PrivacyAwareLoggingProtocol)? = nil
  ) -> any FileSystemServiceProtocol {
    let loggingAdapter = logger != nil 
        ? PrivacyAwareLoggingAdapter(logger: logger!)
        : PrivacyAwareLoggingAdapter(logger: NullLogger())
        
    return FileSystemServiceActor(logger: loggingAdapter)
  }
  
  /**
   Creates a high-performance actor-based file system service.
   
   This service uses dedicated actors with optimised configurations
   for high-throughput file operations, while maintaining thread safety.
   
   - Parameters:
      - logger: Optional privacy-aware logger for operation tracking
   - Returns: An actor-based implementation of FileSystemServiceProtocol
   */
  public func createHighPerformanceService(
    logger: (any PrivacyAwareLoggingProtocol)? = nil
  ) -> any FileSystemServiceProtocol {
    let loggingAdapter = logger != nil 
        ? PrivacyAwareLoggingAdapter(logger: logger!)
        : PrivacyAwareLoggingAdapter(logger: NullLogger())
        
    // Create specialised actors with high-performance configurations
    let readActor = FileSystemReadActor(
        logger: loggingAdapter
    )
    
    let writeActor = FileSystemWriteActor(
        logger: loggingAdapter
    )
    
    let metadataActor = FileMetadataActor(
        logger: loggingAdapter
    )
    
    let secureActor = SecureFileOperationsActor(
        logger: loggingAdapter,
        fileReadActor: readActor,
        fileWriteActor: writeActor
    )
    
    // Compose actors into the main service
    return FileSystemServiceActor(
        logger: loggingAdapter,
        readActor: readActor,
        writeActor: writeActor,
        metadataActor: metadataActor,
        secureActor: secureActor
    )
  }
  
  /**
   Creates a secure actor-based file system service.
   
   This service prioritises security measures such as secure deletion,
   encryption, and permission verification. Use this when working with
   sensitive data or in security-critical contexts.
   
   - Parameters:
      - securityLevel: The security level to enforce (default: .high)
      - logger: Optional privacy-aware logger for operation tracking
   - Returns: An actor-based implementation of FileSystemServiceProtocol
   */
  public func createSecureService(
    securityLevel: SecurityLevel = .high,
    logger: (any PrivacyAwareLoggingProtocol)? = nil
  ) -> any FileSystemServiceProtocol {
    let loggingAdapter = logger != nil 
        ? PrivacyAwareLoggingAdapter(logger: logger!)
        : PrivacyAwareLoggingAdapter(logger: NullLogger())
    
    // Create specialised actors with security-focused configurations
    let readActor = FileSystemReadActor(
        logger: loggingAdapter
    )
    
    let writeActor = FileSystemWriteActor(
        logger: loggingAdapter
    )
    
    let metadataActor = FileMetadataActor(
        logger: loggingAdapter
    )
    
    // Configure a secure actor with enhanced security settings
    let secureActor = SecureFileOperationsActor(
        logger: loggingAdapter,
        fileReadActor: readActor,
        fileWriteActor: writeActor
    )
    
    // Compose actors into the main service
    return FileSystemServiceActor(
        logger: loggingAdapter,
        readActor: readActor,
        writeActor: writeActor,
        metadataActor: metadataActor,
        secureActor: secureActor
    )
  }
  
  /**
   Creates a sandboxed file system service that restricts operations to a specific directory.
   
   This service provides all operations through actors while restricting access to files 
   outside the specified root directory for security purposes.
   
   - Parameters:
      - rootDirectory: The directory to restrict operations to
      - logger: Optional privacy-aware logger for operation tracking
   - Returns: An actor-based implementation of FileSystemServiceProtocol
   */
  public func createSandboxedService(
    rootDirectory: String,
    logger: (any PrivacyAwareLoggingProtocol)? = nil
  ) -> any FileSystemServiceProtocol {
    let loggingAdapter = logger != nil 
        ? PrivacyAwareLoggingAdapter(logger: logger!)
        : PrivacyAwareLoggingAdapter(logger: NullLogger())
    
    // Create the basic actors
    let readActor = FileSystemReadActor(
        logger: loggingAdapter, 
        rootDirectory: rootDirectory
    )
    
    let writeActor = FileSystemWriteActor(
        logger: loggingAdapter,
        rootDirectory: rootDirectory
    )
    
    let metadataActor = FileMetadataActor(
        logger: loggingAdapter,
        rootDirectory: rootDirectory
    )
    
    let secureActor = SecureFileOperationsActor(
        logger: loggingAdapter,
        fileReadActor: readActor,
        fileWriteActor: writeActor
    )
    
    // Create the main service with sandboxed actors
    return FileSystemServiceActor(
        logger: loggingAdapter,
        readActor: readActor,
        writeActor: writeActor,
        metadataActor: metadataActor,
        secureActor: secureActor
    )
  }
  
  /**
   Creates a custom file system service with full configuration options.
   
   This method allows for complete customization of the actor-based service.
   
   - Parameters:
      - readActor: Custom read operations actor
      - writeActor: Custom write operations actor
      - metadataActor: Custom metadata operations actor
      - secureActor: Custom secure operations actor
      - logger: Optional privacy-aware logger for the main service actor
   - Returns: An actor-based implementation of FileSystemServiceProtocol
   */
  public func createCustomService(
    readActor: FileSystemReadActor,
    writeActor: FileSystemWriteActor,
    metadataActor: FileMetadataActor,
    secureActor: SecureFileOperationsActor,
    logger: (any PrivacyAwareLoggingProtocol)? = nil
  ) -> any FileSystemServiceProtocol {
    let loggingAdapter = logger != nil 
        ? PrivacyAwareLoggingAdapter(logger: logger!)
        : PrivacyAwareLoggingAdapter(logger: NullLogger())
    
    return FileSystemServiceActor(
        logger: loggingAdapter,
        readActor: readActor,
        writeActor: writeActor,
        metadataActor: metadataActor,
        secureActor: secureActor
    )
  }
}
