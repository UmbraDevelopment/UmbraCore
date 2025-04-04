/**
 # SecurityProviders Module

 This module contains implementations of the security provider interfaces defined in the
 SecurityCoreInterfaces module. It provides concrete implementations of cryptographic
 services, key management, and other security-related functionality.

 ## Components

 - SecurityProviderCore: The central implementation of security provider functionality
 - OperationsHandler: Routes security operations to appropriate handlers
 - ConfigBuilder: Creates and validates security configurations
 - Utilities: Utility functions for data conversion and formatting

 ## Usage

 Security provider implementations should be instantiated directly or through dependency injection.
 Since security operations are typically asynchronous, all method calls must be awaited:

 ```swift
 // With appropriate implementations
 let securityProvider = YourSecurityProviderImplementation(
   cryptoService: cryptoService,
   keyManager: keyManager
 )

 // Calling methods requires await
 let result = try await securityProvider.encrypt(config: config)
 ```

 ## Actor-Based Concurrency

 Security provider implementations use Swift's actor model to ensure thread safety and
 proper isolation of mutable state. This follows the Alpha Dot Five architecture
 principles for safe concurrency.

 ## Documentation Notes

 The documentation for this module has been updated to reference CoreSecurityTypes and DomainSecurityTypes instead of SecurityCoreTypes and SecurityTypes. Additionally, British English spelling is used throughout the documentation.

 */

// Export Foundation types needed by this module
@_exported import Foundation

@_exported import CoreSecurityTypes
@_exported import DomainSecurityTypes

// Export public interfaces from this module
@_exported import SecurityCoreInterfaces

// Note: This module provides underlying implementations for security providers.
// Specific implementations should be created directly rather than using typealiases.
