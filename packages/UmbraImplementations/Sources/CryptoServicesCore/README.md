# UmbraCore Cryptographic Services

## Overview

The UmbraCore Cryptographic Services module provides a modular, explicit, and type-safe implementation of cryptographic operations for the Umbra platform. This implementation follows the Alpha Dot Five architecture principles and enforces clear boundaries between modules.

## Architecture

The cryptographic services are organised into several modules that each serve a specific purpose:

1. **CryptoServicesCore**: Common utilities, factory, registry, and interfaces used by all implementations
2. **CryptoServicesStandard**: Default AES-based implementation suitable for most platforms
3. **CryptoServicesXfn**: Cross-platform Ring FFI implementation for performance-critical scenarios
4. **CryptoServicesApple**: Apple-native CryptoKit implementation optimised for Apple platforms

## Key Design Principles

### Explicit Implementation Selection

Developers must explicitly choose which cryptographic implementation to use, making security decisions visible and intentional rather than hidden behind abstractions.

```swift
// Create a specific cryptographic service implementation
let cryptoService = await CryptoServiceRegistry.createService(
    type: .standard,  // Explicitly choosing the standard implementation
    secureStorage: secureStorage,
    logger: logger
)
```

### Actor-Based Concurrency

All implementations use Swift actors to ensure thread safety in cryptographic operations.

### Privacy-Aware Logging

Cryptographic operations are logged with appropriate privacy controls to prevent sensitive data leakage.

### Comprehensive Error Handling

Standardised error types and handling patterns ensure consistent error reporting across implementations.

### Platform-Specific Optimisations

Each implementation targets specific platforms and use cases:

- **Standard**: Most platforms, default choice for general usage
- **Xfn**: Performance-critical operations, consistent cross-platform guarantees
- **Apple**: Apple platforms with hardware acceleration

## Usage

### Basic Usage

```swift
// Create a cryptographic service with an explicit implementation type
let cryptoService = await CryptoServiceRegistry.createService(
    type: .standard,
    secureStorage: secureStorage,
    logger: logger
)

// Use standardised parameter types for type safety
let options = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    iv: iv
)

// Perform an encryption operation
let result = await cryptoService.encrypt(
    dataIdentifier: "sensitive-data",
    keyIdentifier: "encryption-key",
    options: options
)

// Handle the result with standardised error types
switch result {
case .success(let encryptedDataId):
    // Use the encrypted data
    let retrieveResult = await cryptoService.retrieveData(identifier: encryptedDataId)
    // ...
case .failure(let error):
    // Handle error with standardised error mapping
    let mappedError = CryptoErrorMapper.map(storageError: error)
    // ...
}
```

### Testing

The module includes standardised mock implementations for testing:

```swift
// Create a mock crypto service for testing
let mockCryptoService = MockCryptoService(
    secureStorage: MockSecureStorage(),
    mockBehaviour: MockCryptoService.MockBehaviour(
        shouldSucceed: true,
        logOperations: true
    )
)
```

## Cryptographic Interfaces

The module defines several standard interfaces:

- **`CryptoServiceProtocol`**: The main interface for cryptographic operations
- **`SecureStorageProtocol`**: Interface for storing sensitive cryptographic data
- **`AsyncServiceInitializable`**: Interface for services requiring async initialisation

## Standardised Parameters and Errors

To ensure consistency across implementations, the module provides standardised types:

- **`StandardEncryptionAlgorithm`**: Enum of supported encryption algorithms
- **`StandardHashAlgorithm`**: Enum of supported hash algorithms
- **`StandardEncryptionMode`**: Enum of supported encryption modes
- **`StandardPaddingType`**: Enum of supported padding types
- **`CryptoOperationError`**: Standardised error type for all operations

## Security Considerations

- **Key Management**: Keys are managed through secure storage and never exposed unless explicitly requested
- **Memory Safety**: Sensitive data is properly cleared from memory when no longer needed
- **Authenticated Encryption**: Default to authenticated encryption modes (GCM)
- **Input Validation**: All inputs are validated before cryptographic operations

## Module Boundaries

Please refer to the [ARCHITECTURAL_BOUNDARIES.md](ARCHITECTURAL_BOUNDARIES.md) document for detailed information on the responsibilities and boundaries of each module in the cryptographic services architecture.

## Migration from Legacy Implementation

If you're migrating from the legacy cryptographic services implementation, note the following key differences:

1. You must explicitly choose an implementation type
2. Error types are more specific and consistent
3. Parameter types are standardised with enums instead of strings
4. All operations follow the Result type pattern for error handling

## Additional Resources

- [Cryptographic Services Guide](../CryptoServicesCore/CRYPTOGRAPHIC_SERVICES_GUIDE.md): Comprehensive implementation guide
- [Architectural Boundaries](../CryptoServicesCore/ARCHITECTURAL_BOUNDARIES.md): Module responsibility and interaction guidelines
