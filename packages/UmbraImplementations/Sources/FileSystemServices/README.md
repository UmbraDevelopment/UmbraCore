# FileSystem Module Refactoring Documentation

## Overview

This document outlines the comprehensive refactoring of the FileSystem module to align with the Alpha Dot Five architecture and Google Swift Style Guide. The refactoring focused on improving organisation, maintainability, and clarity while ensuring full API compatibility.

## Architectural Approach

### Modular Design

The monolithic `FileSystemServiceImpl` was decomposed into focused extensions, each responsible for a specific domain of file system operations:

1. **Core Implementation (`FileSystemServiceImpl.swift`)**
   - Actor definition with state properties
   - Initialisation logic
   - Essential protocol implementation

2. **Core Operations (`CoreOperations.swift`)**
   - Primary protocol method implementations
   - Path existence verification
   - Metadata retrieval
   - Basic file/directory operations (copy, move, remove)

3. **Directory Operations (`DirectoryOperations.swift`)**
   - Directory creation, listing, and removal
   - Recursive directory enumeration
   - Directory-specific error handling

4. **File Operations (`FileOperations.swift`)**
   - Reading and writing file contents
   - Text file handling with encoding support
   - File-specific error handling and validation

5. **Path Operations (`PathOperations.swift`)**
   - Path normalisation and standardisation
   - Path component extraction
   - Path joining and manipulation

6. **Temporary File Operations (`TemporaryFileOperations.swift`)**
   - Secure temporary file and directory creation
   - Resource cleanup and lifecycle management
   - Controlled temporary resource usage

7. **Extended Attribute Operations (`ExtendedAttributeOperations.swift`)**
   - Custom metadata management for files
   - Setting, getting, and enumerating extended attributes
   - Attribute-specific error handling

8. **Streaming Operations (`StreamingOperations.swift`)**
   - Chunked reading and writing for large files
   - Memory-efficient data processing
   - Progressive file handling

### Factory Pattern Implementation

Created a `FileSystemServiceFactory` that provides:

- Standard service configuration for general use
- High-performance configuration for throughput-intensive operations
- Secure configuration with enhanced security settings
- Custom configuration for specialised requirements

## Alpha Dot Five Conformance

### Interface Separation

- Maintained clear boundaries between interfaces and implementations
- Ensured all public methods conform to the `FileSystemServiceProtocol`
- Kept implementation details internal to the module

### Error Handling Strategy

- Used domain-specific `FileSystemError` types from `FileSystemInterfaces`
- Added detailed error descriptions with specific error contexts
- Implemented proper error propagation with transformation from system errors

### Concurrency Support

- Maintained actor isolation for thread safety
- Used `@Sendable` annotations where appropriate for concurrent operations
- Implemented non-isolated methods for performance-critical path operations

## Code Style Improvements

### Documentation

- Added comprehensive documentation for all types and methods
- Used consistent British English spellings in documentation comments
- Included parameter and return value descriptions
- Documented thrown errors and their conditions

### Naming Conventions

- Standardised method naming (e.g., consistent use of prepositions)
- Made parameter labels clear and descriptive
- Followed Google Swift Style Guide for naming conventions

### Error Logging

- Added consistent logging throughout all operations
- Included appropriate log levels based on operation significance
- Ensured log messages are clear and actionable

## Build System Updates

- Updated BUILD.bazel file to explicitly list source files
- Corrected dependencies to support the new architecture
- Removed unnecessary dependencies on legacy modules

## Testing Considerations

The refactored code was designed with testability in mind:

- Internal properties exposed via internal access level for testing
- Clear method boundaries for unit testing
- Dependency injection for FileManager and Logger
- Isolation of side effects for predictable testing

## Migration Path

1. **Current State**: The refactored implementation maintains full API compatibility with the original
2. **Next Steps**: 
   - Develop comprehensive unit tests for all components
   - Consider further optimisations for high-throughput operations
   - Update any client code to use the factory pattern

## Usage Examples

### Standard Usage

```swift
// Get a standard file system service
let fileService = FileSystemServiceFactory.shared.createStandardService(
    logger: appLogger
)

// Use the service
Task {
    try await fileService.writeTextFile(
        text: "Hello, World!",
        to: FilePath(path: "/path/to/file.txt")
    )
}
```

### High-Performance Usage

```swift
// Get a high-performance file system service
let fileService = FileSystemServiceFactory.shared.createHighPerformanceService(
    logger: appLogger
)

// Use with chunked operations for large files
Task {
    try await fileService.writeDataInChunks(
        to: FilePath(path: "/path/to/large-file.bin"),
        overwrite: true
    ) {
        // Return the next chunk or nil when done
        getNextChunk()
    }
}
```

### Secure Usage

```swift
// Get a secure file system service
let fileService = FileSystemServiceFactory.shared.createSecureService(
    logger: appLogger
)

// Use with temporary files for secure operations
Task {
    let result = try await fileService.withTemporaryFile(
        prefix: "secure-",
        suffix: ".tmp"
    ) { tempPath in
        // Perform secure operations with temporary file
        // The file will be automatically deleted after this block
        return processSensitiveData(at: tempPath)
    }
}
```
