/**
 # SecurityProviders Module

 This module contains implementations of the security provider interfaces defined in the
 SecurityCoreInterfaces module. It provides concrete implementations of cryptographic
 services, key management, and other security-related functionality.

 ## Components

 - SecurityProviderImpl: The primary implementation of the SecurityProviderProtocol
 - Core supporting components:
   - SecurityProviderCore: The central implementation of security provider functionality
   - OperationsHandler: Routes security operations to appropriate handlers
   - ConfigBuilder: Creates and validates security configurations
   - Utilities: Utility functions for data conversion and formatting

 ## Usage

 The SecurityProviderImpl can be instantiated directly or through dependency injection:

 ```swift
 // Using default implementations
 let securityProvider = SecurityProviderImpl()

 // With custom implementations
 let securityProvider = SecurityProviderImpl(
   cryptoService: customCryptoService,
   keyManager: customKeyManager
 )
 ```

 ## Documentation Notes

 The documentation for this module has been updated to reference CoreSecurityTypes and DomainSecurityTypes instead of SecurityCoreTypes and SecurityTypes. Additionally, British English spelling is used throughout the documentation.

 */

// Export Foundation types needed by this module
@_exported import Foundation

@_exported import CoreSecurityTypes
@_exported import DomainSecurityTypes

// Export public interfaces from this module
@_exported import SecurityCoreInterfaces

// Public exports
public typealias DefaultSecurityProvider=SecurityProviderImpl
