import Foundation
import UmbraErrorsCore
// Use the shared declarations instead of local ones
import Interfaces


/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors {
  /// Resource error domain
  public enum Resource {
    // This namespace contains the various resource error types
    // Implementation in separate files:
    // - ResourceCoreErrors.swift - Core resource errors
    // - ResourceFileErrors.swift - File system specific errors
    // - ResourcePoolErrors.swift - Resource pool management errors
  }
}
