import Foundation
import Interfaces
import UmbraErrorsCore

// This file provides protocol conformance extensions to ensure
// that error types properly conform to UmbraError from the Interfaces module

// MARK: - Typealias for ErrorSource compatibility

/// Type bridge between UmbraErrorsCore.ErrorSource and Interfaces.ErrorSource
public typealias InterfacesErrorSource = UmbraErrorsCore.ErrorSource

// MARK: - UmbraErrors.Network.Core Extensions

extension UmbraErrors.Network.Core: Interfaces.UmbraError {
  // All required properties and methods are implemented directly on the type
}

// MARK: - UmbraErrors.Security.Core Extensions

extension UmbraErrors.Security.Core: Interfaces.UmbraError {
  // All required properties and methods are implemented directly on the type
}

// MARK: - UmbraErrors.Resource.Core Extensions

extension UmbraErrors.Resource.Core: Interfaces.UmbraError {
  // All required properties and methods are implemented directly on the type
}

// MARK: - UmbraErrors.Repository.Core Extensions

extension UmbraErrors.Repository.Core: Interfaces.UmbraError {
  // Source conversion
  public var source: Interfaces.ErrorSource? {
    if let coreSource = self.umbraErrorsCoreSource {
      return convertToInterfacesSource(coreSource)
    }
    return nil
  }
  
  // Original source accessor to avoid naming conflicts
  private var umbraErrorsCoreSource: UmbraErrorsCore.ErrorSource? {
    nil // Source is typically set when the error is created with context
  }
  
  // Context conversion
  public var context: Interfaces.ErrorContext {
    Interfaces.ErrorContext(
      source: domain,
      operation: "repository_operation",
      details: errorDescription,
      file: "",
      line: 0,
      function: ""
    )
  }
  
  // Source setter
  public func with(source: Interfaces.ErrorSource) -> Self {
    // Convert to the UmbraErrorsCore.ErrorSource type and pass to the original implementation
    let coreSource = convertToUmbraErrorsCoreSource(source) ?? UmbraErrorsCore.ErrorSource()
    return self.with(umbraErrorsCoreSource: coreSource)
  }
  
  // Original implementation that works with UmbraErrorsCore.ErrorSource
  private func with(umbraErrorsCoreSource: UmbraErrorsCore.ErrorSource) -> Self {
    // Since these are enum cases, we need to return a new instance with the same value
    return self
  }
  
  // Context setter
  public func with(context: Interfaces.ErrorContext) -> Self {
    // Since these are enum cases, we need to return a new instance with the same value
    return self
  }
}
