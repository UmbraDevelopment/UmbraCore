import CoreDTOs
import Operations
import FileSystem
import Foundation
import UmbraCoreTypes
import FileSystemTypes
import ErrorHandlingDomains
import UmbraErrors
import UmbraErrorsCore
import DTOs
import SecurityInterfaces

/// Foundation-dependent adapter for file system operations
/// Provides file system operations with Foundation types converted to DTOs
// FIXME: Swift 6 Sendable conformance
// This class needs to handle the non-Sendable fileManager property
// When migrating to Swift 6, either:
// 1. Make this class final and use @unchecked Sendable in the protocol conformance list
// 2. Use a thread-safe wrapper around FileManager
// 3. Add actor isolation
public final class FileSystemServiceDTOAdapter: FileSystemServiceDTOProtocol {
  // MARK: - Private Properties

  // FIXME: Not Sendable in Swift 6
  // FileManager is not Sendable but we only use the default instance
  // which is safe for concurrent access to separate files
  private let fileManager: FileManager
  // Use the proper error domain from ErrorHandlingDomains
  private let errorDomain = ErrorDomains.application

  // MARK: - Initialization

  /// Create a new adapter with the specified file manager
  /// - Parameter fileManager: A file manager instance
  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  // MARK: - FileSystemServiceDTOProtocol

  /// Check if a file exists
  /// - Parameter path: Path to check
  /// - Returns: Boolean indicating if file exists
  public func fileExists(
    at path: FilePathDTO
  ) async -> Bool {
    let pathString = path.path
    return fileManager.fileExists(atPath: pathString)
  }

  /// Get metadata for a file
  /// - Parameter path: Path to get metadata for
  /// - Returns: Metadata or nil if file doesn't exist
  public func getMetadata(
    at path: FilePathDTO
  ) async -> FileSystemMetadataDTO? {
    let pathString = path.path
    
    guard let attributes = try? fileManager.attributesOfItem(atPath: pathString) else {
      return nil
    }
    
    // Extract file attributes
    let fileSize = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
    let creationDate = attributes[.creationDate] as? Date ?? Date()
    let modificationDate = attributes[.modificationDate] as? Date ?? Date()
    
    // Convert dates to UInt64 timestamps
    let creationTimestamp = UInt64(creationDate.timeIntervalSince1970)
    let modificationTimestamp = UInt64(modificationDate.timeIntervalSince1970)
    
    // Extract permissions
    let permissions = (attributes[.posixPermissions] as? NSNumber)?.uint16Value
    
    // Check if it's a directory
    let isDirectory = (attributes[.type] as? FileAttributeType) == .typeDirectory
    
    // Get file extension if any
    let fileExtension = (pathString as NSString).pathExtension
    
    // Determine if file is hidden
    let isHidden = (pathString as NSString).lastPathComponent.hasPrefix(".")
    
    // Determine if file is readable/writable/executable
    let isReadable = fileManager.isReadableFile(atPath: pathString)
    let isWritable = fileManager.isWritableFile(atPath: pathString)
    let isExecutable = fileManager.isExecutableFile(atPath: pathString)
    
    // Determine resource type
    let resourceType: FilePathDTO.ResourceType = isDirectory ? .directory : .file
    
    return FileSystemMetadataDTO(
      fileSize: fileSize,
      creationDate: creationTimestamp,
      modificationDate: modificationTimestamp,
      accessDate: nil,
      ownerID: (attributes[.ownerAccountID] as? NSNumber)?.uint32Value,
      groupID: (attributes[.groupOwnerAccountID] as? NSNumber)?.uint32Value,
      permissions: permissions,
      fileExtension: fileExtension.isEmpty ? nil : fileExtension,
      mimeType: nil,
      isHidden: isHidden,
      isReadable: isReadable,
      isWritable: isWritable,
      isExecutable: isExecutable,
      resourceType: resourceType,
      attributes: [:]
    )
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
    let pathString = directoryPath.path
    
    do {
      // Check if directory exists
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory) else {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Directory does not exist at path: \(pathString)",
          context: ["path": pathString]
        ))
      }
      
      guard isDirectory.boolValue else {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Path is not a directory: \(pathString)",
          context: ["path": pathString]
        ))
      }
      
      // Get contents
      let contents = try fileManager.contentsOfDirectory(atPath: pathString)
      
      // Filter hidden files if needed
      let filteredContents = includeHidden ? contents : contents.filter { !$0.hasPrefix(".") }
      
      // Create FilePathDTOs
      var result = [FilePathDTO]()
      for item in filteredContents {
        let itemPath = pathString + "/" + item
        
        // Determine if it's a directory
        var itemIsDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: itemPath, isDirectory: &itemIsDirectory) {
          let resourceType: FilePathDTO.ResourceType = itemIsDirectory.boolValue ? .directory : .file
          
          // Create FilePathDTO
          let fileName = (itemPath as NSString).lastPathComponent
          let directoryPath = (itemPath as NSString).deletingLastPathComponent
          
          let fileDTO = FilePathDTO(
            path: itemPath,
            fileName: fileName,
            directoryPath: directoryPath,
            resourceType: resourceType
          )
          result.append(fileDTO)
        }
      }
      
      return .success(result)
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to list directory: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }

  /// Create directory
  /// - Parameters:
  ///   - path: Directory path to create
  ///   - withIntermediates: Create intermediate directories
  /// - Returns: Success or failure with error
  public func createDirectory(
    at path: FilePathDTO,
    withIntermediates: Bool
  ) async -> OperationResultDTO<Void> {
    let pathString = path.path
    
    do {
      try fileManager.createDirectory(
        atPath: pathString,
        withIntermediateDirectories: withIntermediates,
        attributes: nil
      )
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to create directory: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
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
    let pathString = path.path
    
    // Check if file exists and we're not overwriting
    if !overwrite && fileManager.fileExists(atPath: pathString) {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "File already exists and overwrite is not enabled",
        context: ["path": pathString]
      ))
    }
    
    do {
      // Create Data from bytes
      let fileData = Data(data)
      try fileData.write(to: URL(fileURLWithPath: pathString))
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to create file: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Read file contents
  /// - Parameter path: File path to read
  /// - Returns: File data or error
  public func readFile(
    at path: FilePathDTO
  ) async -> OperationResultDTO<[UInt8]> {
    let pathString = path.path
    
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: pathString))
      return .success([UInt8](data))
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to read file: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Write data to a file
  /// - Parameters:
  ///   - path: File path to write
  ///   - data: Data to write
  /// - Returns: Success or error
  public func writeFile(
    at path: FilePathDTO,
    data: [UInt8]
  ) async -> OperationResultDTO<Void> {
    let pathString = path.path
    
    do {
      let fileData = Data(data)
      try fileData.write(to: URL(fileURLWithPath: pathString))
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to write file: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Append data to a file
  /// - Parameters:
  ///   - path: File path to append to
  ///   - data: Data to append
  /// - Returns: Success or error
  public func appendFile(
    at path: FilePathDTO,
    data: [UInt8]
  ) async -> OperationResultDTO<Void> {
    let pathString = path.path
    
    do {
      let fileData = Data(data)
      let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: pathString))
      
      try fileHandle.seekToEnd()
      try fileHandle.write(contentsOf: fileData)
      try fileHandle.close()
      
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to append to file: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Delete a file or directory
  /// - Parameters:
  ///   - path: Path to delete
  ///   - recursive: Whether to delete directory contents recursively
  /// - Returns: Success or error
  public func delete(
    at path: FilePathDTO,
    recursive: Bool
  ) async -> OperationResultDTO<Void> {
    let pathString = path.path
    
    do {
      // Check if file exists
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory) else {
        return .success(()) // Nothing to delete
      }
      
      // Handle directory case
      if isDirectory.boolValue {
        if recursive {
          try fileManager.removeItem(atPath: pathString)
        } else {
          // Check if directory is empty
          let contents = try fileManager.contentsOfDirectory(atPath: pathString)
          if !contents.isEmpty {
            return .failure(SecurityErrorDTO(
              type: .unknown,
              description: "Directory is not empty and recursive deletion was not requested",
              context: ["path": pathString]
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
        type: .unknown,
        description: "Failed to delete item: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
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
    let sourcePathString = sourcePath.path
    let destinationPathString = destinationPath.path
    
    do {
      // Check if source exists
      guard fileManager.fileExists(atPath: sourcePathString) else {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Source file does not exist: \(sourcePathString)",
          context: ["sourcePath": sourcePathString]
        ))
      }
      
      // Check if destination exists
      if fileManager.fileExists(atPath: destinationPathString) {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Destination file already exists: \(destinationPathString)",
          context: ["destinationPath": destinationPathString]
        ))
      }
      
      // Move file
      try fileManager.moveItem(atPath: sourcePathString, toPath: destinationPathString)
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to move item: \(error.localizedDescription)",
        context: ["sourcePath": sourcePathString, "destinationPath": destinationPathString],
        underlyingError: error
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
    let sourcePathString = sourcePath.path
    let destinationPathString = destinationPath.path
    
    do {
      // Check if source exists
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: sourcePathString, isDirectory: &isDirectory) else {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Source file does not exist: \(sourcePathString)",
          context: ["sourcePath": sourcePathString]
        ))
      }
      
      // Check if destination exists
      if fileManager.fileExists(atPath: destinationPathString) {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Destination file already exists: \(destinationPathString)",
          context: ["destinationPath": destinationPathString]
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
        type: .unknown,
        description: "Failed to copy item: \(error.localizedDescription)",
        context: ["sourcePath": sourcePathString, "destinationPath": destinationPathString],
        underlyingError: error
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
    let pathString = path.path
    
    do {
      // Get current attributes
      let attributes = try fileManager.attributesOfItem(atPath: pathString)
      
      // Get current permissions
      guard let currentPermissions = attributes[.posixPermissions] as? NSNumber else {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Could not get current permissions",
          context: ["path": pathString]
        ))
      }
      
      // Calculate new permissions
      var newPermissions = currentPermissions.uint16Value
      
      // Owner permissions (bits 8-6)
      newPermissions = (newPermissions & ~0o700) | // Clear owner bits
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
        type: .unknown,
        description: "Failed to set permissions: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
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
    let pathString = path.path
    let targetPathString = targetPath.path
    
    do {
      // Create symbolic link
      try fileManager.createSymbolicLink(atPath: pathString, withDestinationPath: targetPathString)
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to create symbolic link: \(error.localizedDescription)",
        context: ["path": pathString, "targetPath": targetPathString],
        underlyingError: error
      ))
    }
  }
  
  /// Resolve a symbolic link
  /// - Parameter path: Path to resolve
  /// - Returns: Resolved path or error
  public func resolveSymbolicLink(
    at path: FilePathDTO
  ) async -> OperationResultDTO<FilePathDTO> {
    let pathString = path.path
    
    do {
      // Check if path is a symbolic link
      let resourceValues = try URL(fileURLWithPath: pathString)
        .resourceValues(forKeys: [.isSymbolicLinkKey])
      guard let isSymbolicLink = resourceValues.isSymbolicLink, isSymbolicLink else {
        return .failure(SecurityErrorDTO(
          type: .unknown,
          description: "Path is not a symbolic link: \(pathString)",
          context: ["path": pathString]
        ))
      }
      
      // Resolve the link
      let destination = try fileManager.destinationOfSymbolicLink(atPath: pathString)
      
      // Create FilePathDTO from the resolved path
      let fileName = (destination as NSString).lastPathComponent
      let directoryPath = (destination as NSString).deletingLastPathComponent
      
      let resolvedPath = FilePathDTO(
        path: destination,
        fileName: fileName,
        directoryPath: directoryPath,
        resourceType: .unknown
      )
      
      return .success(resolvedPath)
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to resolve symbolic link: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Get temporary directory
  /// - Returns: Path to temporary directory
  public func temporaryDirectory() -> FilePathDTO {
    let tempDirPath = fileManager.temporaryDirectory.path
    let fileName = (tempDirPath as NSString).lastPathComponent
    let directoryPath = (tempDirPath as NSString).deletingLastPathComponent
    
    return FilePathDTO(
      path: tempDirPath,
      fileName: fileName,
      directoryPath: directoryPath,
      resourceType: .directory
    )
  }
  
  /// Get user's document directory
  /// - Returns: Path to document directory or error
  public func documentDirectory() -> OperationResultDTO<FilePathDTO> {
    do {
      let documentDirectoryURL = try fileManager.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
      )
      
      let docDirPath = documentDirectoryURL.path
      let fileName = (docDirPath as NSString).lastPathComponent
      let directoryPath = (docDirPath as NSString).deletingLastPathComponent
      
      let path = FilePathDTO(
        path: docDirPath,
        fileName: fileName,
        directoryPath: directoryPath,
        resourceType: .directory
      )
      
      return .success(path)
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to get document directory: \(error.localizedDescription)",
        underlyingError: error
      ))
    }
  }
  
  /// Write data to file
  /// - Parameters:
  ///   - data: Data to write
  ///   - path: File path
  ///   - overwrite: Whether to overwrite existing files
  /// - Returns: Success or failure with error
  public func writeData(
    _ data: Data,
    to path: FilePathDTO,
    overwrite: Bool
  ) async -> OperationResultDTO<Void> {
    let pathString = path.path
    
    // Check if file exists and we're not overwriting
    if !overwrite && fileManager.fileExists(atPath: pathString) {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "File already exists and overwrite is not enabled",
        context: ["path": pathString]
      ))
    }
    
    do {
      try data.write(to: URL(fileURLWithPath: pathString))
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to write data: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Read data from file
  /// - Parameter path: File path
  /// - Returns: Data read or error
  public func readData(
    from path: FilePathDTO
  ) async -> OperationResultDTO<Data> {
    let pathString = path.path
    
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: pathString))
      return .success(data)
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to read data: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
  
  /// Delete file
  /// - Parameter path: File path
  /// - Returns: Success or failure with error
  public func deleteFile(
    at path: FilePathDTO
  ) async -> OperationResultDTO<Void> {
    let pathString = path.path
    
    do {
      try fileManager.removeItem(atPath: pathString)
      return .success(())
    } catch {
      return .failure(SecurityErrorDTO(
        type: .unknown,
        description: "Failed to delete file: \(error.localizedDescription)",
        context: ["path": pathString],
        underlyingError: error
      ))
    }
  }
}
