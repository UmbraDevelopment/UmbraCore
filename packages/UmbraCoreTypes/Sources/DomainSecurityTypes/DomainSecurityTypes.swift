/**
 # DomainSecurityTypes Module

 This module provides domain-specific security types, protocols, and extensions for the UmbraCore security framework.
 It builds upon the foundational types in CoreSecurityTypes to offer specialised security functionality
 for specific application domains.

 ## Components

 - Security provider protocols and implementations
 - Secure storage abstractions
 - Domain-specific security error extensions
 - Specialised cryptographic types

 All types in this module conform to `Sendable` to support safe usage across actor boundaries.
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Explicitly export the types we need from Foundation
@_exported import struct Foundation.Data
@_exported import struct Foundation.Date
@_exported import struct Foundation.URL

// Export dependencies
@_exported import CoreSecurityTypes
