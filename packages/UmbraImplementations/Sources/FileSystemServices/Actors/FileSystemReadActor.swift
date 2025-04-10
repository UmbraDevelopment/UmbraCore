import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File System Read Actor

 Implements file read operations as an actor to ensure thread safety.
 This actor provides implementations for all methods defined in the
 FileReadOperationsProtocol, with comprehensive error handling and logging.

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing actor-based concurrency for thread safety
 3. Providing comprehensive privacy-aware logging
 4. Using functional programming patterns where appropriate
 5. Supporting sandboxed operation for enhanced security
 */
public actor FileSystemReadActor: FileReadOperationsProtocol {
  /// Logger for operation tracking
  private let logger: LoggingProtocol

  /// File manager instance for performing file operations
  private let fileManager: FileManager

  /// Optional root directory for sandboxed operation
  private let rootDirectory: String?

  /**
   Initialises a new FileSystemReadActor.

   - Parameters:
      - logger: The logger to use for operation tracking
      - rootDirectory: Optional root directory to restrict operations to
   */
  public init(logger: LoggingProtocol, rootDirectory: String?=nil) {
    self.logger=logger
    fileManager=FileManager.default
    self.rootDirectory=rootDirectory
  }

  /**
   Validates that a path is within the root directory if one is specified.

   - Parameter path: The path to validate
   - Returns: The canonicalised path if valid
   - Throws: FileSystemError.accessDenied if the path is outside the root directory
   */
  private func validatePath(_ path: String) throws -> String {
    guard let rootDir=rootDirectory else {
      // No sandboxing, path is valid as-is
      return path
    }

    // Canonicalise paths to resolve any ../ or symlinks
    let canonicalPath=URL(fileURLWithPath: path).standardized.path
    let canonicalRootDir=URL(fileURLWithPath: rootDir).standardized.path

    // Check if the path is within the root directory
    if !canonicalPath.hasPrefix(canonicalRootDir) {
      let context=FileSystemLogContext(
        operation: "validatePath",
        path: path,
        source: "FileSystemReadActor",
        isSecureOperation: true
      )

      await logger.warning(
        "Access attempt to path outside root directory",
        context: context
      )

      throw FileSystemError.accessDenied(
        path: path,
        reason: "Path is outside the permitted root directory"
      )
    }

    return canonicalPath
  }

  /**
   Reads the contents of a file at the specified path.

   - Parameter path: The path to the file to read.
   - Returns: The file contents as Data.
   - Throws: FileSystemError if the read operation fails.
   */
  public func readFile(at path: String) async throws -> Data {
    let context=FileSystemLogContext.forReadOperation(path: path)
    await logger.debug("Reading file at path", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Check if the file exists
      guard fileManager.fileExists(atPath: validatedPath) else {
        throw FileSystemError.notFound(path: validatedPath)
      }

      // Read the file data
      let data=try Data(contentsOf: URL(fileURLWithPath: validatedPath))

      // Log successful completion
      let successContext=context
        .withStatus("success")
        .withUpdatedMetadata(context.metadata.withPublic(
          key: "dataSize",
          value: String(data.count)
        ))
      await logger.debug("Successfully read file", context: successContext)

      return data
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error("Failed to read file: \(error.localizedDescription)", context: context)
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "readFile", path: path)
      await logger.error(
        "Failed to read file: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }

  /**
   Reads the contents of a file as a string.

   - Parameters:
      - path: The path to the file to read.
      - encoding: The string encoding to use.
   - Returns: The file contents as a String.
   - Throws: FileSystemError if the read operation fails or if the data cannot be decoded.
   */
  public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> String {
    let context=FileSystemLogContext.forReadOperation(path: path)
    let metadata=context.metadata.withPublic(key: "encoding", value: "\(encoding)")
    let enhancedContext=context.withUpdatedMetadata(metadata)

    await logger.debug("Reading file as string", context: enhancedContext)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Read the file data
      let data=try await readFile(at: validatedPath)

      // Convert to string with the specified encoding
      guard let string=String(data: data, encoding: encoding) else {
        throw FileSystemError.decodingError(
          path: validatedPath,
          reason: "Could not decode data using the specified encoding"
        )
      }

      // Log successful completion
      let successContext=enhancedContext
        .withStatus("success")
        .withUpdatedMetadata(enhancedContext.metadata.withPublic(
          key: "stringLength",
          value: String(string.count)
        ))
      await logger.debug("Successfully read file as string", context: successContext)

      return string
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to read file as string: \(error.localizedDescription)",
        context: enhancedContext
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "readFileAsString", path: path)
      await logger.error(
        "Failed to read file as string: \(wrappedError.localizedDescription)",
        context: enhancedContext
      )
      throw wrappedError
    }
  }

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The path to check.
   - Returns: True if the file exists, false otherwise.
   */
  public func fileExists(at path: String) async -> Bool {
    let context=FileSystemLogContext.forReadOperation(path: path)
    await logger.debug("Checking if file exists", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      let exists=fileManager.fileExists(atPath: validatedPath)

      // Log result
      let resultContext=context
        .withStatus("success")
        .withUpdatedMetadata(context.metadata.withPublic(key: "exists", value: String(exists)))
      await logger.debug("File existence check complete", context: resultContext)

      return exists
    } catch {
      // Log error but return false rather than throwing
      await logger.warning(
        "File existence check failed: \(error.localizedDescription)",
        context: context
      )
      return false
    }
  }

  /**
   Lists the contents of a directory at the specified path.

   - Parameter path: The path to the directory to list.
   - Returns: An array of file paths contained in the directory.
   - Throws: FileSystemError if the list operation fails.
   */
  public func listDirectory(at path: String) async throws -> [String] {
    let context=FileSystemLogContext.forReadOperation(path: path)
    await logger.debug("Listing directory contents", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Check if the directory exists
      var isDirectory: ObjCBool=false
      guard fileManager.fileExists(atPath: validatedPath, isDirectory: &isDirectory) else {
        throw FileSystemError.notFound(path: validatedPath)
      }

      guard isDirectory.boolValue else {
        throw FileSystemError.notADirectory(path: validatedPath)
      }

      // List directory contents
      let contents=try fileManager.contentsOfDirectory(atPath: validatedPath)

      // Log successful completion
      let successContext=context
        .withStatus("success")
        .withUpdatedMetadata(context.metadata.withPublic(
          key: "itemCount",
          value: String(contents.count)
        ))
      await logger.debug("Successfully listed directory contents", context: successContext)

      // Return full paths
      return contents.map { (validatedPath as NSString).appendingPathComponent($0) }
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to list directory: \(error.localizedDescription)",
        context: context
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "listDirectory", path: path)
      await logger.error(
        "Failed to list directory: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }

  /**
   Lists the contents of a directory recursively.

   - Parameter path: The path to the directory to list recursively.
   - Returns: An array of file paths contained in the directory, including subdirectories.
   - Throws: FileSystemError if the list operation fails.
   */
  public func listDirectoryRecursively(at path: String) async throws -> [String] {
    let context=FileSystemLogContext.forReadOperation(path: path)
    await logger.debug("Listing directory contents recursively", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Check if the directory exists
      var isDirectory: ObjCBool=false
      guard fileManager.fileExists(atPath: validatedPath, isDirectory: &isDirectory) else {
        throw FileSystemError.notFound(path: validatedPath)
      }

      guard isDirectory.boolValue else {
        throw FileSystemError.notADirectory(path: validatedPath)
      }

      // Get directory enumerator
      guard let enumerator=fileManager.enumerator(atPath: validatedPath) else {
        throw FileSystemError.internalError(
          path: validatedPath,
          reason: "Failed to create directory enumerator"
        )
      }

      // Convert relative paths to absolute
      var absolutePaths: [String]=[]
      while let relativePath=enumerator.nextObject() as? String {
        let absolutePath=(validatedPath as NSString).appendingPathComponent(relativePath)
        absolutePaths.append(absolutePath)
      }

      // Log successful completion
      let successContext=context
        .withStatus("success")
        .withUpdatedMetadata(context.metadata.withPublic(
          key: "itemCount",
          value: String(absolutePaths.count)
        ))
      await logger.debug(
        "Successfully listed directory contents recursively",
        context: successContext
      )

      return absolutePaths
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to list directory recursively: \(error.localizedDescription)",
        context: context
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(
        error,
        operation: "listDirectoryRecursively",
        path: path
      )
      await logger.error(
        "Failed to list directory recursively: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }
}
