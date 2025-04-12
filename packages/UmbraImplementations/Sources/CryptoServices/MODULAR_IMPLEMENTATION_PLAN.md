# Modular CryptoServices Implementation Plan

## Overview

This document outlines the plan to refactor the UmbraCore's cryptographic services into a modular, explicitly-selected implementation architecture. Building upon the previous factory consolidation work, this approach will enforce clear separation between different cryptographic implementations while requiring developers to make conscious decisions about which implementation to use.

## Design Goals

1. **Explicit Implementation Selection**
   - Developers must explicitly choose which cryptographic implementation to use
   - Clear documentation of the trade-offs between different implementations
   - No implicit or automatic selection of implementations in production code

2. **Modular Architecture**
   - Each implementation exists in its own module with clear boundaries
   - Implementations do not share code beyond the common interfaces
   - Only the selected implementation gets built and deployed

3. **Enhanced Build Performance**
   - Reduced compile time by only building necessary implementations
   - Smaller binary size by eliminating unused cryptographic code
   - Simplified dependency graphs without circular references

4. **Clear Implementation Boundaries**
   - Standard Implementation: AES-based, general-purpose implementation
   - Cross-platform Implementation: RingFFI with Argon2id for platform-agnostic environments
   - Apple Platform Implementation: CryptoKit optimised for Apple ecosystems

## Implementation Strategy

### Phase 1: Module Restructuring

Create distinct modules for each implementation:

```
//packages/UmbraImplementations/Sources/CryptoServicesCore        (Common utilities, factory)
//packages/UmbraImplementations/Sources/CryptoServicesStandard    (Default AES implementation)
//packages/UmbraImplementations/Sources/CryptoServicesXfn         (Cross-platform with RingFFI)
//packages/UmbraImplementations/Sources/CryptoServicesApple       (Apple CryptoKit implementation)
```

### Phase 2: Interface Refinement

Enhance the `CryptoInterfaces` module to:
- Clarify the contract that all implementations must fulfil
- Add appropriate documentation on implementation selection
- Ensure consistency with the Alpha Dot Five architecture principles

### Phase 3: Configuration System

Create an explicit configuration system for crypto implementation selection:

```swift
public enum CryptoServiceType {
    case standard    // AES-based, standard privacy
    case crossPlatform // RingFFI with Argon2id
    case applePlatform // CryptoKit for Apple platforms
}
```

### Phase 4: BUILD System Configuration

Implement Bazel configuration settings to enable selective building:

```python
config_setting(
    name = "crypto_standard",
    values = {"define": "crypto_implementation=standard"},
)

config_setting(
    name = "crypto_xfn",
    values = {"define": "crypto_implementation=xfn"},
)

config_setting(
    name = "crypto_apple",
    values = {"define": "crypto_implementation=apple"},
)
```

### Phase 5: Factory Implementation

Implement a factory that requires explicit selection:

```swift
public actor CryptoServiceFactory {
    // Factory methods that require explicit selection
    public static func createService(type: CryptoServiceType) async -> CryptoServiceProtocol {
        // Implementation loads the appropriate module based on type
    }
}
```

## Implementation Benefits

1. **Improved Security Posture**
   - Clear boundaries prevent mixing of cryptographic implementations
   - Reduced attack surface by only including necessary code
   - Enhanced auditability through module isolation

2. **Better Developer Experience**
   - Explicit selection prevents confusion about which implementation is being used
   - Documentation is specific to each implementation
   - Clear guidance on which implementation to use for different scenarios

3. **Enhanced Maintainability**
   - Changes to one implementation don't affect others
   - Independent versioning of implementations is possible
   - Easier to add new implementations in the future

4. **Alignment with Alpha Dot Five Architecture**
   - Actor-based implementations for thread safety
   - Provider-based abstractions with clear boundaries
   - Privacy-by-design with appropriate logging controls
   - Strong typing for implementation selection

## Migration Path

1. **For Existing Code**
   - Update imports to reference the specific implementation module
   - Explicitly select the implementation type using the factory
   - Update BUILD.bazel files to reference the correct modules

2. **For New Development**
   - Choose the appropriate implementation based on requirements
   - Use the factory to create the implementation
   - Include only the necessary dependencies in BUILD.bazel

## Testing Strategy

1. **Interface Compliance Tests**
   - Common test suite that verifies all implementations conform to the interface
   - Ensures consistent behaviour across implementations

2. **Implementation-Specific Tests**
   - Targeted tests for the unique features of each implementation
   - Special focus on platform integration for the Apple implementation

3. **Integration Tests**
   - Verify correct factory selection logic
   - Test compatibility with other modules

## Example Usage

```swift
// Developer must explicitly choose an implementation
let configuration = UmbraServiceConfiguration(
    cryptoServiceType: .applePlatform,  // Explicitly choose Apple-native
    privacyLevel: .strict,
    loggingLevel: .minimal
)

let serviceRegistry = await UmbraServiceRegistry(configuration: configuration)
let cryptoService = await serviceRegistry.cryptoService()
```

## Next Steps

1. Create the modular directory structure
2. Update BUILD.bazel files for each module
3. Refactor existing implementations into the new structure
4. Update the factory to support explicit selection
5. Update documentation and examples

## Conclusion

This modular implementation approach enforces developer choice, improves code separation, and aligns with the Alpha Dot Five architecture principles. It will result in more maintainable code with clearer security properties while simplifying the build process.
