# ServicesDTOAdapter

This module provides adapters to use Foundation-independent CoreDTOs with the Services module components, primarily focusing on CredentialManager and SecurityUtils.

## Overview

The ServicesDTOAdapter module bridges the gap between the Services module's Foundation-dependent APIs and the Foundation-independent DTOs (Data Transfer Objects) defined in CoreDTOs. This allows other modules to interact with Services through a standardized, platform-agnostic interface.

## Key Components

### CredentialManagerDTOAdapter

Adapts the CredentialManager to work with Foundation-independent DTOs for:
- Storing credentials
- Retrieving credentials
- Deleting credentials

All operations return `OperationResultDTO<T>` types rather than throwing errors, allowing for standardized error handling across module boundaries.

### SecurityUtilsDTOAdapter

Provides an adapter for SecurityUtils that works with Foundation-independent DTOs for:
- Generating cryptographic keys
- Hashing data
- Encrypting data
- Decrypting data

### ServicesErrorAdapter

Provides utilities for converting various error types from the Services module to `SecurityErrorDTO`, ensuring consistent error handling.

## Usage Examples

See the `Examples/Services/ServicesDTOExample.swift` file for detailed usage examples of all components.

## Build and Integration Issues

Currently, there are compilation issues related to the SecurityInterfaces module that prevent the ServicesDTOAdapter from building successfully. These issues appear to be related to an ongoing refactoring of the Security modules and include:

1. References to missing types (e.g., `CoreErrors.SecurityError`)
2. Missing enum cases in the `SecurityError` type
3. Deprecated references to security protocols and adapters

## Next Steps

1. **Unit Tests**: Create comprehensive unit tests for all adapter classes
2. **SecurityInterfaces Integration**: Once the SecurityInterfaces module is properly refactored, ensure compatibility between ServicesDTOAdapter and SecurityInterfaces
3. **Documentation**: Add more detailed documentation and usage examples
4. **Performance Optimization**: Review adapter implementations for potential performance improvements, especially in data conversion

## Dependencies

- CoreDTOs
- UmbraCoreTypes
- ErrorHandling
- Services/CredentialManager
- Services/SecurityUtils
