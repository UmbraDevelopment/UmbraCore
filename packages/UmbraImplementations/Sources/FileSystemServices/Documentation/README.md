# FileSystemServices Documentation

## Overview

This directory contains documentation for the FileSystemServices module, which has been refactored using Domain-Driven Design principles. These documents explain the architecture, domain boundaries, and best practices for using and extending the file system services.

## Documentation Index

- [**Domain-Driven Design**](./DomainDrivenDesign.md) - Explains the domain boundaries, responsibilities, and architecture
- [**Developer Guide**](./DeveloperGuide.md) - Practical guidance for using and extending the system

## Architecture Quick Reference

The FileSystemServices module is now structured into four core subdomains:

1. **CoreFileOperations** - Basic file read/write operations
2. **FileMetadataOperations** - Attributes and metadata handling
3. **SecureFileOperations** - Security-focused operations
4. **FileSandboxing** - Path restriction and sandboxing

These subdomains are integrated through a `CompositeFileSystemServiceProtocol` that provides a unified API while maintaining separation of concerns internally.

## Key Benefits

- **Improved Maintainability** - Smaller, focused components with clear responsibilities
- **Enhanced Testability** - Each subdomain can be tested in isolation
- **Better Security** - Security concerns are properly isolated
- **Clearer API** - Standardised DTOs and results format
- **Thread Safety** - Actor-based implementations ensure safe concurrent access

## Getting Started

To use the new file system services:

```swift
import FileSystemInterfaces
import FileSystemServices

// Create a file system service
let fileService = await FileSystemServiceFactory.createStandardService()

// Use the service
let (data, result) = try await fileService.readFile(at: "/path/to/file")
```

See the [Developer Guide](./DeveloperGuide.md) for more detailed examples and best practices.

## Alpha Dot Five Compliance

This architecture follows the Alpha Dot Five principles:
- Actor-based concurrency
- Privacy-aware logging
- Comprehensive error handling
- Strong typing with immutable DTOs
- Clear domain separation
