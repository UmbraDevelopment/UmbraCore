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

/// Provides recovery options for security errors
@preconcurrency // Defer isolation checking to runtime
public final class SecurityErrorRecoveryService {
  /// Shared instance
  public static let shared=SecurityErrorRecoveryService()

  /// Recovery providers registered with this service
  /// Made private(set) to maintain Sendable conformance
  private let providers=AtomicArray<any ErrorHandlingInterfaces.RecoveryOptionsProvider>()

  /// Private initialiser to enforce singleton pattern
  private init() {
    // Will be registered later to avoid circular references
  }

  /// Call this method once to initialize the service properly
  @MainActor
  public static func initialize() {
    // Register shared instance with the registry
    ErrorRecoveryRegistry.shared.register(shared)
  }
}

// MARK: - ErrorRecoveryService Protocol Conformance

extension SecurityErrorRecoveryService: ErrorRecoveryService {
  /// Register a provider of recovery options
  /// - Parameter provider: The provider to register
  public func registerProvider(_ provider: any ErrorHandlingInterfaces.RecoveryOptionsProvider) {
    providers.append(provider)
  }

  /// Get available recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Available recovery options
  public func getRecoveryOptions(for error: some Error) -> [any RecoveryOption] {
    // If it's not a security error, return no options
    guard checkIsSecurity(error: error) else {
      return []
    }

    // Collect options from all providers
    var allOptions: [any RecoveryOption]=[]

    // Add options from registered providers
    for provider in providers.values {
      allOptions.append(contentsOf: provider.recoveryOptions(for: error))
    }

    // If no providers handled it, use built-in recovery options
    if allOptions.isEmpty {
      allOptions=defaultRecoveryOptions(for: error)
    }

    return allOptions
  }

  /// Attempt to automatically recover from an error
  /// - Parameters:
  ///   - error: The error to recover from
  ///   - context: Additional context for recovery
  /// - Returns: Whether recovery was successful
  public func attemptRecovery(from error: some Error, context _: [String: Any]?) async -> Bool {
    // Only attempt recovery for security errors
    guard checkIsSecurity(error: error) else {
      return false
    }

    // Get recovery options
    let options=getRecoveryOptions(for: error)

    // Try each option in order
    for option in options {
      // Skip options marked as disruptive (they require user interaction)
      guard !option.isDisruptive else {
        continue
      }

      // Attempt recovery with this option
      await option.perform()

      // Since we don't have a way to know if recovery succeeded,
      // assume the first non-disruptive option worked
      return true
    }

    return false
  }
}

// MARK: - RecoveryOptionsProvider Protocol Conformance (ErrorHandlingInterfaces)

extension SecurityErrorRecoveryService: ErrorHandlingInterfaces.RecoveryOptionsProvider {
  /// Provides recovery options for an error (ErrorHandlingInterfaces version)
  /// - Parameter error: The error to provide recovery options for
  /// - Returns: Array of recovery options
  public func recoveryOptions(for error: some Error) -> [any RecoveryOption] {
    // If it's not a security error, return empty array
    guard checkIsSecurity(error: error) else {
      return []
    }

    // Map strings to recovery options
    let errorString=String(describing: error).lowercased()
    var options: [any RecoveryOption]=[]

    if errorString.contains("authentication") {
      options.append(
        ErrorRecoveryOption(
          title: "Try Again",
          description: "Retry with different credentials",
          isDisruptive: true,
          recoveryAction: { /* Implementation to retry authentication */ }
        )
      )
    } else if errorString.contains("certificate") {
      options.append(
        ErrorRecoveryOption(
          title: "Trust Certificate",
          description: "Trust this certificate for this session",
          isDisruptive: true,
          recoveryAction: { /* Implementation to trust certificate */ }
        )
      )
    } else {
      // Generic security error
      options.append(
        ErrorRecoveryOption(
          title: "Retry",
          description: "Try the operation again",
          isDisruptive: false,
          recoveryAction: { /* Generic retry implementation */ }
        )
      )

      options.append(
        ErrorRecoveryOption(
          title: "Cancel",
          description: "Cancel the operation",
          isDisruptive: false,
          recoveryAction: { /* Cancel implementation */ }
        )
      )
    }

    return options
  }
}

// MARK: - Internal RecoveryOptionsProvider Protocol Conformance

extension SecurityErrorRecoveryService: RecoveryOptionsProvider {
  /// Provides recovery options for an error (local RecoveryOptionsProvider protocol version)
  /// - Parameter error: The error to provide recovery options for
  /// - Returns: Recovery options struct, or nil if no recovery is possible
  public func recoveryOptions(for error: Error) -> RecoveryOptions? {
    // If it's not a security error, return nil
    guard checkIsSecurity(error: error) else {
      return nil
    }

    // Convert from individual options to a RecoveryOptions structure
    let errorString=String(describing: error).lowercased()
    var actions: [RecoveryAction]=[]
    var title: String?
    var message: String?

    if errorString.contains("authentication") {
      title="Authentication Failed"
      message="You need to re-authenticate to continue"
      actions=[
        RecoveryAction(
          id: "retry-auth",
          title: "Try Again",
          description: "Retry with different credentials",
          isDefault: true,
          handler: { /* Implementation to retry authentication */ }
        )
      ]
    } else if errorString.contains("certificate") {
      title="Certificate Issue"
      message="There's a problem with the security certificate"
      actions=[
        RecoveryAction(
          id: "trust-cert",
          title: "Trust Certificate",
          description: "Trust this certificate for the current session",
          isDefault: true,
          handler: { /* Implementation to trust certificate */ }
        )
      ]
    } else {
      // Generic security error
      title="Security Error"
      message="A security error has occurred"
      actions=[
        RecoveryAction(
          id: "retry",
          title: "Retry",
          description: "Try the operation again",
          isDefault: true,
          handler: { /* Generic retry implementation */ }
        ),
        RecoveryAction(
          id: "cancel",
          title: "Cancel",
          description: "Cancel the operation",
          isDefault: false,
          handler: { /* Cancel implementation */ }
        )
      ]
    }

    return RecoveryOptions(
      actions: actions,
      title: title,
      message: message
    )
  }
}

// MARK: - Private Helpers

extension SecurityErrorRecoveryService {
  /// Check if an error is a security error
  /// - Parameter error: The error to check
  /// - Returns: Whether the error is a security error
  private func checkIsSecurity(error: some Error) -> Bool {
    // Check for common security error types
    let nsError=error as NSError
    return nsError.domain.contains("Security") ||
      String(describing: error).contains("Security")
  }

  /// Default recovery options for built-in security errors
  /// - Parameter error: The error to get recovery options for
  /// - Returns: The default recovery options
  private func defaultRecoveryOptions(for error: some Error) -> [any RecoveryOption] {
    let errorString=String(describing: error).lowercased()

    if errorString.contains("authentication") || errorString.contains("unauthorised") {
      return [createRetryAuthenticationOption()]
    } else if errorString.contains("certificate") || errorString.contains("trust") {
      return [createBypassCertificateOption()]
    } else {
      // Create a cancel option manually rather than using a static property
      return [
        ErrorRecoveryOption(
          title: "Cancel",
          description: "Cancel and take no action",
          isDisruptive: false,
          recoveryAction: { /* No action required */ }
        )
      ]
    }
  }

  /// Create a retry authentication option
  /// - Returns: The recovery option
  private func createRetryAuthenticationOption() -> ErrorRecoveryOption {
    ErrorRecoveryOption(
      title: "Try Again",
      description: "Retry with different credentials",
      isDisruptive: true,
      recoveryAction: {
        // This would typically show UI to re-authenticate
        // Implementation not provided
      }
    )
  }

  /// Create a bypass certificate option
  /// - Returns: The recovery option
  private func createBypassCertificateOption() -> ErrorRecoveryOption {
    ErrorRecoveryOption(
      title: "Trust Certificate",
      description: "Trust the server's certificate for this session",
      isDisruptive: true,
      recoveryAction: {
        // This would typically show UI to confirm trust
        // Implementation not provided
      }
    )
  }
}

/// A thread-safe array wrapper for Sendable conformance
final class AtomicArray<Element>: @unchecked Sendable {
  private let lock=NSLock()
  private var _values: [Element]=[]

  var values: [Element] {
    lock.lock()
    defer { lock.unlock() }
    return _values
  }

  func append(_ element: Element) {
    lock.lock()
    defer { lock.unlock() }
    _values.append(element)
  }
}
