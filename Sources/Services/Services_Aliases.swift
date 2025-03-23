/**
 # Services Type Aliases

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

// The following typealiases are provided for backward compatibility only
// and will be removed in a future update. New code should use the fully
// qualified types directly.

/// @deprecated Use UmbraErrors.Security.Core directly
@available(
  *,
  deprecated,
  message: "Use UmbraErrors.Security.Core directly for improved type clarity"
)
public typealias SecurityError=UmbraErrors.Security.Core

/// @deprecated Use UmbraErrors.Crypto.Core directly
@available(
  *,
  deprecated,
  message: "Use UmbraErrors.Crypto.Core directly for improved type clarity"
)
public typealias CryptoError=UmbraErrors.Crypto.Core

/// @deprecated Use UmbraErrors.Service.Core directly
@available(
  *,
  deprecated,
  message: "Use UmbraErrors.Service.Core directly for improved type clarity"
)
public typealias ServiceError=UmbraErrors.Service.Core
