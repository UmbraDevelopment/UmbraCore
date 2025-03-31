import Foundation

/// Protocol defining the basic requirements for an Umbra service
public protocol UmbraService {
  /// The unique identifier for this service
  var identifier: String { get }

  /// The current version of the service
  var version: String { get }

  /// Validates that the service is operational
  func validate() async throws -> Bool
}
