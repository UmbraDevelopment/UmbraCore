/// APIServiceProtocol
///
/// Defines the contract for API service operations within the UmbraCore framework.
/// This protocol provides a comprehensive interface for interacting with UmbraCore
/// functionality in a thread-safe manner using modern Swift concurrency.
///
/// # Key Features
/// - Thread-safe API operations
/// - Foundation-independent data exchange
/// - Privacy-aware error handling
/// - Comprehensive documentation
///
/// # Thread Safety
/// All methods are designed to be called from any thread and implement
/// proper isolation through Swift actors in their implementations.
///
/// # Error Handling
/// Methods use Swift's structured error handling with domain-specific
/// error types from UmbraErrors.
public protocol APIServiceProtocol: Sendable {
  /// Initialises the service with the provided configuration
  /// - Parameter configuration: The configuration to use for initialisation
  /// - Throws: UmbraErrors.APIError if initialisation fails
  func initialise(configuration: APIConfigurationDTO) async throws

  /// Creates an encrypted security-scoped bookmark for the specified URL
  /// - Parameters:
  ///   - url: URL representation as a string
  ///   - identifier: Unique identifier for the bookmark
  /// - Throws: UmbraErrors.APIError if bookmark creation fails
  func createEncryptedBookmark(url: String, identifier: String) async throws

  /// Resolves an encrypted security-scoped bookmark to a URL
  /// - Parameter identifier: Unique identifier for the bookmark
  /// - Returns: URL representation as a string
  /// - Throws: UmbraErrors.APIError if bookmark resolution fails
  func resolveEncryptedBookmark(identifier: String) async throws -> String

  /// Deletes an encrypted security-scoped bookmark
  /// - Parameter identifier: Unique identifier for the bookmark to delete
  /// - Throws: UmbraErrors.APIError if bookmark deletion fails
  func deleteEncryptedBookmark(identifier: String) async throws

  /// Retrieves the current version information of the API
  /// - Returns: Version information as APIVersionDTO
  func getVersion() async -> APIVersionDTO

  /// Subscribes to API service events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of APIEventDTO objects
  func subscribeToEvents(filter: APIEventFilterDTO?) -> AsyncStream<APIEventDTO>
}
