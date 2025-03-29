# UmbraCore Pluggable Security Providers

This module implements a flexible security provider system for UmbraCore, offering three distinct security integration options:

1. **Basic Security** (AES-CBC) - Fallback implementation using common cryptographic primitives
2. **Ring FFI** - Cross-platform security using Rust's Ring cryptography library
3. **Apple CryptoKit** - Native Apple platform integration with hardware acceleration

## Architecture

The security provider architecture follows the Alpha Dot Five pattern with clear separation of interfaces and implementations:

```
┌─────────────────────┐     ┌─────────────────────┐
│ SecurityProviderType │     │ SecurityConfigDTO   │
└─────────────────────┘     └─────────────────────┘
           │                           │
           └───────────┬───────────────┘
                       │
               ┌───────▼──────┐
               │ Provider API │
               └───────┬──────┘
                       │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐      ┌─────▼─────┐     ┌─────▼─────┐
│ Basic   │      │ Ring FFI  │     │ CryptoKit │
│ AES-CBC │      │ Provider  │     │ Provider  │
└─────────┘      └───────────┘     └───────────┘
```

## Usage

### Basic Usage (Swift 6 Compatible)

The security system now uses an actor-based approach for better concurrency safety:

```swift
// Access the crypto system via the actor
let provider = await UmbraCrypto.shared.provider()

// Encrypt data using the provider
let encryptedData = try provider.encrypt(
    plaintext: myData, 
    key: myKey, 
    iv: myIV, 
    config: SecurityConfigDTO.aesEncryption()
)
```

### Working with SecureBytes

`SecureBytes` provides memory-safe handling of sensitive cryptographic data:

```swift
// Create secure bytes from regular data
let sensitiveData = SecureBytes(data: myRegularData)

// Extract data when needed for operations (creates a copy)
let dataForProcessing = sensitiveData.extractUnderlyingData()

// Securely zero when no longer needed
var tempBytes = sensitiveData
tempBytes.reset()
```

### Using the SecurityProviderBridge

The bridge connects the modern provider architecture to existing systems:

```swift
// Create a bridge with logging
let bridge = await UmbraCrypto.shared.createBridge(logger: myLogger)

// Use the bridge with SecureBytes for operations
let result = await bridge.encrypt(data: secureData, using: secureKey)

// Process the result
switch result {
case .success(let encryptedData):
    // Use the encrypted data
case .failure(let error):
    // Handle the error
}
```

### Selecting a Specific Provider

You can explicitly choose which security provider to use:

```swift
// Set up a specific configuration
let config = SecurityConfigDTO(
    algorithm: "AES",
    keySize: 256,
    blockMode: .gcm,
    padding: .noPadding,
    providerType: .apple
)

// Create a provider of the specified type
let provider = try SecurityProviderFactory.createProvider(type: .apple)

// Or change the global provider
await UmbraCrypto.shared.setProvider(provider)
```

## Security Provider Types

### BasicSecurityProvider

A fallback implementation using CommonCrypto with AES-CBC:

- Available on all platforms
- Implements standard encryption/decryption with PKCS#7 padding
- Uses secure random generation for keys and IVs
- Provides SHA-256/384/512 hashing

### AppleSecurityProvider

Native implementation using CryptoKit for Apple platforms:

- Available on macOS 10.15+, iOS 13.0+, tvOS 13.0+, watchOS 6.0+
- Uses AES-GCM for authenticated encryption
- Leverages hardware acceleration where available
- Provides optimised implementations of modern cryptographic algorithms

### RingSecurityProvider

Cross-platform implementation using Rust's Ring library via FFI:

- Works on any platform with Ring FFI bindings
- Uses constant-time implementations to prevent timing attacks
- Provides AES-GCM for authenticated encryption
- Offers high-quality cryptographic primitives

## Key Classes and Protocols

### EncryptionProviderProtocol

The core protocol that all security providers implement:

```swift
public protocol EncryptionProviderProtocol {
    var providerType: SecurityProviderType { get }
    
    func encrypt(plaintext: Data, key: Data, iv: Data, config: SecurityConfigDTO) throws -> Data
    func decrypt(ciphertext: Data, key: Data, iv: Data, config: SecurityConfigDTO) throws -> Data
    func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data
    func generateIV(size: Int) throws -> Data
    func hash(data: Data, algorithm: String) throws -> Data
}
```

### SecurityConfigDTO

Configuration options for security operations:

```swift
public struct SecurityConfigDTO {
    public let algorithm: String
    public let keySize: Int
    public let blockMode: BlockMode
    public let padding: PaddingMode
    public let providerType: SecurityProviderType
    
    // Factory methods available for common configurations
    public static func aesEncryption(
        providerType: SecurityProviderType = .basic
    ) -> SecurityConfigDTO
}
```

### SecureBytes

Memory-safe container for sensitive data:

```swift
public struct SecureBytes: Sendable, Equatable, Hashable, Codable {
    // Create from various sources
    public init(data: Data)
    public init(bytes: [UInt8])
    
    // Access the underlying data (creates a copy)
    public func extractUnderlyingData() -> Data
    
    // Securely zero the contents
    public mutating func reset()
}
```

## Error Handling

The security system uses the `SecurityProtocolError` enum for consistent error handling:

```swift
public enum SecurityProtocolError: Error {
    case invalidInput(String)
    case cryptographicError(String)
    case unsupportedOperation(name: String)
    // Additional cases for specific errors
}
```

## Thread Safety

- The `UmbraCrypto` class is implemented as an actor for proper concurrency safety
- The `SecurityProviderBridge` is also an actor to ensure thread-safe operations
- Individual providers are designed to be thread-safe and can be used from multiple threads

## Best Practices

1. **Memory Management**: Always use `SecureBytes` for sensitive information and call `reset()` when done
2. **Error Handling**: Check for specific error cases in `SecurityProtocolError` for better diagnostics
3. **Provider Selection**: Choose the appropriate provider for your target platforms
4. **Configuration**: Use the factory methods on `SecurityConfigDTO` for standard configurations
5. **Authenticated Encryption**: Prefer AES-GCM when possible for authenticated encryption

## SecurityCryptoServices

This module provides a comprehensive, actor-based implementation of cryptographic services for the UmbraCore framework. It follows the Alpha Dot Five architecture patterns with proper isolation of mutable state.

### Architecture

The module is built around three primary actors:

1. **CryptoServiceActor**: Provides core cryptographic operations including encryption, decryption, and hashing
2. **SecureStorageActor**: Manages secure storage of cryptographic keys and sensitive data
3. **ProviderRegistryActor**: Centralises provider selection and optimisation

All components fully embrace Swift 6's structured concurrency model with proper actor isolation.

### Usage

#### Creating Service Actors

```swift
// Get a logger implementation
let logger = YourLoggerImplementation()

// Create crypto service with specific provider type
let cryptoService = CryptoServices.createCryptoServiceActor(
    providerType: .apple,
    logger: logger
)

// Create secure storage
let secureStorage = CryptoServices.createSecureStorageActor(
    providerType: .apple,
    logger: logger
)

// Create provider registry
let providerRegistry = CryptoServices.createProviderRegistryActor(
    logger: logger
)
```

#### Encryption and Decryption

```swift
// Encryption
let secureData = SecureBytes(data: sensitiveData)
let secureKey = SecureBytes(data: keyData)

do {
    let encryptedData = try await cryptoService.encrypt(
        data: secureData, 
        using: secureKey
    )
    
    // Use the encrypted data
} catch {
    // Handle error (type is SecurityProtocolError)
}

// Decryption
do {
    let decryptedData = try await cryptoService.decrypt(
        data: encryptedData, 
        using: secureKey
    )
    
    // Use the decrypted data
} catch {
    // Handle error
}
```

#### Key Management

```swift
// Generate a new key
let generatedKey = try await cryptoService.generateKey(size: 256)

// Store a key securely
try await secureStorage.storeKey(
    generatedKey, 
    withIdentifier: "master-key"
)

// Retrieve a key
let retrievedKey = try await secureStorage.retrieveKey(
    withIdentifier: "master-key"
)

// Rotate a key
let encryptedItems = [item1, item2, item3]
let reencryptedItems = try await secureStorage.rotateKey(
    withIdentifier: "master-key",
    newKeySize: 256,
    dataToReencrypt: encryptedItems
)
```

#### Provider Selection

```swift
// Select best provider for current platform
let registry = CryptoServices.createProviderRegistryActor(logger: logger)
let provider = try await registry.selectProvider(for: .currentPlatform)

// Select provider for specific environment
let fipsProvider = try await registry.selectProvider(for: .fipsCompliant)
let lowPowerProvider = try await registry.selectProvider(for: .lowPower)
let specificProvider = try await registry.selectProvider(
    for: .specific(type: .apple)
)
```

### Security Considerations

#### Memory Safety

All sensitive data is handled using `SecureBytes`, which zeroes memory when it's deallocated:

```swift
// SecureBytes automatically zeroes memory on deinit
let secureData = SecureBytes(data: sensitiveData)

// Explicitly clear when no longer needed
secureData.reset()
```

#### Concurrency Safety

All mutable state is isolated within actors, ensuring thread-safe access:

```swift
// Crypto operations are automatically thread-safe
Task {
    let result1 = try await cryptoService.encrypt(data, using: key)
}

Task {
    let result2 = try await cryptoService.encrypt(otherData, using: key)
}
```

#### Provider Selection

The architecture supports dynamic provider selection based on environment requirements:

- **Apple platforms**: Uses Apple CryptoKit for optimal performance
- **Cross-platform**: Uses Ring for broad compatibility 
- **Fallback**: Uses Basic AES provider when others are unavailable

### Error Handling

All operations use the `SecurityProtocolError` type for consistent error handling:

```swift
do {
    let result = try await cryptoService.encrypt(data, using: key)
} catch let error as SecurityProtocolError {
    switch error {
    case .invalidInput(let message):
        // Handle invalid input
    case .cryptographicError(let message):
        // Handle cryptographic failure
    case .unsupportedOperation(let name):
        // Handle unsupported operation
    }
} catch {
    // Handle other errors
}
```

### Batch Operations

For performance-critical applications, batch operations are available:

```swift
// Encrypt multiple items in parallel
let batchResults = try await cryptoService.encryptBatch(
    dataItems: [item1, item2, item3],
    using: key
)
