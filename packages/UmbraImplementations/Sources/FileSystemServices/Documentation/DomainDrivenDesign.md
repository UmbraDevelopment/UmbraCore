# Domain-Driven Design for FileSystemServices

This document explains the domain-driven design (DDD) structure of the FileSystemServices module, providing context about the boundaries, responsibilities, and interactions between components.

## Overview

The FileSystemServices module has been refactored using Domain-Driven Design principles to improve maintainability, testability, and clarity. The system is now divided into distinct subdomains, each with clear responsibilities and boundaries.

## Domain Structure

Our DDD approach divides file system operations into four core subdomains:

1. **CoreFileOperations** - Basic file interaction operations
2. **FileMetadataOperations** - File attributes and metadata management
3. **SecureFileOperations** - Security-related file operations
4. **FileSandboxing** - Path restriction and sandboxing controls

These subdomains are integrated via a CompositeFileSystemService that provides a unified interface while maintaining internal separation of concerns.

## Subdomain Responsibilities

### CoreFileOperations

**Primary Responsibility**: Fundamental file system read/write operations and path handling.

This subdomain handles:
- Reading/writing file contents
- Checking file existence
- Path normalisation
- File type verification

**Key Components**:
- `CoreFileOperationsProtocol` - Interface defining core operations
- `CoreFileOperationsImpl` - Actor-based implementation
- `CoreFileOperationsFactory` - Factory for creating implementations

**Isolation Benefits**:
- Allows optimisation of core file access routines
- Provides a clear focus on performance-critical operations
- Keeps basic file I/O separate from security concerns

### FileMetadataOperations

**Primary Responsibility**: Managing file metadata and extended attributes.

This subdomain handles:
- Getting/setting file attributes
- Managing file timestamps
- Handling file permissions
- Manipulating extended attributes

**Key Components**:
- `FileMetadataOperationsProtocol` - Interface defining metadata operations
- `FileMetadataOperationsImpl` - Actor-based implementation
- `FileMetadataOperationsFactory` - Factory for creating implementations

**Isolation Benefits**:
- Encapsulates attribute-specific logic
- Simplifies special cases for extended attributes
- Improves testability of metadata operations

### SecureFileOperations

**Primary Responsibility**: Security-centric file operations.

This subdomain handles:
- Security bookmark creation/resolution
- Secure temporary file handling
- Encrypted file operations
- Secure deletion
- File integrity verification

**Key Components**:
- `SecureFileOperationsProtocol` - Interface defining secure operations
- `SecureFileOperationsImpl` - Actor-based implementation
- `SecureFileOperationsFactory` - Factory for creating implementations

**Isolation Benefits**:
- Keeps security concerns separate from standard operations
- Allows security-specific optimisations and enhancements
- Provides clear boundaries for security reviews

### FileSandboxing

**Primary Responsibility**: Restricting file operations to specific directories.

This subdomain handles:
- Path validation against sandbox boundaries
- Controlled access to directories
- Relative path resolution
- Access control for potentially dangerous operations

**Key Components**:
- `FileSandboxingProtocol` - Interface defining sandboxing operations
- `FileSandboxingImpl` - Actor-based implementation
- `FileSandboxingFactory` - Factory for creating implementations

**Isolation Benefits**:
- Improves security by clearly separating sandboxing logic
- Simplifies sandbox creation and validation
- Provides a consistent approach to path restrictions

## Data Transfer Objects

We use immutable DTOs to standardise data exchange between domains:

- `FileMetadataDTO` - Encapsulates file metadata
- `FileOperationResultDTO` - Standardised operation result structure
- `FilePermissionsDTO` - File permission representation
- `ExtendedAttributeDTO` - Extended attribute representation

Benefits of these DTOs:
- Immutable, thread-safe data structures
- Consistent error handling
- Improved type safety
- Clear documentation of data boundaries

## Composite Service

The `CompositeFileSystemServiceProtocol` and its implementation provide a unified interface to clients while delegating to the appropriate subdomain internally.

**Key Components**:
- `CompositeFileSystemServiceProtocol` - Unified interface for all operations
- `CompositeFileSystemServiceImpl` - Implementation that delegates to subdomains
- `FileSystemServiceFactory` - Factory for creating composite services

**Benefits**:
- Presents a single interface to clients
- Internally maintains separation of concerns
- Simplifies client code
- Allows subdomain substitution and mockability

## Integration Points

Subdomains interact primarily through:

1. **Delegation** - The composite service delegates operations to appropriate subdomains
2. **DTOs** - Data exchange occurs via immutable data transfer objects
3. **Factories** - Factories handle dependency injection and creation logic

## Alpha Dot Five Compliance

This architecture aligns with Alpha Dot Five principles:
- Uses actor isolation for thread safety
- Implements privacy-aware logging
- Provides detailed error handling
- Follows British spelling in documentation
- Maintains strong type safety
- Uses dependency injection for testability

## Usage Examples

### Creating a Standard Service

```swift
// Create a standard service
let fileSystemService = await FileSystemServiceFactory.createStandardService()

// Use the service for operations
let data = try await fileSystemService.readFile(at: "/path/to/file").0
```

### Creating a Secure Service

```swift
// Create a secure service
let secureService = await FileSystemServiceFactory.createSecureService()

// Use secure operations
try await secureService.secureDelete(at: "/path/to/sensitive/file", passes: 3)
```

### Creating a Sandboxed Service

```swift
// Create a sandboxed service
let sandboxedService = await FileSystemServiceFactory.createSandboxedService(rootDirectory: "/safe/directory")

// Operations are restricted to the sandbox
try await sandboxedService.writeFile(data: someData, to: "/safe/directory/file.txt", options: nil)
```

## Testing

The domain-driven approach significantly improves testability:

- Each subdomain can be tested in isolation
- Mocks can be created for each protocol
- The factory system simplifies test setup
- DTOs provide clear validation points

## Future Directions

Potential enhancements to this architecture:

1. **Performance Monitoring** - Add instrumentation to track performance metrics
2. **Error Aggregation** - Implement centralized error handling and analytics
3. **Caching Layer** - Add domain-specific caching strategies
4. **Extended Observability** - Add more detailed logging and tracing

## Conclusion

This domain-driven design approach improves maintainability, testability, and clarity of the FileSystemServices module. By clearly separating concerns and establishing well-defined boundaries, we create a more robust and flexible system that can evolve over time.
