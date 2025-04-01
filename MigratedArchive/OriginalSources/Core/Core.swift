/// Core Module has been completely migrated to the Alpha Dot Five architecture.
/// Use packages/UmbraCoreTypes/Sources/CoreInterfaces and
/// packages/UmbraImplementations/Sources/CoreServices instead.
///
/// Example usage:
/// ```swift
/// import CoreInterfaces
///
/// // Get a service instance
/// let coreService = CoreServiceFactory.createDefault()
///
/// // Initialise with configuration
/// let config = CoreConfigurationDTO(
///    environment: .development,
///    applicationIdentifier: "uk.co.umbra.myapp"
/// )
/// try await coreService.initialise(configuration: config)
/// ```
@available(
  *,
  unavailable,
  message: "Core has been migrated to CoreInterfaces. Use CoreServiceFactory.createDefault() instead."
)
public enum Core {
  /// Current version is meaningless as this module has been completely migrated
  @available(*, unavailable, message: "Use coreService.getVersion() instead")
  public static let version="MIGRATED"

  /// This method has been migrated to the CoreServiceProtocol
  @available(
    *,
    unavailable,
    message: "Use CoreServiceFactory.createDefault() and initialise() instead"
  )
  public static func initialize() async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the CoreServiceProtocol
  @available(*, unavailable, message: "Use coreService.getSystemInfo() instead")
  public static func getSystemInfo() async -> Any {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the CoreServiceProtocol
  @available(*, unavailable, message: "Use coreService.getVersion() instead")
  public static func getVersion() async -> Any {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }
}

/// Errors that can occur during Core operations
/// @unavailable This has been replaced by UmbraErrors.CoreError in the Alpha Dot Five architecture.
@available(
  *,
  unavailable,
  renamed: "UmbraErrors.CoreError",
  message: "Use UmbraErrors.CoreError from the Alpha Dot Five architecture"
)
public enum CoreError: Error {
  case initialisationError(String)
  case configurationError(String)
  case serviceError(String)
  case invalidOperation(String)
}
