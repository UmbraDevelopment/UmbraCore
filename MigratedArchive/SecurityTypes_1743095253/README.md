# SecurityTypes

The SecurityTypes module provides the foundational security types and protocols for the UmbraCore framework.

## Overview

SecurityTypes defines the core security primitives, protocols, and interfaces that are used throughout the UmbraCore security architecture. It is designed to be foundation-free to enable use in a wide variety of contexts.

## Features

- Core security type definitions
- Security protocol interfaces
- Error type definitions
- Cryptographic operation primitives
- Security service interfaces

## Architecture

This module is part of the broader security architecture in UmbraCore that includes:

1. **SecurityTypes**: Core type definitions (this module)
2. **SecurityProtocolsCore**: Protocol interfaces
3. **SecurityImplementation**: Concrete implementations
4. **SecurityBridge**: Integration with platform security features

## Usage

```swift
import SecurityTypes

// Define a secure operation
let operation = SecurityOperation(
    type: .encryption,
    algorithm: .aes256,
    mode: .gcm
)

// Use security types in your implementation
struct SecureData: SecureStorable {
    let data: EncryptedData
    let metadata: SecurityMetadata
    
    // Implementation of SecureStorable protocol
}
```

## Integration

This module is designed to be imported by any component that needs to work with security concepts without introducing heavy dependencies. It is foundation-free to enable use in a wide variety of contexts.
