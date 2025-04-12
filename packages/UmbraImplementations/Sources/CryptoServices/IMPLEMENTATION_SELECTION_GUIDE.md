# Cryptographic Implementation Selection Guide

## Overview

UmbraCore provides three distinct cryptographic implementations, each optimised for different use cases and environments. This guide helps developers make an informed decision about which implementation to use based on their specific requirements.

## Explicit Implementation Selection

The Alpha Dot Five architecture requires developers to explicitly select which cryptographic implementation they wish to use, rather than relying on automatic selection. This ensures conscious decision-making about important security characteristics.

```swift
// Example of explicit implementation selection
let cryptoService = await CryptoServiceSelection.create(
    implementationType: .applePlatform,  // Explicit selection
    logger: myLogger
)
```

## Available Implementations

### Standard Implementation (`.standard`)

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

### Cross-Platform Implementation (`.crossPlatform`)

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

### Apple Platform Implementation (`.applePlatform`)

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
```

## Best Practices

1. **Make Explicit Decisions:** Always explicitly choose which implementation to use based on your requirements.

2. **Document Your Choice:** Include comments explaining why a particular implementation was selected.

3. **Test Thoroughly:** Each implementation may have slightly different behaviour, especially around edge cases.

4. **Consider the Environment:** Match your implementation choice to your deployment environment.

5. **Review Security Implications:** Each implementation has different security characteristics that should be understood.

## Conclusion

By explicitly selecting the appropriate cryptographic implementation, you ensure that your application uses the most suitable security approach for your specific requirements and environment.
