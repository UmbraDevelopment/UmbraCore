# UmbraCore Security Architecture

The UmbraCore security implementation follows the Alpha Dot Five architecture, providing a modular, maintainable, and secure approach to cryptographic operations.

## Architectural Overview

The security module is organised around these core principles:

1. **Command Pattern**: Each security operation is encapsulated in a separate command object, following the Single Responsibility Principle.

2. **Actor-Based Concurrency**: The implementation uses Swift actors to provide thread safety and structured concurrency.

3. **Provider-Based Abstraction**: Multiple security implementations are supported through a provider pattern.

4. **Privacy-By-Design**: All logging and error handling is privacy-aware, preventing sensitive information leakage.

5. **Type Safety**: The system uses strongly-typed interfaces that make illegal states unrepresentable.

## Component Structure

### Core Components

- **SecurityProviderCore**: The main actor implementing the SecurityProviderProtocol, orchestrating security operations.

- **SecurityCommandFactory**: Creates appropriate command objects for different security operations.

- **SecurityOperationHandler**: Provides standardised execution flow for operations, including logging and error handling.

### Security Operations

Each security operation is implemented as a separate command class:

- **EncryptCommand**: Handles encryption operations.
- **DecryptCommand**: Handles decryption operations.
- **HashCommand**: Handles hashing operations.
- **VerifyHashCommand**: Handles hash verification operations.
- **GenerateKeyCommand**: Handles cryptographic key generation.
- **DeriveKeyCommand**: Handles cryptographic key derivation.

### Utility Components

- **SecurityMetadataExtractor**: Extracts and validates data from security configuration metadata.
- **SecurityProviderFactory**: Creates security providers with different security levels.

## Security Levels

The security implementation offers three pre-configured security levels:

1. **Standard Security**: Suitable for most applications with a good balance between security and performance.
   - AES-256 encryption with GCM mode
   - Basic key derivation
   - Privacy-aware logging

2. **High Security**: Enhanced security for sensitive applications.
   - AES-256 encryption with additional integrity checks
   - Stronger key derivation
   - Enhanced security event logging

3. **Maximum Security**: Highest security level for extremely sensitive data.
   - Maximum strength encryption
   - Memory-hard key derivation
   - Comprehensive security audit logging
   - Additional defence-in-depth measures

## Usage Examples

### Basic Encryption

```swift
// Get a security provider
let securityProvider = await SecurityProviderFactory.createStandardSecurityProvider()

// Create a configuration
let options = SecurityConfigOptions(
    metadata: [
        "inputData": inputData.base64EncodedString(),
        "keyIdentifier": "my-key-identifier"
    ]
)
let config = await securityProvider.createSecureConfig(options: options)

// Perform encryption
let result = try await securityProvider.encrypt(config: config)

// Access the encrypted data
let encryptedData = result.resultData
```

### Secure Key Generation

```swift
// Get a high-security provider
let securityProvider = await SecurityProviderFactory.createHighSecurityProvider()

// Create a configuration
let options = SecurityConfigOptions(
    metadata: [
        "keyType": KeyType.aes256.rawValue,
        "keySize": "256"
    ]
)
let config = await securityProvider.createSecureConfig(options: options)

// Generate a key
let result = try await securityProvider.generateKey(config: config)

// Access the key identifier
guard let keyIdentifierData = result.resultData,
      let keyIdentifier = String(data: keyIdentifierData, encoding: .utf8) else {
    throw SecurityError.operationFailed(reason: "Failed to get key identifier")
}
```

## Error Handling

The security implementation provides comprehensive error handling with domain-specific error types:

- **SecurityError**: General security operation errors
- **SecurityStorageError**: Errors related to key storage and retrieval

All errors contain appropriate context for troubleshooting while maintaining privacy.

## Logging

The security implementation uses privacy-aware logging with different privacy levels:

- **Public**: Information safe to log in any environment
- **Protected**: Information that should only be logged in controlled environments
- **Private**: Sensitive information that should never be logged

## Extending the Architecture

To add new security operations:

1. Create a new command class implementing the SecurityOperationCommand protocol
2. Update the SecurityCommandFactory to create your new command
3. Add a convenience method to SecurityProviderCore if appropriate

## Testing

The command-based architecture makes testing easier:

- Each command can be tested in isolation
- Mock commands can be created for testing the provider
- Security operations can be verified independently
