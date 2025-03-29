# Migration Guide: Security Provider Architecture

This guide provides step-by-step instructions for migrating from the legacy security implementation to the new pluggable security provider architecture.

## Overview of Changes

The security implementation has been refactored to provide:

- Multiple security provider options (Basic, Apple CryptoKit, Ring FFI)
- Actor-based concurrency for Swift 6 compatibility
- Enhanced memory safety for sensitive data with `SecureBytes`
- More consistent error handling with `SecurityProtocolError`
- Better protocol boundaries and interfaces

## Migration Steps

### 1. Update Import Statements

```swift
// Old imports
import UmbraErrors

// New imports
import SecurityCoreTypes
import SecurityCoreInterfaces
import SecurityTypes
```

### 2. Use SecureBytes for Sensitive Data

```swift
// Old approach
let sensitiveData = Data(...)
let encryptedData = try cryptoService.encrypt(data: sensitiveData, using: keyData)

// New approach
let secureData = SecureBytes(data: sensitiveData)
let secureKey = SecureBytes(data: keyData)
let result = await cryptoService.encrypt(data: secureData, using: secureKey)
```

Important: Use `extractUnderlyingData()` instead of the deprecated `data()` method when you need to access the raw Data:

```swift
// Preferred
let rawData = secureBytes.extractUnderlyingData()

// Deprecated (will continue to work but generates a warning)
let rawData = secureBytes.data()
```

### 3. Access UmbraCrypto via Actor

```swift
// Old approach (no longer available)
let provider = UmbraCrypto.provider
UmbraCrypto.useProvider(.apple)

// New approach
let provider = await UmbraCrypto.shared.provider()
await UmbraCrypto.shared.setProvider(newProvider)
```

### 4. Handle Results Instead of Throws

The bridge between the old and new architecture now returns `Result` types rather than throwing errors:

```swift
// Old approach
do {
    let encrypted = try cryptoService.encrypt(data: dataBytes, using: keyBytes)
    // Use encrypted data
} catch {
    // Handle error
}

// New approach
let result = await cryptoService.encrypt(data: secureData, using: secureKey)
switch result {
case .success(let encrypted):
    // Use encrypted data
case .failure(let error):
    // Handle error (type is now SecurityProtocolError)
}
```

### 5. Update Error Handling

Replace `UmbraErrors.Crypto.Core` with `SecurityProtocolError`:

```swift
// Old error types
catch UmbraErrors.Crypto.Core.invalidKeySize { ... }
catch UmbraErrors.Crypto.Core.encryptionFailed { ... }

// New error types
catch SecurityProtocolError.invalidInput(let message) { ... }
catch SecurityProtocolError.cryptographicError(let message) { ... }
catch SecurityProtocolError.unsupportedOperation(name: let name) { ... }
```

### 6. Configure Providers Explicitly

```swift
// Create config with specific provider type
let config = SecurityConfigDTO.aesEncryption(
    providerType: .apple
)

// Create provider directly
let provider = try SecurityProviderFactory.createProvider(type: .apple)

// Create bridge with specific provider
let logger = YourLoggerImplementation()
let bridge = await UmbraCrypto.shared.createBridge(logger: logger)
```

### 7. Consider Platform-Specific Optimisations

Take advantage of platform-specific features:

```swift
#if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
    // Use Apple provider for best performance on Apple platforms
    let config = SecurityConfigDTO.aesEncryption(providerType: .apple)
#elseif canImport(RingCrypto)
    // Use Ring for best cross-platform security
    let config = SecurityConfigDTO.aesEncryption(providerType: .ring)
#else
    // Fall back to basic provider
    let config = SecurityConfigDTO.aesEncryption(providerType: .basic)
#endif
```

## Common Migration Issues

### Issue: Cannot find type 'LoggingProtocol'

```swift
// Solution: Add import
import LoggingInterfaces
```

### Issue: 'data()' is deprecated

```swift
// Solution: Replace with extractUnderlyingData()
let bytes = secureData.extractUnderlyingData()
```

### Issue: UmbraCrypto property access errors

```swift
// Solution: Use actor-based approach
await UmbraCrypto.shared.provider()
```

## Verifying Migration

Use these checks to verify successful migration:

1. Code compiles without warnings related to Swift 6 concurrency
2. Data encrypted with old system can be decrypted with new system
3. All `guard let dataBytes = data.extractUnderlyingData()` patterns are replaced
4. All static `UmbraCrypto` accesses are updated to use the actor

## Testing Recommendations

1. Create unit tests that verify interoperability between old and new formats
2. Test across different platforms if applicable
3. Verify proper memory zeroing of sensitive data with `SecureBytes.reset()`
4. Test fallback mechanisms when preferred providers aren't available

## Timeline

- **Current Phase**: Core Implementation and API Stabilisation
- **Next Phase**: Provider-Specific Optimisations
- **Final Phase**: Legacy Compatibility Removal (when all systems migrated)

## Help and Support

If you encounter issues during migration, please:

1. Check the updated README.md for current best practices
2. Review this migration guide for common issues
3. Contact the security team for complex integration questions
