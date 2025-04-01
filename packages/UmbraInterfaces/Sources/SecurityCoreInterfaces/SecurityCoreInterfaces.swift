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

import CoreSecurityTypes
import DomainSecurityTypes
import UmbraErrors

/// Main module for security interfaces
/// This module contains all the core security interfaces used throughout the system
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL

// Exports all core security interfaces
@_exported import struct CoreSecurityTypes.SecurityConfigDTO
@_exported import enum CoreSecurityTypes.SecurityOperation
@_exported import struct CoreSecurityTypes.SecurityResultDTO
@_exported import enum DomainSecurityTypes.SecurityProtocolError
