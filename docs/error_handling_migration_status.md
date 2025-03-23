# Error Handling Migration Status

This document tracks the migration of UmbraCore modules from the legacy `CoreErrors` system to the new standardised error handling architecture located in the `ErrorHandling*` modules.

## Migration Overview

The migration involves:

1. Replacing imports of `CoreErrors` with the appropriate new modules:
   - `ErrorHandlingCore`
   - `ErrorHandlingDomains`
   - `ErrorHandlingInterfaces`
   - `ErrorHandlingMapping`

2. Replacing direct references to `CoreErrors` types with fully qualified types from the new architecture.

3. Marking existing typealiases with `@deprecated` annotations to encourage direct usage of the underlying types.

4. Updating error throwing, catching, and handling logic to use the new error types.

## Migration Status

| Module | Status | Notes |
|--------|--------|-------|
| UmbraCryptoService | ✅ Completed | All files migrated to new error handling architecture |
| CoreTypesImplementation | ✅ Completed | Updated all files and deprecated typealiases |
| Services | ✅ Completed | Updated Services_Aliases.swift, SecurityBookmarkService.swift, URLProvider.swift, and CryptoService.swift |
| SecurityInterfacesBase | ✅ Completed | Updated SecurityError.swift with proper mappings to UmbraErrors.XPC.SecurityError, added deprecation annotations to typealiases, and updated SecurityProviderBase.swift |
| CoreDTOs | ✅ Completed | Module was already migrated with proper error handling. Contains compatibility functions in ErrorTypesCompat.swift to support transition between legacy and new APIs. Migration guidance included in XPCSecurityErrorDTO.swift. |
| UmbraSecurity | ✅ Completed | Updated SecurityServiceNoCrypto.swift and both versions of URL+SecurityScoped.swift to use the new error handling modules. Fixed malformed import statements and replaced all direct references to CoreErrors types. |

## Typealias Deprecation Strategy

Typealiases are being marked as deprecated with migration guidance to use the fully qualified types directly. This follows the UmbraCore project guidelines to reduce indirection and improve type clarity.

Example of a deprecated typealias:

```swift
/// @deprecated This typealias will be removed in a future update.
/// New code should use UmbraErrors.Security.Core directly to improve code clarity.
@available(
  *,
  deprecated,
  message: "Use UmbraErrors.Security.Core directly instead of this typealias for improved type clarity"
)
public typealias CESecurityError = UmbraErrors.Security.Core
```

## Next Steps

1. Run comprehensive tests to verify error handling works correctly
2. Update any remaining documentation
3. Consider removing the legacy CoreErrors module if it's no longer referenced anywhere in the codebase

## Completion Criteria

The migration will be considered complete when:

1. All modules use the new error handling architecture
2. All deprecated typealiases are properly annotated with migration guidance
3. All tests pass successfully
4. The legacy CoreErrors module can be safely removed from the codebase

Last updated: 23 March 2025
