import Foundation
import UmbraCoreTypes

/// A mock implementation for testing
/// Provides predictable responses without requiring actual XPC communication
@available(*, deprecated, message: "Use MockXPCService instead")
public final class DummyXPCService {
  /// Protocol identifier for this service
  public static var protocolIdentifier: String { "com.umbracore.testing.xpc" }

  /// Indicates whether operations should succeed
  private let shouldSucceed: Bool

  /// The fixed identifier to return
  private let hostIdentifier: String

  /// Creates a new dummy XPC service
  /// - Parameters:
  ///   - shouldSucceed: Whether operations should succeed (default: true)
  ///   - hostIdentifier: The host identifier to return (default: "test-host-12345")
  public init(shouldSucceed: Bool=true, hostIdentifier: String="test-host-12345") {
    self.shouldSucceed=shouldSucceed
    self.hostIdentifier=hostIdentifier
  }

  /// Ping the service to check if it's responsive
  /// - Returns: Always returns true for the dummy implementation
  public func ping() async -> Bool {
    true
  }

  /// Get the service version
  /// - Returns: A fixed version string for testing
  public func getServiceVersion() async -> String? {
    "1.0.0-test"
  }

  /// Validates the connection with the service (for compatibility)
  public func validateConnection(withReply reply: @escaping (Bool, Error?) -> Void) {
    reply(true, nil)
  }

  /// Gets the service version (for compatibility)
  public func getServiceVersion(withReply reply: @escaping (String) -> Void) {
    reply("1.0.0-test")
  }

  /// Get the service status dictionary
  /// - Returns: A mock status dictionary
  public func getServiceStatus() async -> [String: Any]? {
    [
      "status": "running",
      "uptime": 3600,
      "memoryUsage": 1024 * 1024
    ]
  }

  /// Get the device identifier
  /// - Returns: A mock device identifier or nil if shouldSucceed is false
  public func getDeviceIdentifier() async -> String? {
    shouldSucceed ? "test-device-67890" : nil
  }

  /// Basic key synchronization mechanism
  /// - Parameter data: The secure bytes to synchronize
  /// - Returns: Success flag
  public func synchronizeKeys(_: UmbraCoreTypes.SecureBytes) async -> Bool {
    shouldSucceed
  }

  /// Performs a mock secure operation
  /// - Parameters:
  ///   - operation: The operation name
  ///   - config: Configuration parameters
  ///   - completion: Callback for results
  public func performSecureOperation(
    operation _: String,
    config: [String: Any],
    completion: @escaping (Bool, Data?, Error?) -> Void
  ) {
    if shouldSucceed {
      let responseData=config["data"] as? Data ?? Data("Test result".utf8)
      completion(true, responseData, nil)
    } else {
      let error=NSError(domain: "com.umbracore.test", code: 500, userInfo: [
        NSLocalizedDescriptionKey: "Mock operation failure"
      ])
      completion(false, nil, error)
    }
  }

  /// Returns a mock host identifier
  /// - Parameter completion: Callback with the result
  public func getHostIdentifier(completion: @escaping (Result<String, Error>) -> Void) {
    if shouldSucceed {
      completion(.success(hostIdentifier))
    } else {
      let error=NSError(domain: "com.umbracore.test", code: 501, userInfo: [
        NSLocalizedDescriptionKey: "Failed to get host identifier"
      ])
      completion(.failure(error))
    }
  }

  /// Performs a mock client registration
  /// - Parameters:
  ///   - bundleIdentifier: The bundle identifier to register
  ///   - completion: Callback with the result
  public func registerClient(
    bundleIdentifier _: String,
    completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    if shouldSucceed {
      completion(.success(true))
    } else {
      let error=NSError(domain: "com.umbracore.test", code: 502, userInfo: [
        NSLocalizedDescriptionKey: "Failed to register client"
      ])
      completion(.failure(error))
    }
  }
}
