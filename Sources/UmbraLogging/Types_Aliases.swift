import CoreErrors
import ErrorHandlingDomains

/// Type alias for backward compatibility
/// @deprecated Use CoreErrors.ResourceError directly instead.
@available(*, deprecated, message: "Use CoreErrors.ResourceError directly instead")
public typealias ResourceError=CoreErrors.ResourceError

/// Type alias for backward compatibility
/// @deprecated Use CoreErrors.RepositoryError directly instead.
@available(*, deprecated, message: "Use CoreErrors.RepositoryError directly instead")
public typealias RepositoryError=CoreErrors.RepositoryError

/// Type alias for backward compatibility
/// @deprecated Use CoreErrors.SecurityError directly instead.
@available(*, deprecated, message: "Use CoreErrors.SecurityError directly instead")
public typealias SecurityError=CoreErrors.SecurityError

/// Type alias for backward compatibility
/// @deprecated Use CoreErrors.CryptoError directly instead.
@available(*, deprecated, message: "Use CoreErrors.CryptoError directly instead")
public typealias CryptoError=CoreErrors.CryptoError
