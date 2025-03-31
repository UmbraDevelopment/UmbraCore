# UmbraKeychainService

The UmbraKeychainService module provides secure keychain access for UmbraCore applications.

## Overview

UmbraKeychainService enables secure storage and retrieval of sensitive credentials such as repository passwords, SSH keys, and cloud provider tokens in the macOS Keychain.

## Features

- Secure storage of Restic repository passwords
- Management of cloud provider credentials
- SSH key integration
- Cross-application credential sharing
- Automatic access control management

## Architecture

UmbraKeychainService is designed to work in both sandboxed and non-sandboxed environments:

1. **Direct Mode**: For applications with direct keychain access
2. **XPC Mode**: For sandboxed applications that need to delegate keychain operations

## Usage

```swift
import UmbraKeychainService

// Create a keychain service
let keychainService = UmbraKeychainService()

// Store a repository password
try await keychainService.storePassword(
    "my-secure-password",
    forRepository: "backup-repo",
    withOptions: .accessibleAfterFirstUnlock
)

// Retrieve a repository password
let password = try await keychainService.retrievePassword(
    forRepository: "backup-repo"
)
```

## Security Considerations

- All keychain operations use secure best practices
- Access control lists are properly maintained
- XPC integration ensures sandboxed applications can securely access credentials
- Deleted credentials are securely wiped from memory
