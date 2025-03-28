/**
 # FileSystemServices Module
 
 This module provides comprehensive implementations of file system interfaces,
 with secure and optimised file operations.
 
 ## Overview
 
 FileSystemServices implements the FileSystemInterfaces protocols, providing
 foundation-independent abstractions for common file system operations with
 proper error handling and security considerations.
 
 ## Key Features
 
 - Thread-safe file operations through proper synchronisation
 - Comprehensive error mapping to domain-specific error types
 - Support for common operations like read, write, move, and copy
 - Directory listing with filtering options
 - Metadata extraction for files and directories
 
 ## Usage Example
 
 ```swift
 // Get the file system service implementation
 let fileSystem = FileSystemServiceImpl()
 
 // Read a configuration file
 let configPath = FilePath("/path/to/config.json")
 let result = await fileSystem.readFile(at: configPath)
 
 switch result {
 case .success(let data):
     // Process the configuration data
     let configString = String(bytes: data, encoding: .utf8)
     print("Loaded configuration: \(configString ?? "")")
 
 case .failure(let error):
     // Handle the specific error
     print("Failed to load configuration: \(error)")
 }
 ```
 
 ## Error Handling
 
 All operations return strongly-typed results that include detailed error information
 when operations fail. This allows for proper error handling and recovery strategies.
 */

/// Module namespace for file system service implementations
public enum FileSystemServices {
    // This is a namespace-only enumeration that is not meant to be instantiated
}
