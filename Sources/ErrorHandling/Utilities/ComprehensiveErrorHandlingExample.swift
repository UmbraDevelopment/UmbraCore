import Core
import Foundation
import Interfaces
import Protocols
import Recovery
import UmbraErrorsCore
import UmbraLogging

/// Comprehensive examples showing how to use the enhanced error handling system
/// with error recovery and notifications
public final class ComprehensiveErrorHandlingExample {
  /// Sets up the error handling system for an application
  public func setupErrorHandling() {
    // Log the setup process
    let logger=UmbraLogger.shared
    logger.info("Setting up error handling system...")

    // Setup error logger
    let errorLogger=ErrorLogger.shared
    ErrorHandler.shared.setLogger(errorLogger)

    // Setup notification handler
    let notificationManager=ErrorNotificationManager.shared
    ErrorHandler.shared.setNotificationHandler(notificationManager)

    // Register recovery providers
    let securityProvider=SecurityDomainProvider()
    let networkProvider=NetworkDomainProvider()
    let fileSystemProvider=FilesystemDomainProvider()

    // Register the providers with the recovery manager
    ErrorHandler.shared.registerRecoveryProvider(RecoveryManager.shared)
    RecoveryManager.shared.registerProvider(securityProvider)
    RecoveryManager.shared.registerProvider(networkProvider)
    RecoveryManager.shared.registerProvider(fileSystemProvider)

    logger.info("Error handling system setup completed")
  }

  /// Demonstrates how to handle errors with recovery options
  public func demonstrateErrorHandling() async {
    // Create various error types to demonstrate handling
    let errors: [Error]=[
      FileSystemError.fileNotFound(path: "/path/to/missing/file.txt"),
      SecurityError.authenticationFailed(reason: "Invalid credentials"),
      NetworkError.connectionTimeout(url: "https://api.example.com/data"),
      ApplicationError.invalidOperation(operation: "deleteAccount", reason: "Account is locked")
    ]

    // Handle each error
    for error in errors {
      if let umbraError=error as? UmbraError {
        await handleUmbraError(umbraError)
      } else {
        // For non-UmbraErrors, wrap them in a generic error
        let wrappedError=GenericUmbraError(
          domain: "ExampleDomain",
          code: "UNKNOWN",
          errorDescription: "An unknown error occurred: \(error.localizedDescription)",
          source: ErrorSource(file: #file, line: #line, function: #function)
        )
        await handleUmbraError(wrappedError)
      }
    }
  }

  /// Handle a UmbraError with appropriate severity and recovery
  /// - Parameter error: The error to handle
  private func handleUmbraError(_ error: UmbraError) async {
    // Select an appropriate severity based on the error type
    let severity=determineSeverity(for: error)

    // Log the error with the determined severity
    ErrorHandler.shared.handle(
      error,
      severity: severity,
      file: #file,
      function: #function,
      line: #line
    )

    // For severe errors, attempt recovery
    if severity >= .error {
      let recovered=await attemptAutomaticRecovery(from: error)
      if !recovered {
        // If automatic recovery failed, notify the user with recovery options
        await notifyUser(about: error)
      }
    }
  }

  /// Determine appropriate severity for an error
  /// - Parameter error: The error to evaluate
  /// - Returns: The appropriate severity level
  private func determineSeverity(for error: UmbraError) -> ErrorSeverity {
    // Determine severity based on error type and context
    switch error {
      case let securityError as SecurityError:
        // Security errors are typically high severity
        securityError.isCritical ? .critical : .error

      case let networkError as NetworkError:
        // Network errors might be temporary and recoverable
        networkError.isTimeout ? .warning : .error

      case let fileError as FileSystemError:
        // File errors severity depends on the specific issue
        if case .fileNotFound=fileError {
          .warning
        } else {
          .error
        }

      default:
        // Default to error severity for unknown error types
        .error
    }
  }

  /// Attempt to automatically recover from an error
  /// - Parameter error: The error to recover from
  /// - Returns: Whether recovery was successful
  private func attemptAutomaticRecovery(from error: Error) async -> Bool {
    print("Attempting automatic recovery...")

    // Simulated recovery logic
    switch error {
      case let networkError as NetworkError:
        // For network timeouts, try to reconnect
        if networkError.isTimeout {
          // Simulate a retry
          print("Retrying network connection...")
          return true
        }

      case let fileError as FileSystemError:
        // For missing files, we might create them if they're expected
        if case let .fileNotFound(path)=fileError {
          // Simulate creating the file
          print("Creating missing file at \(path)...")
          return true
        }

      case let securityError as SecurityError:
        // For authentication failures, we might prompt for credentials
        if case .authenticationFailed=securityError {
          // This would typically show a login dialog in a real app
          print("Displaying login dialog...")
          return false // Requires user interaction, not automatic
        }

      default:
        print("No automatic recovery available for this error type")
        return false
    }

    return false
  }

  /// Notify the user about an error with recovery options
  /// - Parameter error: The error to notify about
  private func notifyUser(about error: Error) async {
    // Get recovery options for this error
    let recoveryOptions=getRecoveryOptions(for: error)

    // In a real app, we would show a dialog or notification to the user
    // Here we'll just simulate it
    print("ERROR: \(error.localizedDescription)")
    print("Recovery options:")

    for (index, option) in recoveryOptions.enumerated() {
      print("[\(index + 1)] \(option.title)")
    }

    // Simulate user selecting the first option if available
    if let firstOption=recoveryOptions.first {
      print("User selected: \(firstOption.title)")
      await firstOption.perform()
    } else {
      print("No recovery options available")
    }
  }

  /// Get recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  private func getRecoveryOptions(for error: Error) -> [RecoveryOption] {
    // In a real implementation, this would come from the recovery providers
    // Here we'll provide some example options based on error type

    switch error {
      case is FileSystemError:
        createFileSystemRecoveryOptions(for: error as! FileSystemError)

      case is NetworkError:
        createNetworkRecoveryOptions(for: error as! NetworkError)

      case is SecurityError:
        createSecurityRecoveryOptions(for: error as! SecurityError)

      default:
        // Default recovery options for unknown error types
        [
          ErrorRecoveryOption(
            title: "Retry",
            description: "Try the operation again",
            action: {
              print("Retrying operation...")
            }
          ),
          ErrorRecoveryOption(
            title: "Cancel",
            description: "Cancel the operation",
            isDefault: true,
            action: {
              print("Operation cancelled")
            }
          )
        ]
    }
  }

  /// Create recovery options for file system errors
  private func createFileSystemRecoveryOptions(for error: FileSystemError) -> [RecoveryOption] {
    switch error {
      case .fileNotFound:
        [
          ErrorRecoveryOption(
            title: "Create File",
            description: "Create the missing file",
            action: {
              print("Creating file...")
            }
          ),
          ErrorRecoveryOption(
            title: "Choose Different File",
            description: "Select a different file",
            action: {
              print("Opening file selector...")
            }
          ),
          ErrorRecoveryOption(
            title: "Cancel",
            description: "Cancel the operation",
            isDefault: true,
            action: {
              print("Operation cancelled")
            }
          )
        ]
      default:
        []
    }
  }

  /// Create recovery options for network errors
  private func createNetworkRecoveryOptions(for _: NetworkError) -> [RecoveryOption] {
    // Network-specific recovery options
    []
  }

  /// Create recovery options for security errors
  private func createSecurityRecoveryOptions(for _: SecurityError) -> [RecoveryOption] {
    // Security-specific recovery options
    []
  }
}

// MARK: - Example Error Types

/// File system error examples
enum FileSystemError: UmbraError {
  case fileNotFound(path: String)
  case permissionDenied(path: String)
  case diskFull

  var domain: String { "FileSystem" }

  var code: String {
    switch self {
      case .fileNotFound: "FILE_NOT_FOUND"
      case .permissionDenied: "PERMISSION_DENIED"
      case .diskFull: "DISK_FULL"
    }
  }

  var errorDescription: String {
    switch self {
      case let .fileNotFound(path):
        "The file could not be found at: \(path)"
      case let .permissionDenied(path):
        "You don't have permission to access: \(path)"
      case .diskFull:
        "The disk is full"
    }
  }

  var source: ErrorSource?

  var underlyingError: Error?

  var context: ErrorContext {
    BaseErrorContext(domain: domain, code: 0, description: errorDescription)
  }

  func with(context _: ErrorContext) -> Self { self }

  func with(underlyingError _: Error) -> Self { self }

  func with(source _: ErrorSource) -> Self { self }

  var description: String { errorDescription }
}

/// Security error examples
enum SecurityError: UmbraError {
  case authenticationFailed(reason: String)
  case unauthorizedAccess(resource: String)
  case encryptionFailure

  var domain: String { "Security" }

  var isCritical: Bool {
    switch self {
      case .encryptionFailure: true
      default: false
    }
  }

  var code: String {
    switch self {
      case .authenticationFailed: "AUTH_FAILED"
      case .unauthorizedAccess: "UNAUTHORIZED"
      case .encryptionFailure: "ENCRYPTION_FAILED"
    }
  }

  var errorDescription: String {
    switch self {
      case let .authenticationFailed(reason):
        "Authentication failed: \(reason)"
      case let .unauthorizedAccess(resource):
        "Unauthorized access to resource: \(resource)"
      case .encryptionFailure:
        "Failed to encrypt sensitive data"
    }
  }

  var source: ErrorSource?

  var underlyingError: Error?

  var context: ErrorContext {
    BaseErrorContext(domain: domain, code: 0, description: errorDescription)
  }

  func with(context _: ErrorContext) -> Self { self }

  func with(underlyingError _: Error) -> Self { self }

  func with(source _: ErrorSource) -> Self { self }

  var description: String { errorDescription }
}

/// Network error examples
enum NetworkError: UmbraError {
  case connectionFailed(url: String)
  case connectionTimeout(url: String)
  case invalidResponse(statusCode: Int)

  var domain: String { "Network" }

  var isTimeout: Bool {
    switch self {
      case .connectionTimeout: true
      default: false
    }
  }

  var code: String {
    switch self {
      case .connectionFailed: "CONNECTION_FAILED"
      case .connectionTimeout: "TIMEOUT"
      case .invalidResponse: "INVALID_RESPONSE"
    }
  }

  var errorDescription: String {
    switch self {
      case let .connectionFailed(url):
        "Failed to connect to: \(url)"
      case let .connectionTimeout(url):
        "Connection timed out to: \(url)"
      case let .invalidResponse(statusCode):
        "Invalid response received (status code: \(statusCode))"
    }
  }

  var source: ErrorSource?

  var underlyingError: Error?

  var context: ErrorContext {
    BaseErrorContext(domain: domain, code: 0, description: errorDescription)
  }

  func with(context _: ErrorContext) -> Self { self }

  func with(underlyingError _: Error) -> Self { self }

  func with(source _: ErrorSource) -> Self { self }

  var description: String { errorDescription }
}

/// Application error examples
enum ApplicationError: UmbraError {
  case invalidOperation(operation: String, reason: String)
  case configurationError(setting: String)
  case resourceUnavailable(resource: String)

  var domain: String { "Application" }

  var code: String {
    switch self {
      case .invalidOperation: "INVALID_OPERATION"
      case .configurationError: "CONFIG_ERROR"
      case .resourceUnavailable: "RESOURCE_UNAVAILABLE"
    }
  }

  var errorDescription: String {
    switch self {
      case let .invalidOperation(operation, reason):
        "Invalid operation '\(operation)': \(reason)"
      case let .configurationError(setting):
        "Configuration error in setting: \(setting)"
      case let .resourceUnavailable(resource):
        "Required resource unavailable: \(resource)"
    }
  }

  var source: ErrorSource?

  var underlyingError: Error?

  var context: ErrorContext {
    BaseErrorContext(domain: domain, code: 0, description: errorDescription)
  }

  func with(context _: ErrorContext) -> Self { self }

  func with(underlyingError _: Error) -> Self { self }

  func with(source _: ErrorSource) -> Self { self }

  var description: String { errorDescription }
}

// MARK: - Helper Classes

/// Simulated error logger implementation
class ErrorLogger: ErrorLoggingService {
  static let shared=ErrorLogger()

  private init() {}

  func log(_ error: some UmbraError, withSeverity severity: ErrorSeverity) {
    print("[\(severity)] \(error.domain).\(error.code): \(error.errorDescription)")
  }
}

/// Simulated notification manager implementation
class ErrorNotificationManager: ErrorNotificationService {
  static let shared=ErrorNotificationManager()

  private init() {}

  @MainActor
  func notifyUser(
    about error: Error,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]
  ) async -> (option: RecoveryOption, status: RecoveryStatus)? {
    // In a real implementation, this would show a UI alert
    print("[NOTIFICATION \(level)] \(error.localizedDescription)")

    // Simulate user selecting the first recovery option if available
    if let firstOption=recoveryOptions.first {
      print("User selected recovery option: \(firstOption.title)")
      await firstOption.perform()
      return (firstOption, .success)
    }

    return nil
  }
}
