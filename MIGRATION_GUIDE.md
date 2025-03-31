# UmbraCore Alpha Dot Five Migration Guide

## Overview

UmbraCore has been completely restructured following the Alpha Dot Five architecture principles:

1. **Actor-Based Concurrency**: All services utilize Swift actors for thread safety and structured concurrency
2. **Privacy-By-Design**: Enhanced privacy-aware error handling and logging to prevent sensitive information leakage
3. **Type Safety**: Using strongly-typed interfaces that make illegal states unrepresentable
4. **Async/Await**: Full adoption of Swift's modern concurrency model
5. **Clear Domain Boundaries**: Proper separation between Security, Crypto, and other domains

## Migration Map

The following table maps legacy modules to their new locations:

| Legacy Module | Migrated To |
|---------------|-------------|
| UmbraSecurity | packages/UmbraCoreTypes/Sources/SecurityInterfaces + packages/UmbraImplementations/Sources/SecurityImplementation |
| UmbraCrypto | packages/UmbraCoreTypes/Sources/CryptoTypes + packages/UmbraImplementations/Sources/CryptoServices |
| UmbraCryptoService | packages/UmbraImplementations/Sources/CryptoXPCServices |
| SecurityUtils | packages/UmbraImplementations/Sources/SecurityUtils |
| ErrorHandling | packages/UmbraCoreTypes/Sources/ErrorCoreTypes + packages/UmbraImplementations/Sources/ErrorHandlingImpl |
| UmbraKeychainService | packages/UmbraImplementations/Sources/KeychainServices |
| UmbraBookmarkService | packages/UmbraImplementations/Sources/SecurityUtils (SecurityBookmarkActor) |
| RepositoryManager | packages/UmbraImplementations/Sources/RepositoryServices |
| ResticTypes | packages/UmbraCoreTypes/Sources/ResticTypes |
| ResticCLIHelper | packages/UmbraImplementations/Sources/ResticServices |

## Code Migration Examples

### 1. Migrating from UmbraSecurity to SecurityImplementation

**Old Code:**
```swift
import UmbraSecurity

let securityService = SecurityService()
let encryptedData = securityService.encrypt(data: sensitiveData, key: encryptionKey)
```

**New Code:**
```swift
import SecurityInterfaces
import SecurityImplementation

let factory = SecurityServiceFactory()
let securityService = try await factory.createSecurityService()
let context = SecurityContextDTO(securityLevel: .high, 
                               operationType: .encryption,
                               keyIdentifier: "primary-key")
let encryptedData = try await securityService.secureData(data: sensitiveData, context: context)
```

### 2. Migrating from UmbraCryptoService to CryptoXPCServices

**Old Code:**
```swift
import UmbraCryptoService

let cryptoService = CryptoService()
let hash = cryptoService.computeHash(data: inputData, algorithm: .sha256)
```

**New Code:**
```swift
import CryptoInterfaces
import CryptoXPCServices

let factory = CryptoXPCServiceFactory(logger: logger)
let cryptoService = try await factory.createCryptoXPCService()
let options = CryptoOperationOptionsDTO(algorithm: .sha256, 
                                      securityLevel: .standard)
let hash = try await cryptoService.hash(data: inputData, options: options)
```

## Important Implementation Changes

1. **All APIs are now async/await**
   All synchronous APIs have been replaced with asynchronous alternatives using Swift's structured concurrency.

2. **DTOs for data transfer**
   All data passed between modules now uses clearly defined DTOs with strict type safety.

3. **Factory pattern for service creation**
   Services are now created through factory methods that handle dependency injection.

4. **Actors for thread safety**
   All services are implemented as actors to ensure thread safety.

5. **Enhanced error handling**
   All errors are clearly defined with comprehensive context information.

## Breaking Changes

The Alpha Dot Five architecture introduces several breaking changes:

1. All legacy modules have been deprecated and removed
2. No backward compatibility is maintained
3. All APIs now use `async/await` for concurrency
4. Type names have changed to follow a consistent naming convention

## British Spelling Compliance

As per project guidelines, the codebase now uses British spelling in all documentation and user-facing elements:
- "initialise" instead of "initialize"
- "organisation" instead of "organization"
- "behaviour" instead of "behavior"
- "colour" instead of "color"

Note that actual code identifiers may still use American spelling to maintain compatibility with Swift's standard library.
