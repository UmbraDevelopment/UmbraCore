/**
 # SecurityCryptoServices Module

 This module provides cryptographic service implementations for the UmbraCore security framework.
 It implements the cryptographic interfaces defined in SecurityCoreInterfaces with concrete
 implementations using Foundation's cryptographic libraries.

 ## Components

 - CryptoServiceImpl: Main implementation of the CryptoServiceProtocol
 - Supporting services:
   - SymmetricCryptoService: Handles symmetric encryption/decryption
   - HashingService: Handles cryptographic hashing operations

 ## Usage

 The CryptoServiceImpl can be instantiated directly or through dependency injection:

 ```swift
 // Using default implementations
 let cryptoService = CryptoServiceImpl()

 // Usage via SecurityProviderProtocol
 let securityProvider = SecurityProviderImpl(
   cryptoService: CryptoServiceImpl(),
   keyManager: /* key manager implementation */
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
public typealias DefaultCryptoService=CryptoServiceImpl
