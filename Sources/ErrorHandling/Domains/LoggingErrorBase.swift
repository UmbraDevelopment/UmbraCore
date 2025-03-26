import Foundation
import UmbraErrorsCore
// Use the shared declarations instead of local ones
import Interfaces


/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors {
  /// Logging error domain
  public enum Logging {
    // This namespace contains the various logging error types
    // Implementation in separate files:
    // - LoggingCoreErrors.swift - Core logging errors
    // - LoggingConfigErrors.swift - Configuration specific errors
  }
}
