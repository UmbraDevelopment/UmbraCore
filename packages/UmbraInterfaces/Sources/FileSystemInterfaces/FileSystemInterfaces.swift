/**
 # FileSystemInterfaces Module

 This module provides foundation-independent interfaces for performing file system operations.

 ## Overview

 FileSystemInterfaces defines the contracts that file system service implementations
 must adhere to, ensuring a consistent programming model regardless of the underlying
 implementation. This separation of interfaces from implementation facilitates:

 - Testing through mock implementations
 - Platform-specific optimisations without API changes
 - Clear dependency boundaries in the architecture

 ## Key Components

 - `FileSystemServiceProtocol`: The primary interface for file system operations
 - Result types for handling operation outcomes and errors

 ## Usage Example

 ```swift
 let fileSystem: FileSystemServiceProtocol = getFileSystemService()

 // Check if a file exists
 let exists = await fileSystem.fileExists(at: FilePath("/path/to/file"))

 // Read a file's contents
 let result = await fileSystem.readFile(at: FilePath("/path/to/file"))
 switch result {
 case .success(let data):
     // Process the file data
     print("File contains \(data.count) bytes")
 case .failure(let error):
     // Handle the error
     print("Failed to read file: \(error)")
 }
 ```
 */

/// Module namespace for FileSystemInterfaces
public enum FSNamespace {
  // This is a namespace-only enumeration that is not meant to be instantiated
}
