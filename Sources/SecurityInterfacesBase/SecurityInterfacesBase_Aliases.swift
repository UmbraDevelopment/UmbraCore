/**
 # SecurityInterfacesBase Type Aliases
 
 This file provides temporary type aliases to support the migration from the legacy
 error handling system to the new standardised error handling architecture in the
 ErrorHandling directory.
 
 **Migration Notice:**
 These typealiases are being phased out as part of the broader initiative to remove
 indirection in the UmbraCore codebase. New code should use fully qualified types
 from the ErrorHandling modules directly.
 */

import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping

/// @deprecated Use UmbraErrors.Security.Core directly
@available(
  *,
  deprecated,
  message: "Use UmbraErrors.Security.Core directly instead of this typealias for improved type clarity"
)
public typealias SecurityProviderError = UmbraErrors.Security.Core
