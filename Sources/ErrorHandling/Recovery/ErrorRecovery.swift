import Foundation
import UmbraErrorsCore
import Interfaces
import Protocols

/// Represents a potential recovery option for an error
public struct ErrorRecoveryOption: RecoveryOption, Sendable {
  /// A unique identifier for this recovery option
  public let id: UUID

  /// User-facing title for this recovery option
  public let title: String

  /// Additional description of what this recovery will do
  public let recoveryDescription: String

  /// The action to execute when this option is selected
  public let action: @MainActor () -> Void

  /// Whether this is the default option
  public let isDefault: Bool

  /// Initialize a recovery option
  /// - Parameters:
  ///   - id: Unique identifier (defaults to random UUID)
  ///   - title: User-facing title
  ///   - description: Detailed description of what this option does
  ///   - isDefault: Whether this is the default option (defaults to false)
  ///   - action: The action to perform when selected
  public init(
    id: UUID=UUID(),
    title: String,
    description: String,
    isDefault: Bool=false,
    action: @escaping @MainActor () -> Void
  ) {
    self.id=id
    self.title=title
    self.recoveryDescription=description
    self.isDefault=isDefault
    self.action=action
  }
}

/// Protocol for errors that provide recovery options
public protocol RecoverableError: UmbraError {
  /// Gets available recovery options for this error
  /// - Returns: Array of recovery options
  @MainActor
  func getRecoveryOptions() -> [RecoveryOption]
}

/// Protocol for error recovery managers
public protocol ErrorRecoveryService: Sendable {
  /// Register a provider of recovery options
  /// - Parameter provider: The provider to register
  func registerProvider(_ provider: RecoveryOptionsProvider)

  /// Get recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Available recovery options
  @MainActor
  func getRecoveryOptions(for error: Error) -> [RecoveryOption]
}

/// A manager for error recovery options
public final class RecoveryManager: RecoveryOptionsProvider, Sendable {
  /// The shared instance
  @MainActor
  public static let shared=RecoveryManager()

  /// Recovery providers registered with this manager
  private let providers=AtomicArray<DomainRecoveryProvider>()

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /// Register a provider of recovery options
  /// - Parameter provider: The provider to register
  @MainActor
  public func registerProvider(_ provider: DomainRecoveryProvider) {
    providers.append(provider)
  }

  /// Get recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  @MainActor
  public func recoveryOptions(for error: Error) async -> [RecoveryOption] {
    // Get the error domain
    let domain=String(describing: type(of: error))

    // Look for a provider that can handle this domain
    for provider in providers.elements {
      if provider.canHandle(domain: domain) {
        // Get recovery options from this provider
        return await provider.createRecoveryOptions(for: error)
      }
    }

    // If no specific provider was found, return default options
    return createDefaultRecoveryOptions(for: error)
  }

  /// Create default recovery options for an error
  /// - Parameter error: The error to create options for
  /// - Returns: Array of default recovery options
  @MainActor
  private func createDefaultRecoveryOptions(for error: Error) -> [RecoveryOption] {
    // Create default options based on the error type
    var options: [RecoveryOption]=[]

    // Add retry option
    options.append(
      ErrorRecoveryOption(
        title: "Retry",
        description: "Retry the operation that failed",
        action: {
          // This would normally retry the operation
          print("Retry selected")
        }
      )
    )

    // Add ignore option
    options.append(
      ErrorRecoveryOption(
        title: "Ignore",
        description: "Ignore this error and continue",
        action: {
          // This would normally just ignore the error
          print("Ignore selected")
        }
      )
    )

    // Add cancel option
    options.append(
      ErrorRecoveryOption(
        title: "Cancel",
        description: "Cancel the operation",
        isDefault: true,
        action: {
          // This would normally cancel the operation
          print("Cancel selected")
        }
      )
    )

    return options
  }
}

/// Protocol for domain-specific recovery providers
public protocol DomainRecoveryProvider: Sendable {
  /// Check if this provider can handle errors from a given domain
  /// - Parameter domain: The domain to check
  /// - Returns: True if this provider can handle errors from this domain
  func canHandle(domain: String) -> Bool

  /// Create recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  func recoveryOptions(for error: Error) -> [RecoveryOption]
}

/// Security domain provider
public struct SecurityDomainProvider: DomainRecoveryProvider {
  public init() {}

  public func canHandle(domain: String) -> Bool {
    domain.contains("Security") || domain.contains("Crypto")
  }

  public func recoveryOptions(for error: Error) -> [RecoveryOption] {
    // Security-specific recovery options
    []
  }
}

/// Network domain provider
public struct NetworkDomainProvider: DomainRecoveryProvider {
  public init() {}

  public func canHandle(domain: String) -> Bool {
    domain.contains("Network") || domain.contains("HTTP")
  }

  public func recoveryOptions(for error: Error) -> [RecoveryOption] {
    // Network-specific recovery options
    []
  }
}

/// Filesystem domain provider
public struct FilesystemDomainProvider: DomainRecoveryProvider {
  public init() {}

  public func canHandle(domain: String) -> Bool {
    domain.contains("File") || domain.contains("Directory")
  }

  public func recoveryOptions(for error: Error) -> [RecoveryOption] {
    // Filesystem-specific recovery options
    []
  }
}

/// User domain provider
public struct UserDomainProvider: DomainRecoveryProvider {
  public init() {}

  public func canHandle(domain: String) -> Bool {
    domain.contains("User") || domain.contains("Input")
  }

  public func recoveryOptions(for error: Error) -> [RecoveryOption] {
    // User-specific recovery options
    []
  }
}
