/**
 # SecurityUtils Module

 This module provides utility functions for security operations within the UmbraCore
 security framework. It contains helper functions for data conversion, validation,
 and other security-related utilities.

 ## Components

 - SecurityUtilsImpl: Implementation of security utility functions
   - Secure string handling
   - Data conversion (hex, base64)
   - Security validation
   - Random data generation
   - Secure comparison

 ## Usage

 The SecurityUtilsImpl can be instantiated directly:

 ```swift
 let securityUtils = SecurityUtilsImpl()

 // Convert hex string to bytes
 if let bytes = securityUtils.hexStringToBytes("DEADBEEF") {
   // Use secure bytes...
 }

 // Generate random string
 let randomToken = securityUtils.generateRandomString(length: 32)
 ```
 */

// Export Foundation types needed by this module
@_exported import Foundation

// Export dependencies
@_exported import SecurityCoreTypes
@_exported import SecurityTypes
@_exported import UmbraErrors

// Public exports
public typealias DefaultSecurityUtils=SecurityUtilsImpl
