/// Config Module has been completely migrated to the Alpha Dot Five architecture.
/// Use packages/UmbraCoreTypes/Sources/ConfigInterfaces and
/// packages/UmbraImplementations/Sources/ConfigServices instead.
///
/// Example usage:
/// ```swift
/// import ConfigInterfaces
///
/// // Get a service instance
/// let configService = ConfigurationServiceFactory.createDefault()
///
/// // Initialise with JSON file source
/// let source = ConfigurationServiceFactory.createJsonFileSource(filePath: "/path/to/config.json")
/// try await configService.initialise(source: source)
///
/// // Get configuration values in a type-safe way
/// let value = try await configService.getString(for: "some.key")
/// ```
@available(
  *,
  unavailable,
  message: "Config has been migrated to ConfigInterfaces. Use ConfigurationServiceFactory.createDefault() instead."
)
public enum Config {
  /// Current version is meaningless as this module has been completely migrated
  @available(*, unavailable, message: "Use configService.getVersion() instead")
  public static let version="MIGRATED"

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(
    *,
    unavailable,
    message: "Use ConfigurationServiceFactory.createDefault() and initialise() instead"
  )
  public static func initialise(sourcePath _: String?=nil) async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.getString() instead")
  public static func getString(for _: String) async throws -> String {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.getInt() instead")
  public static func getInt(for _: String) async throws -> Int {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.getDouble() instead")
  public static func getDouble(for _: String) async throws -> Double {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.getBool() instead")
  public static func getBool(for _: String) async throws -> Bool {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.getArray() instead")
  public static func getArray(for _: String) async throws -> [Any] {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.getDictionary() instead")
  public static func getDictionary(for _: String) async throws -> [String: Any] {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.setValue() instead")
  public static func setValue(_: Any, for _: String, in _: String?=nil) async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.saveChanges() instead")
  public static func saveChanges(to _: String?=nil) async throws {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }

  /// This method has been migrated to the ConfigurationServiceProtocol
  @available(*, unavailable, message: "Use configService.subscribeToChanges() instead")
  public static func subscribeToChanges(filter _: Any?=nil) -> Any {
    fatalError("This API has been completely migrated to the Alpha Dot Five architecture")
  }
}

/// Errors that can occur during Config operations
/// @unavailable This has been replaced by UmbraErrors.ConfigError in the Alpha Dot Five
/// architecture.
@available(
  *,
  unavailable,
  renamed: "UmbraErrors.ConfigError",
  message: "Use UmbraErrors.ConfigError from the Alpha Dot Five architecture"
)
public enum ConfigError: Error {
  case initialisationError(String)
  case invalidKey(String)
  case typeError(String)
  case sourceError(String)
}
