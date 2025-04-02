/**
 # SecurityCore Module

 This module provides essential security utilities and implementations that form the
 foundation of the UmbraCore security architecture. It contains core components that
 don't require actor isolation but are fundamental to security operations.

 Following the Alpha Dot Five architecture principles, this module serves as a home
 for critical security utilities that can be used across the security subsystem without
 introducing unnecessary dependencies.

 ## Components

 - **MemoryProtection**: Essential utilities for secure memory management
   - Secure zeroing of sensitive data
   - Temporary secure memory allocation
   - Secure random generation

 - **SecurityUtilities**: Core utilities for security operations
   - Data conversion (hex, base64)
   - Secure string handling
   - Constant-time comparisons

 ## Usage

 ```swift
 // Securely handle sensitive data
 var sensitiveData: [UInt8] = retrieveSensitiveData()
 defer {
     MemoryProtection.secureZero(&sensitiveData)
 }
 
 // Use with automatic cleanup
 let result = MemoryProtection.withSecureTemporaryData(initialValue) { buffer in
     // Process sensitive data
     return processData(buffer)
 }
 ```
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies
@_exported import CoreSecurityTypes
@_exported import DomainSecurityTypes
@_exported import UmbraErrors

// Public exports
public typealias DefaultSecurityUtils = SecurityUtilities
