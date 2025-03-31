# SecurityTypeConverters

A standardised type conversion utility module for UmbraCore security components.

## Overview

This module provides consistent conversion utilities for transferring data between different security-related modules in UmbraCore. It addresses several key challenges:

1. **Cross-module data conversion**: Standardised methods for converting between `BinaryData`, `SecureBytes`, and `DataBridge`
2. **DTO-based communication**: Extensions for working with `SecurityConfigDTO` and `SecurityResultDTO`
3. **Error mapping**: Utilities for converting between different error types across security modules

## Key Components

### DTOExtensions

Extensions for `SecurityConfigDTO` and `SecurityResultDTO` that provide:
- Conversion to/from `BinaryData`
- Creation from various error types
- Helper methods for modifying DTOs with different data types

```swift
// Convert config to binary data
let binaryConfig = securityConfig.toBinaryData()

// Create result from binary data
let result = SecurityResultDTO.from(binaryData: myBinaryData)

// Create result from error
let errorResult = SecurityResultDTO.from(error: securityError)
```

### BinaryDataConverters

Extensions for converting between different secure data types:
- `BinaryData` ↔ `SecureBytes`
- `BinaryData` ↔ `DataBridge`
- `SecureBytes` ↔ `DataBridge`

```swift
// Convert BinaryData to SecureBytes
let secureBytes = binaryData.toSecureBytes()

// Convert SecureBytes to BinaryData
let binaryData = secureBytes.toBinaryData()

// Convert to/from DataBridge
let bridge = binaryData.toDataBridge()
let data = CoreTypesInterfaces.BinaryData.from(bridge: bridge)
```

### ErrorMappers

Standardised error conversion methods:
- Map to `SecurityProtocolsCore.SecurityError`
- Map to `CoreErrors.SecurityError`
- Map to `CoreErrors.XPCErrors.SecurityError`

```swift
// Convert any error to SecurityError
let securityError = SecurityErrorMapper.toSecurityError(anyError)

// Convert to CoreErrors.SecurityError
let coreError = SecurityErrorMapper.toCoreError(anyError)

// Convert to XPC error type
let xpcError = SecurityErrorMapper.toXPCError(anyError)
```

## Usage Guidelines

1. Always use these standardised converters instead of creating custom conversion logic
2. When creating new security modules, add extension methods to this package
3. Use explicit module-qualified names when working with similarly named types

## Example

```swift
import SecurityTypeConverters

// Using the converter utilities in a security bridge
func processSecureData(_ binaryData: CoreTypesInterfaces.BinaryData) -> SecurityResultDTO {
    do {
        // Convert to SecureBytes for internal processing
        let secureBytes = binaryData.toSecureBytes()
        
        // Process the data...
        
        // Return success result
        return SecurityResultDTO(data: secureBytes)
    } catch {
        // Map any error to a consistent SecurityResultDTO
        return SecurityResultDTO.from(error: SecurityErrorMapper.toSecurityError(error))
    }
}
```
