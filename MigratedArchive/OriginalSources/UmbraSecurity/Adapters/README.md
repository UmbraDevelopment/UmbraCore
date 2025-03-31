# Foundation-Independent Security Adapters

This module provides Foundation-independent adapters for the UmbraSecurity services, allowing interaction with security features without Foundation dependencies at module boundaries.

## Components

### BookmarkServiceDTOAdapter

An adapter that provides a Foundation-independent interface for bookmark operations:

- Create bookmarks using `FilePathDTO` instead of `URL`
- Resolve bookmarks to `FilePathDTO` objects
- Manage security-scoped resource access

### SecurityServiceDTOAdapter

Provides a Foundation-independent interface to security operations:

- Random data generation
- Hashing with various algorithms
- Encryption and decryption
- Secure token generation

### SecurityServiceDTOFactory

Factory methods for creating the adapters:

- `createSecurityService()` - Create a security service adapter
- `createBookmarkService()` - Create a bookmark service adapter
- `createComplete()` - Create both services in one call

## Usage

```swift
// Get services from the factory
let (securityService, bookmarkService) = SecurityServiceDTOFactory.createComplete()

// Generate random bytes
let randomBytesResult = securityService.generateRandomBytes(count: 32)

// Create a bookmark
let path = FilePathDTO.documentsDirectory().appendingComponent("example.txt")
let bookmarkResult = bookmarkService.createBookmark(for: path)
```

See the `Examples/UmbraSecurity/FoundationIndependentExample.swift` file for a comprehensive usage example.

## Design Principles

1. All public interfaces use only Foundation-independent types
2. All methods return `OperationResultDTO<T>` for consistent error handling
3. Adapters handle conversion between Foundation and non-Foundation types internally
4. Factory methods simplify the creation of appropriately configured adapters

## Next Steps

1. Complete test coverage for all adapters
2. Extend to additional security services
3. Create similar adapters for other Foundation-dependent modules
