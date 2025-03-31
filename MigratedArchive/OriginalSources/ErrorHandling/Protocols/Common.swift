import Foundation
import Interfaces
import UmbraErrorsCore

/// Recovery options provider extension type
/// This complements the RecoveryOptionsProvider protocol from ErrorHandlingProtocol.swift
extension RecoveryOptionsProvider {
  /// Default implementation for getting recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  public func getRecoveryOptions(for _: Error) -> [any RecoveryOption] {
    // By default, return an empty array
    []
  }

  /// Check if this provider can handle errors from a specific domain
  /// - Parameter domain: The domain to check
  /// - Returns: True if this provider can handle errors from the domain
  public func canHandle(domain _: String) -> Bool {
    false
  }
}

/// Concrete implementation of a recovery option
public struct StandardRecoveryOption: RecoveryOption {
  /// Unique identifier
  public let id: UUID
  /// Title of the option
  public let title: String
  /// Description of what the option does
  public let description: String?
  /// Whether this option is disruptive (e.g., will cancel operations)
  public let isDisruptive: Bool
  /// Action to take when the option is selected
  private let actionHandler: () async -> Void

  /// Initialize a recovery option
  /// - Parameters:
  ///   - id: The unique identifier (defaults to a new UUID)
  ///   - title: The title of the option
  ///   - description: Description of what the option does (optional)
  ///   - isDisruptive: Whether this option is disruptive (defaults to false)
  ///   - action: Action to take when selected
  public init(
    id: UUID=UUID(),
    title: String,
    description: String?=nil,
    isDisruptive: Bool=false,
    action: @escaping () async -> Void
  ) {
    self.id=id
    self.title=title
    self.description=description
    self.isDisruptive=isDisruptive
    actionHandler=action
  }

  /// Perform the recovery action
  public func perform() async {
    await actionHandler()
  }
}
