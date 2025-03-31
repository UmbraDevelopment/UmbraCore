# SecurityInterfaces

This module provides a clean interface for security operations that bridges between different underlying security implementations.

## Architecture

The SecurityInterfaces module is designed to solve Swift's namespace conflict issues when dealing with types that have the same name in different modules. It uses a pattern of isolated imports and type mapping to avoid ambiguity.

### Key Components

1. **SecurityProvider Protocol**: The main public interface for security operations
2. **SecurityProviderAdapter**: Bridges between the SecurityProtocolsCore implementation and SecurityProvider interface
3. **SecurityProtocolsCore Isolation**: Separate files that import only SecurityProtocolsCore to avoid conflicts
4. **Type Mapping Functions**: Convert between similar types in different modules
5. **Error Mapping**: Comprehensive error translation between different modules
6. **Subpackage Isolation**: Dedicated module for SecurityProtocolsCore wrappers
7. **Type Aliases**: Simplify references to types from different modules

### Namespace Resolution Approach

The module uses an enhanced "Isolation Pattern" to resolve namespace conflicts:

- **Isolated Imports**: Files that only import one conflicting module at a time
- **Proxy Classes**: Wrappers that handle type conversion between modules
- **Build Configuration**: Special compiler flags for improved type resolution
- **Subpackages**: Separate modules with distinct names for highly conflicting areas
- **Private Type Aliases**: Clarify which version of a type is being used

For detailed information about the namespace resolution strategy, see the [NamespaceResolution.md](Documentation/NamespaceResolution.md) documentation.

## Updated Usage Example

```swift
import SecurityInterfaces

// Create a SecurityProvider using the factory
do {
    let securityProvider = try SecurityProviderFactory.createProvider(ofType: "standard")
    
    // Use the security provider
    let result = try await securityProvider.performSecurityOperation(
        operation: .encrypt,
        parameters: [
            "data": "My secret message".data(using: .utf8)!,
            "key": "encryption-key",
            "algorithm": "AES",
        ]
    )
    
    // Process the result
    if result.success, let encryptedData = result.data {
        print("Encrypted data: \(encryptedData.base64EncodedString())")
    }
} catch {
    print("Security operation failed: \(error)")
}
```

## Module Organization

The SecurityInterfaces module is organized as follows:

- **SecurityProvider.swift**: Main protocol and adapter implementation
- **SecurityProviderFactory.swift**: Factory for creating provider instances
- **SecurityProtocolsCore/**: Isolated wrapper for SecurityProtocolsCore module
  - **SPCorePackage.swift**: Re-exports and type aliases
  - **SecurityProtocolsCoreProvider.swift**: Provider wrapper
  - **SecurityProtocolsCoreErrorMapping.swift**: Error mapping
  - **SecurityProtocolsCoreTypeMapping.swift**: Type mapping functions
- **Tests/**: Test cases for the module
- **Documentation/**: Detailed documentation on patterns and usage

## Error Handling

The module handles errors by:

1. Mapping specific error types between modules using dedicated mapping functions
2. Preserving error details and context when converting between error types
3. Using a consistent SecurityInterfacesError for all public APIs

## Compiler Configuration

The module uses special compiler flags to handle type resolution:

```bazel
copts = [
    "-Xfrontend", "-enable-implicit-module-import-name-qualification",
]
```

## Subpackage Structure

The SecurityInterfaces module now includes a dedicated subpackage for SecurityProtocolsCore interactions:

```bazel
# SecurityInterfacesSPCore subpackage
module_name = "SecurityInterfaces_SecurityProtocolsCore"
```

## Using Third-Party Providers

You can also use third-party providers that conform to either SecurityProviderBase or SecurityProtocolsCore.SecurityProviderProtocol:

```swift
import SecurityInterfaces
import ThirdPartySecurityModule

// Create a provider from the third-party implementation
let thirdPartyImpl = ThirdPartySecurityProvider()
let securityProvider = try SecurityProviderFactory.createProvider(fromThirdParty: thirdPartyImpl)

// Use it as normal
let result = try await securityProvider.performSecurityOperation(operation: .encrypt, parameters: params)
```

## Testing

Run the provided unit tests to verify the correct functioning of the security module:

```swift
import XCTest
import SecurityInterfaces

class MySecurityTests: XCTestCase {
    func testEncryption() async throws {
        let provider = try SecurityProviderFactory.createProvider(ofType: "test")
        // Test security operations...
    }
}
