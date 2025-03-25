

import ErrorHandlingModels
import ErrorHandlingNotification
import ErrorHandlingProtocols
import ErrorHandlingRecovery
import Foundation
import UmbraErrors
import UmbraErrorsCore
import UmbraLogging

// Removed UmbraLoggingAdapters import to fix library evolution issues

/// Examples of how to use the enhanced error handling system
public final class ErrorHandlingExamples {
  /// Example of creating and handling a security error
  public func securityErrorExample() {
    do {
      try authenticateUser(username: "user", password: "pass")
    } catch let error as UmbraErrors.GeneralSecurity.Core {
      // Handle security error with rich context
      handleSecurityError(error)
    } catch {
      // Handle other errors
      print("Unexpected error: \(error.localizedDescription)")
    }
  }

  /// Example of mapping between error types
  @MainActor
  public func errorMappingExample() {
    // Get an instance of GeneralSecurity.Core error
    _=authenticationFailedError("Invalid credentials")

    // Map to different error type using the mapper
    // Since we don't have mapCoreToXPC, we'll create the XPC error directly
    let xpcError=UmbraErrors.GeneralSecurity.XPC.connectionFailed(reason: "Mapped from core error")
    print("Created XPC error: \(xpcError)")

    // Create a network error
    let networkError=UmbraErrors.Network.Core.connectionFailed(reason: "Connection timeout")

    // Log the network error
    print("Network error: \(networkError)")
  }

  /// Example of adding context to errors
  public func contextEnrichmentExample() {
    do {
      try performOperation()
    } catch {
      // With the new error system, we'd handle context differently
      // This is a simplified example
      print("Operation failed: \(error)")

      if let securityError=error as? UmbraErrors.GeneralSecurity.Core {
        // Handle specific security error
        print("Security error: \(securityError)")
      }
    }
  }

  /// Example of wrapping errors
  public func errorWrappingExample() {
    do {
      try performNetworkOperation()
    } catch {
      // With the new error system, we'd wrap errors differently
      // This is a simplified example
      let networkError=error as? UmbraErrors.Network.Core ??
        UmbraErrors.Network.Core
        .connectionFailed(reason: "Unknown error: \(error.localizedDescription)")

      print("Network error: \(networkError)")
    }
  }

  /// Example of using logging with errors
  public func loggingExample() {
    // Create errors with different severity levels
    let debugError=UmbraErrors.GeneralSecurity.Core.internalError("This is a debug-level issue")

    let infoError=UmbraErrors.Network.Core
      .connectionFailed(reason: "Connection temporarily unavailable")

    let warningError=UmbraErrors.GeneralSecurity.Core
      .invalidInput(reason: "Permissions will expire soon")

    // Create a map for details
    let _: [String: String]=[
      "expectedHash": "a1b2c3d4e5f6",
      "actualHash": "a1b2c3d4e5f7",
      "userID": "user123",
      "documentID": "doc456"
    ]

    // Use hashVerificationFailed which is appropriate for integrity violations
    let criticalError=UmbraErrors.GeneralSecurity.Core
      .hashVerificationFailed(reason: "Data integrity violation detected")

    // Simple logging (no adapters)
    print("Debug: \(debugError)")
    print("Info: \(infoError)")
    print("Warning: \(warningError)")
    print("Critical: \(criticalError)")
  }

  // MARK: - Private Methods

  private func authenticateUser(username: String, password _: String) throws {
    // Simulated authentication failure
    throw authenticationFailedError("Invalid credentials for user \(username)")
  }

  private func performOperation() throws {
    // Simulated operation failure
    throw UmbraErrors.GeneralSecurity.Core.internalError("Failed to encrypt data")
  }

  private func performNetworkOperation() throws {
    // Simulated network error
    throw UmbraErrors.Network.Core.connectionFailed(reason: "Connection timeout")
  }

  private func handleSecurityError(_ error: UmbraErrors.GeneralSecurity.Core) {
    print("Security system encountered an error: \(error)")

    // Handle different types of security errors
    switch error {
      case let .encryptionFailed(reason):
        print("Encryption failed: \(reason)")

      case let .decryptionFailed(reason):
        print("Decryption failed: \(reason)")

      case let .keyGenerationFailed(reason):
        print("Key generation failed: \(reason)")

      case let .invalidKey(reason):
        print("Invalid key: \(reason)")

      case let .hashVerificationFailed(reason):
        print("Hash verification failed: \(reason)")

      case let .invalidInput(reason):
        print("Invalid input: \(reason)")

      case let .internalError(reason):
        print("Internal security error: \(reason)")

      case let .randomGenerationFailed(reason):
        print("Random generation failed: \(reason)")

      case let .storageOperationFailed(reason):
        print("Storage operation failed: \(reason)")

      case let .timeout(operation):
        print("Operation timed out: \(operation)")

      case let .serviceError(code, reason):
        print("Service error \(code): \(reason)")

      case let .notImplemented(feature):
        print("Not implemented: \(feature)")

      @unknown default:
        print("Unknown security error: \(error)")
    }
  }

  /// Creates an authentication failed error with the given reason
  private func authenticationFailedError(_ reason: String) -> UmbraErrors.GeneralSecurity.Core {
    // Using a valid error from the Core enum since authentication isn't directly in Core
    UmbraErrors.GeneralSecurity.Core.invalidInput(reason: "Authentication failed: \(reason)")
  }
}
