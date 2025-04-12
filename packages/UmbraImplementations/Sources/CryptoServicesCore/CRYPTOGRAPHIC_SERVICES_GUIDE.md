# UmbraCore Cryptographic Services Guide

## Table of Contents

1. [Overview](#overview)
2. [Modular Architecture](#modular-architecture)
3. [Implementation Selection](#implementation-selection)
4. [Factory Pattern](#factory-pattern)
5. [Security Considerations](#security-considerations)
6. [Migration Guide](#migration-guide)
7. [Implementation Status](#implementation-status)
8. [Best Practices](#best-practices)
9. [Next Steps](#next-steps)
10. [Standardised Interfaces](#standardised-interfaces)
11. [Error Handling Standards](#error-handling-standards)
12. [Testing Support](#testing-support)

## Overview

UmbraCore's cryptographic services provide a modular, explicitly-selected implementation architecture that enforces clear separation between different cryptographic implementations while requiring developers to make conscious decisions about which implementation to use. This architecture follows the Alpha Dot Five principles with actor-based concurrency, strict privacy controls, and comprehensive logging.

## Modular Architecture

### Design Goals

1. **Explicit Implementation Selection**
   - Developers must explicitly choose which cryptographic implementation to use
   - Clear documentation of the trade-offs between different implementations
   - No implicit or automatic selection of implementations in production code

2. **Modular Architecture**
   - Each implementation exists in its own module with clear boundaries
   - Implementations do not share code beyond the common interfaces
   - Only the selected implementation gets built and deployed

3. **Enhanced Build Performance**
   - Reduced compile time by only building necessary implementations
   - Smaller binary size by eliminating unused cryptographic code
   - Simplified dependency graphs without circular references

4. **Clear Implementation Boundaries**
   - Standard Implementation: AES-based, general-purpose implementation
   - Cross-platform Implementation: RingFFI with Argon2id for platform-agnostic environments
   - Apple Platform Implementation: CryptoKit optimised for Apple ecosystems

### Module Structure

```
//packages/UmbraImplementations/Sources/CryptoServicesCore        (Common utilities, factory)
//packages/UmbraImplementations/Sources/CryptoServicesStandard    (Default AES implementation)
//packages/UmbraImplementations/Sources/CryptoServicesXfn         (Cross-platform with RingFFI)
//packages/UmbraImplementations/Sources/CryptoServicesApple       (Apple CryptoKit implementation)
```

## Implementation Selection

UmbraCore provides three distinct cryptographic implementations, each optimised for different use cases and environments. This guide helps developers make an informed decision about which implementation to use based on their specific requirements.

### Explicit Implementation Selection

The Alpha Dot Five architecture requires developers to explicitly select which cryptographic implementation they wish to use, rather than relying on automatic selection. This ensures conscious decision-making about important security characteristics.

```swift
// Example of explicit implementation selection
let cryptoService = await CryptoServiceSelection.create(
    implementationType: .applePlatform,  // Explicit selection
    logger: myLogger
)
```

### Available Implementations

#### Standard Implementation (`.standard`)

The standard implementation provides a balanced approach to security and compatibility, using AES-256-CBC encryption with standard key management.

**Key Characteristics:**
- AES-256-CBC encryption with proper initialisation vectors
- Standard SHA-256/SHA-512 hashing
- SecRandomCopyBytes for secure random generation
- Standard privacy controls in logging

**When to Use:**
- General-purpose cryptographic operations
- When working with Restic in non-specialised environments
- When performance and compatibility are primary concerns

**Build Configuration:**
```bash
bazelisk build //your/target --//packages/UmbraImplementations:crypto_implementation=standard
```

#### Cross-Platform Implementation (`.crossPlatform`)

The cross-platform implementation uses Ring cryptography library with Argon2id for maximum compatibility across different operating systems.

**Key Characteristics:**
- Platform-agnostic implementation
- Argon2id for password-based key derivation
- Constant-time implementations to prevent timing attacks
- Stricter privacy controls for sensitive environments

**When to Use:**
- When developing cross-platform applications (Windows, macOS, Linux)
- When requiring consistent behaviour across different environments
- For applications with heightened security requirements
- When using advanced key derivation like Argon2id

**Build Configuration:**
```bash
bazelisk build //your/target --//packages/UmbraImplementations:crypto_implementation=xfn
```

#### Apple Platform Implementation (`.applePlatform`)

The Apple platform implementation leverages Apple's CryptoKit for hardware-accelerated encryption on Apple devices.

**Key Characteristics:**
- Optimised specifically for Apple platforms
- Hardware acceleration where available
- AES-GCM for authenticated encryption
- Secure enclave integration on supported devices
- Full macOS/iOS sandboxing compliance

**When to Use:**
- When developing exclusively for Apple platforms
- When requiring hardware acceleration for cryptographic operations
- When operating within Apple's security and sandboxing guidelines
- For applications that need to leverage the Secure Enclave

**Build Configuration:**
```bash
bazelisk build //your/target --//packages/UmbraImplementations:crypto_implementation=apple
```

## Factory Pattern

As part of the Alpha Dot Five architecture implementation, we have consolidated multiple cryptographic service factory implementations into a single canonical implementation.

### Usage Examples

```swift
// Create a service with explicit type selection
let cryptoService = await CryptoServiceRegistry.createService(
    type: .applePlatform,
    logger: myLogger
)
```

### Key Benefits

1. **Eliminated Duplication**: Removed duplicate implementations between factories
2. **Improved Consistency**: Ensured consistent error handling and parameter patterns
3. **Enhanced Type Safety**: Updated parameter types to match the interfaces
4. **Better Dependency Management**: Eliminated circular dependencies between modules
5. **Streamlined API**: Provided a cleaner, more intuitive API for creating services

## Security Considerations

### Algorithm Selection

Each implementation uses different default algorithms:
- Standard: AES-256-CBC for encryption, SHA-256 for hashing
- Cross-Platform: ChaCha20-Poly1305 for encryption, BLAKE3 for hashing, Argon2id for key derivation
- Apple Platform: AES-GCM with hardware acceleration where available

### Entropy Sources

Implementations use different entropy sources:
- Standard: SecRandomCopyBytes (Apple Security framework)
- Cross-Platform: Ring's secure random implementation
- Apple Platform: CryptoKit.generateRandomBytes()

### Performance Characteristics

- Standard: Good general-purpose performance
- Cross-Platform: Consistent but potentially slower on some platforms
- Apple Platform: Optimised with potential hardware acceleration

## Migration Guide

### From Previous Implementation

If you are migrating from the previous non-modular implementation:

1. Replace direct imports:
   ```swift
   // Before
   import CryptoServices
   
   // After - choose one based on requirements
   import CryptoServicesCore    // For type definitions
   import CryptoServicesStandard // For standard implementation
   import CryptoServicesXfn     // For cross-platform implementation
   import CryptoServicesApple   // For Apple platform implementation
   ```

2. Update factory usage:
   ```swift
   // Before
   let cryptoService = await CryptoServiceFactory.createDefault()
   
   // After - with explicit type selection
   let cryptoService = await CryptoServiceSelection.create(
       implementationType: .standard,
       logger: myLogger
   )
   ```

3. Update build files:
   ```python
   # Add dependencies based on which implementation you need
   deps = [
       "//packages/UmbraImplementations/Sources/CryptoServicesCore",
       "//packages/UmbraImplementations/Sources/CryptoServicesStandard",
   ]
   ```

### Testing with Different Implementations

For complete test coverage, consider testing with all implementations:

```swift
// Test with standard implementation
func testWithStandardImpl() async {
    let cryptoService = await CryptoServiceSelection.create(
        implementationType: .standard,
        secureStorage: mockSecureStorage,
        logger: mockLogger
    )
    // Run tests...
}

// Test with cross-platform implementation
func testWithCrossPlatformImpl() async {
    let cryptoService = await CryptoServiceSelection.create(
        implementationType: .crossPlatform,
        secureStorage: mockSecureStorage,
        logger: mockLogger
    )
    // Run tests...
}

// Test with Apple platform implementation
func testWithApplePlatformImpl() async {
    let cryptoService = await CryptoServiceSelection.create(
        implementationType: .applePlatform,
        secureStorage: mockSecureStorage,
        logger: mockLogger
    )
    // Run tests...
}

## Implementation Status

### Current Status (April 2025)

The modular implementation of UmbraCore's cryptographic services has been successfully completed. All three planned implementations are now functional with their specific security characteristics and platform optimisations:

1. **Standard Implementation** (CryptoServicesStandard)
   - Complete implementation of AES-256-CBC encryption
   - SecRandomCopyBytes for secure random generation
   - Standard SHA-256/SHA-512 hashing
   - Privacy-aware logging and error handling

2. **Cross-Platform Implementation** (CryptoServicesXfn)
   - Complete implementation with simulated Ring FFI functionality
   - ChaCha20-Poly1305 encryption simulation
   - BLAKE3 hashing and Argon2id key derivation
   - Ready for integration with actual Ring FFI bindings

3. **Apple Platform Implementation** (CryptoServicesApple)
   - Complete implementation with CryptoKit integration
   - AES-GCM authenticated encryption
   - Hardware-accelerated operations where available
   - Secure Enclave integration support

### Consolidation Progress

In addition to completing the implementation, we've performed a comprehensive consolidation and cleanup:

1. **Factory Pattern Consolidation**
   - Removed duplicate factory pattern in CryptoServices/Factory
   - Migrated all service references to use CryptoServiceRegistry directly
   - Updated imports across the codebase to use the modular approach

2. **Code Cleanup**
   - Removed all .bak and .backup files
   - Removed redundant Provider implementation superseded by our modular approach
   - Removed redundant Factory implementation superseded by the modular service registry
   - Consolidated utility code and type definitions into CryptoServicesCore

3. **Reference Updates**
   - Updated SecurityProviderFactory to use the modular registry
   - Updated SecurityServiceFactory to use the modular registry
   - Updated ServiceContainerImpl to use the modular registry
   - Updated SecureStorageActor to use the modular registry
   - Updated BookmarkServices to use the modular registry

## Best Practices

1. **Make Explicit Decisions:** Always explicitly choose which implementation to use based on your requirements.

2. **Document Your Choice:** Include comments explaining why a particular implementation was selected.

3. **Test Thoroughly:** Each implementation may have slightly different behaviour, especially around edge cases.

4. **Consider the Environment:** Match your implementation choice to your deployment environment.

5. **Review Security Implications:** Each implementation has different security characteristics that should be understood.

## Next Steps

With the core implementation complete and the codebase consolidated, the following next steps are recommended:

1. **Testing & Validation**
   - Develop comprehensive test suites for each implementation
   - Implement cross-implementation compatibility tests
   - Verify thread safety and concurrency behaviour
   - Benchmark performance across implementations

2. **Integration Refinements**
   - Integrate actual Ring FFI bindings for the cross-platform implementation
   - Enhance CryptoKit integration with Secure Enclave for Apple platforms
   - Update existing code that uses the previous non-modular implementation

3. **Documentation & Migration**
   - Create migration guides for existing code
   - Develop example applications demonstrating each implementation
   - Update API documentation with implementation-specific details

4. **Security Audit**
   - Conduct a security review of each implementation
   - Verify cryptographic properties across implementations
   - Document security characteristics and limitations

5. **Performance Optimisation**
   - Profile each implementation for performance bottlenecks
   - Optimise key operations for each target platform
   - Document performance characteristics

6. **Continuous Integration**
   - Set up CI pipelines for testing across implementations
   - Ensure build configurations correctly select implementations
   - Create validation tests for each platform

## Standardised Interfaces

As part of the Alpha Dot Five architecture, we have standardised interfaces across all cryptographic implementations to ensure consistency, type safety, and better developer experience.

### Parameter Standards

All implementations now use standardised parameter types defined in `ParameterStandards.swift`. These replace string literals with type-safe enumerations:

#### Encryption Algorithms

```swift
// Use standardised enum instead of string literals
let options = EncryptionOptions.standard(
    algorithm: .aes256GCM, // Type-safe enum
    mode: .gcm,           // Type-safe enum
    padding: .pkcs7       // Type-safe enum
)

// Instead of string literals
let options = EncryptionOptions(
    algorithm: "AES-256-GCM", // Error-prone string literal
    mode: "GCM",             // Error-prone string literal
    padding: "PKCS7"         // Error-prone string literal
)
```

#### Available Standardised Types

| Type | Description | Available Values |
|------|-------------|-----------------|
| `StandardEncryptionAlgorithm` | Encryption algorithms | `.aes128CBC`, `.aes256CBC`, `.aes256GCM`, `.chacha20Poly1305` |
| `StandardHashAlgorithm` | Hash algorithms | `.sha256`, `.sha384`, `.sha512`, `.hmacSHA256` |
| `StandardEncryptionMode` | Encryption modes | `.cbc`, `.gcm`, `.cfb`, `.ctr` |
| `StandardPaddingType` | Padding types | `.none`, `.pkcs7` |

#### Helper Extension Methods

The framework provides extension methods to easily create options with standardised parameters:

```swift
// Create standard options with default values
let options = EncryptionOptions.standard()  

// Create options with specific algorithm
let options = EncryptionOptions.standard(algorithm: .aes256GCM)  

// Create options with custom IV
let options = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    iv: myCustomIV
)
```

### Interface Consistency

All cryptographic service implementations now follow consistent interface patterns:

1. **Actor-Based Implementation**: All services are implemented as Swift actors for thread safety
2. **Async Functions**: All operations are async functions for proper concurrency
3. **Result Type Return Values**: All operations return `Result<Success, Error>` types
4. **Standardised Parameter Types**: All options use standard parameter types
5. **Public SecureStorage Property**: All implementations expose their secure storage for testing

## Error Handling Standards

The new error handling system provides consistent, informative errors across all implementations.

### Error Types

All implementations now use standardised error types from `ErrorStandards.swift`:

```swift
// Standard operational error
let error = CryptoErrorMapper.operationalError(
    code: .encryptionFailed,
    message: "Encryption operation failed",
    underlyingError: originalError // Optional
)

// Standard validation error
let result = CryptoErrorHandling.validate(
    keyData.count == expectedKeySize,
    code: .invalidKeySize,
    message: "Key must be \(expectedKeySize) bytes"
)
```

### Error Codes

Standardised error codes provide consistent error reporting across implementations:

| Error Code | Description |
|------------|-------------|
| `.invalidInput` | Invalid input parameters |
| `.invalidKeySize` | Key size doesn't match algorithm requirements |
| `.invalidIVSize` | IV size doesn't match algorithm requirements |
| `.encryptionFailed` | General encryption failure |
| `.decryptionFailed` | General decryption failure |
| `.hashingFailed` | Hashing operation failed |
| `.keyGenerationFailed` | Key generation failed |
| `.randomGenerationFailed` | Secure random generation failed |
| `.invalidDataFormat` | Data format doesn't match expectations |
| `.unsupportedAlgorithm` | Algorithm not supported by implementation |
| `.storageError` | Secure storage operation failed |

### Validation Helpers

The framework provides helper functions for common validation operations:

```swift
// Validate general conditions
let result = CryptoErrorHandling.validate(
    !identifier.isEmpty,
    code: .invalidInput,
    message: "Identifier cannot be empty"
)

// Validate key parameters
let result = CryptoErrorHandling.validateKey(
    keyData,
    algorithm: .aes256GCM
)

// Validate IV parameters
let result = CryptoErrorHandling.validateIV(
    ivData,
    algorithm: .aes256GCM
)
```

### Error Mapping

Standardised error mapping utilities help convert between different error types:

```swift
// Map storage errors to crypto errors
let cryptoError = CryptoErrorMapper.map(
    storageError: storageError
)

// Map crypto errors to domain-specific errors
let domainError = CryptoErrorMapper.map(
    cryptoError: cryptoError,
    toDomain: .authentication
)
```

## Testing Support

The new architecture includes standardised testing utilities and mock implementations.

### Mock Implementations

The `CryptoServicesCore/Testing` module provides standardised mock implementations:

```swift
// Create a mock crypto service with configurable behaviour
let mockCryptoService = MockCryptoService(
    secureStorage: MockSecureStorage(),
    mockBehaviour: .init(
        shouldSucceed: true,
        shouldGenerateRandomKeys: true,
        logOperations: true
    )
)

// Configure for failure testing
let failingMockService = MockCryptoService(
    secureStorage: MockSecureStorage(),
    mockBehaviour: .init(
        shouldSucceed: false,
        errorToReturn: .encryptionFailed
    )
)
```

### Testing Utilities

The module includes utilities for generating test keys, IVs, and other test data:

```swift
// Generate test keys
let testKey = CryptoTestUtilities.generateTestKey(
    algorithm: .aes256GCM
)

// Generate test IVs
let testIV = CryptoTestUtilities.generateTestIV(
    algorithm: .aes256GCM
)

// Generate test data with specified size
let testData = CryptoTestUtilities.generateTestData(size: 1024)
```

## Migration Guide

### Migrating from String Literals to Standardised Types

```swift
// Before
let options = EncryptionOptions(
    algorithm: "AES-256-GCM",
    mode: "GCM",
    padding: "PKCS7"
)

// After
let options = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    padding: .pkcs7
)
```

### Migrating to Standardised Error Handling

```swift
// Before
if keyData.count != kCCKeySizeAES256 {
    return .failure(.invalidKeySize)
}

// After
let keyValidation = CryptoErrorHandling.validateKey(keyData, algorithm: algorithm)
if case .failure(let error) = keyValidation {
    return .failure(.storageError(error.message))
}
```

### Migrating to Mock Implementations for Testing

```swift
// Before
let mockService = MockCryptoService(shouldSucceed: true)

// After
let mockService = MockCryptoService(
    secureStorage: MockSecureStorage(),
    mockBehaviour: .init(
        shouldSucceed: true,
        shouldGenerateRandomKeys: true
    )
)
```

## Conclusion

The modular implementation of UmbraCore's cryptographic services provides developers with clear, explicit choices for their cryptographic needs. The architecture achieves the design goals of modularity, explicit selection, and clear implementation boundaries, while aligning with the Alpha Dot Five architecture principles.

Additionally, we've successfully consolidated and cleaned up redundant code, removing duplicated factory patterns and superseded implementations. The codebase is now cleaner, more maintainable, and better aligned with the modular architecture.

The next phases of work will focus on integration, testing, documentation, and performance optimisation to ensure the implementation is robust, secure, and easy to use across all target platforms.
