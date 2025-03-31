# CryptoTypes

CryptoTypes provides the essential type definitions for cryptographic operations in the UmbraCore system. Following the Alpha Dot Five architecture, this module focuses exclusively on type definitions and avoids implementation details or Foundation dependencies where possible.

## Contents

This module contains:

- Cryptographic configuration types
- Secure storage data structures 
- Cryptographic algorithm definitions
- Key representation types

## Usage Guidelines

- Use these types for defining cryptographic interfaces
- Import only when type definitions are needed
- Avoid adding implementation code to this module
- Maintain Foundation independence where feasible
- Respect proper module boundaries

## Migration Notes

This module was migrated from the legacy CryptoTypes as part of the Alpha Dot Five architecture implementation. The functionality was split into:

- **CryptoTypes** (this module): Core type definitions
- **CryptoInterfaces**: Service protocol definitions
- **CryptoServices**: Implementation of cryptographic operations

## Relationship with Other Modules

- **UmbraErrors**: Uses UmbraErrors for error types
- **SecurityTypes**: Complementary to SecurityTypes, focuses specifically on cryptographic aspects
