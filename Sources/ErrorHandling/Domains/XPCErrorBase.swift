import Foundation
import UmbraErrorsCore

// Use the shared declarations instead of local ones
import Interfaces

/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors {
  /// XPC communication error domain
  public enum XPC {
    // This namespace contains the various XPC error types
    // Implementation in separate files:
    // - XPCCoreErrors.swift - Core XPC communication errors
    // - XPCProtocolErrors.swift - XPC protocol-specific errors
  }
}
