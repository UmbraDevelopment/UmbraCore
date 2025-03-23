import CoreErrors // Keep for backward compatibility
import ErrorHandlingDomains

/// Type alias for backward compatibility
/// Uses the new ErrorHandling system's domain-specific errors
public typealias RepositoryError = ErrorHandlingDomains.RepositoryError

/// Legacy type alias for code that hasn't been migrated yet
@available(*, deprecated, message: "Use ErrorHandlingDomains.RepositoryError instead")
public typealias LegacyRepositoryError = CoreErrors.RepositoryError
