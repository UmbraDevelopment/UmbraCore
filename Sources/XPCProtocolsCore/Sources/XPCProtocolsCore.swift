// DEPRECATED: XPCProtocolsCore
// This entire file was deprecated and has been removed.
// Use ModernXPCService or other modern XPC components instead.

/**
 # XPCProtocolsCore

 ## Overview
 This module provides core XPC protocol definitions and error handling for UmbraCore.
 Instead of using deprecated typealiases, always use fully qualified references to types.

 ## Key Components
 - Modern XPC Service implementation in ModernXPCService
 - Protocol definitions for XPC communication
 - Security error handling with CoreErrors.XPCErrors.SecurityError

 ## Proper Usage
 Always use fully qualified type references:
 ```swift
 func handleError(_ error: CoreErrors.XPCErrors.SecurityError) {
     // Handle the error
 }
 ```
 */

@_exported import CoreErrors
@_exported import UmbraCoreTypes
