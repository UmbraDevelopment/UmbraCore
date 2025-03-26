import Foundation

/// A simplified manager for test mocks that provides registration and tracking capabilities
@MainActor
public final class MockManager {
  /// Shared instance for global access
  public static let shared=MockManager()

  /// Collection of registered mocks
  private var registeredMocks: [Any]=[]

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /// Register a mock object with the manager
  /// - Parameter mock: The mock object to register
  public func register(_ mock: Any) {
    registeredMocks.append(mock)
  }

  /// Clear all registered mocks
  public func reset() {
    registeredMocks.removeAll()
  }

  /// Get the count of registered mocks
  /// - Returns: Number of registered mocks
  public var mockCount: Int {
    registeredMocks.count
  }
}
