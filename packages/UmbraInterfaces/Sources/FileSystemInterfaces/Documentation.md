# FileSystem Service Documentation

## Overview

The FileSystem Service provides a comprehensive, foundation-independent interface for performing file system operations securely and efficiently. It offers a clean abstraction layer that isolates application code from platform-specific file system details.

## Getting Started

### Creating a FileSystem Service

The recommended way to obtain a FileSystem service instance is through the `FileSystemServiceFactory`:

```swift
import FileSystemInterfaces
import FileSystemServices

// Get the standard service
let fileSystem = FileSystemServiceFactory.shared.createStandardService()

// For high-performance operations
let performantFileSystem = FileSystemServiceFactory.shared.createHighPerformanceService()

// For security-sensitive operations
let secureFileSystem = FileSystemServiceFactory.shared.createSecureService()
```

### Basic File Operations

```swift
// Working with files
let filePath = FilePath(path: "/path/to/file.txt")

// Check if a file exists
let exists = await fileSystem.fileExists(at: filePath)

// Read a text file
let content = try await fileSystem.readTextFile(at: filePath)

// Write to a text file
try await fileSystem.writeTextFile(text: "Hello, world!", to: filePath)

// Delete a file
try await fileSystem.remove(at: filePath)
```

### Directory Operations

```swift
let directoryPath = FilePath(path: "/path/to/directory")

// Create a directory
try await fileSystem.createDirectory(at: directoryPath, withIntermediates: true)

// List directory contents
let contents = try await fileSystem.listDirectory(at: directoryPath, includeHidden: false)

// Check if a path is a directory
let isDir = try await fileSystem.isDirectory(at: directoryPath)
```

### Advanced Operations

```swift
// Copy files
try await fileSystem.copy(from: sourcePath, to: destinationPath, overwrite: false, preserveAttributes: true)

// Move files
try await fileSystem.move(from: sourcePath, to: destinationPath, overwrite: false)

// Create a temporary directory
let tempDir = try await fileSystem.createTemporaryDirectory(inDirectory: nil, prefix: "my-app-")

// Working with extended attributes
try await fileSystem.setExtendedAttribute(name: "com.myapp.metadata", value: [1, 2, 3], at: filePath)
let metadata = try await fileSystem.getExtendedAttribute(name: "com.myapp.metadata", at: filePath)
```

### Efficient File Handling

```swift
// Stream reading a large file in chunks
try await fileSystem.readDataInChunks(at: largeFilePath, chunkSize: 1024 * 1024) { chunk in
    // Process each chunk
    processData(chunk)
}

// Stream writing a large file
try await fileSystem.writeDataInChunks(to: outputPath, overwrite: true) {
    // Return the next chunk or nil when done
    return getNextChunk()
}
```

## Error Handling

All operations that can fail throw `FileSystemError` with detailed information about what went wrong:

```swift
do {
    try await fileSystem.writeTextFile(text: "Hello", to: path)
} catch let error as FileSystemError {
    switch error {
    case .invalidPath(let path, let reason):
        print("Invalid path \(path): \(reason)")
    case .pathNotFound(let path):
        print("Path not found: \(path)")
    case .pathAlreadyExists(let path):
        print("Path already exists: \(path)")
    case .readError(let path, let reason):
        print("Read error for \(path): \(reason)")
    case .writeError(let path, let reason):
        print("Write error for \(path): \(reason)")
    case .permissionDenied(let path, let reason):
        print("Permission denied for \(path): \(reason)")
    case .invalidArgument(let reason):
        print("Invalid argument: \(reason)")
    }
}
```

## Path Manipulation

```swift
// Normalise a path
let normalisedPath = try await fileSystem.normalisePath(path)

// Join paths
let fullPath = try await fileSystem.joinPath(basePath, with: "subfolder")

// Extract components
let fileName = fileSystem.fileName(path)
let directory = fileSystem.directoryPath(path)
```

## Best Practices

1. **Error Handling**: Always handle errors properly with appropriate recovery or fallback mechanisms.

2. **Path Validation**: Validate file paths before operations, especially those from user input.

3. **Temporary Files**: Use the built-in temporary file methods rather than creating your own.

4. **Large Files**: Use streaming methods for large files to avoid excessive memory usage.

5. **Extended Attributes**: Keep extended attribute names within your application's namespace.

6. **Concurrency**: The service is thread-safe, but be mindful of your own concurrency when handling returned data.

7. **Security**: Use the secure service variant when working with sensitive data.

## Service Configuration

### Standard Service
Balanced performance and security suitable for most applications.

### High-Performance Service
Optimised for throughput with larger buffer sizes and higher QoS priorities. Ideal for:
- Processing large files
- Batch operations
- Media processing

### Secure Service
Enhanced security measures for sensitive operations. Features:
- Stricter permission enforcement
- No symbolic link following
- Secure temporary files
- Enhanced error validation

## Architecture

The FileSystem service follows the Alpha Dot Five architecture with clear separation between interfaces and implementations. This allows for easier testing, mocking, and platform-specific optimisations.

The implementation is internally organised into logical extensions:
- Core Operations
- Directory Operations
- File Operations
- Path Operations
- Streaming Operations
- Temporary File Operations
- Extended Attribute Operations

## Compatibility Notes

- Swift 6 Ready: All APIs are designed to be forward-compatible with Swift 6.
- Concurrency: Uses Swift's structured concurrency for safe async operations.
- Actor Isolation: The service is isolated through Swift's actor system.
