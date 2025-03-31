# FileSystemTypes

## Overview
The FileSystemTypes module provides the core file system data types and structures used throughout the UmbraCore system. It offers a standardised interface for representing file paths, file system item types, and metadata.

## Public API Summary

### Primary Types
- `FilePath`: A structure representing a file path in the system.
- `FileSystemItemType`: An enumeration of file system item types (file, directory, symbolic link, etc.).
- `FileSystemMetadata`: A structure containing metadata about a file system item.

### Key Functionality
- Foundation-independent file path and file system item representations
- Immutable value types for thread-safety
- Standardised metadata structures

## Usage Examples

### Working with file paths
```swift
// Create a file path
let filePath = FilePath(path: "/path/to/file.txt")

// Use the file path in other UmbraCore modules
let metadata = fileSystem.getMetadata(filePath)
```

### Working with file system metadata
```swift
// Example of using FileSystemMetadata
func printFileInfo(metadata: FileSystemMetadata) {
    print("Path: \(metadata.path.path)")
    print("Type: \(metadata.itemType.rawValue)")
    print("Size: \(metadata.size) bytes")
    if let modDate = metadata.modificationDate {
        print("Modified: \(modDate)")
    }
}
```

## Notes for Developers
- This module is designed to be free of external dependencies beyond Foundation
- All types are immutable for thread-safety
- All types conform to Sendable, Equatable, and Hashable for use in concurrent contexts
