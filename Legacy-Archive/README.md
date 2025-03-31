# UmbraCore Legacy Code Archive

This directory contains archived code from the pre-Alpha Dot Five architecture of UmbraCore. These modules have been fully migrated to the newer package structure following the Alpha Dot Five architecture principles:

- Actor-based concurrency
- Clear interface and implementation separation
- Thread safety through proper Swift concurrency patterns
- Privacy-aware logging
- British spelling in documentation

## Purpose

This archive is maintained for historical reference only. All functionality has been migrated to the package structure in `/packages/`. 

## Migration Map

| Legacy Module | Migrated To |
|---------------|------------|
| UmbraSecurity | packages/UmbraCoreTypes/Sources/SecurityInterfaces + packages/UmbraImplementations/Sources/SecurityImplementation |
| UmbraCrypto | packages/UmbraCoreTypes/Sources/CryptoTypes + packages/UmbraImplementations/Sources/CryptoServices |
| SecurityUtils | packages/UmbraImplementations/Sources/SecurityUtils |
| ErrorHandling | packages/UmbraCoreTypes/Sources/ErrorCoreTypes + packages/UmbraImplementations/Sources/ErrorHandlingImpl |
| UmbraKeychainService | packages/UmbraImplementations/Sources/KeychainServices |
| RepositoryManager | packages/UmbraImplementations/Sources/RepositoryServices |

## Important Note

**DO NOT USE THESE MODULES IN NEW CODE**. All new development should use the packages in `/packages/` exclusively.

This archive was created on 31 March 2025 as part of the Alpha Dot Five migration project.
