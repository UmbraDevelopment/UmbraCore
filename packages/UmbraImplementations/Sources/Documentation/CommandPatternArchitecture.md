# UmbraCore Command Pattern Architecture

This document describes the command pattern architecture implemented in the UmbraCore project for both cryptographic and file system operations, aligning with the Alpha Dot Five principles.

## Overview

The command pattern is a behavioural design pattern that encapsulates a request as an object, thereby allowing parameterisation of clients with different requests, queuing or logging of requests, and support for undoable operations. In UmbraCore, we use the command pattern to:

1. **Decouple Operation Execution from Operation Definition** - Separating the what from the how
2. **Improve Testability** - Commands can be tested in isolation
3. **Enhance Maintainability** - Each command has a clear, single responsibility
4. **Support Privacy-Aware Logging** - Consistent privacy classification across operations
5. **Standardise Error Handling** - Common patterns for handling failures

## Command Pattern Implementation

Our implementation follows this general structure:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Service Actor  │ ─── │ Command Factory │ ─── │ Command Classes │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Core Components

#### Command Protocols

Each domain has a base command protocol that defines the contract for all commands:

- `CryptoCommand` - Base protocol for cryptographic operations
- `FileSystemCommand` - Base protocol for file system operations

These protocols define a common `execute` method that takes a logging context and an operation ID, and returns a `Result` type.

#### Base Command Classes

Abstract base classes provide common functionality for commands:

- `BaseCryptoCommand` - For cryptographic operations
- `BaseFileSystemCommand` - For file system operations

These base classes include:
- Logger access
- Context creation helpers
- Common utility methods
- Standardised error handling

#### Command Factories

Factories create appropriate command instances:

- `CryptoCommandFactory` - Creates cryptographic command instances
- `ProviderCommandFactory` - Creates provider-based command instances

#### Service Actors

Actor-based services orchestrate command execution:

- `HighSecurityCryptoService` - Uses commands for high-security operations
- `DefaultCryptoService` - Uses commands for standard cryptographic operations
- `CryptoServiceWithProvider` - Uses provider-based commands

## Security Implementations

### Cryptographic Commands

The cryptographic service implementation includes these command types:

- **EncryptCommand** - For encrypting data
- **DecryptCommand** - For decrypting data
- **HashCommand** - For hashing data
- **VerifyHashCommand** - For verifying hashes
- **GenerateKeyCommand** - For generating cryptographic keys
- **DeriveKeyCommand** - For deriving keys from existing keys
- **ImportDataCommand** - For importing data securely
- **ExportDataCommand** - For exporting data securely

Each command encapsulates a specific cryptographic operation and follows consistent patterns for logging, error handling, and configuration.

### Provider-Based Commands

For operations that use a security provider:

- **ProviderEncryptCommand** - For provider-based encryption
- **ProviderDecryptCommand** - For provider-based decryption
- **ProviderHashCommand** - For provider-based hashing
- **ProviderVerifyHashCommand** - For provider-based hash verification
- **ProviderGenerateKeyCommand** - For provider-based key generation
- **ProviderDeriveKeyCommand** - For provider-based key derivation

These commands delegate the actual cryptographic work to a `SecurityProviderProtocol` implementation, while maintaining the command pattern structure.

## File System Implementations

The file system service implementation includes these command types:

- **ReadFileCommand** - For reading file contents
- **WriteFileCommand** - For writing data to files
- **CreateDirectoryCommand** - For creating directories
- **DeleteFileCommand** - For deleting files
- **MoveFileCommand** - For moving files
- **CopyFileCommand** - For copying files
- **ListDirectoryCommand** - For listing directory contents
- **GetFileAttributesCommand** - For retrieving file attributes

## Advantages of This Architecture

### 1. Testability

Commands can be tested in isolation, which makes unit testing more straightforward and focused. Mock dependencies can be injected to test specific behaviours.

### 2. Separation of Concerns

Each command has a clear, single responsibility, which makes the code easier to understand and maintain. The service actors focus on orchestration, while the commands focus on specific operations.

### 3. Consistent Patterns

Common patterns for logging, error handling, and configuration are implemented consistently across all commands, which reduces duplication and ensures consistent behaviour.

### 4. Privacy-Aware Logging

Privacy classification is built into the command structure, ensuring that sensitive information is properly classified and handled in logs.

### 5. Extensibility

New operations can be added by creating new command classes, without modifying existing code. This follows the Open/Closed Principle.

## Usage Examples

### Cryptographic Operations

```swift
// Create a high-security crypto service
let cryptoService = await CryptoServiceFactory.createHighSecurityCryptoService()

// Encrypt data
let encryptedData = await cryptoService.encrypt(
    data: myData, 
    keyIdentifier: "my-encryption-key",
    algorithm: .aes256GCM
)
```

### File System Operations

```swift
// Create a file system service
let fileSystemService = FileSystemService()

// Read a file
let fileContents = await fileSystemService.readFile(path: "/path/to/file")

// Write to a file
await fileSystemService.writeFile(
    data: myData, 
    path: "/path/to/file", 
    createParentDirectories: true
)
```

## Implementing New Commands

To add a new operation:

1. Create a new command class that implements the appropriate command protocol
2. Extend the command factory to create your new command
3. Add a method to the service actor to perform the new operation

## Conclusion

The command pattern architecture in UmbraCore provides a clean, modular approach to implementing cryptographic and file system operations. It aligns with the Alpha Dot Five principles and ensures consistent behaviour across the codebase.

This approach has significantly improved the maintainability, testability, and extensibility of the codebase, while ensuring a high level of security and privacy awareness.
