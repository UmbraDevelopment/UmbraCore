import Foundation
import UmbraErrorsCore

// Use the shared declarations instead of local ones
import Interfaces

/// Error domain namespace

/// Error context protocol

/// Base error context implementation

/// Application-specific errors extension
extension UmbraErrors {
  /// Application error domain
  public enum Application {
    // This namespace contains the various application error types
    // Implementation in separate files:
    // - ApplicationCoreErrors.swift - Core application errors
    // - ApplicationUIErrors.swift - User interface errors
    // - ApplicationLifecycleErrors.swift - Application lifecycle errors
  }
}
