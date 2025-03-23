import Foundation
import SecurityInterfaces
import SecurityProtocolsCore
import SecurityTypes

// Define a protocol for URL-based security access
public protocol URLSecurityProvider {
  /// Start accessing a URL security-scoped resource
  /// - Parameter url: URL to access
  /// - Returns: True if access was granted
  /// - Throws: SecurityError if access cannot be granted
  func startAccessing(url: URL) async throws -> Bool
}

// Define a dedicated error type for our test module
public enum TestSecurityError: Error {
  case invalidInput(message: String)
}

extension SecurityProtocolsCore.SecurityProviderProtocol {
  /// Start accessing a URL security-scoped resource
  /// - Parameter url: URL to access
  /// - Returns: True if access was granted
  /// - Throws: SecurityError if access cannot be granted
  public func startAccessing(url: URL) async throws -> Bool {
    // Access the path directly to avoid recursive call
    guard !url.path.isEmpty else {
      throw TestSecurityError.invalidInput(message: "Empty path")
    }
    return true
  }

  /// Performs an operation with security-scoped access to a path
  /// - Parameters:
  ///   - path: The path to access with security scope
  ///   - operation: The operation to perform while access is granted
  /// - Returns: The result of the operation
  /// - Throws: An error if access could not be granted or if the operation fails
  public func withSecurityScopedAccess<T: Sendable>(
    to _: String,
    perform operation: @Sendable () async throws -> T
  ) async throws -> T {
    // Mock implementation that always grants access
    try await operation()
  }
}
