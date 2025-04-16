import BuildConfig
import CoreFileOperations
import FileMetadataOperations
import FileSandboxing
import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingServices
import SecureFileOperations

/**
 # File System Service Factory

 Factory class for creating instances of CompositeFileSystemServiceProtocol with different configurations.
 This provides a centralised way to create file system services with consistent options
 using a domain-driven design approach.

 ## Environment and Backend Strategy Support

 This factory supports different environment configurations:
 - Debug/Development: Enhanced logging with developer-friendly features
 - Alpha/Beta: Testing environments with balanced logging and performance
 - Production: Optimised performance with appropriate security controls

 It also supports different backend strategies:
 - Restic: Default integration with Restic's file system approach
 - RingFFI: Ring-based cryptography for secure file operations
 - AppleCK: Apple CryptoKit for sandboxed environments

 ## Alpha Dot Five Architecture

 This factory creates actor-based file system services in accordance with
 Alpha Dot Five architecture principles. The actor-based services provide enhanced thread
 safety, better modularisation, and improved error handling.
 */
public struct FileSystemServiceFactory: Sendable {

  // MARK: - Singleton Instance

  /// Shared instance for singleton access pattern
  public static let shared=FileSystemServiceFactory()

  // MARK: - Factory Methods

  /**
   Creates a file system service configured for the specified environment and backend strategy.

   This is the primary factory method that other specialised methods delegate to.

   - Parameters:
      - environment: The environment to configure for
      - backendStrategy: The backend strategy to use
      - logger: Optional logger for operation tracking
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public func createFileSystemService(
    environment: BuildConfig.UmbraEnvironment?=nil,
    backendStrategy: BackendStrategy?=nil,
    logger: (any LoggingProtocol)?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveEnvironment=environment ?? BuildConfig.activeEnvironment
    let effectiveBackend=backendStrategy ?? BuildConfig.activeBackendStrategy

    // Select the appropriate configuration based on environment and backend
    switch (effectiveEnvironment, effectiveBackend) {
      case (_, .appleCK):
        // Always use sandbox-compatible service for Apple CryptoKit
        return await createSandboxedService(
          logger: logger,
          environment: effectiveEnvironment
        )

      case (.production, _), (.beta, _):
        // Use secure service for production and beta environments
        return await createSecureService(
          logger: logger,
          environment: effectiveEnvironment,
          backendStrategy: effectiveBackend
        )

      case (.alpha, _):
        // Use performance-optimised service for alpha testing
        return await createPerformanceOptimisedService(
          logger: logger,
          environment: effectiveEnvironment,
          backendStrategy: effectiveBackend
        )

      case (.debug, _), (.development, _):
        // Use standard service for development environments
        return await createStandardService(
          logger: logger,
          environment: effectiveEnvironment,
          backendStrategy: effectiveBackend
        )
    }
  }

  /**
   Creates a standard composite file system service.

   This is the recommended factory method for general-purpose file operations.
   It provides a thread-safe implementation suitable for most scenarios.

   - Parameters:
      - logger: Optional logger for operation tracking
      - environment: Optional environment override
      - backendStrategy: Optional backend strategy override
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public static func createStandardService(
    logger: (any LoggingProtocol)?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil,
    backendStrategy: BackendStrategy?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    await shared.createStandardService(
      logger: logger,
      environment: environment,
      backendStrategy: backendStrategy
    )
  }

  /**
   Creates a standard composite file system service.

   Instance method implementation that provides the actual service creation logic.

   - Parameters:
      - logger: Optional logger for operation tracking
      - environment: Optional environment override
      - backendStrategy: Optional backend strategy override
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public func createStandardService(
    logger: (any LoggingProtocol)?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil,
    backendStrategy _: BackendStrategy?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveEnvironment=environment ?? BuildConfig.activeEnvironment

    // Configure logging based on environment
    let effectiveLogger: any LoggingProtocol=if let logger {
      logger
    } else {
      await createEnvironmentAppropriateLogger(
        environment: effectiveEnvironment,
        category: "StandardFileSystem"
      )
    }

    // Create subdomain implementations
    let coreOperations=CoreFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let metadataOperations=FileMetadataOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let secureOperations=SecureFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )

    // Create a temporary sandbox in the user's home directory
    let homeDirectory=FileManager.default.homeDirectoryForCurrentUser.path
    let sandboxDirectory="\(homeDirectory)/.umbra_sandbox"

    // Create the sandbox directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: sandboxDirectory) {
      try? FileManager.default.createDirectory(
        atPath: sandboxDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    let sandboxing=FileSandboxingFactory.createStandardSandbox(
      rootDirectory: sandboxDirectory,
      logger: effectiveLogger
    )

    // Create the composite service
    return CompositeFileSystemServiceImpl(
      coreOperations: coreOperations,
      metadataOperations: metadataOperations,
      secureOperations: secureOperations,
      sandboxing: sandboxing,
      logger: effectiveLogger
    )
  }

  /**
   Creates a secure composite file system service.

   This service prioritises security measures such as secure deletion,
   encryption, and permission verification. Use this when working with
   sensitive data or in security-critical contexts.

   - Parameters:
      - logger: Optional logger for operation tracking
      - environment: Optional environment override
      - backendStrategy: Optional backend strategy override
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public static func createSecureService(
    logger: (any LoggingProtocol)?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil,
    backendStrategy: BackendStrategy?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    await shared.createSecureService(
      logger: logger,
      environment: environment,
      backendStrategy: backendStrategy
    )
  }

  /**
   Creates a secure composite file system service.

   Instance method implementation that provides the actual service creation logic.

   - Parameters:
      - logger: Optional logger for operation tracking
      - environment: Optional environment override
      - backendStrategy: Optional backend strategy override
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public func createSecureService(
    logger: (any LoggingProtocol)?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil,
    backendStrategy _: BackendStrategy?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveEnvironment=environment ?? BuildConfig.activeEnvironment

    // Configure logging based on environment
    let effectiveLogger: any LoggingProtocol=if let logger {
      logger
    } else {
      await createEnvironmentAppropriateLogger(
        environment: effectiveEnvironment,
        category: "SecureFileSystem"
      )
    }

    // Create subdomain implementations with proper security configuration
    let coreOperations=CoreFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let metadataOperations=FileMetadataOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let secureOperations=SecureFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )

    // Create a secure sandbox in the user's application support directory
    let appSupportDirectory=try? FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).path

    let sandboxDirectory="\(appSupportDirectory ?? FileManager.default.temporaryDirectory.path)/umbra_secure_sandbox"

    // Create the sandbox directory with secure permissions if it doesn't exist
    if !FileManager.default.fileExists(atPath: sandboxDirectory) {
      try? FileManager.default.createDirectory(
        atPath: sandboxDirectory,
        withIntermediateDirectories: true,
        attributes: [
          FileAttributeKey.posixPermissions: 0o700 // Owner read/write/execute only
        ]
      )
    }

    let sandboxing=FileSandboxingFactory.createStandardSandbox(
      rootDirectory: sandboxDirectory,
      logger: effectiveLogger
    )

    // Create the composite service
    return CompositeFileSystemServiceImpl(
      coreOperations: coreOperations,
      metadataOperations: metadataOperations,
      secureOperations: secureOperations,
      sandboxing: sandboxing,
      logger: effectiveLogger
    )
  }

  /**
   Creates a sandboxed file system service suitable for restricted environments.

   This service provides file operations that comply with sandbox restrictions
   present in environments like macOS App Store apps or iOS applications.

   - Parameters:
      - logger: Optional logger for operation tracking
      - environment: Optional environment override
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public func createSandboxedService(
    logger: (any LoggingProtocol)?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveEnvironment=environment ?? BuildConfig.activeEnvironment

    // Configure logging based on environment
    let effectiveLogger: any LoggingProtocol=if let logger {
      logger
    } else {
      await createEnvironmentAppropriateLogger(
        environment: effectiveEnvironment,
        category: "SandboxedFileSystem"
      )
    }

    // Create the appropriate operations for a sandboxed environment
    let coreOperations=CoreFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let metadataOperations=FileMetadataOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let secureOperations=SecureFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )

    // Use application container directory for sandbox
    let containerDirectory=try? FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("UmbraSandbox").path

    let sandboxing=FileSandboxingFactory.createStandardSandbox(
      rootDirectory: containerDirectory ?? FileManager.default.temporaryDirectory.path,
      logger: effectiveLogger
    )

    // Create the composite service with sandbox restrictions
    return CompositeFileSystemServiceImpl(
      coreOperations: coreOperations,
      metadataOperations: metadataOperations,
      secureOperations: secureOperations,
      sandboxing: sandboxing,
      logger: effectiveLogger
    )
  }

  /**
   Creates a performance-optimised file system service for high-throughput operations.

   This service prioritises performance over advanced security features, making it
   suitable for operations like bulk file processing or high-throughput data pipelines.

   - Parameters:
      - logger: Optional logger for operation tracking
      - environment: Optional environment override
      - backendStrategy: Optional backend strategy override
   - Returns: An implementation of CompositeFileSystemServiceProtocol
   */
  public func createPerformanceOptimisedService(
    logger: (any LoggingProtocol)?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil,
    backendStrategy _: BackendStrategy?=nil
  ) async -> any CompositeFileSystemServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveEnvironment=environment ?? BuildConfig.activeEnvironment

    // Configure logging based on environment but with minimal logging for performance
    let effectiveLogger: any LoggingProtocol=if let logger {
      logger
    } else {
      await createEnvironmentAppropriateLogger(
        environment: effectiveEnvironment,
        category: "PerformanceFileSystem"
      )
    }

    // Create performance-optimised operations
    let coreOperations=CoreFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let metadataOperations=FileMetadataOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )
    let secureOperations=SecureFileOperationsFactory.createStandardOperations(
      logger: effectiveLogger
    )

    // Use temp directory for maximum performance
    let tempDirectory=FileManager.default.temporaryDirectory.appendingPathComponent(
      "UmbraPerformance"
    ).path

    // Create minimal sandbox for performance
    let sandboxing=FileSandboxingFactory.createStandardSandbox(
      rootDirectory: tempDirectory,
      logger: effectiveLogger
    )

    // Return performance-optimised implementation
    return CompositeFileSystemServiceImpl(
      coreOperations: coreOperations,
      metadataOperations: metadataOperations,
      secureOperations: secureOperations,
      sandboxing: sandboxing,
      logger: effectiveLogger
    )
  }

  // MARK: - Helper Methods

  /**
   Creates an appropriate logger for the specified environment.

   - Parameters:
      - environment: The environment to create a logger for
      - category: The logging category
   - Returns: A logging protocol implementation
   */
  private func createEnvironmentAppropriateLogger(
    environment _: BuildConfig.UmbraEnvironment,
    category: String
  ) async -> any LoggingProtocol {
    let factory=LoggingServiceFactory.shared

    // Use privacy-aware logger for enhanced data protection
    return await factory.createPrivacyAwareLogger(
      category: category
    )
  }
}
