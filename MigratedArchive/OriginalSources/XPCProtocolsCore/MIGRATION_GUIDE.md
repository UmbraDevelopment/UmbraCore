# XPCProtocolsCore Migration Guide

## Transitioning from Legacy to Modern XPC Service

This document provides guidance for transitioning from the `LegacyXPCServiceAdapter` to the new `ModernXPCService` implementation.

## Overview

The UmbraCore XPC Service architecture has evolved to provide a more maintainable, type-safe, and efficient implementation with the following key improvements:

- Better error handling with Swift's `Result` type
- Async/await support for modern Swift concurrency
- Consistent and clear protocol definitions
- Improved type safety and reduced reliance on NS* types

## Key Changes

1. **Factory Method Usage**:
   The `XPCProtocolMigrationFactory` now exclusively creates instances of `ModernXPCService` for all protocol levels.

2. **Protocol Hierarchy**:
   - `XPCServiceProtocolBasic` - Basic ping and key synchronisation operations
   - `XPCServiceProtocolStandard` - Adds cryptographic operations like encrypt/decrypt
   - `XPCServiceProtocolComplete` - Provides the full set of operations

3. **Error Handling**:
   - Modern methods return `Result<Success, XPCSecurityError>` instead of optionals
   - Detailed error types with descriptive messages instead of simple failure indicators

## Migration Steps

### 1. Identify Usage of Legacy Adapter

Search your codebase for:
- Direct instantiations of `LegacyXPCServiceAdapter`
- References to legacy error types and conversion methods
- Callback-based completion handlers for XPC operations

### 2. Replace Factory Method Calls

Instead of creating legacy adapters directly:

```swift
// Old
let adapter = LegacyXPCServiceAdapter(service: xpcService)

// New
let adapter = XPCProtocolMigrationFactory.createCompleteAdapter()
```

### 3. Update Error Handling

Convert from callback-based error handling to Result-based handling:

```swift
// Old
adapter.encrypt(data: data) { encryptedData, error in
    if let error = error {
        // Handle error
    } else {
        // Use encryptedData
    }
}

// New
Task {
    let result = await adapter.encrypt(data: data)
    switch result {
    case .success(let encryptedData):
        // Use encryptedData
    case .failure(let error):
        // Handle specific error
    }
}
```

### 4. Update Security Error Handling

When working with security errors:

```swift
// Convert from legacy errors
if let error = error {
    // Old
    let securityError = XPCProtocolMigrationFactory.convertToStandardError(error)
    
    // New - use pattern matching
    switch securityError {
    case .invalidData(let reason):
        // Handle invalid data error
    case .serviceUnavailable:
        // Handle service unavailable
    default:
        // Handle other errors
    }
}
```

### 5. Testing Considerations

When testing modules that use the XPC service:

- Use `ModernXPCService` directly for integration tests
- For unit tests, consider implementing simple mock objects that conform to the relevant protocols

## Removing Objective-C Dependencies

UmbraCore is moving away from Objective-C dependencies to create a pure Swift implementation that is more maintainable, type-safe, and performant. The following steps will help you eliminate Objective-C dependencies in your code:

### 1. Replace NSData with SecureBytes

```swift
// Old - Objective-C dependent
let data = NSData(bytes: bytes, length: bytes.count)
service.encryptData(data, keyIdentifier: "key-1")

// New - Pure Swift
let secureBytes = SecureBytes(bytes: bytes)
await service.encrypt(data: secureBytes)
```

### 2. Replace NSError with Swift Errors and Result types

```swift
// Old - Objective-C dependent
func encrypt(_ data: NSData, completion: @escaping (NSData?, NSError?) -> Void) {
    // Implementation
}

// New - Pure Swift
func encrypt(data: SecureBytes) async -> Result<SecureBytes, XPCSecurityError> {
    // Implementation
}
```

### 3. Replace NSNumber boolean returns with Swift Bool

```swift
// Old - Objective-C dependent
func verifySignature(_ signature: NSData, for data: NSData) -> NSNumber

// New - Pure Swift
func verifySecureSignature(_ signature: SecureBytes, for data: SecureBytes) async -> Result<Bool, XPCSecurityError>
```

### 4. Replace NSDictionary with Swift Dictionaries

```swift
// Old - Objective-C dependent
func getServiceStatus() -> NSDictionary?

// New - Pure Swift
func getServiceStatus() async -> Result<XPCServiceStatus, XPCSecurityError>
```

### 5. Replace @objc Protocol Requirements with Swift-native Alternatives

```swift
// Old - Objective-C dependent
@objc protocol LegacyProtocol {
    @objc func doSomething() -> Bool
    @objc optional func doSomethingElse() -> NSData?
}

// New - Pure Swift
protocol ModernProtocol {
    func doSomething() async -> Result<Bool, Error>
    // Optional methods can be handled with protocol extensions
}

extension ModernProtocol {
    // Default implementation for optional methods
    func doSomethingElse() async -> Result<Data, Error> {
        .failure(XPCSecurityError.operationNotSupported(name: "doSomethingElse"))
    }
}
```

### 6. Test Case Updates

When updating test cases, replace mocks that rely on Objective-C runtime features with Swift protocol conformance:

```swift
// Old - Objective-C dependent mock
class MockService: NSObject, LegacyCryptoProtocol {
    @objc func encryptData(_ data: NSData, keyIdentifier: String?) -> NSData {
        // Test implementation
    }
    // Other required methods...
}

// New - Pure Swift mock
struct MockModernService: XPCServiceProtocolComplete {
    func encrypt(data: SecureBytes) async -> Result<SecureBytes, XPCSecurityError> {
        // Test implementation
    }
    // Other required methods with default implementations...
}
```

## Complete Removal Timeline

The following timeline outlines the planned removal of Objective-C dependencies:

1. **Current Phase**: Deprecate all Objective-C protocols and the LegacyXPCServiceAdapter
2. **Phase 2**: Replace all direct usage of LegacyXPCServiceAdapter with factory methods
3. **Phase 3**: Remove LegacyXPCServiceAdapter.swift entirely
4. **Phase 4**: Remove all remaining Objective-C compatibilities from protocol definitions

## Reference: Common Error Mappings

| Legacy Error | Modern Error |
|--------------|--------------|
| `invalidFormat` | `invalidData(reason:)` |
| Service unavailable errors | `serviceUnavailable` |
| Authentication failures | `authenticationFailed(reason:)` |
| General errors | `internalError(reason:)` |

## Example: Complete Migration

```swift
// OLD IMPLEMENTATION
func processData(_ data: Data, completion: @escaping (Data?, Error?) -> Void) {
    let adapter = LegacyXPCServiceAdapter(service: xpcService)
    adapter.encrypt(data.bytes) { encryptedData, error in
        if let error = error {
            completion(nil, error)
        } else if let encryptedData = encryptedData {
            completion(Data(encryptedData), nil)
        } else {
            completion(nil, NSError(...))
        }
    }
}

// NEW IMPLEMENTATION
func processData(_ data: Data) async -> Result<Data, Error> {
    let service = XPCProtocolMigrationFactory.createCompleteAdapter()
    let secureData = SecureBytes(bytes: [UInt8](data))
    
    let result = await service.encrypt(data: secureData)
    return result.map { encryptedBytes in
        Data(encryptedBytes)
    }
}
```

## Additional Resources

- See `ModernXPCService.swift` for the complete implementation
- Refer to test cases in `XPCProtocolsCore/Tests/ModernXPCServiceTests.swift` for examples
