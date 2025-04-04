# Crypto Services Factory Migration Guide

## Overview

The `CryptoServices` enum in the `SecurityCryptoServices` module has been removed as part of a consolidation of cryptographic service factories. All functionality has been moved to the canonical `CryptoServiceFactory` in the `CryptoServices` module.

This guide will help you migrate your code to use the consolidated implementation.

## Migration Steps

### 1. Update Import Statements

```swift
// Before
import SecurityCryptoServices 

// After
import CryptoServices
```

### 2. Update Factory Method Calls

#### Creating a Crypto Service

```swift
// Before
let cryptoService = await CryptoServices.createCryptoService(
    providerType: .cryptoKit,
    logger: logger
)

// After
let cryptoService = await CryptoServiceFactory.createWithProviderType(
    providerType: .cryptoKit,
    logger: logger
)
```

#### Creating Secure Storage

```swift
// Before
let secureStorage = await CryptoServices.createSecureStorage(
    providerType: .cryptoKit,
    storageURL: storageURL,
    logger: logger
)

// After
// First create a provider registry to get the provider
let registry = await CryptoServiceFactory.createProviderRegistry(logger: logger)
let provider = await registry.createProvider(type: .cryptoKit)

// Then create the secure storage with the provider
let secureStorage = await CryptoServiceFactory.createSecureStorage(
    provider: provider,
    storageURL: storageURL,
    logger: logger
)

// Alternatively, if you don't need a specific provider type:
let secureStorage = await CryptoServiceFactory.createSecureStorage(
    storageURL: storageURL,
    logger: logger
)
```

#### Creating Provider Registry

```swift
// Before
let registry = await CryptoServices.createProviderRegistry(
    logger: logger
)

// After
let registry = await CryptoServiceFactory.createProviderRegistry(
    logger: logger
)
```

### 3. Update Option Types References

As part of the consolidation effort, the following option types have been standardised to use the canonical definitions from `SecurityCoreInterfaces`:

- `EncryptionOptions`
- `DecryptionOptions`
- `HashingOptions`
- `KeyGenerationOptions`

If you were previously using these types from the `CryptoServices` module, you should update your code to use the canonical versions:

```swift
// Before
import CryptoServices
let options = EncryptionOptions(algorithm: .aes256CBC, padding: .pkcs7)

// After
import SecurityCoreInterfaces
let options = EncryptionOptions(algorithm: .aes256CBC, padding: .pkcs7)
```

The CryptoServices module now contains typealiases to the canonical types for backward compatibility, but direct import of SecurityCoreInterfaces is recommended for new code.

Note that the canonical `EncryptionOptions` and `DecryptionOptions` now include a `padding` property that was previously only available in the CryptoServices versions.

## Benefits of the Consolidated Implementation

1. **No Circular Dependencies**: The consolidated implementation eliminates circular dependencies between modules
2. **Single Source of Truth**: All cryptographic service factory methods are in one location
3. **Enhanced Functionality**: The canonical implementation provides more options and better error handling
4. **Improved Security**: Consistent security patterns across the codebase

## Getting Help

If you encounter any issues migrating to the new implementation, please refer to the documentation in the `CryptoServiceFactory` class or contact the security team.
