import AppKit
import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

#if os(macOS)
#endif

/// A macOS implementation of the ErrorNotificationService
@MainActor
public final class MacErrorNotificationService: ErrorNotificationService {
  /// Supported error domains for this service
  public let supportedErrorDomains: [String]

  /// Notification levels supported by this service
  public let supportedLevels: [ErrorNotificationLevel]

  /// Initialises with specific error domains and levels
  /// - Parameters:
  ///   - supportedDomains: Domains this service can handle (or nil for all)
  ///   - supportedLevels: Levels this service can handle
  public init(
    supportedDomains: [String]?=nil,
    supportedLevels: [ErrorNotificationLevel]=[.warning, .error, .critical]
  ) {
    supportedErrorDomains=supportedDomains ?? []
    self.supportedLevels=supportedLevels
  }

  /// Creates a notification service that handles all domains
  /// - Returns: A notification service for all error domains
  public static func forAllDomains() -> MacErrorNotificationService {
    MacErrorNotificationService(supportedDomains: nil)
  }

  /// Notifies the user about an error using macOS alerts
  /// - Parameters:
  ///   - error: The error to notify about
  ///   - level: The notification level
  ///   - recoveryOptions: Recovery options to present
  /// - Returns: The chosen recovery option ID, if any
  public func notifyUser(
    about error: some Error,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]
  ) async -> UUID? {
    // Skip if this service doesn't support the error domain or level
    if !canHandle(error) || !supportedLevels.contains(level) {
      return nil
    }

    #if os(macOS)
      // Get error information
      let domain=getDomain(for: error)
      let title=getTitle(for: error, domain: domain)
      let message=getMessage(for: error)

      // Setup alert with error information
      let alert=NSAlert()
      alert.messageText=title
      alert.informativeText=message

      // Configure alert style based on level
      switch level {
        case .debug, .info:
        alert.alertStyle = .informational
        case .warning:
        alert.alertStyle = .warning
        case .error, .critical:
        alert.alertStyle = .critical
        @unknown default:
        alert.alertStyle = .critical
      }

      // Add recovery options to alert
      for option in recoveryOptions {
        let buttonTitle=option.title
        alert.addButton(withTitle: buttonTitle)
      }

      // Show alert and get user response
      let response=alert.runModal()

      // Determine which button was clicked (first button is NSAlertFirstButtonReturn)
      let buttonIndex=Int(response.rawValue) - NSApplication.ModalResponse.alertFirstButtonReturn
        .rawValue

      // Return ID of selected recovery option if valid
      if buttonIndex >= 0, buttonIndex < recoveryOptions.count {
        return recoveryOptions[buttonIndex].id
      }

      return nil
    #else
      // Not supported on non-macOS platforms
      return nil
    #endif
  }

  /// Whether this service can handle a particular error
  /// - Parameter error: The error to check
  /// - Returns: Whether this service can handle the error
  public func canHandle(_ error: some Error) -> Bool {
    // If no specific domains are defined, handle all
    if supportedErrorDomains.isEmpty {
      return true
    }

    // Check if error domain is supported
    let domain=getDomain(for: error)
    return supportedErrorDomains.contains(domain)
  }

  #if os(macOS)
    /// Configures an alert for an error
    /// - Parameters:
    ///   - alert: The alert to configure
    ///   - error: The error to display
    ///   - level: The notification level
    private func configureAlert(_ alert: NSAlert, for error: Error, level: ErrorNotificationLevel) {
      let domain=getDomain(for: error)
      alert.messageText=getTitle(for: error, domain: domain)
      alert.informativeText=getMessage(for: error)

      // Configure alert style based on level
      switch level {
        case .debug, .info:
          alert.alertStyle = .informational
        case .warning:
          alert.alertStyle = .warning
        case .error, .critical:
          alert.alertStyle = .critical
        @unknown default:
          alert.alertStyle = .critical
      }
    }
  #endif

  /// Gets the domain for an error
  /// - Parameter error: The error to get the domain for
  /// - Returns: The error domain
  private func getDomain(for error: Error) -> String {
    if let umbraError=error as? UmbraError {
      return umbraError.domain
    } else {
      // Access NSError properties directly through the bridged Error
      let nsError=error as NSError
      return nsError.domain
    }
  }

  /// Gets a title for an error
  /// - Parameters:
  ///   - error: The error
  ///   - domain: The error domain
  /// - Returns: A user-friendly title
  private func getTitle(for error: Error, domain: String) -> String {
    if let umbraError=error as? UmbraError {
      "Error in \(domain): \(umbraError.code)"
    } else {
      "Error in \(domain)"
    }
  }

  /// Gets a message for an error
  /// - Parameter error: The error
  /// - Returns: A user-friendly message
  private func getMessage(for error: Error) -> String {
    if let umbraError=error as? UmbraError {
      umbraError.errorDescription
    } else {
      error.localizedDescription
    }
  }
}
