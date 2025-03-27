# CryptoInterfaces

CryptoInterfaces provides the protocol definitions for cryptographic operations in the UmbraCore system. Following the Alpha Dot Five architecture, this module focuses exclusively on interface definitions and avoids implementation details.

## Contents

This module contains:

- `CryptoServiceProtocol`: Defines core cryptographic operations like encryption, decryption, and key generation
- `CredentialManagerProtocol`: Defines credential storage and retrieval operations

## Usage Guidelines

- Use these interfaces when defining services that perform cryptographic operations
- Implement these protocols in the UmbraImplementations modules
- Keep protocol definitions focused on behaviour rather than implementation

## Relationship with Other Modules

- Uses `SecurityTypes.SecureBytes` for secure data handling
- Works alongside `SecureStorageProvider` from SecurityTypes
- Avoids direct dependencies on Foundation where possible

## Migration Notes

This module was created as part of splitting the original CryptoTypes module according to the Alpha Dot Five architecture:

- Type definitions → UmbraCoreTypes/CryptoTypes
- Interface definitions → UmbraInterfaces/CryptoInterfaces (this module)
- Implementations → UmbraImplementations/CryptoServices

The interfaces have been modified to use `SecurityTypes.SecureBytes` instead of `Foundation.Data` to improve Foundation independence in alignment with the Alpha Dot Five architectural goals.
