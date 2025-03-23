import CoreServicesTypes
import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping
import Foundation
import UmbraLogging

/// Protocol defining the base requirements for all UmbraCore services
public protocol UmbraService: Actor {
  /// Unique identifier for the service type
  static var serviceIdentifier: String { get }

  /// Current state of the service
  nonisolated var state: ServiceState { get }

  /// Initialise the service
  /// - Throws: ErrorHandlingCore.ServiceError if initialisation fails
  func initialize() async throws

  /// Gracefully shut down the service
  func shutdown() async

  /// Check if the service is in a usable state
  /// - Returns: true if the service can be used
  func isUsable() async -> Bool
}

/// Extension providing default implementations for UmbraService
extension UmbraService {
  public func isUsable() async -> Bool {
    state == .ready || state == .running
  }
}

/// Errors that can occur during service operations
/// @deprecated This will be replaced by ErrorHandlingCore.ServiceError in a future version.
/// New code should use ErrorHandlingCore.ServiceError directly.
/// Protocol for services that require cleanup of resources
@available(
  *,
  deprecated,
  message: "This will be replaced by ErrorHandlingCore.ServiceError in a future version. Use ErrorHandlingCore.ServiceError directly."
)

public protocol CleanupCapable {
  /// Clean up any resources used by the service
  /// - Parameter force: If true, forcefully clean up resources even if in use
  func cleanup(force: Bool) async throws
}

/// Protocol for services that can be reset to their initial state
public protocol Resettable {
  /// Reset the service to its initial state
  /// - Parameter preserveConfig: If true, preserve configuration during reset
  func reset(preserveConfig: Bool) async throws
}

/// Protocol for services that support health checks
public protocol HealthCheckable {
  /// Perform a health check on the service
  /// - Returns: true if the service is healthy
  func checkHealth() async throws -> Bool

  /// Get detailed health status information
  /// - Returns: Dictionary containing health status details
  func getHealthStatus() async -> [String: Any]
}

// Extension to add more details to ErrorHandlingCore.ServiceError
extension ErrorHandlingCore.ServiceError {
  /// Add a detailed message to the error
  /// - Parameter message: The detailed error message
  /// - Returns: A corresponding ErrorHandlingCore.ServiceError with the message
  public static func withMessage(_ message: String) -> ErrorHandlingCore.ServiceError {
    // Log the error message
    print("Service error: \(message)")
    // Return a default error
    return .operationFailed
  }
}

// Specific extensions for each error type
extension ErrorHandlingCore.ServiceError {
  /// Add a detailed message to initialisation failed error
  /// - Parameter message: The detailed error message
  /// - Returns: An initialisation failed error
  public static func initialisationFailedWithMessage(_ message: String) -> ErrorHandlingCore
  .ServiceError {
    print("Service initialisation failed: \(message)")
    return .initialisationFailed
  }

  /// Add a detailed message to invalid state error
  /// - Parameter message: The detailed error message
  /// - Returns: An invalid state error
  public static func invalidStateWithMessage(_ message: String) -> ErrorHandlingCore.ServiceError {
    print("Invalid service state: \(message)")
    return .invalidState
  }

  /// Add a detailed message to configuration error
  /// - Parameter message: The detailed error message
  /// - Returns: A configuration error
  public static func configurationErrorWithMessage(_ message: String) -> ErrorHandlingCore
  .ServiceError {
    print("Service configuration error: \(message)")
    return .configurationError
  }

  /// Add a detailed message to dependency error
  /// - Parameter message: The detailed error message
  /// - Returns: A dependency error
  public static func dependencyErrorWithMessage(_ message: String) -> ErrorHandlingCore
  .ServiceError {
    print("Service dependency error: \(message)")
    return .dependencyError
  }

  /// Add a detailed message to operation failed error
  /// - Parameter message: The detailed error message
  /// - Returns: An operation failed error
  public static func operationFailedWithMessage(_ message: String) -> ErrorHandlingCore
  .ServiceError {
    print("Operation failed: \(message)")
    return .operationFailed
  }
}
