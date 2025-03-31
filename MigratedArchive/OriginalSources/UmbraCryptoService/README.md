# UmbraCryptoService

The UmbraCryptoService module provides cryptographic operations for UmbraCore applications.

## Overview

UmbraCryptoService implements secure cryptographic operations using both CryptoKit (for native macOS security) and CryptoSwift (for cross-process operations), providing a unified interface for all cryptographic needs.

## Features

- Symmetric encryption and decryption
- Key generation and management
- Secure hashing and verification
- Digital signatures
- Random number generation
- Cross-process cryptographic operations

## Architecture

UmbraCryptoService implements a dual-library cryptographic approach:

1. **CryptoKit Integration**
   - Native macOS security features for ResticBar
   - Hardware-backed security operations
   - Secure key storage with Secure Enclave
   - Optimised for sandboxed environments

2. **CryptoSwift Integration**
   - Cross-process operations for other components
   - Platform-independent implementation
   - Flexible XPC service support
   - Consistent cross-application behaviour

## Usage

```swift
import UmbraCryptoService

// Create a crypto service
let cryptoService = UmbraCryptoService()

// Encrypt data
let encryptedData = try await cryptoService.encrypt(
    data: sensitiveData,
    using: .aes256gcm,
    key: derivedKey,
    authenticationData: metadata
)

// Decrypt data
let decryptedData = try await cryptoService.decrypt(
    data: encryptedData,
    using: .aes256gcm,
    key: derivedKey,
    authenticationData: metadata
)
```

## Security Considerations

- All cryptographic operations follow industry best practices
- Keys are properly managed and protected
- Memory containing sensitive data is securely wiped after use
- Hardware security features are used when available
