import CoreErrors
import ErrorHandlingDomains

/// Type alias to support legacy code that uses BinaryData
/// @deprecated Use SecureData directly instead.
@available(*, deprecated, message: "Use SecureData directly instead")
public typealias BinaryData=SecureData

/// Module initialisation function
/// Call this to ensure all components are properly registered
public func initialiseModule() {
  CoreTypesExtensions.registerModule()
}

/// Legacy type for compatibility with older code
/// @deprecated Use CoreSecurityError directly instead.
@available(*, deprecated, message: "Use CoreSecurityError directly instead")
public typealias SecurityErrorBase=CoreSecurityError
