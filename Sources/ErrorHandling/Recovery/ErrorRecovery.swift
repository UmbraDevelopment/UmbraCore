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

/// Represents a potential recovery option for an error
public struct ErrorRecoveryOption: RecoveryOption, Sendable {
  /// A unique identifier for this recovery option
  public let id: UUID

  /// User-facing title for this recovery option
  public let title: String

  /// Additional description of what this recovery will do
  public let description: String?

  /// How likely this recovery option is to succeed
  public let successLikelihood: RecoveryLikelihood

  /// Whether this recovery option can disrupt the user's workflow
  public let isDisruptive: Bool

  /// The action to perform for recovery
  public let recoveryAction: @Sendable () async throws -> Void

  /// Creates a new recovery option
  /// - Parameters:
  ///   - id: A unique identifier (optional, auto-generated if nil)
  ///   - title: The user-facing button or option title
  ///   - description: Optional additional details about this recovery
  ///   - successLikelihood: How likely this recovery is to succeed
  ///   - isDisruptive: Whether this recovery interrupts workflow
  ///   - recoveryAction: The action to perform for this recovery
  public init(
    id: UUID?=nil,
    title: String,
    description: String?=nil,
    successLikelihood: RecoveryLikelihood = .medium,
    isDisruptive: Bool=false,
    recoveryAction: @escaping @Sendable () async throws -> Void
  ) {
    self.id=id ?? UUID()
    self.title=title
    self.description=description
    self.successLikelihood=successLikelihood
    self.isDisruptive=isDisruptive
    self.recoveryAction=recoveryAction
  }

  /// Perform the recovery action as required by RecoveryOption protocol
  public func perform() async {
    _=await execute()
  }

  /// Execute the recovery action
  /// - Returns: Whether recovery was successful
  public func execute() async -> Bool {
    do {
      try await recoveryAction()
      return true
    } catch {
      // Create a simple error description if logging is not available
      print("Recovery action failed: \(id) - \(error)")
      return false
    }
  }
}

/// How likely a recovery option is to succeed
public enum RecoveryLikelihood: String, CaseIterable, Sendable {
  case high="High"
  case medium="Medium"
  case low="Low"
  case unknown="Unknown"

  /// Gets a numerical value representing the likelihood (0-1)
  public var probability: Double {
    switch self {
      case .high: 0.9
      case .medium: 0.5
      case .low: 0.1
      case .unknown: 0.0
    }
  }
}

/// Protocol for errors that provide recovery options
public protocol RecoverableError: ErrorHandlingInterfaces.UmbraError {
  /// Gets available recovery options for this error
  /// - Returns: Array of recovery options
  func recoveryOptions() -> [ErrorRecoveryOption]

  /// Attempts to recover from this error using all available options
  /// - Returns: Whether recovery was successful
  func attemptRecovery() async -> Bool
}

/// Default implementation of RecoverableError
extension RecoverableError {
  /// Default implementation attempts each recovery option in order
  public func attemptRecovery() async -> Bool {
    let options=recoveryOptions()
    for option in options {
      if await option.execute() {
        return true
      }
    }
    return false
  }
}

/// Concrete implementation of recovery options
/// This builds on the ErrorRecoveryOption interface defined in ErrorHandlingInterfaces
public final class RecoveryManager: RecoveryOptionsProvider, Sendable {
  /// The shared instance
  @MainActor
  public static let shared=RecoveryManager()

  /// Debug mode flag
  private let verbose=false

  /// Dictionary of domain-specific recovery providers
  /// Using actor isolation to ensure thread safety
  @MainActor
  private var domainProviders: [String: DomainRecoveryProvider]=[:]

  /// Create a new recovery manager
  @MainActor
  public init() {
    // Initialize the recovery manager
    registerDefaultProviders()
  }

  /// Register a recovery provider for a specific error domain
  /// - Parameters:
  ///   - provider: The provider to register
  ///   - domain: The error domain to register for
  @MainActor
  public func register(provider: DomainRecoveryProvider, for domain: String) {
    domainProviders[domain]=provider
  }

  /// Register the default providers
  @MainActor
  private func registerDefaultProviders() {
    // Register built-in providers for standard error domains
    register(provider: SecurityDomainProvider(), for: "Security")
    register(provider: NetworkDomainProvider(), for: "Network")
    register(provider: FilesystemDomainProvider(), for: "Filesystem")
    register(provider: UserDomainProvider(), for: "User")
  }

  /// Provides recovery options for the specified error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  @MainActor
  public func recoveryOptions(for error: Error) async -> [RecoveryOption] {
    // Get the error domain
    let domain=String(describing: type(of: error))

    // Print debug information if enabled
    if verbose {
      print("Finding recovery options for error: \(error) in domain: \(domain)")
    }

    // Look for a provider for this error domain
    if let provider=domainProviders[domain] {
      if verbose {
        print("Using provider: \(type(of: provider)) for domain: \(domain)")
      }

      // Get options from the provider
      return provider.recoveryOptions(for: error)
    }

    // Fallback to default options if no provider handled it
    return createDefaultRecoveryOptions(for: error)
  }

  /// Provides default recovery options for common error types
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of default recovery options
  @MainActor
  private func createDefaultRecoveryOptions(for _: Error) -> [RecoveryOption] {
    // Create default options based on the error type
    var options: [RecoveryOption]=[]

    // Add retry option
    options.append(
      ErrorRecoveryOption(
        title: "Try Again",
        description: "Attempt the operation again",
        successLikelihood: .medium,
        isDisruptive: false,
        recoveryAction: {
          // No-op for default option, would be overridden by caller
        }
      )
    )

    // Add cancel option
    options.append(
      ErrorRecoveryOption(
        title: "Cancel",
        description: "Cancel the operation",
        successLikelihood: .high,
        isDisruptive: false,
        recoveryAction: {
          // No-op for default option, would be overridden by caller
        }
      )
    )

    return options
  }
}

/// Provider for domain-specific recovery options
public protocol DomainRecoveryProvider {
  /// Checks if this provider can handle the given error domain
  /// - Parameter domain: The error domain
  /// - Returns: True if this provider can handle errors in this domain
  func canHandle(domain: String) -> Bool

  /// Gets recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  func recoveryOptions(for error: Error) -> [RecoveryOption]
}

/// Basic implementation of domain recovery provider
public struct SecurityDomainProvider: DomainRecoveryProvider {
  public func canHandle(domain: String) -> Bool {
    domain.contains("Security")
  }

  public func recoveryOptions(for _: Error) -> [RecoveryOption] {
    // Security-specific recovery options
    []
  }
}

/// Network domain recovery provider
public struct NetworkDomainProvider: DomainRecoveryProvider {
  public func canHandle(domain: String) -> Bool {
    domain.contains("Network")
  }

  public func recoveryOptions(for _: Error) -> [RecoveryOption] {
    // Network-specific recovery options
    []
  }
}

/// Filesystem domain recovery provider
public struct FilesystemDomainProvider: DomainRecoveryProvider {
  public func canHandle(domain: String) -> Bool {
    domain.contains("File") || domain.contains("Directory")
  }

  public func recoveryOptions(for _: Error) -> [RecoveryOption] {
    // Filesystem-specific recovery options
    []
  }
}

/// User interaction domain recovery provider
public struct UserDomainProvider: DomainRecoveryProvider {
  public func canHandle(domain: String) -> Bool {
    domain.contains("User") || domain.contains("Input")
  }

  public func recoveryOptions(for _: Error) -> [RecoveryOption] {
    // User-specific recovery options
    []
  }
}
