# CryptoService Factory Consolidation

## Overview

As part of the Alpha Dot Five architecture implementation, we have consolidated multiple cryptographic service factory implementations into a single canonical implementation. This document explains the consolidation and provides guidance for using the updated factories.

## Canonical Implementation

The canonical implementation is now the `CryptoServiceFactory` in the CryptoServices module. This factory provides comprehensive methods for creating various cryptographic service implementations following the Alpha Dot Five architecture principles.

## Key Benefits

1. **Eliminated Duplication**: Removed duplicate implementations between CryptoServiceFactory and CryptoServicesFactory
2. **Improved Consistency**: Ensured consistent error handling and parameter patterns across all factory methods
3. **Enhanced Type Safety**: Updated parameter types to match the interfaces in CryptoInterfaces module
4. **Better Dependency Management**: Eliminated circular dependencies between modules
5. **Streamlined API**: Provided a cleaner, more intuitive API for creating cryptographic services

## Usage Examples

### Basic Usage

```swift
// Create a default implementation
let cryptoService = await CryptoServiceFactory.createDefault()

// Create a service with custom secure storage
let customService = await CryptoServiceFactory.createDefault(
  secureStorage: mySecureStorage,
  logger: myLogger
)
```

### Provider-Specific Implementations

```swift
// Create a service with a specific provider type
let cryptoWithProvider = await CryptoServiceFactory.createWithProviderType(
  providerType: .cryptoKit,
  logger: myLogger
)

// For more advanced requirements
let cryptoService = await CryptoServiceFactory.createWithProvider(
  provider: myProvider,
  secureStorage: mySecureStorage,
  logger: myLogger
)
```

### Logging and Testing

```swift
// Create a service with logging capabilities
let loggingService = await CryptoServiceFactory.createLoggingService(
  logger: myLogger
)

// Create a mock implementation for testing
let mockService = await CryptoServiceFactory.createMock()
```

## Migration Guide

If you were previously using:

- `CryptoServicesFactory` in SecurityCryptoServices module: Update imports to `import CryptoServices` and use the corresponding methods in `CryptoServiceFactory`
- `CryptoServices` enum (now removed): Update all calls to use `CryptoServiceFactory` directly
- The previous version of `CryptoServiceFactory`: Update method calls to match the new parameter patterns (optional parameters have been added)
- Any custom crypto service creation code: Consider using the factory methods instead for better consistency

## Advanced Usage

For more advanced usage scenarios, refer to the comprehensive factory methods in `CryptoServiceFactory`:

- `createWithProviderType`: For using specific security provider implementations
- `createProviderRegistry`: For managing security providers
- `createSecureStorage`: For creating secure storage implementations
- `createLoggingDecorator`: For adding logging capabilities to any implementation

For any additional questions or assistance, please contact the Security Architecture team.
