# CryptoTypes Migration Plan

## Functional Analysis

The CryptoTypes module currently contains a mix of:

1. Pure cryptographic operations (encryption, decryption, key generation)
2. Credential management functionality
3. Configuration types

## Proposed Migration Structure

### UmbraCoreTypes/CryptoTypes
- Core cryptographic types
- Cryptographic algorithm definitions
- Key types and structures

### UmbraInterfaces/CryptoServiceInterfaces
- Service protocols for cryptographic operations
- Pure cryptographic operation definitions

### UmbraInterfaces/CredentialManagementInterfaces
- Credential storage and retrieval interfaces
- Integrate with existing SecurityTypes where appropriate

## Potential Duplication Concerns

1. The SecureStorageProvider in SecurityTypes overlaps with credential storage
2. Error handling should leverage UmbraErrors instead of custom errors
3. Configuration should align with the broader UmbraCore configuration approach

## Migration Steps

1. Migrate core types to UmbraCoreTypes/CryptoTypes
2. Review interfaces against SecurityTypes for potential consolidation
3. Update all references to use new module structure
4. Add to MigratedArchive once completed
