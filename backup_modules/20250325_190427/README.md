# SecurityBridge Module

The SecurityBridge module serves as a boundary layer between Foundation types and foundation-free domain types in the UmbraCore security subsystem. It centralises all Foundation conversions in one place, providing a clear separation between the two type systems.

## Purpose

This module is designed to:

1. Convert between Foundation types (Data, URL, Date) and domain types (SecureBytes, ResourceLocator, TimePoint)
2. Adapt Foundation-dependent implementations to foundation-free protocols
3. Provide utilities for XPC service communication
4. Bridge between legacy APIs and modern foundation-free implementations

## CoreDTO Integration

The SecurityBridge module has been enhanced with Foundation-independent CoreDTOs support. This integration allows for standardised data transfer between modules without relying on Foundation types, particularly useful for XPC communication and cross-module interactions.

### Key Components

#### DTO Adapters

Three primary adapter types have been implemented:

- **SecurityDTOAdapter**: Converts between Foundation-dependent security types and Foundation-independent CoreDTOs
- **XPCSecurityDTOAdapter**: Specialises in conversions between CoreDTOs and XPC-compatible types
- **SecurityProtocolDTOAdapter**: Bridges between protocol-specific types and DTO types

#### SecurityBridge API

The adapters are exposed through the `SecurityBridge.DTOAdapters` namespace:

```swift
// Converting errors
let errorDTO = SecurityBridge.DTOAdapters.toErrorDTO(error: myError)
let nativeError = SecurityBridge.DTOAdapters.fromErrorDTO(dto: errorDTO)

// Converting configurations
let configDTO = SecurityBridge.DTOAdapters.toDTO(config: encryptionConfig)
let nativeConfig = SecurityBridge.DTOAdapters.fromDTO(config: configDTO)

// XPC support
let xpcDict = SecurityBridge.DTOAdapters.toXPC(error: errorDTO)
```

### Benefits

1. **Type Safety**: The DTO approach ensures type safety across module boundaries
2. **Reduced Coupling**: Modules no longer need to depend on Foundation for data transfer
3. **Better XPC Support**: DTOs provide a clean way to transfer data to and from XPC services
4. **Standardisation**: Common patterns for error handling and configuration transfer
5. **Performance**: Reduced overhead by eliminating unnecessary type conversions

## Architecture

```
SecurityBridge
├── Sources
│   ├── DTOAdapters
│   │   ├── SecurityDTOAdapter.swift        // Converts between native errors and SecurityErrorDTO
│   │   ├── XPCSecurityDTOAdapter.swift     // Prepares DTOs for XPC transfer
│   │   └── SecurityProtocolDTOAdapter.swift // Converts protocol-specific types to DTOs
│   ├── XPCBridge
│   │   └── FoundationConversions.swift     // Foundation conversion utilities
│   └── SecurityBridge.swift                // Main entry point
├── Documentation
│   └── CoreDTOIntegration.md               // Detailed documentation
└── README.md                               // This file
```

## Related Modules

- **CoreDTOs**: Contains foundation-free DTO definitions
- **SecurityInterfaces**: Defines interfaces for security operations
- **SecurityProtocolsCore**: Defines foundation-free security protocols

## Examples

See the [SecurityBridgeDTOExample.swift](../../Examples/SecurityBridgeDTOExample.swift) file for usage examples.

## Tests

Unit tests for the DTO adapters are available in the SecurityBridgeTests target.

## Related Documents

- [XPC Protocol Consolidation Guide](../Documentation/XPC_PROTOCOLS_MIGRATION_GUIDE.md)
- [Security Provider Refactoring](../SecurityInterfaces/Refactoring/SecurityProviderRefactoring.md)
