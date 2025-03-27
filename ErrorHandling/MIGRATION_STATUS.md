# Error Handling Architecture Migration

## Current Status

We are in the process of migrating the UmbraCore error handling system from a scattered implementation in `//Sources` to a consolidated architecture in the top-level `//ErrorHandling` directory. This migration aligns with our goal of removing typealiases and using fully qualified types.

## Completed Components

- ✅ **ErrorHandling/Interfaces**
  - Core error protocols and structures
  - Base error handling capabilities
  
- ✅ **ErrorHandling/Core**
  - Generic error implementations
  - Error factory functions
  
- ✅ **ErrorHandling/Mapping**
  - Error mapping infrastructure
  - Registry for mapping between error types
  - Security-specific error mappers
  
- ✅ **ErrorHandling/Domains**
  - Security errors (UmbraErrors.Security.Core)
  - Crypto errors
  - Protocol errors

## Migrated Modules

- ✅ **SecurityImplementation**
  - Updated CryptoError.swift to use fully qualified types
  - Fixed CryptoErrorMapper.swift to reference new error handling modules
  - Updated CryptoServiceCore.swift with proper error handling imports
  - Updated KeyDerivationService.swift to use local CryptoError
  - Updated CryptoServiceImpl.swift with new error handling architecture

- ✅ **CoreDTOs**
  - Updated ErrorTypesCompat.swift to use fully qualified types
  - Fixed OperationResultDTO.swift to use ErrorHandlingCore

- ✅ **UmbraSecurity**
  - Fixed SecurityCryptoService.swift imports
  - Updated SecurityService.swift to use new error handling modules
  - Corrected malformed imports in SecurityServiceBridge.swift
  - Applied consistent error handling patterns

- ✅ **SecurityInterfaces**
  - Updated module exports to use new error handling modules

- ✅ **XPC**
  - Updated XPCServiceProtocols.swift to use the new error handling modules
  - Replaced references to CoreErrors.XPCErrors.SecurityError with ErrorHandlingDomains.SecurityError
  - Ensured proper error mapping for XPC communications

- ✅ **UmbraKeychainService**
  - Updated KeychainXPCProtocol.swift to use the new error handling modules
  - Replaced legacy error handling in KeychainXPCService.swift
  - Updated KeychainXPCDTO.swift to use fully qualified types from ErrorHandlingDomains
  - Removed local error type declarations that duplicated ErrorHandling modules

- ✅ **Core**
  - Updated Core_Aliases.swift to import new error handling modules
  - Updated ServiceContainer.swift to use ErrorHandlingCore.ServiceError instead of CoreErrors.ServiceError
  - Updated UmbraService.swift to reference the new error types and added proper deprecation notices
  - Updated XPCServiceProtocolAlias.swift with appropriate deprecation notices and improved documentation

## Remaining Tasks

1. **Module Imports Update**
   - Continue updating imports in any remaining modules to reference the new error handling modules
   - Replace any import of the old error modules with the new ones

2. **Usage Migration**
   - Replace references to old error types with fully qualified types from the new namespace
   - Example: `SecurityError` → `UmbraErrors.Security.Core.operationFailed`

3. **Legacy Module Removal**
   - Once all references are updated, remove:
     - `//Sources/UmbraErrors`
     - `//Sources/ErrorHandlingInterfaces`
     - `//Sources/ErrorHandlingDomains`

4. **Build File Updates**
   - Update BUILD.bazel files to depend on the new modules
   - Remove references to deprecated modules

## Namespace Structure

The new error handling architecture utilises a hierarchical namespace approach:

```swift
UmbraErrors.Security.Core.operationFailed(reason: "Operation failed")
UmbraErrors.Crypto.invalidKey(reason: "Invalid key format")
```

This replaces the previous approach with typealiases and flatter namespaces.

## Migration Guidelines

1. **Direct Type Usage**
   - Always use fully qualified types from the `UmbraErrors` namespace
   - Do not create new typealiases to these types

2. **Proper Error Creation**
   - Use the factory methods in `ErrorFactory` to ensure proper source tracking
   - Example: `ErrorFactory.makeError(UmbraErrors.Security.Core.invalidKey(reason: "Bad key"))`

3. **Error Handling**
   - Use pattern matching with the specific error cases
   - Example: 
     ```swift
     if case let UmbraErrors.Security.Core.invalidParameter(name, reason) = error {
         // Handle parameter error
     }
     ```

## Migration Progress Tracking

| Module | Status | Notes |
|--------|--------|-------|
| SecurityImplementation | Completed | Updated to use new error handling architecture |
| CoreDTOs | Completed | Updated to use fully qualified types |
| UmbraSecurity | Completed | Updated to use new error handling modules |
| SecurityInterfaces | Completed | Updated module exports to use new error handling modules |
| XPC | Completed | Updated to use new error handling architecture |
| UmbraKeychainService | Completed | Updated to use new error handling modules |
| ResticCLIHelper | Partially Complete | Self-contained ResticError doesn't require updating |
| Core | Completed | Updated all files to use new error handling architecture |
