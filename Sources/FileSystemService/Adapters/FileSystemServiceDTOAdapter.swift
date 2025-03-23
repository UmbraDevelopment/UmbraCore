import CoreDTOs
import Foundation
import UmbraCoreTypes

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// Foundation-independent adapter for file system operations
public class FileSystemServiceDTOAdapter: FileSystemServiceDTOProtocol {
  // MARK: - Private Properties

  private let fileManager: FileManager
  private let errorDomain=ErrorHandlingDomains.UmbraErrors.FileSystem.self

  // MARK: - Initialization

  /// Initialize with a specific FileManager instance
  /// - Parameter fileManager: FileManager to use for operations
  public init(fileManager: FileManager = .default) {
    self.fileManager=fileManager
  }

  // MARK: - FileSystemServiceDTOProtocol Implementation

  /// Check if a file exists at the specified path
  /// - Parameter path: File path to check
  /// - Returns: Boolean indicating existence
  public func fileExists(at path: FilePathDTO) async -> Bool {
    let pathString=path.absolutePath
    return fileManager.fileExists(atPath: pathString)
  }

  /// Get metadata about a file
  /// - Parameter path: File path to check
  /// - Returns: Metadata or nil if file doesn't exist
  public func getMetadata(at path: FilePathDTO) async -> FileSystemMetadataDTO? {
    let pathString=path.absolutePath

    // Check if file exists
    var isDirectory: ObjCBool=false
    guard fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory) else {
      return nil
    }

    do {
      // Get file attributes
      let attributes=try fileManager.attributesOfItem(atPath: pathString)

      // Determine resource type
      let resourceType: FilePathDTO.ResourceType
      if isDirectory.boolValue {
        resourceType = .directory
      } else {
        // Check if it's a symbolic link
        let resourceValues=try URL(fileURLWithPath: pathString)
          .resourceValues(forKeys: [.isSymbolicLinkKey])
        if let isSymbolicLink=resourceValues.isSymbolicLink, isSymbolicLink {
          resourceType = .symbolicLink
        } else {
          resourceType = .file
        }
      }

      // Create and return metadata
      return FileSystemMetadataDTO.from(
        attributes: attributes,
        path: pathString,
        resourceType: resourceType
      )
    } catch {
      return FileSystemMetadataDTO.empty(resourceType: isDirectory.boolValue ? .directory : .file)
    }
  }

  /// List contents of a directory
  /// - Parameters:
  ///   - directoryPath: Directory to list
  ///   - includeHidden: Whether to include hidden files
  /// - Returns: Array of file paths or error
  public func listDirectory(
    at directoryPath: FilePathDTO,
    includeHidden: Bool
  ) async -> OperationResultDTO<[FilePathDTO]> {
    let pathString=directoryPath.absolutePath

    do {
      // Check if directory exists
      var isDirectory: ObjCBool=false
      guard fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory) else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.directoryNotFound.code,
          domain: errorDomain.directoryNotFound.domain,
          message: "Directory does not exist at path: \(pathString)"
        ))
      }

      guard isDirectory.boolValue else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.notADirectory.code,
          domain: errorDomain.notADirectory.domain,
          message: "Path is not a directory: \(pathString)"
        ))
      }

      // Get contents
      let contents=try fileManager.contentsOfDirectory(atPath: pathString)

      // Filter hidden files if needed
      let filteredContents=includeHidden ? contents : contents.filter { !$0.hasPrefix(".") }

      // Create FilePathDTOs
      var result=[FilePathDTO]()
      for item in filteredContents {
        let itemPath=pathString + "/" + item

        // Determine if it's a directory, file, or symbolic link
        var itemIsDirectory: ObjCBool=false
        if fileManager.fileExists(atPath: itemPath, isDirectory: &itemIsDirectory) {
          let resourceType: FilePathDTO.ResourceType

          if itemIsDirectory.boolValue {
            resourceType = .directory
          } else {
            // Check if it's a symbolic link
            let resourceValues=try URL(fileURLWithPath: itemPath)
              .resourceValues(forKeys: [.isSymbolicLinkKey])
            if let isSymbolicLink=resourceValues.isSymbolicLink, isSymbolicLink {
              resourceType = .symbolicLink
            } else {
              resourceType = .file
            }
          }

          // Create FilePathDTO
          let fileDTO=FilePathDTO(
            absolutePath: itemPath,
            resourceType: resourceType
          )
          result.append(fileDTO)
        }
      }

      return .success(result)
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.listDirectoryFailed.code,
        domain: errorDomain.listDirectoryFailed.domain,
        message: "Failed to list directory: \(error.localizedDescription)"
      ))
    }
  }

  /// Create a directory
  /// - Parameters:
  ///   - path: Directory path to create
  ///   - withIntermediates: Whether to create intermediate directories
  /// - Returns: Success or error
  public func createDirectory(
    at path: FilePathDTO,
    withIntermediates: Bool
  ) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath

    do {
      try fileManager.createDirectory(
        atPath: pathString,
        withIntermediateDirectories: withIntermediates,
        attributes: nil
      )
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.createDirectoryFailed.code,
        domain: errorDomain.createDirectoryFailed.domain,
        message: "Failed to create directory: \(error.localizedDescription)"
      ))
    }
  }

  /// Create a file
  /// - Parameters:
  ///   - path: File path to create
  ///   - data: Data to write
  ///   - overwrite: Whether to overwrite if file exists
  /// - Returns: Success or error
  public func createFile(
    at path: FilePathDTO,
    data: [UInt8],
    overwrite: Bool
  ) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath

    // Check if file exists and we're not overwriting
    if !overwrite && fileManager.fileExists(atPath: pathString) {
      return .failure(SecurityErrorDTO(
        code: errorDomain.fileAlreadyExists.code,
        domain: errorDomain.fileAlreadyExists.domain,
        message: "File already exists and overwrite is not enabled"
      ))
    }

    do {
      // Create Data from bytes
      let fileData=Data(data)

      // Write to file
      try fileData.write(to: URL(fileURLWithPath: pathString))
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.createFileFailed.code,
        domain: errorDomain.createFileFailed.domain,
        message: "Failed to create file: \(error.localizedDescription)"
      ))
    }
  }

  /// Read file contents
  /// - Parameter path: File path to read
  /// - Returns: File data or error
  public func readFile(at path: FilePathDTO) async -> OperationResultDTO<[UInt8]> {
    let pathString=path.absolutePath

    do {
      // Read file data
      let data=try Data(contentsOf: URL(fileURLWithPath: pathString))
      return .success([UInt8](data))
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.readFileFailed.code,
        domain: errorDomain.readFileFailed.domain,
        message: "Failed to read file: \(error.localizedDescription)"
      ))
    }
  }

  /// Write data to a file
  /// - Parameters:
  ///   - path: File path to write
  ///   - data: Data to write
  /// - Returns: Success or error
  public func writeFile(at path: FilePathDTO, data: [UInt8]) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath

    do {
      // Create Data from bytes
      let fileData=Data(data)

      // Write to file
      try fileData.write(to: URL(fileURLWithPath: pathString))
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.writeFileFailed.code,
        domain: errorDomain.writeFileFailed.domain,
        message: "Failed to write file: \(error.localizedDescription)"
      ))
    }
  }

  /// Append data to a file
  /// - Parameters:
  ///   - path: File path to append to
  ///   - data: Data to append
  /// - Returns: Success or error
  public func appendFile(at path: FilePathDTO, data: [UInt8]) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath

    do {
      // Create Data from bytes
      let fileData=Data(data)

      // Create file handle
      let fileHandle=try FileHandle(forWritingTo: URL(fileURLWithPath: pathString))

      // Seek to end
      try fileHandle.seekToEnd()

      // Write data
      try fileHandle.write(contentsOf: fileData)

      // Close file
      try fileHandle.close()

      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.appendFileFailed.code,
        domain: errorDomain.appendFileFailed.domain,
        message: "Failed to append to file: \(error.localizedDescription)"
      ))
    }
  }

  /// Delete a file or directory
  /// - Parameters:
  ///   - path: Path to delete
  ///   - recursive: Whether to delete directory contents recursively
  /// - Returns: Success or error
  public func delete(at path: FilePathDTO, recursive: Bool) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath

    do {
      // Check if file exists
      var isDirectory: ObjCBool=false
      guard fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory) else {
        return .success(()) // File doesn't exist, so nothing to delete
      }

      // Handle directory case
      if isDirectory.boolValue {
        // For directories, check if recursive deletion is requested
        if recursive {
          try fileManager.removeItem(atPath: pathString)
        } else {
          // Check if directory is empty
          let contents=try fileManager.contentsOfDirectory(atPath: pathString)
          if !contents.isEmpty {
            return .failure(SecurityErrorDTO(
              code: errorDomain.directoryNotEmpty.code,
              domain: errorDomain.directoryNotEmpty.domain,
              message: "Directory is not empty and recursive deletion was not requested"
            ))
          }

          // Directory is empty, delete it
          try fileManager.removeItem(atPath: pathString)
        }
      } else {
        // For files, just delete
        try fileManager.removeItem(atPath: pathString)
      }

      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.deleteFailed.code,
        domain: errorDomain.deleteFailed.domain,
        message: "Failed to delete item: \(error.localizedDescription)"
      ))
    }
  }

  /// Move a file or directory
  /// - Parameters:
  ///   - sourcePath: Source path
  ///   - destinationPath: Destination path
  /// - Returns: Success or error
  public func move(
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO
  ) async -> OperationResultDTO<Void> {
    let sourcePathString=sourcePath.absolutePath
    let destinationPathString=destinationPath.absolutePath

    do {
      // Check if source exists
      guard fileManager.fileExists(atPath: sourcePathString) else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.fileNotFound.code,
          domain: errorDomain.fileNotFound.domain,
          message: "Source file does not exist: \(sourcePathString)"
        ))
      }

      // Check if destination exists
      if fileManager.fileExists(atPath: destinationPathString) {
        return .failure(SecurityErrorDTO(
          code: errorDomain.fileAlreadyExists.code,
          domain: errorDomain.fileAlreadyExists.domain,
          message: "Destination file already exists: \(destinationPathString)"
        ))
      }

      // Move file
      try fileManager.moveItem(atPath: sourcePathString, toPath: destinationPathString)
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.moveFailed.code,
        domain: errorDomain.moveFailed.domain,
        message: "Failed to move item: \(error.localizedDescription)"
      ))
    }
  }

  /// Copy a file or directory
  /// - Parameters:
  ///   - sourcePath: Source path
  ///   - destinationPath: Destination path
  ///   - recursive: Whether to copy directory contents recursively
  /// - Returns: Success or error
  public func copy(
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
    recursive: Bool
  ) async -> OperationResultDTO<Void> {
    let sourcePathString=sourcePath.absolutePath
    let destinationPathString=destinationPath.absolutePath

    do {
      // Check if source exists
      var isDirectory: ObjCBool=false
      guard fileManager.fileExists(atPath: sourcePathString, isDirectory: &isDirectory) else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.fileNotFound.code,
          domain: errorDomain.fileNotFound.domain,
          message: "Source file does not exist: \(sourcePathString)"
        ))
      }

      // Check if destination exists
      if fileManager.fileExists(atPath: destinationPathString) {
        return .failure(SecurityErrorDTO(
          code: errorDomain.fileAlreadyExists.code,
          domain: errorDomain.fileAlreadyExists.domain,
          message: "Destination file already exists: \(destinationPathString)"
        ))
      }

      // Handle directory case
      if isDirectory.boolValue {
        if recursive {
          // Copy directory and contents
          try fileManager.copyItem(atPath: sourcePathString, toPath: destinationPathString)
        } else {
          // Create empty directory
          try fileManager.createDirectory(
            atPath: destinationPathString,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
      } else {
        // Copy file
        try fileManager.copyItem(atPath: sourcePathString, toPath: destinationPathString)
      }

      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.copyFailed.code,
        domain: errorDomain.copyFailed.domain,
        message: "Failed to copy item: \(error.localizedDescription)"
      ))
    }
  }

  /// Set file permissions
  /// - Parameters:
  ///   - path: File path
  ///   - readable: Whether file should be readable
  ///   - writable: Whether file should be writable
  ///   - executable: Whether file should be executable
  /// - Returns: Success or error
  public func setPermissions(
    at path: FilePathDTO,
    readable: Bool,
    writable: Bool,
    executable: Bool
  ) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath

    do {
      // Get current attributes
      let attributes=try fileManager.attributesOfItem(atPath: pathString)

      // Get current permissions
      guard let currentPermissions=attributes[.posixPermissions] as? NSNumber else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.permissionError.code,
          domain: errorDomain.permissionError.domain,
          message: "Could not get current permissions"
        ))
      }

      // Calculate new permissions
      var newPermissions=currentPermissions.uint16Value

      // Owner permissions (bits 8-6)
      newPermissions=(newPermissions & ~0o700) | // Clear owner bits
        (readable ? 0o400 : 0) | // Set read bit
        (writable ? 0o200 : 0) | // Set write bit
        (executable ? 0o100 : 0) // Set execute bit

      // Set new permissions
      try fileManager.setAttributes(
        [.posixPermissions: NSNumber(value: newPermissions)],
        ofItemAtPath: pathString
      )

      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.permissionError.code,
        domain: errorDomain.permissionError.domain,
        message: "Failed to set permissions: \(error.localizedDescription)"
      ))
    }
  }

  /// Create a symbolic link
  /// - Parameters:
  ///   - path: Path for the link
  ///   - targetPath: Target the link points to
  /// - Returns: Success or error
  public func createSymbolicLink(
    at path: FilePathDTO,
    targetPath: FilePathDTO
  ) async -> OperationResultDTO<Void> {
    let pathString=path.absolutePath
    let targetPathString=targetPath.absolutePath

    do {
      // Create symbolic link
      try fileManager.createSymbolicLink(atPath: pathString, withDestinationPath: targetPathString)
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.symlinkError.code,
        domain: errorDomain.symlinkError.domain,
        message: "Failed to create symbolic link: \(error.localizedDescription)"
      ))
    }
  }

  /// Resolve a symbolic link
  /// - Parameter path: Path to resolve
  /// - Returns: Resolved path or error
  public func resolveSymbolicLink(at path: FilePathDTO) async -> OperationResultDTO<FilePathDTO> {
    let pathString=path.absolutePath

    do {
      // Check if path is a symbolic link
      let resourceValues=try URL(fileURLWithPath: pathString)
        .resourceValues(forKeys: [.isSymbolicLinkKey])
      guard let isSymbolicLink=resourceValues.isSymbolicLink, isSymbolicLink else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.notASymlink.code,
          domain: errorDomain.notASymlink.domain,
          message: "Path is not a symbolic link: \(pathString)"
        ))
      }

      // Resolve the link
      let destination=try fileManager.destinationOfSymbolicLink(atPath: pathString)

      // Create FilePathDTO from the resolved path
      let resolvedPath=FilePathDTO(
        absolutePath: destination,
        resourceType: .unknown // We don't know the type of the target until we check it
      )

      return .success(resolvedPath)
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.symlinkError.code,
        domain: errorDomain.symlinkError.domain,
        message: "Failed to resolve symbolic link: \(error.localizedDescription)"
      ))
    }
  }

  /// Get temporary directory
  /// - Returns: Path to temporary directory
  public func temporaryDirectory() -> FilePathDTO {
    let tempDir=fileManager.temporaryDirectory.path
    return FilePathDTO(
      absolutePath: tempDir,
      resourceType: .directory
    )
  }

  /// Get user's document directory
  /// - Returns: Path to document directory or error
  public func documentDirectory() -> OperationResultDTO<FilePathDTO> {
    do {
      let documentDirectoryURL=try fileManager.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
      )

      let path=FilePathDTO(
        absolutePath: documentDirectoryURL.path,
        resourceType: .directory
      )

      return .success(path)
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.directoryNotFound.code,
        domain: errorDomain.directoryNotFound.domain,
        message: "Failed to get document directory: \(error.localizedDescription)"
      ))
    }
  }
}
