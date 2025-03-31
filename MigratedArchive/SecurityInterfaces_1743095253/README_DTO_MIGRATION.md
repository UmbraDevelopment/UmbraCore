# SecurityInterfaces DTO Migration Guide

This guide explains how to migrate from using Foundation-dependent types in the SecurityInterfaces module to the new Foundation-independent CoreDTOs.

## Overview

The SecurityInterfaces module has been updated to use Foundation-independent DTOs from the CoreDTOs module. These changes allow for:

1. Better portability across platforms
2. Improved XPC communication with standardised data formats
3. Easier testing without Foundation dependencies
4. More predictable serialisation/deserialisation
5. Cleaner interfaces with explicit data requirements

## Key Changes

1. Added support for `SecurityConfigDTO` as an alternative to `SecurityConfiguration`
2. Added support for `SecurityErrorDTO` as an alternative to Foundation-dependent error types
3. Created new `SecurityProviderDTO` protocol that uses these DTOs
4. Updated XPC protocol support with DTO-compatible interfaces
5. Provided adapters for backward compatibility

## How to Migrate

### For API Consumers

If you're using the SecurityInterfaces API, you have several options:

1. **Gradual Migration**: Continue using the existing `SecurityProvider` protocol. It works as before but now uses the adapters internally.

2. **Direct DTO Usage**: Switch to the new `SecurityProviderDTO` protocol for Foundation-independent code:

```swift
// Before
let provider = SecurityProviderFactory.createSecurityProvider()
let configResult = await provider.getSecurityConfiguration()

// After
let provider = SecurityProviderFactory.createSecurityProviderDTO()
let configResult = await provider.getSecurityConfigDTO()
```

3. **Mixed Approach**: Use an adapter to convert between styles:

```swift
// Adapt a legacy provider to use DTOs
let legacyProvider = SecurityProviderFactory.createSecurityProvider()
let modernProvider = SecurityProviderDTOAdapter(provider: legacyProvider)

// Or adapt a DTO-based provider to use traditional APIs
let dtoProvider = SecurityProviderFactory.createSecurityProviderDTO()
// Use it with legacy interfaces through default implementations
let configResult = await dtoProvider.getSecurityConfiguration() 
```

### For XPC Communication

XPC communication now supports both traditional and DTO-based approaches:

```swift
// Create a traditional XPC service
let service = connectToXPCService()
let completeService = XPCProtocolMigrationFactory.createCompleteAdapter(service)

// Convert to DTO-based service
let dtoService = XPCProtocolMigrationFactory.createDTOAdapter(completeService)

// Use DTO methods
let configResult = await dtoService.getSecurityConfigDTO()
```

### For Implementers

If you're implementing a security provider, you have two options:

1. **Implement SecurityProvider**: Continue implementing the traditional protocol. Users can adapt it to the DTO version as needed.

2. **Implement SecurityProviderDTO**: Implement the DTO-based protocol directly and enjoy the benefits of Foundation independence.

```swift
public final class MySecurityProvider: SecurityProviderDTO {
    // Implement methods that use CoreDTOs directly
    
    public func getSecurityConfigDTO() async -> Result<SecurityConfigDTO, SecurityErrorDTO> {
        // Implementation using Foundation-independent types
    }
    
    // Other methods...
}
```

## Best Practices

1. **Prefer DTOs for New Code**: Write new code using the DTO-based interfaces for better future compatibility.

2. **Use Adapters for Legacy Code**: If you have existing code using the traditional interfaces, use the provided adapters.

3. **Test Both Interfaces**: Ensure your code works with both interfaces during the transition period.

4. **Error Handling**: Be careful with error conversion between the two systems. The `SecurityDTOAdapter` provides conversion methods.

5. **Explicit Data Requirements**: Take advantage of the explicit nature of DTOs to document your data requirements clearly.

## Examples

See the `Examples` directory for practical examples of using the DTO-based interfaces, including:

- Direct usage of DTOs
- Adapting between traditional and DTO interfaces
- XPC communication with DTOs

## FAQ

**Q: Will the old interfaces be deprecated?**
A: No, they will continue to be supported through the adapter layer, but new development should prefer the DTO versions.

**Q: Are there performance implications?**
A: The adapters add minimal overhead, primarily for conversion between types. Direct DTO usage avoids this overhead.

**Q: How do I handle custom error types?**
A: Extend the `SecurityDTOAdapter` with methods to convert between your custom error types and `SecurityErrorDTO`.

**Q: Can I use both interfaces simultaneously?**
A: Yes, the `SecurityProviderDTO` interface includes default implementations that adapt to the traditional interface.
