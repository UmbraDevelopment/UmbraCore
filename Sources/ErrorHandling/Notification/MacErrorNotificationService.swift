import AppKit
import Foundation

/// Extension to Error protocol to provide domain and code information
extension Error {
  /// Get the domain of the error
  var errorDomain: String? {
    // First try to access as NSError
    let nsError = self as NSError
    return nsError.domain
  }
  
  /// Get the code of the error
  var errorCode: String? {
    // First try to access as NSError
    let nsError = self as NSError
    return String(nsError.code)
  }
}

/// A macOS implementation of the ErrorNotificationService
@MainActor
public final class MacErrorNotificationService: ErrorNotificationService {
  /// Supported error domains for this service
  public let supportedErrorDomains: [String]
  
  /// Supported notification levels
  public let supportedLevels: [ErrorNotificationLevel] = [
    .critical, .error, .warning, .info
  ]

  /// Initialise with the supported error domains
  /// - Parameter supportedDomains: The error domains to support (nil for all domains)
  public init(
    supportedDomains: [String]?
  ) {
    supportedErrorDomains=supportedDomains ?? []
  }

  /// Creates a notification service that supports all error domains
  /// - Returns: A notification service for all error domains
  public static func forAllDomains() -> MacErrorNotificationService {
    MacErrorNotificationService(supportedDomains: [])
  }

  /// Check if this service can handle an error
  /// - Parameter error: The error to check
  /// - Returns: Whether the error can be handled
  public func canHandle(_ error: some Error) -> Bool {
    // Get the domain for the error
    let domain=getDomain(for: error)

    // Check if we handle this domain
    if supportedErrorDomains.isEmpty {
      // We handle all domains
      return true
    } else {
      // We only handle specific domains
      return supportedErrorDomains.contains(domain)
    }
  }

  /// Present a notification to the user about an error
  /// - Parameters:
  ///   - error: The error to notify the user about
  ///   - level: The severity level of the notification
  ///   - recoveryOptions: Available recovery options to present
  /// - Returns: The UUID of the recovery option chosen, if any
  public func notifyUser(
    about error: some Error,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]
  ) async -> UUID? {
    // Skip if this service doesn't support the error domain or level
    guard canHandle(error) else {
      return nil
    }

    return await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        // Create alert
        let alert=NSAlert()
        
        // Configure alert content
        self.configureAlert(alert, for: error, level: level)
        
        // Add recovery options as buttons
        for option in recoveryOptions {
          alert.addButton(withTitle: option.title)
        }
        
        // If there are no recovery options, just add an OK button
        if recoveryOptions.isEmpty {
          alert.addButton(withTitle: "OK")
        }
        
        // Present alert modally
        let response=alert.runModal()
        
        // Process response
        switch response {
        case .alertFirstButtonReturn:
          // First button was clicked
          if !recoveryOptions.isEmpty {
            // Return the UUID of the first recovery option
            continuation.resume(returning: recoveryOptions[0].id)
          } else {
            // No recovery options, just return nil
            continuation.resume(returning: nil)
          }
        case .alertSecondButtonReturn:
          // Second button was clicked
          if recoveryOptions.count >= 2 {
            // Return the UUID of the second recovery option
            continuation.resume(returning: recoveryOptions[1].id)
          } else {
            // This would be the OK button
            continuation.resume(returning: nil)
          }
        case .alertThirdButtonReturn:
          // Third button was clicked
          if recoveryOptions.count >= 3 {
            // Return the UUID of the third recovery option
            continuation.resume(returning: recoveryOptions[2].id)
          } else {
            // Shouldn't happen
            continuation.resume(returning: nil)
          }
        default:
          // Some other button was clicked, just return nil
          continuation.resume(returning: nil)
        }
      }
    }
  }

  /// Configure the alert based on the error and level
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

    // Add recovery options to alert
    // handled by caller
  }

  /// Gets the domain for an error
  /// - Parameter error: The error to get the domain for
  /// - Returns: The error domain
  private func getDomain(for error: Error) -> String {
    if let domain = error.errorDomain {
      return domain
    } else {
      return "Unknown"
    }
  }

  /// Gets a user-friendly title for an error
  /// - Parameters:
  ///   - error: The error to get a title for
  ///   - domain: The error domain
  /// - Returns: A user-friendly title
  private func getTitle(for error: Error, domain: String) -> String {
    if let code = error.errorCode {
      return "Error in \(domain): \(code)"
    } else {
      return "Error in \(domain)"
    }
  }

  /// Gets a user-friendly message for an error
  /// - Parameter error: The error to get a message for
  /// - Returns: A user-friendly message
  private func getMessage(for error: Error) -> String {
    error.localizedDescription
  }
}
