/**
 # SecurityCoreInterfaces Module
 
 This module provides core security interface protocols for the UmbraCore security framework.
 It defines the contracts that security implementations must follow, with particular focus on
 type safety and foundation-independence.
 
 ## Protocols
 
 - CryptoServiceProtocol: Interface for cryptographic operations
 - KeyManagementProtocol: Interface for secure key management 
 - SecureStorageProtocol: Interface for secure data storage
 - SecurityProviderProtocol: Top-level interface for comprehensive security operations
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies
@_exported import SecurityTypes
@_exported import SecurityCoreTypes
@_exported import UmbraErrors
