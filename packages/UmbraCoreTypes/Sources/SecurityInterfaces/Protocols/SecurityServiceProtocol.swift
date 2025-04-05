import Foundation
import SecurityInterfacesDTOs
import UmbraErrors
import UmbraErrorsDomains

/// Protocol defining the interface for high-level security services in the UmbraCore framework.
///
/// This protocol provides security policy enforcement, secure resource access management,
/// and secure execution contexts, while delegating low-level cryptographic operations to
/// the appropriate crypto services.
public protocol SecurityServiceProtocol: Sendable {
  /// Initialises the security service with the given configuration
  /// - Parameter configuration: Configuration options for the security service
  /// - Throws: SecurityError if initialisation fails
  func initialise(configuration: SecurityConfigurationDTO) async throws

  /// Secures data according to the security policy defined in the security context
  /// - Parameters:
  ///   - data: The data to secure
  ///   - context: The security context defining how the data should be secured
  /// - Returns: The secured data
  /// - Throws: SecurityError if the operation fails
  func secureData(_ data: [UInt8], securityContext: SecurityContextDTO) async throws -> [UInt8]

  /// Retrieves secured data according to the security policy defined in the security context
  /// - Parameters:
  ///   - securedData: The secured data to retrieve
  ///   - context: The security context defining how the data should be retrieved
  /// - Returns: The original data
  /// - Throws: SecurityError if the operation fails
  func retrieveSecuredData(
    _ securedData: [UInt8],
    securityContext: SecurityContextDTO
  ) async throws -> [UInt8]

  /// Creates a secure bookmark for the given URL
  /// - Parameter url: The URL to create a bookmark for
  /// - Returns: The bookmark data
  /// - Throws: SecurityError if bookmark creation fails
  func createBookmark(for url: URL) async throws -> [UInt8]

  /// Resolves a secure bookmark to a URL
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: The resolved URL and a flag indicating whether the bookmark needs to be recreated
  /// - Throws: SecurityError if bookmark resolution fails
  func resolveBookmark(_ bookmarkData: [UInt8]) async throws -> (URL, Bool)

  /// Verifies the integrity of data according to the security policy defined in the security
  /// context
  /// - Parameters:
  ///   - data: The data to verify
  ///   - signature: The signature or verification data
  ///   - context: The security context defining how the verification should be performed
  /// - Returns: True if the data is valid, false otherwise
  /// - Throws: SecurityError if verification fails
  func verifyDataIntegrity(
    _ data: [UInt8],
    verification: [UInt8],
    context: SecurityContextDTO
  ) async throws -> Bool

  /// Returns version information about the security service
  /// - Returns: Version information as a DTO
  func getVersion() async -> SecurityVersionDTO

  /// Subscribes to security events matching the given filter
  /// - Parameter filter: Filter criteria for events
  /// - Returns: An async stream of security events
  func subscribeToEvents(filter: SecurityEventFilterDTO) -> AsyncStream<SecurityEventDTO>
}
