# UmbraCore Security Architecture: Module Boundaries

## Overview

This document defines clear boundaries between UmbraCore's cryptographic and security-related modules to reduce redundancy, improve maintainability, and ensure proper separation of concerns. Following the Alpha Dot Five architecture principles, we establish clear responsibilities for each module while ensuring they work together cohesively.

## Module Responsibilities

### 1. Cryptographic Services Modules

**Primary Responsibility:** Provide low-level cryptographic primitives and operations

#### CryptoServicesCore
- **Purpose:** Define common utilities, types, and factory/registry functionality
- **Responsibilities:**
  - Define `CryptoServiceType` enum for explicit implementation selection
  - Provide `CryptoServiceRegistry` for creating service implementations
  - Define common crypto-related types used across implementations
  - Provide utility functions for data conversion, formatting, etc.
  - Supply core interfaces and abstract base implementations

#### CryptoServicesStandard
- **Purpose:** Provide standard AES-based implementation
- **Responsibilities:**
  - Implement AES-256-CBC encryption/decryption
  - Provide standard hashing (SHA-256/SHA-512)
  - Implement key generation using SecRandomCopyBytes
  - Focus on general-purpose compatibility and performance

#### CryptoServicesXfn
- **Purpose:** Provide cross-platform implementation using RingFFI and Argon2id
- **Responsibilities:**
  - Implement ChaCha20-Poly1305 encryption/decryption
  - Provide BLAKE3 hashing
  - Implement Argon2id key derivation
  - Focus on platform-agnostic implementations
  - Ensure constant-time implementations for security

#### CryptoServicesApple
- **Purpose:** Provide Apple-native implementation using CryptoKit
- **Responsibilities:**
  - Implement AES-GCM authenticated encryption
  - Leverage hardware acceleration where available
  - Integrate with Secure Enclave where supported
  - Focus on Apple platform optimisation

### 2. Security Providers Module

**Primary Responsibility:** Provide higher-level security abstractions

#### SecurityProviders
- **Purpose:** Abstract security operations across different providers
- **Responsibilities:**
  - Implement security provider abstractions
  - Provide configuration management for security systems
  - Handle security operations (token management, credential validation)
  - **NOT Responsible For:** Direct cryptographic operations
  - **Should:** Delegate cryptographic operations to CryptoServices

### 3. Security Implementation Module

**Primary Responsibility:** Implement specific security services

#### SecurityImplementation
- **Purpose:** Implement concrete security services
- **Responsibilities:**
  - Provide authentication services
  - Implement authorisation logic
  - Handle security policy enforcement
  - **NOT Responsible For:** Low-level cryptographic operations
  - **Should:** Use CryptoServices for cryptographic needs
  - **Should:** Use SecurityProviders for provider-specific operations

#### SecurityCryptoServices
- **Purpose:** Bridge between security and cryptographic services
- **Responsibilities:**
  - Provide actors for thread-safe crypto operations
  - Handle secure storage with cryptographic protections
  - **Should:** Delegate actual cryptographic operations to CryptoServices
  - **Should NOT:** Duplicate cryptographic implementations

## Interface Alignment

To ensure consistency across modules, interfaces should follow these guidelines:

### Parameter Type Consistency

- **Data Handling:** Use consistent types for binary data (Data or [UInt8])
- **Identifiers:** Use String consistently for identifiers
- **Options:** Use structured option types rather than individual parameters
- **Error Handling:** Use structured Result types with well-defined error enums

### Common Patterns

- **Async/Actor Model:** Use Swift actors for thread safety and async/await for operations
- **Factory Methods:** Use consistent factory method patterns for service creation
- **Dependency Injection:** Consistently provide dependencies via initialisation
- **Privacy Metadata:** Use consistent privacy metadata classification

## Type Definition Placement

To avoid duplication, type definitions should be placed as follows:

### Core Types Package
- **CryptoTypes:** Foundational cryptographic types
- **SecurityTypes:** Foundational security types
- **CoreSecurityTypes:** Common security-related types

### Interface Packages
- **CryptoInterfaces:** Cryptographic service interfaces
- **SecurityInterfaces:** Security service interfaces

### Implementation Packages
- **CryptoServicesCore/Types:** Implementation-specific crypto types
- **SecurityProviders:** Provider-specific types
- **SecurityImplementation:** Implementation-specific security types

## Interaction Flow

The interaction between modules should follow this pattern:

1. Application code interacts with SecurityImplementation
2. SecurityImplementation uses SecurityProviders for provider abstraction
3. Both SecurityImplementation and SecurityProviders use CryptoServices for cryptographic operations
4. CryptoServices performs actual cryptographic operations

This establishes a clear dependency direction:
```
Application → SecurityImplementation → SecurityProviders → CryptoServices
```

## Migration Strategy

To align existing code with these boundaries:

1. **Identify Violations:** Find code that crosses these boundaries
2. **Extract Cryptographic Operations:** Move direct crypto operations to appropriate CryptoServices module
3. **Update Dependencies:** Ensure proper dependency direction
4. **Update Interfaces:** Align interfaces with the patterns above

## Conclusion

By establishing clear boundaries between cryptographic and security modules, we can reduce redundancy, improve maintainability, and ensure proper separation of concerns while maintaining the cohesive functionality of the UmbraCore security architecture.
