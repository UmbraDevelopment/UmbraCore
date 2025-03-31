import Foundation

/// Protocol for resources that can be managed by a ResourcePool
public protocol BasicManagedResource: Sendable {
  /// Unique identifier for the resource
  nonisolated var id: String { get }

  /// Current state of the resource
  nonisolated var state: ResourceState { get }

  /// Type of the resource
  static var resourceType: String { get }

  /// Initialize the resource
  /// - Throws: Error if initialization fails
  func initialize() async throws

  /// Acquire the resource for use
  /// - Throws: Error if acquisition fails
  func acquire() async throws

  /// Release the resource when done
  /// - Throws: Error if release fails
  func release() async throws

  /// Clean up the resource when it's no longer needed
  /// - Throws: Error if cleanup fails
  func cleanup() async throws
}
