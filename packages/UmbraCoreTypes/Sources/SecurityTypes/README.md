# SecurityTypes

## Overview
The SecurityTypes module provides core security types and utility structures used throughout the UmbraCore system. It contains foundational security types with special focus on secure memory management.

## Public API Summary

### Primary Types
- `SecureBytes`: A secure byte array that automatically zeros its contents when deallocated, providing a Foundation-independent alternative to Data with secure memory handling.
- Various cryptographic aliases including `Nonce`, `Salt`, `Key`, `InitialisationVector`, and `Hash` for semantic clarity.

### Key Functionality
- Secure memory management for sensitive data
- Cryptographically sound byte manipulation
- Memory-zeroing capabilities to prevent sensitive data leakage

## Usage Examples

### Working with SecureBytes
```swift
// Create empty secure bytes
let emptyBytes = SecureBytes()

// Create from raw bytes
let key = SecureBytes(bytes: [0x01, 0x02, 0x03, 0x04])

// Create with zeros
let zeros = try? SecureBytes(count: 32)

// Access bytes
let firstByte = key[0]

// Append bytes
var mutableBytes = SecureBytes()
mutableBytes.append(0xFF)
mutableBytes.append(contentsOf: [0xAA, 0xBB, 0xCC])

// Zero memory when finished
mutableBytes.reset()
```

### Using with Foundation Data
```swift
// Convert to Data for interoperability with Foundation APIs
let secureBytes = SecureBytes(bytes: [0x01, 0x02, 0x03, 0x04])
let data = secureBytes.toData()

// Create from Data (typically from network, files, etc.)
let newSecureBytes = SecureBytes(bytes: [UInt8](data))
```

## Notes for Developers
- Always use `reset()` on SecureBytes instances when finished with sensitive data
- For better memory safety, consider limiting the scope of SecureBytes variables
- All bytes are zeroed automatically upon deallocation but explicit resetting is advised for deterministic cleanup
- This module is designed to have minimal dependencies beyond Foundation
