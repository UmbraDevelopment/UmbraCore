import Foundation
import Interfaces
import UmbraErrorsCore

// MARK: - Error Type Translations

/// Translation layer between UmbraErrorsCore and Interfaces error types
/// Provides explicit type conversions to help Swift's type checker

// MARK: - ErrorSource Translations

/// Convert a UmbraErrorsCore.ErrorSource to Interfaces.ErrorSource
public func convertCoreToInterfaces(_ source: UmbraErrorsCore.ErrorSource?) -> Interfaces
.ErrorSource? {
  // In this case, they're actually the same type at runtime but the compiler doesn't know that
  // This function exists just to help the compiler with type checking
  source as? Interfaces.ErrorSource
}

/// Convert a Interfaces.ErrorSource to UmbraErrorsCore.ErrorSource
public func convertInterfacesToCore(_ source: Interfaces.ErrorSource?) -> UmbraErrorsCore
.ErrorSource? {
  // In this case, they're actually the same type at runtime but the compiler doesn't know that
  // This function exists just to help the compiler with type checking
  source as? UmbraErrorsCore.ErrorSource
}

// MARK: - Extension Helpers

// The following extensions provide explicit implementations of methods needed
// to satisfy the Interfaces.UmbraError protocol without creating circular dependencies

extension UmbraErrors.Network.Core {
  // Make an explicit implementation of the source getter that satisfies Interfaces.UmbraError
  public var interfacesSource: Interfaces.ErrorSource? {
    convertCoreToInterfaces(source)
  }

  // Make an explicit implementation of with(source:) that satisfies Interfaces.UmbraError
  public func interfacesWith(source: Interfaces.ErrorSource) -> Self {
    with(source: convertInterfacesToCore(source) ?? UmbraErrorsCore.ErrorSource())
  }
}

extension UmbraErrors.Security.Core {
  // Make an explicit implementation of the source getter that satisfies Interfaces.UmbraError
  public var interfacesSource: Interfaces.ErrorSource? {
    convertCoreToInterfaces(source)
  }

  // Make an explicit implementation of with(source:) that satisfies Interfaces.UmbraError
  public func interfacesWith(source: Interfaces.ErrorSource) -> Self {
    with(source: convertInterfacesToCore(source) ?? UmbraErrorsCore.ErrorSource())
  }
}

extension UmbraErrors.Repository.Core {
  // Make an explicit implementation of the source getter that satisfies Interfaces.UmbraError
  public var interfacesSource: Interfaces.ErrorSource? {
    convertCoreToInterfaces(source)
  }

  // Make an explicit implementation of with(source:) that satisfies Interfaces.UmbraError
  public func interfacesWith(source: Interfaces.ErrorSource) -> Self {
    with(source: convertInterfacesToCore(source) ?? UmbraErrorsCore.ErrorSource())
  }
}

// Note: Resource.Core extensions are temporarily commented out
// because the module structure is being refactored to resolve dependencies
/*
 extension UmbraErrors.Resource.Core {
     // Make an explicit implementation of the source getter that satisfies Interfaces.UmbraError
     public var interfacesSource: Interfaces.ErrorSource? {
         return convertCoreToInterfaces(self.source)
     }

     // Make an explicit implementation of with(source:) that satisfies Interfaces.UmbraError
     public func interfacesWith(source: Interfaces.ErrorSource) -> Self {
         return self.with(source: convertInterfacesToCore(source) ?? UmbraErrorsCore.ErrorSource())
     }
 }
 */
