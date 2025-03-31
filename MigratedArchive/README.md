# UmbraCore Migration Archive

This directory contains the archived code from the pre-Alpha Dot Five architecture of UmbraCore. These modules have been fully migrated to the new package structure following the Alpha Dot Five architecture principles:

- Actor-based concurrency
- Clear interface and implementation separation
- Thread safety through proper Swift concurrency patterns
- Privacy-aware logging
- British spelling in documentation

## Purpose

This archive is maintained for historical reference only. All functionality has been migrated to the package structure in `/packages/`. 

## Migration Map

The following table shows where each legacy module has been migrated to:

| Legacy Module | Migrated To |
|---------------|------------|
| UmbraSecurity | packages/UmbraCoreTypes/Sources/SecurityInterfaces + packages/UmbraImplementations/Sources/SecurityImplementation |
| UmbraCrypto | packages/UmbraCoreTypes/Sources/CryptoTypes + packages/UmbraImplementations/Sources/CryptoServices |
| SecurityUtils | packages/UmbraImplementations/Sources/SecurityUtils |
| ErrorHandling | packages/UmbraCoreTypes/Sources/ErrorCoreTypes + packages/UmbraImplementations/Sources/ErrorHandlingImpl |
| UmbraKeychainService | packages/UmbraImplementations/Sources/KeychainServices |
| RepositoryManager | packages/UmbraImplementations/Sources/RepositoryServices |

## Important Note

These modules should not be used in new code. All new development should use the packages in `/packages/` exclusively.

This archive was created on 31 March 2025 as part of the Alpha Dot Five migration project.
