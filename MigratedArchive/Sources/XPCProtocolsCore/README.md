# XPCProtocolsCore

This module provides the foundation-free XPC protocol definitions for UmbraCore, serving as a central location for all XPC communication protocols.

## Overview

The XPCProtocolsCore module is a critical part of the UmbraCore XPC Protocol Consolidation effort. It defines standardised and foundation-free protocol interfaces for secure cross-process communication.

## Features

- Foundation-free protocol definitions
- Standardised error types
- Cross-module protocol compatibility
- Adaptors for legacy protocol support
- Foundation-independent DTO-based communication
- Standardised result encapsulation with `OperationResultDTO`
- Advanced key exchange operations
- Secure message passing between application and XPC service
- Structured command execution framework
- Permission management and validation
- Resource lifecycle management

## Integration

This module is designed to be imported by any component that needs to participate in XPC communication without introducing a dependency on Foundation.

```swift
import XPCProtocolsCore

// Define a service conforming to XPC protocols
class MyService: XPCServiceProtocolComplete {
    // Implementation
}

// Define a service using the new DTO-based protocols
class MyDTOService: XPCServiceProtocolDTO {
    // Implementation with DTOs
}

// Or adapt an existing service
let service = MyService()
let dtoAdapter = XPCServiceProtocolDTOAdapter(service: service)

// Create a client connection to the XPC service
let xpcClient = ModernXPCService()

// Execute a command through the XPC service
try await xpcClient.executeCommand(
    command: "backup",
    arguments: ["--tag", "daily", "/Users/Documents"],
    environment: ["PASSWORD": passwordRef]
)
```

## DTO-Based Protocols

The module provides Foundation-independent DTO-based protocols that offer improved type safety and portability:

- `XPCServiceProtocolDTO`: Base protocol for DTO-based XPC services
- `XPCServiceProtocolCompleteDTO`: Comprehensive protocol with key management
- `KeyExchangeDTOProtocol`: Protocol for key exchange operations
- `KeyManagementDTOProtocol`: Protocol for key management operations

These protocols use CoreDTOs for all data exchanges, eliminating Foundation dependencies.

## Modern XPC Components

The module includes modern XPC components for building robust XPC services:

- `XPCConnectionManager`: Actor-based manager for XPC connections
- `XPCConnectionProtocol`: Protocol for establishing and managing XPC connections
- `XPCError`: Comprehensive error type for XPC operations

## Security Considerations

- All commands are validated before execution
- Environment variables are securely passed between processes
- Resources are properly cleaned up after operations
- Security boundaries are maintained throughout operations

## Example Implementation

See `ExampleDTOXPCService.swift` for a complete example of implementing the DTO-based protocols.

## Migration

When migrating from legacy XPC protocols, refer to:

- `XPC_PROTOCOLS_MIGRATION_GUIDE.md` for legacy protocol migration
- `DTO_MIGRATION_GUIDE.md` for moving to DTO-based protocols

## Adapters

The module provides adapters to bridge between legacy and DTO-based protocols:

- `XPCServiceProtocolDTOAdapter`: Adapts legacy services to DTO protocols
- `XPCServiceProtocolCompleteDTOAdapter`: Adapts complete services to DTO protocols
- `KeyExchangeDTOAdapter`: Adds key exchange functionality to standard services
