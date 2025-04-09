# File System Services Developer Guide

This guide explains how to integrate with, extend, and optimise the FileSystemServices module based on our Domain-Driven Design approach.

## Integration Guide

### Basic Usage

To use the FileSystemServices in your code:

```swift
import FileSystemInterfaces
import FileSystemServices

// Create a standard service
let fileSystemService = await FileSystemServiceFactory.createStandardService()

// Read a file
do {
    let (data, result) = try await fileSystemService.readFile(at: "/path/to/file")
    // Process data...
} catch {
    // Handle errors...
}
```

### Selecting the Right Service Type

The FileSystemServiceFactory provides several service types for different needs:

```swift
// Standard service for general use
let standardService = await FileSystemServiceFactory.createStandardService()

// Security-focused service
let secureService = await FileSystemServiceFactory.createSecureService()

// Sandboxed service for restricted operations
let sandboxedService = await FileSystemServiceFactory.createSandboxedService(
    rootDirectory: "/allowed/directory"
)

// Test service for unit testing
let testService = await FileSystemServiceFactory.createTestService(
    testRootDirectory: "/test/directory",
    logger: mockLogger
)
```

Choose the appropriate service type based on your security and functionality requirements.

## Handling File Operations Safely

### Error Handling Best Practices

All file operations can throw errors. Use proper error handling:

```swift
do {
    try await fileSystemService.writeFile(data: someData, to: "/path/to/file", options: nil)
} catch let error as FileSystemError {
    switch error {
    case .pathNotFound(let path):
        // Handle specific error types
        logger.error("Path not found: \(path)")
    case .writeError(let path, let reason):
        logger.error("Write error at \(path): \(reason)")
    default:
        logger.error("Other file error: \(error)")
    }
} catch {
    logger.error("Unexpected error: \(error)")
}
```

### Using Operation Results

Every operation returns a `FileOperationResultDTO` that contains metadata and context:

```swift
let (exists, result) = await fileSystemService.fileExists(at: "/path/to/file")

if exists {
    // File exists, use result.metadata for file information
    if let metadata = result.metadata {
        print("File size: \(metadata.size)")
        print("Created: \(metadata.creationDate)")
    }
    
    // Check operation context
    if let context = result.context {
        // Use context information...
    }
}
```

## Extending the System

### Creating Custom Implementations

You can implement any of the subdomain protocols to create custom behaviour:

```swift
// Create a custom implementation of CoreFileOperationsProtocol
public actor CustomCoreFileOperations: CoreFileOperationsProtocol {
    // Implement required methods...
}

// Use your custom implementation
let customCoreOps = CustomCoreFileOperations()
let coreOps = CoreFileOperationsFactory.createStandardOperations()
let metadataOps = FileMetadataOperationsFactory.createStandardOperations()
let secureOps = SecureFileOperationsFactory.createStandardOperations()
let sandboxing = FileSandboxingFactory.createStandardSandbox(rootDirectory: "/path")

// Create composite service with your custom core implementation
let customService = CompositeFileSystemServiceImpl(
    coreOperations: customCoreOps,
    metadataOperations: metadataOps,
    secureOperations: secureOps,
    sandboxing: sandboxing
)
```

### Adding New Operations

To add new functionality:

1. Define a protocol extension on the appropriate subdomain protocol
2. Implement the extension in your custom implementation
3. Use the extended functionality through your service

```swift
// Extend the protocol
extension CoreFileOperationsProtocol {
    func countLinesInFile(at path: String) async throws -> Int {
        let (string, _) = try await readFileAsString(at: path, encoding: .utf8)
        return string.components(separatedBy: .newlines).count
    }
}

// Now this method is available on any CoreFileOperationsProtocol implementation
let lineCount = try await fileSystemService.countLinesInFile(at: "/path/to/file")
```

## Performance Optimisation

### Bulk Operations

For operations on multiple files, avoid sequential processing:

```swift
// Inefficient way (sequential)
for path in paths {
    try await fileSystemService.delete(at: path)
}

// Better approach (concurrent)
try await withThrowingTaskGroup(of: Void.self) { group in
    for path in paths {
        group.addTask {
            try await fileSystemService.delete(at: path)
        }
    }
}
```

### Minimising Disk Operations

Combine operations where possible to reduce I/O:

```swift
// Instead of reading, modifying, and writing back:
let (data, _) = try await fileSystemService.readFile(at: path)
let modifiedData = processData(data)
try await fileSystemService.writeFile(data: modifiedData, to: path, options: nil)

// Consider implementing and using atomic operations:
extension CoreFileOperationsProtocol {
    func modifyFile(at path: String, transform: (Data) -> Data) async throws -> FileOperationResultDTO {
        let (data, _) = try await readFile(at: path)
        let modifiedData = transform(data)
        return try await writeFile(data: modifiedData, to: path, options: nil)
    }
}
```

## Testing with the DDD Architecture

### Mocking Subdomains

Create test doubles for individual subdomains:

```swift
class MockCoreFileOperations: CoreFileOperationsProtocol {
    var readFileHandler: ((String) throws -> (Data, FileOperationResultDTO))?
    
    func readFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
        guard let handler = readFileHandler else {
            return (Data(), FileOperationResultDTO.success(path: path))
        }
        return try handler(path)
    }
    
    // Implement other required methods...
}

// Configure the mock
let mockCoreOps = MockCoreFileOperations()
mockCoreOps.readFileHandler = { path in
    if path == "/test/file.txt" {
        return (Data("test content".utf8), FileOperationResultDTO.success(path: path))
    }
    throw FileSystemError.pathNotFound(path: path)
}

// Use in tests
let service = CompositeFileSystemServiceImpl(
    coreOperations: mockCoreOps,
    metadataOperations: realMetadataOps,
    secureOperations: realSecureOps,
    sandboxing: realSandboxing
)
```

### Integration Testing

For integration tests, use a real temporary directory:

```swift
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

// Create a real service with the temporary directory
let service = await FileSystemServiceFactory.createSandboxedService(
    rootDirectory: tempDir.path
)

// Run tests...

// Clean up
try? FileManager.default.removeItem(at: tempDir)
```

## Security Considerations

### Secure File Operations

Always use the secure operations when dealing with sensitive data:

```swift
// For sensitive data, use secure operations
try await fileSystemService.writeSecureFile(
    data: sensitiveData,
    to: path,
    options: SecureFileOptions.maximumSecurity
)

// For permanent deletion of sensitive data, use secure delete
try await fileSystemService.secureDelete(at: path, passes: 3)
```

### Sandboxing for Untrusted Input

When processing user-provided paths, use sandboxing:

```swift
// Create a sandboxed service
let sandboxedService = await FileSystemServiceFactory.createSandboxedService(
    rootDirectory: "/safe/directory"
)

// Check if a user-provided path is within the sandbox
let (isWithinSandbox, _) = await sandboxedService.isPathWithinSandbox(userProvidedPath)
if isWithinSandbox {
    // Safe to proceed
} else {
    // Handle security violation
}
```

## Migrating from Legacy Code

### Step-by-Step Migration

1. Replace direct usage of `FileSystemServiceImpl` with factory-created instances:

```swift
// Old code
let fileService = FileSystemServiceImpl()

// New code
let fileService = await FileSystemServiceFactory.createStandardService()
```

2. Update error handling to work with the new FileOperationResultDTO pattern:

```swift
// Old code
do {
    try await fileService.writeFile(data: data, to: path)
} catch {
    // Handle error
}

// New code
do {
    let result = try await fileService.writeFile(data: data, to: path, options: nil)
    if result.status == .success {
        // Operation succeeded
    } else {
        // Operation had issues
    }
} catch {
    // Handle error
}
```

3. For advanced use cases, gradually transition to using the specific subdomain operations where needed.

## Troubleshooting Common Issues

### File Access Permissions

If you encounter permission errors:

1. Check the file permissions using `getAttributes`
2. Ensure your application has necessary entitlements
3. For sandboxed operations, verify paths are within the allowed directory
4. For secure bookmarks, ensure they are properly created and stored

### Concurrency Issues

The actor-based design prevents most concurrency issues, but be aware of:

1. Long-running operations blocking an actor
2. Excessive concurrent operations on the same file
3. Deadlocks when calling between actors incorrectly

Use `withThrowingTaskGroup` for parallel operations and minimize actor mutation.

## Best Practices

1. **Use factory methods** instead of direct instantiation
2. **Check operation results** for complete metadata
3. **Prefer sandboxed operations** for user-provided paths
4. **Implement proper error handling** with specific error types
5. **Use appropriate service types** for different security needs
6. **Leverage async/await** for concurrent operations
7. **Test with isolation** by mocking specific subdomains
8. **Maintain proper error logging** for failed operations

## Further Resources

- [Domain-Driven Design.md](./DomainDrivenDesign.md) - Overview of the DDD architecture
- [Alpha Dot Five Architecture](internal-link) - Umbra's architecture principles
- [FileSystemInterfaces Documentation](internal-link) - API reference
