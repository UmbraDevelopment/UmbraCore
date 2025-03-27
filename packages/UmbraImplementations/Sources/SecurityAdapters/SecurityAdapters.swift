/**
 # SecurityAdapters Module
 
 This module provides adapter implementations for integrating the UmbraCore security
 framework with various platforms and frameworks. These adapters translate between
 UmbraCore's security interfaces and external systems, allowing for seamless integration.
 
 ## Components
 
 - FoundationCryptoAdapter: Adapts UmbraCore security to Foundation's cryptographic patterns
 - AnyCryptoServiceAdapter: Type-erasing adapter for CryptoServiceProtocol
 
 ## Usage
 
 The adapters can be used to bridge between UmbraCore security and external systems:
 
 ```swift
 // Foundation integration
 let foundationAdapter = FoundationCryptoAdapter()
 
 // Use UmbraCore security with Foundation types
 let encrypted = try await foundationAdapter.encrypt(data: myData, using: myKey)
 
 // Type erasure
 let cryptoService: CryptoServiceProtocol = AnyCryptoServiceAdapter(wrapped: concreteCryptoService)
 ```
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies
@_exported import SecurityCoreInterfaces
@_exported import SecurityCoreTypes
@_exported import SecurityProviders
@_exported import SecurityTypes
@_exported import UmbraErrors
