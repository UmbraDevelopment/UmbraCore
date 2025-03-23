/**
 # XPC Service Protocol Aliases

 This file provides type aliases for XPC service protocols to allow for more convenient usage
 of these protocols throughout the codebase. It helps standardise naming across the application.

 **Migration Notice:**
 This is a transitional file to help with the migration away from typealiases to direct usage
 of fully qualified types as defined in the UmbraCore type policy. Most of these typealiases
 will be removed in the future once the codebase has been updated to use the original types.

 ## Preferred Usage
 New code should avoid these typealiases and instead reference the original types directly
 from the XPCProtocolsCore module. This reduces indirection and improves code clarity.
 */

import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping
import UmbraCoreTypes
import XPCProtocolsCore

// MARK: - Protocol Aliases

/// Alias to the modern XPC service protocol from XPCProtocolsCore
/// **Deprecation Notice:** This typealias will be removed in a future release.
/// New code should use XPCServiceProtocolStandard directly from XPCProtocolsCore module.
@available(
  *,
  deprecated,
  message: "Use XPCServiceProtocolStandard directly from XPCProtocolsCore instead of this typealias"
)
public typealias XPCServiceProtocol=XPCServiceProtocolStandard

/// Alias to the basic XPC service protocol
/// **Deprecation Notice:** This typealias will be removed in a future release.
/// New code should use XPCServiceProtocolBasic directly from XPCProtocolsCore module.
@available(
  *,
  deprecated,
  message: "Use XPCServiceProtocolBasic directly from XPCProtocolsCore instead of this typealias"
)
public typealias XPCServiceProtocolBase=XPCServiceProtocolBasic

/// Alias to the complete XPC service protocol - directly imported from XPCProtocolsCore
/// This protocol provides the most comprehensive set of operations.
/// **Deprecation Notice:** This typealias will be removed in a future release.
/// New code should use XPCServiceProtocolStandard directly from XPCProtocolsCore module.
@available(
  *,
  deprecated,
  message: "Use XPCServiceProtocolStandard directly from XPCProtocolsCore instead of this typealias"
)
public typealias XPCServiceProtocolComplete=XPCServiceProtocolStandard

/// Legacy XPC service protocol (deprecated)
@available(
  *,
  deprecated,
  message: "Use XPCServiceProtocolStandard directly from XPCProtocolsCore instead of this typealias"
)
public typealias LegacyXPCServiceProtocol=XPCServiceProtocol
