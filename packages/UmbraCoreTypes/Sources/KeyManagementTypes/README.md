# KeyManagementTypes

## Purpose

This module provides type definitions for key management operations in UmbraCore. It defines structures and enumerations related to cryptographic key management that are used throughout the system.

These types are foundation-independent where possible, following the UmbraCore Alpha Dot Five architecture principles to maximise reusability and minimise dependencies.

## Public API Summary

- `KeyMetadata`: Comprehensive metadata structure for cryptographic keys
- `KeyStatus`: Status enumeration for key lifecycle states
- `StorageLocation`: Locations where keys can be stored
- `AccessControls`: Access control settings for cryptographic operations

## Dependencies

This package has minimal dependencies, primarily:
- Foundation (for Date and Data types)

## Example Usage

```swift
// Create key metadata
let metadata = KeyMetadata(
    status: .active,
    storageLocation: .secureEnclave,
    accessControls: .requiresBiometric,
    createdAt: Date(),
    lastModified: Date(),
    expiryDate: nil,
    algorithm: "RSA-4096",
    keySize: 4096,
    name: "UserMasterKey",
    applicationTag: "com.umbra.masterkey",
    isExtractable: false,
    isPermanent: true,
    usageFlags: [.decrypt, .sign]
)

// Check key status
if metadata.status == .active && !metadata.isExpired() {
    // Use the key for operations
}
```

## Internal Structure

This module contains several Swift files that define the core key management types:

- `KeyMetadata.swift`: Comprehensive metadata for cryptographic keys
- `KeyStatus.swift`: Enumeration of possible key states
- `StorageLocation.swift`: Storage location definitions
- `AccessControls.swift`: Access control settings
- `TypeConverters.swift`: Conversion utilities for non-Foundation environments
