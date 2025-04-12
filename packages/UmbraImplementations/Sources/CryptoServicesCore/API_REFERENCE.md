# UmbraCore Cryptographic Services API Reference

## Table of Contents

1. [Overview](#overview)
2. [Service Selection](#service-selection)
3. [Core Interfaces](#core-interfaces)
4. [Encryption Operations](#encryption-operations)
5. [Decryption Operations](#decryption-operations)
6. [Hash Operations](#hash-operations)
7. [Key Management](#key-management)
8. [Algorithm Compatibility](#algorithm-compatibility)
9. [Error Handling](#error-handling)
10. [Testing Utilities](#testing-utilities)

## Overview

UmbraCore's cryptographic services provide a modular, explicitly-selected implementation architecture that enforces clear separation between different cryptographic implementations while requiring developers to make conscious decisions about which implementation to use.

This API reference provides comprehensive documentation of the available interfaces, implementations, algorithms, and usage patterns to help developers use the cryptographic services effectively.

## Service Selection

The first step in using UmbraCore's cryptographic services is selecting the appropriate implementation for your use case. This is done through the `CryptoServiceRegistry`:

```swift
// Create a cryptographic service with an explicit implementation type
let cryptoService = await CryptoServiceRegistry.createService(
    type: .standard, // Explicitly choose the implementation
    secureStorage: mySecureStorage,
    logger: myLogger
)
```

### Available Service Types

The `CryptoServiceType` enum defines the available implementation types:

```swift
public enum CryptoServiceType: String {
    case standard       // Default AES-based implementation
    case applePlatform  // Apple CryptoKit implementation
    case crossPlatform  // Ring FFI implementation
}
```

## Core Interfaces

All cryptographic services implement the `CryptoServiceProtocol` interface:

```swift
public protocol CryptoServiceProtocol {
    // Core cryptographic operations
    func encrypt(dataIdentifier: String, keyIdentifier: String, options: EncryptionOptions?) async -> Result<String, SecurityStorageError>
    func decrypt(dataIdentifier: String, keyIdentifier: String, options: DecryptionOptions?) async -> Result<String, SecurityStorageError>
    
    // Hash operations
    func verifyHash(dataIdentifier: String, hashIdentifier: String, options: HashOptions?) async -> Result<Bool, SecurityStorageError>
    func computeHash(dataIdentifier: String, options: HashOptions?) async -> Result<String, SecurityStorageError>
    
    // Key management
    func generateKey(identifier: String, options: KeyGenerationOptions?) async -> Result<Bool, SecurityStorageError>
    
    // Data handling
    func retrieveData(identifier: String) async -> Result<Data, SecurityStorageError>
    func storeData(_ data: Data, identifier: String) async -> Result<Bool, SecurityStorageError>
}
```

## Encryption Operations

Encryption operations transform plaintext data into ciphertext using a specified key and algorithm.

### Basic Encryption

```swift
// Store the data to encrypt
let dataToEncrypt = "Sensitive information".data(using: .utf8)!
let dataId = "plaintext-data-123"
await secureStorage.store(dataToEncrypt, withIdentifier: dataId)

// Encrypt with default options
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: dataId,
    keyIdentifier: "encryption-key-456"
)

switch encryptResult {
case .success(let encryptedDataId):
    print("Data encrypted successfully, ID: \(encryptedDataId)")
case .failure(let error):
    print("Encryption failed: \(error)")
}
```

### Encryption with Specific Algorithm

```swift
// Create options with specific algorithm and mode
let encryptionOptions = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    padding: .pkcs7
)

// Encrypt with specified options
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: dataId,
    keyIdentifier: "encryption-key-456",
    options: encryptionOptions
)
```

### Encryption with Custom Initialisation Vector

```swift
// Generate a custom IV (or get from an external source)
let customIV = Data((0..<16).map { _ in UInt8.random(in: 0...255) })

// Create options with the custom IV
let encryptionOptions = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    iv: customIV
)

// Encrypt with the custom IV
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: dataId,
    keyIdentifier: "encryption-key-456",
    options: encryptionOptions
)
```

### Authenticated Encryption with Additional Data

```swift
// Additional authenticated data provides integrity checking
let aad = "Context information".data(using: .utf8)!

// Create options with AAD
let encryptionOptions = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    additionalAuthenticatedData: aad
)

// Encrypt with authenticated data
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: dataId,
    keyIdentifier: "encryption-key-456",
    options: encryptionOptions
)
```

## Decryption Operations

Decryption operations transform ciphertext back into plaintext using the corresponding key and algorithm.

### Basic Decryption

```swift
// Decrypt with default options
let decryptResult = await cryptoService.decrypt(
    dataIdentifier: encryptedDataId,
    keyIdentifier: "encryption-key-456"
)

switch decryptResult {
case .success(let decryptedDataId):
    // Retrieve the decrypted data
    let dataResult = await cryptoService.retrieveData(identifier: decryptedDataId)
    if case .success(let decryptedData) = dataResult {
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        print("Decrypted data: \(decryptedString ?? "Unable to decode as string")")
    }
case .failure(let error):
    print("Decryption failed: \(error)")
}
```

### Authenticated Decryption with Additional Data

```swift
// Must use the same AAD as during encryption
let aad = "Context information".data(using: .utf8)!

// Create options with AAD
let decryptionOptions = DecryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm,
    additionalAuthenticatedData: aad
)

// Decrypt with authenticated data
let decryptResult = await cryptoService.decrypt(
    dataIdentifier: encryptedDataId,
    keyIdentifier: "encryption-key-456",
    options: decryptionOptions
)
```

## Hash Operations

Hash operations compute a fixed-size digest of data for integrity verification.

### Computing a Hash

```swift
// Compute a hash with default options (SHA-256)
let hashResult = await cryptoService.computeHash(
    dataIdentifier: dataId
)

switch hashResult {
case .success(let hashId):
    print("Hash computed successfully, ID: \(hashId)")
case .failure(let error):
    print("Hashing failed: \(error)")
}
```

### Computing a Hash with Specific Algorithm

```swift
// Create options with specific hash algorithm
let hashOptions = HashOptions.standard(
    algorithm: .sha512
)

// Compute a hash with specified algorithm
let hashResult = await cryptoService.computeHash(
    dataIdentifier: dataId,
    options: hashOptions
)
```

### Verifying a Hash

```swift
// Verify a previously computed hash
let verifyResult = await cryptoService.verifyHash(
    dataIdentifier: dataId,
    hashIdentifier: hashId
)

switch verifyResult {
case .success(let isValid):
    if isValid {
        print("Hash verification successful")
    } else {
        print("Hash verification failed - data may have been tampered with")
    }
case .failure(let error):
    print("Hash verification operation failed: \(error)")
}
```

## Key Management

Key management operations handle the generation, storage, and retrieval of cryptographic keys.

### Generating a Random Key

```swift
// Generate a key with default options (256-bit AES key)
let generateResult = await cryptoService.generateKey(
    identifier: "encryption-key-456"
)

switch generateResult {
case .success:
    print("Key generated successfully")
case .failure(let error):
    print("Key generation failed: \(error)")
}
```

### Generating a Key with Specific Size

```swift
// Create options with specific key size
let keyOptions = KeyGenerationOptions.standard(
    algorithm: .aes256GCM,
    byteLength: 32 // 256-bit key
)

// Generate a key with specified size
let generateResult = await cryptoService.generateKey(
    identifier: "encryption-key-456",
    options: keyOptions
)
```

### Generating a Password-Derived Key

```swift
// Create options for password-derived key
let keyOptions = KeyGenerationOptions.passwordDerived(
    password: "secure-passphrase",
    saltLength: 16,
    iterations: 10000,
    algorithm: .argon2id
)

// Generate a key from password
let generateResult = await cryptoService.generateKey(
    identifier: "password-derived-key-789",
    options: keyOptions
)
```

## Algorithm Compatibility

Each implementation supports different algorithms based on its underlying cryptographic library:

| Algorithm | Standard Implementation | Apple Platform Implementation | Cross-Platform Implementation |
|-----------|-------------------------|-------------------------------|------------------------------|
| **Encryption** |
| AES-256-CBC | ✅ Supported | ❌ Not supported | ❌ Not supported |
| AES-256-GCM | ⚠️ Limited support | ✅ Preferred | ❌ Not supported |
| ChaCha20-Poly1305 | ❌ Not supported | ❌ Not supported | ✅ Preferred |
| **Hashing** |
| SHA-256 | ✅ Supported | ✅ Supported | ✅ Supported |
| SHA-384 | ✅ Supported | ✅ Supported | ✅ Supported |
| SHA-512 | ✅ Supported | ✅ Supported | ✅ Supported |
| HMAC-SHA256 | ✅ Supported | ✅ Supported | ✅ Supported |
| BLAKE3 | ❌ Not supported | ❌ Not supported | ✅ Supported |
| **Key Derivation** |
| PBKDF2 | ✅ Supported | ✅ Supported | ✅ Supported |
| Argon2id | ❌ Not supported | ❌ Not supported | ✅ Supported |
| **Modes** |
| CBC | ✅ Supported | ⚠️ Limited support | ❌ Not supported |
| GCM | ⚠️ Limited support | ✅ Preferred | ❌ Not supported |
| CTR | ✅ Supported | ⚠️ Limited support | ❌ Not supported |
| **Padding** |
| PKCS7 | ✅ Supported | ✅ Supported | ❌ Not supported |
| None | ✅ Supported | ✅ Supported | ✅ Supported |

### Recommended Algorithms by Implementation

#### Standard Implementation

- **Encryption:** AES-256-CBC with PKCS7 padding
- **Hashing:** SHA-256
- **Key Derivation:** PBKDF2

#### Apple Platform Implementation

- **Encryption:** AES-256-GCM (authenticated encryption)
- **Hashing:** SHA-256
- **Key Derivation:** PBKDF2 with hardware acceleration where available

#### Cross-Platform Implementation

- **Encryption:** ChaCha20-Poly1305 (authenticated encryption)
- **Hashing:** BLAKE3 or SHA-256
- **Key Derivation:** Argon2id

## Error Handling

The cryptographic services use a standardised error handling approach:

```swift
// Example of proper error handling
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: dataId,
    keyIdentifier: "encryption-key-456"
)

switch encryptResult {
case .success(let encryptedDataId):
    // Handle success case
    print("Encryption successful, ID: \(encryptedDataId)")
    
case .failure(let error):
    // Get more details about the error
    let mappedError = CryptoErrorMapper.map(storageError: error)
    
    // Handle specific error types
    switch mappedError.code {
    case .invalidInput:
        print("Invalid input parameters: \(mappedError.message)")
    case .invalidKeySize:
        print("Key size is invalid: \(mappedError.message)")
    case .encryptionFailed:
        print("Encryption operation failed: \(mappedError.message)")
    default:
        print("Error: \(mappedError.message)")
    }
}
```

### Error Validation Helpers

Use the validation helpers to ensure parameters are valid:

```swift
// Validate a condition
let validation = CryptoErrorHandling.validate(
    !identifier.isEmpty,
    code: .invalidInput,
    message: "Identifier cannot be empty"
)

// Check if validation failed
if case .failure(let error) = validation {
    print("Validation failed: \(error.message)")
    return .failure(.storageError(error.message))
}

// Validate a key
let keyValidation = CryptoErrorHandling.validateKey(
    keyData,
    algorithm: .aes256GCM
)

// Validate an IV
let ivValidation = CryptoErrorHandling.validateIV(
    ivData,
    algorithm: .aes256GCM
)
```

## Testing Utilities

The cryptographic services include utilities for testing:

### Mock Implementations

```swift
// Create a mock crypto service for testing
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

### Test Data Generation

```swift
// Generate test keys for testing
let testKey = CryptoTestUtilities.generateTestKey(
    algorithm: .aes256GCM
)

// Generate test IVs for testing
let testIV = CryptoTestUtilities.generateTestIV(
    algorithm: .aes256GCM
)

// Generate test data with specific size
let testData = CryptoTestUtilities.generateTestData(size: 1024)
```

### Common Test Patterns

```swift
// Test successful encryption
func testSuccessfulEncryption() async {
    // Arrange
    let mockStorage = MockSecureStorage()
    let mockService = MockCryptoService(
        secureStorage: mockStorage,
        mockBehaviour: .init(shouldSucceed: true)
    )
    
    let testData = CryptoTestUtilities.generateTestData(size: 128)
    let dataId = "test-data"
    let keyId = "test-key"
    
    // Store test data in mock storage
    await mockStorage.store(testData, withIdentifier: dataId)
    
    // Act
    let result = await mockService.encrypt(
        dataIdentifier: dataId,
        keyIdentifier: keyId
    )
    
    // Assert
    switch result {
    case .success(let encryptedId):
        XCTAssertTrue(encryptedId.starts(with: "mock-encrypted-"))
    case .failure(let error):
        XCTFail("Encryption failed with error: \(error)")
    }
}
```
