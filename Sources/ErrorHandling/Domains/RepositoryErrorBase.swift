import Foundation
import UmbraErrorsCore

// Use the shared declarations instead of local ones
import Interfaces

/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors {
  /// Repository error domain
  public enum Repository {
    // This namespace contains the various repository error types
    // Implementation in separate files:
    // - RepositoryCoreErrors.swift - Core repository errors
    // - RepositoryStorageErrors.swift - Storage-specific errors
    // - RepositoryQueryErrors.swift - Query-related errors
  }
}
