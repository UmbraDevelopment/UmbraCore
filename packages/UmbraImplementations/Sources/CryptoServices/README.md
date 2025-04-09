# CryptoServices

CryptoServices provides concrete implementations of the cryptographic operations defined in the CryptoInterfaces module. This module contains the actual implementation code that performs cryptographic functions.

## Contents

This module contains:

- The canonical `CryptoServiceFactory` for creating cryptographic service implementations
- Default implementations of `CryptoServiceProtocol`
- Implementations of `CredentialManagerProtocol`
- Integration with platform-specific cryptographic libraries

## Usage Guidelines

- Import this module when you need to perform cryptographic operations
- Use `CryptoServiceFactory` to create cryptographic service implementations
- Use dependency injection patterns to provide these implementations to other modules
- Consider platform-specific optimisations where appropriate
- Default implementations should be suitable for most use cases

## Factory Usage

```swift
// Create a crypto service with default configuration
let cryptoService = await CryptoServiceFactory.shared.createDefault()

// Create a crypto service with custom configuration
let customService = await CryptoServiceFactory.shared.createDefault(
    logger: customLogger,
    secureStorage: mySecureStorage
)
```

## Relationship with Other Modules

- Implements protocols defined in `CryptoInterfaces`
- Uses types defined in `CryptoTypes`
- Leverages `UmbraErrors` for proper error handling
- Works with `SecurityTypes` for secure data handling

## Migration Notes

This module was created as part of splitting the original CryptoTypes module according to the Alpha Dot Five architecture:

- Type definitions → UmbraCoreTypes/CryptoTypes
- Interface definitions → UmbraInterfaces/CryptoInterfaces
- Implementations → UmbraImplementations/CryptoServices (this module)

The implementations have been updated to use `SecurityTypes.SecureBytes` instead of direct Foundation Data dependencies where possible, improving portability and conforming to the Alpha Dot Five principles.

For detailed information about the consolidation of cryptographic service factories, see [FACTORY_CONSOLIDATION.md](FACTORY_CONSOLIDATION.md).
