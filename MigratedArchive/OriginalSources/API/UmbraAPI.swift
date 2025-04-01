import Foundation

/// UmbraAPI has been completely migrated to the Alpha Dot Five architecture.
/// Use packages/UmbraCoreTypes/Sources/APIInterfaces and
/// packages/UmbraImplementations/Sources/APIServices instead.
///
/// Example usage:
/// ```swift
/// import APIInterfaces
///
/// // Get a service instance
/// let apiService = APIServiceFactory.createDefault()
///
/// // Initialize with configuration
/// let config = APIConfigurationDTO(environment: .development)
/// try await apiService.initialise(configuration: config)
/// ```
@available(
  *,
  unavailable,
  message: "UmbraAPI has been migrated to APIInterfaces. Use APIServiceFactory.createDefault() instead."
)
public enum UmbraAPI {
  /// This method has been migrated to the APIServiceProtocol
  @available(
    *,
    unavailable,
    message: "Use APIServiceFactory.createDefault() and initialise() instead"
  )
  public static func initialize() async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the APIServiceProtocol
  @available(*, unavailable, message: "Use apiService.createEncryptedBookmark() instead")
  public static func createEncryptedBookmark(
    for _: URL,
    identifier _: String
  ) async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the APIServiceProtocol
  @available(*, unavailable, message: "Use apiService.resolveEncryptedBookmark() instead")
  public static func resolveEncryptedBookmark(
    withIdentifier _: String
  ) async throws -> URL {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the APIServiceProtocol
  @available(*, unavailable, message: "Use apiService.deleteEncryptedBookmark() instead")
  public static func deleteEncryptedBookmark(
    withIdentifier _: String
  ) async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }
}
