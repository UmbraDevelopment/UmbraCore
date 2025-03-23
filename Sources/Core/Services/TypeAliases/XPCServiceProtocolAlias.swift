/**
 # XPC Service Protocol Aliases

 This file provides type aliases for XPC service protocols to allow for more convenient usage
 of these protocols throughout the codebase. It helps standardise naming across the application.

 Note: This is a transitional file to help with the migration from legacy error types to the
 new standardised error types in XPCProtocolsCore.
 */

import CoreErrors
import UmbraCoreTypes
import XPCProtocolsCore

// NOTE: This typealias has been deprecated in favour of using error types from the
// ErrorHandling module directly.
// It is kept temporarily for backward compatibility but will be removed in a future release.
// For new code, please use UmbraErrors.Security.Protocols instead.

// Security error type - using UmbraErrors namespace from ErrorHandling module
// We're using the standard protocols error type in the Security domain

/// Alias to the modern XPC service protocol from XPCProtocolsCore
public typealias XPCServiceProtocol=XPCServiceProtocolStandard

/// Alias to the basic XPC service protocol
public typealias XPCServiceProtocolBase=XPCServiceProtocolBasic

/// Alias to the complete XPC service protocol - directly imported from XPCProtocolsCore
// This protocol provides the most comprehensive set of operations
public typealias XPCServiceProtocolComplete=XPCServiceProtocolStandard

/// Legacy XPC service protocol (deprecated)
@available(
  *,
  deprecated,
  message: "Use XPCServiceProtocol instead which points to XPCServiceProtocolStandard"
)
public typealias LegacyXPCServiceProtocol=XPCServiceProtocol
