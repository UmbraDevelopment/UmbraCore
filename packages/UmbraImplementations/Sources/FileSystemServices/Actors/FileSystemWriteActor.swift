import FileSystemInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File System Write Actor

 Implements file write operations as an actor to ensure thread safety.
 This actor provides implementations for all methods defined in the
 FileWriteOperationsProtocol, with comprehensive error handling and logging.

 ## Alpha Dot Five Architecture

 This implementation follows the Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing actor-based concurrency for thread safety
 3. Providing comprehensive privacy-aware logging
 4. Using functional programming patterns where appropriate
 5. Supporting sandboxed operation for enhanced security
 */
public actor FileSystemWriteActor: FileWriteOperationsProtocol {
  /// Logger for operation tracking
  private let logger: LoggingProtocol

  /// File manager instance for performing file operations
  private let fileManager: FileManager

  /// Queue for serializing file operations
  private let operationQueue: DispatchQueue

  /// Optional root directory for sandboxed operation
  private let rootDirectory: String?

  /**
   Initialises a new FileSystemWriteActor.

   - Parameters:
      - logger: The logger to use for operation tracking
      - rootDirectory: Optional root directory to restrict operations to
   */
  public init(logger: LoggingProtocol, rootDirectory: String?=nil) {
    self.logger=logger
    fileManager=FileManager.default
    operationQueue=DispatchQueue(label: "com.umbra.filesystem.write", qos: .userInitiated)
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
        source: "FileSystemWriteActor",
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
   Creates an empty file at the specified path.

   - Parameters:
      - path: The path where the file should be created.
      - options: Optional file creation options.
   - Returns: The path to the created file.
   - Throws: FileSystemError if the file creation fails.
   */
  public func createFile(at path: String, options: FileCreationOptions?) async throws -> String {
    let context=FileSystemLogContext(
      operation: "createFile",
      path: path
    )

    await logger.debug("Creating file", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Check if we need to create parent directories
      if let createParentDirectories=options?.createParentDirectories, createParentDirectories {
        let parentDirectory=(validatedPath as NSString).deletingLastPathComponent
        if !parentDirectory.isEmpty && !fileManager.fileExists(atPath: parentDirectory) {
          try fileManager.createDirectory(
            atPath: parentDirectory,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      }

      // Create the file
      let created=fileManager.createFile(
        atPath: validatedPath,
        contents: options?.initialContents,
        attributes: options?.attributes?.toDictionary()
      )

      if !created {
        throw FileSystemError.writeError(
          path: validatedPath,
          reason: "Failed to create file"
        )
      }

      // Log successful creation
      let successContext=context
        .withStatus("success")
      await logger.debug("Successfully created file", context: successContext)

      return validatedPath
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error("Failed to create file: \(error.localizedDescription)", context: context)
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "createFile", path: path)
      await logger.error(
        "Failed to create file: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }

  /**
   Writes data to a file at the specified path.

   - Parameters:
      - data: The data to write.
      - path: The path where the data should be written.
      - options: Optional file write options.
   - Throws: FileSystemError if the write operation fails.
   */
  public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws {
    let context=FileSystemLogContext.forWriteOperation(
      path: path,
      size: data.count
    )

    await logger.debug("Writing data to file", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Check if we can overwrite existing files
      let overwrite=options?.overwrite ?? false

      if fileManager.fileExists(atPath: validatedPath) && !overwrite {
        throw FileSystemError.alreadyExists(path: validatedPath)
      }

      // Create parent directories if needed
      if let createParentDirectories=options?.createParentDirectories, createParentDirectories {
        let parentDirectory=(validatedPath as NSString).deletingLastPathComponent
        if !parentDirectory.isEmpty && !fileManager.fileExists(atPath: parentDirectory) {
          try fileManager.createDirectory(
            atPath: parentDirectory,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      }

      // Atomically write the file
      let atomicWrite=options?.atomicWrite ?? true
      try data.write(
        to: URL(fileURLWithPath: validatedPath),
        options: atomicWrite ? .atomic : []
      )

      // Set attributes if provided
      if let attrs=options?.attributes, !attrs.isEmpty {
        try fileManager.setAttributes(attrs.toDictionary(), ofItemAtPath: validatedPath)
      }

      // Log successful write
      let successContext=context
        .withStatus("success")
      await logger.debug("Successfully wrote file", context: successContext)
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error("Failed to write file: \(error.localizedDescription)", context: context)
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "writeFile", path: path)
      await logger.error(
        "Failed to write file: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }

  /**
   Writes a string to a file at the specified path.

   - Parameters:
      - string: The string to write.
      - path: The path where the string should be written.
      - encoding: The string encoding to use.
      - options: Optional file write options.
   - Throws: FileSystemError if the write operation fails.
   */
  public func writeString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileWriteOptions?
  ) async throws {
    let context=FileSystemLogContext.forWriteOperation(
      path: path,
      size: string.count
    )

    let metadata=context.metadata.withPublic(key: "encoding", value: "\(encoding)")
    let enhancedContext=context.withUpdatedMetadata(metadata)

    await logger.debug("Writing string to file", context: enhancedContext)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Convert string to data with the specified encoding
      guard let data=string.data(using: encoding) else {
        throw FileSystemError.encodingError(
          reason: "Failed to encode string with the specified encoding: \(encoding)"
        )
      }

      // Write the data
      try await writeFile(data: data, to: validatedPath, options: options)

      // Log successful write
      let successContext=enhancedContext
        .withStatus("success")
      await logger.debug("Successfully wrote string to file", context: successContext)
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to write string to file: \(error.localizedDescription)",
        context: enhancedContext
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "writeString", path: path)
      await logger.error(
        "Failed to write string to file: \(wrappedError.localizedDescription)",
        context: enhancedContext
      )
      throw wrappedError
    }
  }

  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The path where the directory should be created.
      - options: Optional directory creation options.
   - Returns: The path to the created directory.
   - Throws: FileSystemError if the directory creation fails.
   */
  public func createDirectory(
    at path: String,
    options: DirectoryCreationOptions?
  ) async throws -> String {
    let context=FileSystemLogContext(
      operation: "createDirectory",
      path: path
    )

    await logger.debug("Creating directory", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Create the directory
      let createIntermediates=options?.createIntermediateDirectories ?? true

      try fileManager.createDirectory(
        atPath: validatedPath,
        withIntermediateDirectories: createIntermediates,
        attributes: options?.attributes?.toDictionary()
      )

      // Log successful creation
      let successContext=context
        .withStatus("success")
      await logger.debug("Successfully created directory", context: successContext)

      return validatedPath
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to create directory: \(error.localizedDescription)",
        context: context
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "createDirectory", path: path)
      await logger.error(
        "Failed to create directory: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }

  /**
   Deletes a file or directory at the specified path.

   - Parameter path: The path to the file or directory to delete.
   - Throws: FileSystemError if the deletion fails.
   */
  public func delete(at path: String) async throws {
    let context=FileSystemLogContext(
      operation: "delete",
      path: path
    )

    await logger.debug("Deleting file or directory", context: context)

    do {
      // Validate path is within root directory if specified
      let validatedPath=try validatePath(path)

      // Check if the file exists
      if !fileManager.fileExists(atPath: validatedPath) {
        throw FileSystemError.notFound(path: validatedPath)
      }

      // Delete the file or directory
      try fileManager.removeItem(atPath: validatedPath)

      // Log successful deletion
      let successContext=context
        .withStatus("success")
      await logger.debug("Successfully deleted file or directory", context: successContext)
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to delete file or directory: \(error.localizedDescription)",
        context: context
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "delete", path: path)
      await logger.error(
        "Failed to delete file or directory: \(wrappedError.localizedDescription)",
        context: context
      )
      throw wrappedError
    }
  }

  /**
   Moves a file or directory from one path to another.

   - Parameters:
      - sourcePath: The source path of the file or directory to move.
      - destinationPath: The destination path where the file or directory should be moved.
      - options: Optional file move options.
   - Throws: FileSystemError if the move operation fails.
   */
  public func move(
    from sourcePath: String,
    to destinationPath: String,
    options: FileMoveOptions?
  ) async throws {
    let context=FileSystemLogContext(
      operation: "move",
      path: sourcePath
    )

    let metadata=context.metadata.withPrivate(key: "destinationPath", value: destinationPath)
    let enhancedContext=context.withUpdatedMetadata(metadata)

    await logger.debug("Moving file or directory", context: enhancedContext)

    do {
      // Validate paths are within root directory if specified
      let validatedSourcePath=try validatePath(sourcePath)
      let validatedDestinationPath=try validatePath(destinationPath)

      // Check if the source exists
      if !fileManager.fileExists(atPath: validatedSourcePath) {
        throw FileSystemError.notFound(path: validatedSourcePath)
      }

      // Check if the destination exists and if we can overwrite
      let overwrite=options?.overwrite ?? false
      if fileManager.fileExists(atPath: validatedDestinationPath) {
        if !overwrite {
          throw FileSystemError.alreadyExists(path: validatedDestinationPath)
        }

        // Delete the destination if overwrite is enabled
        try fileManager.removeItem(atPath: validatedDestinationPath)
      }

      // Create parent directories if needed
      if let createParentDirectories=options?.createParentDirectories, createParentDirectories {
        let parentDirectory=(validatedDestinationPath as NSString).deletingLastPathComponent
        if !parentDirectory.isEmpty && !fileManager.fileExists(atPath: parentDirectory) {
          try fileManager.createDirectory(
            atPath: parentDirectory,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      }

      // Move the file or directory
      try fileManager.moveItem(atPath: validatedSourcePath, toPath: validatedDestinationPath)

      // Log successful move
      let successContext=enhancedContext
        .withStatus("success")
      await logger.debug("Successfully moved file or directory", context: successContext)
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to move file or directory: \(error.localizedDescription)",
        context: enhancedContext
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "move", path: sourcePath)
      await logger.error(
        "Failed to move file or directory: \(wrappedError.localizedDescription)",
        context: enhancedContext
      )
      throw wrappedError
    }
  }

  /**
   Copies a file or directory from one path to another.

   - Parameters:
      - sourcePath: The source path of the file or directory to copy.
      - destinationPath: The destination path where the file or directory should be copied.
      - options: Optional file copy options.
   - Throws: FileSystemError if the copy operation fails.
   */
  public func copy(
    from sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions?
  ) async throws {
    let context=FileSystemLogContext(
      operation: "copy",
      path: sourcePath
    )

    let metadata=context.metadata.withPrivate(key: "destinationPath", value: destinationPath)
    let enhancedContext=context.withUpdatedMetadata(metadata)

    await logger.debug("Copying file or directory", context: enhancedContext)

    do {
      // Validate paths are within root directory if specified
      let validatedSourcePath=try validatePath(sourcePath)
      let validatedDestinationPath=try validatePath(destinationPath)

      // Check if the source exists
      if !fileManager.fileExists(atPath: validatedSourcePath) {
        throw FileSystemError.notFound(path: validatedSourcePath)
      }

      // Check if the destination exists and if we can overwrite
      let overwrite=options?.overwrite ?? false
      if fileManager.fileExists(atPath: validatedDestinationPath) {
        if !overwrite {
          throw FileSystemError.alreadyExists(path: validatedDestinationPath)
        }

        // Delete the destination if overwrite is enabled
        try fileManager.removeItem(atPath: validatedDestinationPath)
      }

      // Create parent directories if needed
      if let createParentDirectories=options?.createParentDirectories, createParentDirectories {
        let parentDirectory=(validatedDestinationPath as NSString).deletingLastPathComponent
        if !parentDirectory.isEmpty && !fileManager.fileExists(atPath: parentDirectory) {
          try fileManager.createDirectory(
            atPath: parentDirectory,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      }

      // Copy the file or directory
      try fileManager.copyItem(atPath: validatedSourcePath, toPath: validatedDestinationPath)

      // Log successful copy
      let successContext=enhancedContext
        .withStatus("success")
      await logger.debug("Successfully copied file or directory", context: successContext)
    } catch let error as FileSystemError {
      // Re-throw already wrapped errors
      await logger.error(
        "Failed to copy file or directory: \(error.localizedDescription)",
        context: enhancedContext
      )
      throw error
    } catch {
      // Wrap and log other errors
      let wrappedError=FileSystemError.wrap(error, operation: "copy", path: sourcePath)
      await logger.error(
        "Failed to copy file or directory: \(wrappedError.localizedDescription)",
        context: enhancedContext
      )
      throw wrappedError
    }
  }
}
