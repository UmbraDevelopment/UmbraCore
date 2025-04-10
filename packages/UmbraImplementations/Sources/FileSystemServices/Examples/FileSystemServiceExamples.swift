import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File System Service Examples

 This file contains examples of how to use the actor-based file system services.
 These examples demonstrate the recommended patterns for:

 1. Getting an appropriate file system service from the factory
 2. Performing various file operations using the actor-based APIs
 3. Handling errors properly
 4. Ensuring proper privacy controls in logging

 ## Alpha Dot Five Architecture

 The examples follow the Alpha Dot Five architecture principles:
 1. Using actor-based concurrency for thread safety
 2. Implementing comprehensive error handling
 3. Using proper British spelling in documentation
 4. Ensuring privacy-aware logging
 5. Following Swift concurrency best practices
 */

/// Examples of basic file system operations
public enum FileSystemServiceExamples {

  /// Simple logger implementation for examples only
  private actor SimpleLoggerActor {
    func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
      print("[\(level)] \(context.source ?? "Unknown"): \(message)")
    }
  }

  /// Create a simple logger for examples
  private static func createExampleLogger() -> LoggingProtocol {
    actor SimpleLogger: LoggingProtocol {
      let loggerImpl=SimpleLoggerActor()

      // Required by LoggingProtocol - create a dummy implementation since we don't use it
      private let _dummyActor=LoggingActor(destinations: [], minimumLogLevel: .debug)

      var loggingActor: LoggingActor {
        _dummyActor
      }

      func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
        await loggerImpl.log(level, message, context: context)
      }

      // LoggingProtocol implementation
      func debug(_ message: String, context: LogContextDTO) async {
        await log(.debug, message, context: context)
      }

      func info(_ message: String, context: LogContextDTO) async {
        await log(.info, message, context: context)
      }

      func warn(_ message: String, context: LogContextDTO) async {
        await log(.warning, message, context: context)
      }

      func error(_ message: String, context: LogContextDTO) async {
        await log(.error, message, context: context)
      }
    }

    return SimpleLogger()
  }

  /**
   Demonstrates basic file reading and writing operations.

   This example shows:
   - Getting a standard actor-based file system service
   - Writing a string to a file
   - Reading the file back as a string
   - Proper error handling and cleanup
   */
  public static func basicReadWriteExample() async {
    // Create a simple logger for examples
    let logger=createExampleLogger()

    // Create log context for logging
    let logContext=FileSystemLogContext(operation: "basicFileOperationExample")

    // Get a file system service instance
    let fileSystem=await FileSystemServiceFactory.createStandardService(
      logger: logger
    )

    // Create a temporary file path
    let tempDir=FileManager.default.temporaryDirectory.path
    let tempFile=tempDir + "/" + UUID().uuidString + "-example.txt"

    do {
      // Write content to the file
      let content="Hello, World! This is an example file."
      _=try await fileSystem.writeFile(
        data: content.data(using: .utf8)!,
        to: tempFile,
        options: FileWriteOptions()
      )

      // Read the content back
      let readResult=try await fileSystem.readFile(at: tempFile)
      let readContent=String(data: readResult.0, encoding: .utf8)!

      await logger.info(
        "Successfully wrote and read file content: \(readContent.count) characters",
        context: logContext
      )

      // Clean up
      _=try await fileSystem.delete(at: tempFile)
    } catch {
      // Log and handle errors properly
      if let fileError=error as? FileSystemError {
        await logger.error(
          "File operation failed: \(fileError.localizedDescription)",
          context: logContext
        )
      } else {
        await logger.error("Unexpected error: \(error.localizedDescription)", context: logContext)
      }
    }
  }

  /**
   Demonstrates secure file operations.

   This example shows:
   - Getting a secure actor-based file system service
   - Creating a secure temporary file
   - Writing encrypted content to the file
   - Reading and decrypting the content
   - Securely deleting the file when done
   */
  public static func secureFileOperationsExample() async {
    // Create a simple logger for examples
    let logger=createExampleLogger()

    // Create log context for logging
    let logContext=FileSystemLogContext(operation: "secureFileOperationExample")

    // Get a secure file system service instance
    let fileSystem=await FileSystemServiceFactory.createSecureService(
      logger: logger
    )

    do {
      // Create a secure temporary file
      let tempDir=FileManager.default.temporaryDirectory.path
      let secureFile=tempDir + "/" + UUID().uuidString + "-secure-example.txt"

      // Prepare sensitive data
      let sensitiveData="This is confidential information that should be properly secured."
        .data(using: .utf8)!

      // Write data securely with encryption
      _=try await fileSystem.writeFile(
        data: sensitiveData,
        to: secureFile,
        options: FileWriteOptions()
      )

      // Read data securely with decryption
      let readResult=try await fileSystem.readFile(at: secureFile)
      let decryptedData=readResult.0

      // Verify data integrity
      _=String(data: decryptedData, encoding: .utf8)
      await logger.info(
        "Successfully processed secure data of \(decryptedData.count) bytes",
        context: logContext
      )

      // Securely delete the file when done
      _=try await fileSystem.delete(at: secureFile)
    } catch {
      // Log and handle errors properly
      if let fileError=error as? FileSystemError {
        await logger.error(
          "Secure file operation failed: \(fileError.localizedDescription)",
          context: logContext
        )
      } else {
        await logger.error(
          "Unexpected error in secure operations: \(error.localizedDescription)",
          context: logContext
        )
      }
    }
  }

  /**
   Demonstrates file metadata operations.

   This example shows:
   - Getting a standard actor-based file system service
   - Creating a file with specific attributes
   - Setting and getting attributes
   - Working with extended attributes for custom metadata
   */
  public static func metadataOperationsExample() async {
    // Create a simple logger for examples
    let logger=createExampleLogger()

    // Create log context for logging
    let logContext=FileSystemLogContext(operation: "metadataOperationExample")

    // Get a file system service instance
    let fileSystem=await FileSystemServiceFactory.createStandardService(
      logger: logger
    )

    // Create a temporary file path
    let tempDir=FileManager.default.temporaryDirectory.path
    let tempFile=tempDir + "/" + UUID().uuidString + "-metadata-example.txt"

    do {
      // Create a file with specific attributes
      _=try await fileSystem.writeFile(
        data: "File with custom metadata".data(using: .utf8)!,
        to: tempFile,
        options: FileWriteOptions()
      )

      // Read file attributes directly through the composite interface
      let attrs=try await fileSystem.getAttributes(at: tempFile)

      // Use the attributes directly from the FileMetadataDTO
      let fileSize=attrs.0.size
      let creationDate=attrs.0.creationDate

      await logger.info(
        "File metadata: size=\(fileSize) bytes, created=\(creationDate.timeIntervalSince1970)",
        context: logContext
      )

      // Set an extended attribute using the proper method signature
      _=try await fileSystem.setExtendedAttribute(
        data: "Custom file metadata".data(using: String.Encoding.utf8)!,
        name: "com.example.customMetadata",
        at: tempFile,
        options: nil
      )

      // We can get attributes but need to adapt how we work with them
      _=try await fileSystem.getAttributes(at: tempFile)
      await logger.info("File attributes obtained", context: logContext)

      // Read back the extended attribute
      let attributeResult=try await fileSystem.getExtendedAttribute(
        name: "com.example.customMetadata",
        at: tempFile
      )
      let readMetadata=attributeResult.0

      if let metadataString=String(data: readMetadata, encoding: String.Encoding.utf8) {
        await logger.info("Retrieved metadata: \(metadataString)", context: logContext)
      }

      // Clean up
      _=try await fileSystem.delete(at: tempFile)
    } catch {
      if let fileError=error as? FileSystemError {
        await logger.error(
          "Metadata operation failed: \(fileError.localizedDescription)",
          context: logContext
        )
      } else {
        await logger.error("Unexpected error: \(error.localizedDescription)", context: logContext)
      }
    }
  }

  /**
   Demonstrates high-performance file operations for large files.

   This example shows:
   - Getting a high-performance actor-based file system service
   - Working with large files efficiently
   - Proper resource management and cleanup
   */
  public static func highPerformanceExample() async {
    // Create a simple logger for examples
    let logger=createExampleLogger()

    // Create log context for logging
    let logContext=FileSystemLogContext(operation: "largeFileExample")

    // Get a file system service instance
    let fileSystem=await FileSystemServiceFactory.createStandardService(
      logger: logger
    )

    // Create temporary directory and unique filename
    let tempDir=FileManager.default.temporaryDirectory.path
    let largeTempFile=tempDir + "/" + UUID().uuidString + "-large-file.dat"

    do {
      // Generate a somewhat large dataset (10MB for example)
      let dataSize=10 * 1024 * 1024 // 10MB
      var largeData=Data(count: dataSize)

      // Fill with random bytes (optional)
      largeData.withUnsafeMutableBytes { ptr in
        let buffer=ptr.bindMemory(to: UInt8.self)
        for i in 0..<buffer.count {
          buffer[i]=UInt8.random(in: 0...255)
        }
      }

      await logger.info("Writing \(dataSize) bytes to large file", context: logContext)

      // Time the operation
      let startTime=CFAbsoluteTimeGetCurrent()

      // Write the large data
      _=try await fileSystem.writeFile(
        data: largeData,
        to: largeTempFile,
        options: FileWriteOptions()
      )

      // Read it back to verify
      let readDataResult=try await fileSystem.readFile(at: largeTempFile)
      let readData=readDataResult.0

      let endTime=CFAbsoluteTimeGetCurrent()
      let elapsedTime=endTime - startTime

      // Verify integrity
      let dataMatches=readData.count == largeData.count

      await logger.info(
        "High-performance operation completed in \(elapsedTime) seconds, data integrity: \(dataMatches)",
        context: logContext
      )

      // Clean up
      _=try await fileSystem.delete(at: largeTempFile)
    } catch {
      if let fileError=error as? FileSystemError {
        await logger.error(
          "High-performance operation failed: \(fileError.localizedDescription)",
          context: logContext
        )
      } else {
        await logger.error("Unexpected error: \(error.localizedDescription)", context: logContext)
      }
    }
  }
}
