# UmbraCore Crypto Command Architecture

The UmbraCore CryptoServices implementation has been refactored to follow a command-based architecture that aligns with the Alpha Dot Five principles, providing a modular, maintainable, and secure approach to cryptographic operations.

## Architectural Overview

The cryptographic services module is organised around these core principles:

1. **Command Pattern**: Each cryptographic operation is encapsulated in a separate command object, following the Single Responsibility Principle.

2. **Actor-Based Concurrency**: The implementation uses Swift actors to provide thread safety and structured concurrency.

3. **Modularity**: The architecture separates concerns into distinct layers: commands, service implementations, and factories.

4. **Privacy-By-Design**: All logging and error handling is privacy-aware, preventing sensitive information leakage.

5. **Testability**: The command-based architecture facilitates easier unit testing of individual operations.

## Component Structure

### Core Components

- **CryptoCommand Protocol**: Defines the contract for all cryptographic operation commands.

- **BaseCryptoCommand**: Abstract base class providing common functionality for all commands.

- **HighSecurityCryptoService**: Actor implementation that orchestrates cryptographic operations through commands.

- **CryptoCommandFactory**: Factory for creating appropriate command objects for different operations.

### Command Implementations

Each cryptographic operation is implemented as a separate command class:

- **EncryptDataCommand**: Handles encryption operations.
- **DecryptDataCommand**: Handles decryption operations.
- **HashDataCommand**: Handles hashing operations.
- **VerifyHashCommand**: Handles hash verification operations.
- **GenerateKeyCommand**: Handles cryptographic key generation.
- **ImportDataCommand**: Handles secure data import operations.
- **ExportDataCommand**: Handles secure data export operations.

### Factory Component

- **CryptoServiceFactory**: Creates cryptographic service implementations with different security levels.

## Advantages of the Command Pattern

The command pattern offers several key benefits for cryptographic operations:

1. **Improved Maintainability**: By breaking down monolithic implementations into focused components, the codebase becomes more maintainable.

2. **Enhanced Testability**: Each command can be tested in isolation, making it easier to verify correctness.

3. **Consistent Error Handling**: Common error handling patterns can be implemented at the command level.

4. **Privacy-Aware Logging**: Consistent privacy-aware logging can be enforced across all operations.

5. **Extensibility**: New cryptographic operations can be added by creating new command classes without modifying existing code.

## Usage Examples

### High-Security Encryption

```swift
// Get a high-security crypto service
let cryptoService = await CryptoServiceFactory.createHighSecurityCryptoService()

// Encrypt data
let result = await cryptoService.encrypt(
    data: myData,
    keyIdentifier: "my-encryption-key",
    algorithm: .aes256GCM
)

switch result {
case .success(let encryptedData):
    // Use the encrypted data
    print("Data encrypted successfully: \(encryptedData.count) bytes")
    
case .failure(let error):
    // Handle the error
    print("Encryption failed: \(error)")
}
```

### Hash Computation

```swift
// Get a crypto service
let cryptoService = await CryptoServiceFactory.shared.createDefault()

// Compute a hash
let hashResult = await cryptoService.hash(
    data: myData,
    algorithm: .sha256
)

switch hashResult {
case .success(let hash):
    // Use the hash
    print("Hash computed successfully: \(hash.count) bytes")
    
case .failure(let error):
    // Handle the error
    print("Hashing failed: \(error)")
}
```

## Extending the Architecture

To add a new cryptographic operation:

1. Create a new command class that implements the `CryptoCommand` protocol and extends `BaseCryptoCommand`.
2. Update the `CryptoCommandFactory` to create your new command.
3. Add a method to `HighSecurityCryptoService` to perform the new operation.

## Implementation Considerations

### Thread Safety

The cryptographic service is implemented as an actor, ensuring thread safety for all operations. Commands themselves are not actors, but they are only executed within the context of the service actor.

### Error Handling

All commands return `Result` types to handle both success and failure cases consistently. Errors are properly categorised using the `SecurityStorageError` type.

### Logging

All commands implement privacy-aware logging, with clear differentiation between public, protected, and private information. This ensures sensitive data is never inadvertently logged.
