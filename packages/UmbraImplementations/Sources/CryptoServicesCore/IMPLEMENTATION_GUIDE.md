# UmbraCore Cryptographic Services Implementation Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Implementation Selection Guide](#implementation-selection-guide)
3. [Standard Implementation Examples](#standard-implementation-examples)
4. [Apple Platform Implementation Examples](#apple-platform-implementation-examples)
5. [Cross-Platform Implementation Examples](#cross-platform-implementation-examples)
6. [Migration Examples](#migration-examples)
7. [Best Practices](#best-practices)

## Introduction

This guide provides practical examples of how to use each of UmbraCore's cryptographic service implementations. It is intended to help developers make an informed choice about which implementation is most appropriate for their specific use case, and to demonstrate the correct usage patterns for each implementation.

## Implementation Selection Guide

Choosing the right cryptographic implementation is critical for security, performance, and portability. This table summarises the key factors to consider:

| Factor | Standard Implementation | Apple Platform Implementation | Cross-Platform Implementation |
|--------|-------------------------|-------------------------------|------------------------------|
| **Environments** | General purpose | Apple platforms only | Any platform with Ring FFI |
| **Key Strength** | Industry standard | Hardware-accelerated where available | Strong with constant-time operations |
| **Performance** | Good baseline | Excellent on Apple silicon | Consistent across platforms |
| **Security Model** | FIPS-compatible approach | Apple security architecture | Audited cryptographic primitives |
| **Hardware Acceleration** | Limited | Extensive on Apple platforms | None |
| **Attestation Support** | No | Yes via Secure Enclave | No |
| **Memory Safety** | Standard | Enhanced via CryptoKit | Enhanced via Ring |
| **Portability** | Medium | Low (Apple-only) | High |

### When to Choose Each Implementation

#### Choose Standard Implementation When:

- You need a general-purpose implementation for most environments
- You are working with existing systems that expect AES-CBC encryption
- You need FIPS-compatible cryptographic operations
- You want a balanced approach between compatibility and security

#### Choose Apple Platform Implementation When:

- You are developing exclusively for Apple platforms
- You want to take advantage of hardware acceleration
- You need integration with the Secure Enclave on supported devices
- You require high performance on Apple silicon

#### Choose Cross-Platform Implementation When:

- You need consistent behaviour across different platforms
- You are concerned about timing attacks and side-channel vulnerabilities
- You need modern authenticated encryption with ChaCha20-Poly1305
- You require Argon2id for password hashing and key derivation

## Standard Implementation Examples

The Standard Implementation provides a balanced approach using AES encryption:

### Basic Usage Patterns

```swift
import CryptoServicesCore
import CryptoServicesStandard
import SecurityInterfaces

// Create the secure storage
let secureStorage = MySecureStorage()

// Create the standard implementation
let cryptoService = await CryptoServiceRegistry.createService(
    type: .standard,
    secureStorage: secureStorage,
    logger: logger
)

// Generate an encryption key
let keyResult = await cryptoService.generateKey(
    identifier: "standard-aes-key"
)

// Store sensitive data
let sensitiveData = "Confidential information".data(using: .utf8)!
let storeResult = await cryptoService.storeData(
    sensitiveData,
    identifier: "plaintext-data"
)

// Encrypt the data with AES-CBC (the default for standard implementation)
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: "plaintext-data",
    keyIdentifier: "standard-aes-key"
)

// Decrypt the data
if case .success(let encryptedId) = encryptResult {
    let decryptResult = await cryptoService.decrypt(
        dataIdentifier: encryptedId,
        keyIdentifier: "standard-aes-key"
    )
    
    // Process decrypted data
    if case .success(let decryptedId) = decryptResult {
        let dataResult = await cryptoService.retrieveData(identifier: decryptedId)
        // ...
    }
}
```

### Using CBC Mode with Specific Options

```swift
// Using AES-256-CBC with PKCS7 padding (explicit specification)
let encryptionOptions = EncryptionOptions.standard(
    algorithm: .aes256CBC,
    mode: .cbc,
    padding: .pkcs7
)

let encryptResult = await cryptoService.encrypt(
    dataIdentifier: "plaintext-data",
    keyIdentifier: "standard-aes-key",
    options: encryptionOptions
)
```

### Hashing with SHA-256

```swift
// Compute a SHA-256 hash
let hashOptions = HashOptions.standard(
    algorithm: .sha256
)

let hashResult = await cryptoService.computeHash(
    dataIdentifier: "plaintext-data",
    options: hashOptions
)

// Verify the hash
if case .success(let hashId) = hashResult {
    let verifyResult = await cryptoService.verifyHash(
        dataIdentifier: "plaintext-data",
        hashIdentifier: hashId,
        options: hashOptions
    )
}
```

## Apple Platform Implementation Examples

The Apple Platform Implementation leverages CryptoKit for optimised performance on Apple devices:

### Basic Usage Patterns

```swift
import CryptoServicesCore
import CryptoServicesApple
import SecurityInterfaces

// Create the secure storage
let secureStorage = MySecureStorage()

// Create the Apple platform implementation
let cryptoService = await CryptoServiceRegistry.createService(
    type: .applePlatform,
    secureStorage: secureStorage,
    logger: logger
)

// Generate an encryption key (will use CryptoKit's key generation)
let keyResult = await cryptoService.generateKey(
    identifier: "apple-aes-key"
)

// Store sensitive data
let sensitiveData = "Confidential information".data(using: .utf8)!
let storeResult = await cryptoService.storeData(
    sensitiveData,
    identifier: "plaintext-data"
)

// Encrypt the data with AES-GCM (the default for Apple implementation)
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: "plaintext-data",
    keyIdentifier: "apple-aes-key"
)

// Decrypt the data
if case .success(let encryptedId) = encryptResult {
    let decryptResult = await cryptoService.decrypt(
        dataIdentifier: encryptedId,
        keyIdentifier: "apple-aes-key"
    )
    
    // Process decrypted data
    if case .success(let decryptedId) = decryptResult {
        let dataResult = await cryptoService.retrieveData(identifier: decryptedId)
        // ...
    }
}
```

### Using Authenticated Encryption with Additional Data

```swift
// Additional data to authenticate alongside the ciphertext
let aad = "Request ID: 12345".data(using: .utf8)!

// Using AES-256-GCM with authenticated data
let encryptionOptions = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    additionalAuthenticatedData: aad
)

let encryptResult = await cryptoService.encrypt(
    dataIdentifier: "plaintext-data",
    keyIdentifier: "apple-aes-key",
    options: encryptionOptions
)

// When decrypting, must provide the same additional authenticated data
let decryptionOptions = DecryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    additionalAuthenticatedData: aad
)

if case .success(let encryptedId) = encryptResult {
    let decryptResult = await cryptoService.decrypt(
        dataIdentifier: encryptedId,
        keyIdentifier: "apple-aes-key",
        options: decryptionOptions
    )
}
```

### Using SecureEnclave on Supported Devices

```swift
// Create options that request Secure Enclave if available
let keyOptions = KeyGenerationOptions.standard(
    algorithm: .aes256GCM,
    useSecureEnclave: true  // Will fall back if not available
)

// Generate a key potentially in the Secure Enclave
let keyResult = await cryptoService.generateKey(
    identifier: "secure-enclave-key",
    options: keyOptions
)
```

## Cross-Platform Implementation Examples

The Cross-Platform Implementation uses Ring cryptography library for consistent results across different environments:

### Basic Usage Patterns

```swift
import CryptoServicesCore
import CryptoServicesXfn
import SecurityInterfaces

// Create the secure storage
let secureStorage = MySecureStorage()

// Create the cross-platform implementation
let cryptoService = await CryptoServiceRegistry.createService(
    type: .crossPlatform,
    secureStorage: secureStorage,
    logger: logger
)

// Generate an encryption key for ChaCha20-Poly1305
let keyResult = await cryptoService.generateKey(
    identifier: "chacha-poly-key"
)

// Store sensitive data
let sensitiveData = "Confidential information".data(using: .utf8)!
let storeResult = await cryptoService.storeData(
    sensitiveData,
    identifier: "plaintext-data"
)

// Encrypt the data with ChaCha20-Poly1305 (the default for cross-platform implementation)
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: "plaintext-data",
    keyIdentifier: "chacha-poly-key"
)

// Decrypt the data
if case .success(let encryptedId) = encryptResult {
    let decryptResult = await cryptoService.decrypt(
        dataIdentifier: encryptedId,
        keyIdentifier: "chacha-poly-key"
    )
    
    // Process decrypted data
    if case .success(let decryptedId) = decryptResult {
        let dataResult = await cryptoService.retrieveData(identifier: decryptedId)
        // ...
    }
}
```

### Password-Based Key Derivation with Argon2id

```swift
// Create options for deriving a key from a password using Argon2id
let keyOptions = KeyGenerationOptions.passwordDerived(
    password: "secure-passphrase",
    saltLength: 16,
    iterations: 3,
    memory: 65536,    // 64 MB
    parallelism: 4,
    algorithm: .argon2id
)

// Generate a key from the password
let keyResult = await cryptoService.generateKey(
    identifier: "derived-key",
    options: keyOptions
)
```

### Using BLAKE3 Hashing

```swift
// Compute a BLAKE3 hash
let hashOptions = HashOptions.standard(
    algorithm: .blake3,
    outputLength: 32  // 32 bytes = 256 bits
)

let hashResult = await cryptoService.computeHash(
    dataIdentifier: "plaintext-data",
    options: hashOptions
)

// Verify the hash
if case .success(let hashId) = hashResult {
    let verifyResult = await cryptoService.verifyHash(
        dataIdentifier: "plaintext-data",
        hashIdentifier: hashId,
        options: hashOptions
    )
}
```

## Migration Examples

### Migrating from String Literals to Standardised Types

```swift
// Before: Using string literals for algorithm, mode, and padding
let oldOptions = EncryptionOptions(
    algorithm: "AES-256-GCM",
    mode: "GCM",
    padding: "PKCS7"
)

// After: Using standardised enums
let newOptions = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    padding: .pkcs7
)
```

### Migrating to Factory-Based Service Creation

```swift
// Before: Direct instantiation
let oldService = StandardCryptoService(
    secureStorage: mySecureStorage,
    logger: myLogger
)

// After: Factory-based instantiation
let newService = await CryptoServiceRegistry.createService(
    type: .standard,
    secureStorage: mySecureStorage,
    logger: myLogger
)
```

### Migrating to Standardised Error Handling

```swift
// Before: Direct error checking
if keyData.count != kCCKeySizeAES256 {
    return .failure(.invalidKeySize)
}

// After: Using validation helpers
let keyValidation = CryptoErrorHandling.validateKey(keyData, algorithm: algorithm)
if case .failure(let error) = keyValidation {
    return .failure(.storageError(error.message))
}
```

## Best Practices

### Selecting the Right Implementation

1. **Consider your deployment environment** - Choose the implementation that best matches the platforms you'll be deploying to.
2. **Evaluate your security requirements** - Different implementations offer different security characteristics.
3. **Consider performance needs** - Hardware acceleration can provide significant performance improvements in some environments.
4. **Test thoroughly** - Always test your chosen implementation with your specific workload.

### Security Considerations

1. **Use authenticated encryption where possible** - AES-GCM and ChaCha20-Poly1305 provide authenticated encryption, which should be preferred over non-authenticated modes.
2. **Never reuse nonces/IVs with the same key** - Allow the implementation to generate these values for you when possible.
3. **Use strong key derivation for password-based keys** - Argon2id is recommended when available.
4. **Validate inputs** - Use the validation helpers to ensure your inputs meet the requirements of your chosen algorithms.
5. **Handle errors appropriately** - Don't leak information through error messages in production environments.

### Performance Optimisation

1. **Batch operations when possible** - Minimise the number of cryptographic operations by processing data in larger chunks.
2. **Reuse keys for related operations** - Generating new keys is expensive; reuse keys when appropriate.
3. **Choose hardware-accelerated implementations** - When available, hardware acceleration can provide significant performance improvements.
4. **Use appropriate key derivation parameters** - Adjust memory and CPU usage based on your environment and security requirements.
5. **Profile and benchmark** - Always measure the performance of your cryptographic operations to identify bottlenecks.

### Compatibility Considerations

1. **Maintain consistency across platforms** - If your application needs to run on multiple platforms, consider using the cross-platform implementation for consistent behaviour.
2. **Document algorithm choices** - Clearly document which algorithms and modes you're using to ensure future compatibility.
3. **Version your encrypted data** - Include version information with your encrypted data to support future algorithm transitions.
4. **Have a key rotation strategy** - Plan for regular key rotation and algorithm updates.
5. **Test interoperability** - If multiple systems need to decrypt the same data, ensure they can correctly process each other's outputs.
