/// Example class demonstrating the usage of the error handling system
///
/// This class provides sample implementations and usage patterns for:
/// - Setting up error notifications
/// - Registering recovery options
/// - Handling different error types
/// - Mapping errors between domains
public class ErrorHandlingExample {
  /// Sample notification handler for demonstration purposes
  private class SampleNotificationHandler: ErrorHandlingInterfaces.ErrorNotificationProtocol {
    /// Shows notifications in the console for demonstration
    public func presentError(
      _ error: some ErrorHandlingInterfaces.UmbraError,
      recoveryOptions: [ErrorHandlingInterfaces.RecoveryOption]
    ) {
      print("=== ERROR NOTIFICATION ===")
      print("Title: \(error.domain) Error")
      print("Message: \(error.errorDescription)")
      print("Severity: Critical")

      if !recoveryOptions.isEmpty {
        print("Recovery options:")
        for (index, option) in recoveryOptions.enumerated() {
          print("  \(index + 1). \(option.title)")
        }
      }

      print("=========================")
    }
  }

  /// Sample recovery provider for demonstration purposes
  private final class SampleRecoveryProvider: ErrorHandlingInterfaces.RecoveryOptionsProvider {
    /// Provides recovery options for security errors
    public func recoveryOptions(for error: some Error)
    -> [any ErrorHandlingInterfaces.RecoveryOption] {
      // Map to security error if possible
      if let securityError=error as? SecurityCoreErrorWrapper {
        // Provide different recovery options based on error type
        switch securityError.wrappedError {
          case .encryptionFailed, .decryptionFailed:
            return [
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Try Again",
                description: "Retry the cryptographic operation",
                handler: { @Sendable in
                  print("Retrying cryptographic operation...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption,
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Use Alternative Method",
                description: "Try a different cryptographic approach",
                handler: { @Sendable in
                  print("Using alternative cryptographic method...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption
            ]
          case .invalidKey:
            return [
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Regenerate Key",
                description: "Create a new security key",
                handler: { @Sendable in
                  print("Regenerating security key...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption,
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Import Existing Key",
                description: "Use a previously saved key",
                handler: { @Sendable in
                  print("Importing existing key...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption
            ]
          case .hashVerificationFailed:
            return [
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Download Again",
                description: "Retry the download to get a clean file",
                handler: { @Sendable in
                  print("Downloading file again...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption,
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Ignore Warning",
                description: "Continue despite integrity concerns",
                isDisruptive: true,
                handler: { @Sendable in
                  print("Ignoring integrity warning...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption
            ]
          default:
            return [
              ErrorHandlingInterfaces.ErrorRecoveryOption(
                title: "Retry Operation",
                description: "Try the operation again",
                handler: { @Sendable in
                  print("Retrying operation...")
                }
              ) as any ErrorHandlingInterfaces.RecoveryOption
            ]
        }
      }

      // Default recovery options for unknown errors
      return [
        ErrorHandlingInterfaces.ErrorRecoveryOption(
          title: "Retry",
          description: "Try the operation again",
          handler: { @Sendable in
            print("Retrying operation...")
          }
        ) as any ErrorHandlingInterfaces.RecoveryOption,
        ErrorHandlingInterfaces.ErrorRecoveryOption(
          title: "Cancel",
          description: "Cancel the current operation",
          handler: { @Sendable in
            print("Operation cancelled")
          }
        ) as any ErrorHandlingInterfaces.RecoveryOption
      ]
    }
  }

  /// Run a demonstration of the error handling system
  @MainActor
  public func run() {
    // Set up the error handler
    let errorHandler=ErrorHandler.shared
    errorHandler.setNotificationHandler(SampleNotificationHandler())
    errorHandler.registerRecoveryProvider(SampleRecoveryProvider())

    print("Starting error handling demonstration...")

    // Create a security error for demonstration
    let securityError=UmbraErrors.GeneralSecurity.Core.invalidKey(reason: "Missing encryption key")

    // Manually create a wrapped error
    let wrappedError=SecurityCoreErrorWrapper(securityError)

    // Report the error
    Task {
      // Remove unnecessary await since the method is not actually performing async operations
      errorHandler.handle(wrappedError)
      print("Security error handled.")

      // Demonstrate error mapping
      demonstrateErrorMapping()
    }
  }

  private func demonstrateErrorMapping() {
    print("\nDemonstrating error mapping...")

    // Create a mock external error
    struct ExternalError: Error, CustomStringConvertible {
      let message: String
      var description: String { message }
    }

    let externalError=ExternalError(message: "External API connection failed")

    // Try to map to security error
    let securityMapper=SecurityErrorMapper()

    // Map external error to core error
    if let mappedError=securityMapper.mapToCoreError(externalError) {
      print("Successfully mapped to security error: \(mappedError)")
    } else {
      // Handle unmapped errors with an application error
      let coreAppError=UmbraErrors.Application.Core.externalServiceError(
        "External API authentication required"
      )
      let wrappedAppError=ApplicationCoreErrorWrapper(coreAppError)
      print("Mapped to application error: \(wrappedAppError.errorDescription)")
    }
  }

  /// Demonstrate direct usage of error mapping and handling
  public func demonstrateDirectUsage() {
    // Create a sample security error
    let coreError=UmbraErrors.GeneralSecurity.Core.invalidKey(reason: "Key has expired")

    // Wrap the error in our conforming wrapper
    let securityError=SecurityCoreErrorWrapper(coreError)

    // Handle the wrapped error
    print("\nDemonstrating direct error handling...")
    print("Error domain: \(securityError.domain)")
    print("Error code: \(securityError.code)")
    print("Error description: \(securityError.errorDescription)")
    print("Recovery suggestion: \(securityError.recoverySuggestion ?? "None available")")

    // Add context to the error
    let contextualError=securityError.with(
      context: ErrorHandlingInterfaces.ErrorContext(
        source: "KeyManager",
        operation: "validateKey",
        details: "Failed to validate key during authentication"
      )
    )

    print("\nContextual error information:")
    print("Source: \(contextualError.context.source)")
    print("Operation: \(contextualError.context.operation)")
    print("Details: \(contextualError.context.details ?? "None")")
  }
}

// MARK: - Extensions for Demo

extension ErrorHandlingExample {
  /// Create an example notification for demonstration
  private func createDemoNotification() -> ErrorHandlingNotification.ErrorNotification {
    let securityError=SecurityCoreErrorWrapper(
      UmbraErrors.GeneralSecurity.Core.invalidKey(reason: "Expired key")
    )

    return ErrorHandlingNotification.ErrorNotification(
      error: securityError,
      title: "Security Alert",
      message: "Security key has expired",
      recoveryOptions: []
    )
  }
}
