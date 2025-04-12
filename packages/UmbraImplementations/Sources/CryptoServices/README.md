# CryptoServices

CryptoServices provides a modular approach to cryptographic operations with explicitly selectable implementations. This module serves as the entry point for the modular cryptographic services architecture.

## Modular Architecture

This module is part of a modular structure that includes:

- **CryptoServicesCore** - Common utilities, factory, and registry
- **CryptoServicesStandard** - Default AES-based implementation
- **CryptoServicesXfn** - Cross-platform implementation with RingFFI and Argon2id
- **CryptoServicesApple** - Apple-native implementation using CryptoKit

## Explicit Implementation Selection

Following the Alpha Dot Five architecture principles, this module requires developers to explicitly select which cryptographic implementation to use, rather than relying on automatic selection.

```swift
// Create a service with explicit type selection
let cryptoService = await CryptoServiceRegistry.createService(
    type: .applePlatform,
    logger: myLogger
)
```

## Documentation

For comprehensive documentation on the cryptographic services architecture, implementation options, and migration guidance, please refer to:

- [CRYPTOGRAPHIC_SERVICES_GUIDE.md](/packages/UmbraImplementations/Sources/CryptoServicesCore/CRYPTOGRAPHIC_SERVICES_GUIDE.md) - Complete guide to the modular cryptographic services

## Build Configuration

To build with a specific implementation:

```bash
# For standard implementation (default)
bazelisk build //your/target --//packages/UmbraImplementations:crypto_implementation=standard

# For cross-platform implementation
bazelisk build //your/target --//packages/UmbraImplementations:crypto_implementation=xfn

# For Apple platform implementation
bazelisk build //your/target --//packages/UmbraImplementations:crypto_implementation=apple
```

## Relationship with Other Modules

- Implements protocols defined in `CryptoInterfaces`
- Uses types defined in `CryptoTypes`
- Leverages proper error handling with appropriate error types
- Works with `SecurityTypes` for secure data handling

## Migration Notes

If you are migrating from the previous non-modular implementation:

1. Replace `CryptoServiceFactory.createDefault()` with explicit implementation selection
2. Update imports to reference the specific implementation modules
3. Consider the security characteristics of each implementation when making your selection

For detailed migration guidance, see the comprehensive documentation referenced above.
