/**
 # SecurityKeyManagement Module
 
 This module provides key management implementations for the UmbraCore security framework.
 It implements the key management interfaces defined in SecurityCoreInterfaces with concrete
 implementations focusing on secure key storage, retrieval, rotation, and deletion.
 
 ## Components
 
 - KeyManagerImpl: Main implementation of the KeyManagementProtocol
 - Supporting components:
   - KeyStore: Secure storage for cryptographic keys
   - KeyStorageManager: Thread-safe storage manager for keys
 
 ## Usage
 
 The KeyManagerImpl can be instantiated directly or through dependency injection:
 
 ```swift
 // Using default implementation
 let keyManager = KeyManagerImpl()
 
 // Usage via SecurityProviderProtocol
 let securityProvider = SecurityProviderImpl(
   cryptoService: /* crypto service implementation */,
   keyManager: KeyManagerImpl()
 )
 ```
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies
@_exported import SecurityCoreInterfaces
@_exported import SecurityCoreTypes
@_exported import SecurityTypes
@_exported import UmbraErrors

// Public exports
public typealias DefaultKeyManager = KeyManagerImpl
