# AlphaAPIServices Migration Guide

This document provides guidance for transitioning from the legacy API service implementation to the new Alpha Dot Five architecture-based implementation.

## Overview

The UmbraCore project has migrated its API services to the Alpha Dot Five architecture, which offers several improvements:

- **Actor-based concurrency** for thread safety
- **Domain-driven design** with specialised handlers
- **Privacy-aware logging** throughout all operations
- **Comprehensive error handling** with proper domain mapping

## Key Components

### 1. AlphaAPIService

The central actor-based service that coordinates all API operations. It replaces the previous `APIServiceImpl` class.

```swift
// Legacy (removed)
let apiService = APIServiceFactory.createDefault()

// New approach
let apiService = AlphaAPIServiceFactory.createDefault()
```

### 2. AlphaAPIServiceFactory

Factory for creating properly configured service instances with appropriate dependencies. Replaces the previous `APIServiceFactory`.

```swift
// Production use with full dependencies
let apiService = AlphaAPIServiceFactory.createProduction(
    repositoryService: repositoryService, 
    backupService: backupService,
    securityService: securityService
)

// Testing use with mock implementations
let testApiService = AlphaAPIServiceFactory.createForTesting(mocks: true)
```

### 3. Domain Handlers

Specialised handlers for different operation domains:

- **SecurityDomainHandler**: Manages security operations (encryption, keys, etc.)
- **RepositoryDomainHandler**: Manages repository operations
- **BackupDomainHandler**: Manages backup and snapshot operations

## API Usage Patterns

### Executing Operations

```swift
// Execute an operation and get the result or throw an error
let result = try await apiService.execute(operation)

// Execute with a result wrapper (no throws)
let apiResult = await apiService.executeWithResult(operation)
switch apiResult {
    case .success(let result):
        // Handle success
    case .failure(let error):
        // Handle error
}
```

### Operation Cancellation

```swift
// Cancel a specific operation
try await apiService.cancelOperation(id: operationID)

// Cancel all operations
await apiService.cancelAllOperations()
```

## Error Handling

Errors are now mapped to standardised `APIError` types:

```swift
do {
    let result = try await apiService.execute(operation)
    // Process result
} catch let error as APIError {
    switch error {
    case .resourceNotFound(let message, let code):
        // Handle not found
    case .operationFailed(let message, let code, let underlyingError):
        // Handle operation failure
    case .permissionDenied(let message, let code):
        // Handle permission issues
    // ...other error cases
    }
} catch {
    // Handle unexpected errors
}
```

## Privacy-Aware Logging

All operations now use privacy-aware metadata for logging:

```swift
// Example metadata structure in domain handlers
let metadata = PrivacyMetadata([
    "operation": .public("operationName"),
    "repository_id": .public(repositoryID),
    "files": .private(fileList.joined(separator: ", "))
])
```

## Migration Checklist

1. Replace all references to `APIServiceImpl` with `AlphaAPIService`
2. Replace all references to `APIServiceFactory` with `AlphaAPIServiceFactory` 
3. Update error handling code to work with the new error mapping approach
4. Ensure operations are properly defined as conforming to appropriate operation protocols
5. Update any custom domain handlers to follow the new pattern

## Known Differences

1. **Initialisation**: New implementation doesn't require separate initialisation after creation
2. **Error Types**: More specific and structured error types with better context
3. **Execution Options**: Enhanced support for timeout and cancellation options
4. **Asynchronous Model**: Fully embraces Swift's structured concurrency model

## Support

For any issues or questions about this migration, please refer to the [UmbraCore Documentation](https://internal.umbra-dev.com/docs) or contact the Core Services team.
