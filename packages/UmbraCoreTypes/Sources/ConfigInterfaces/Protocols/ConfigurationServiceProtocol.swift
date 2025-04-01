/// ConfigurationServiceProtocol
///
/// Defines the contract for configuration management within the UmbraCore framework.
/// This protocol provides a comprehensive interface for managing configuration
/// values, sources, and updates.
///
/// # Key Features
/// - Thread-safe configuration management
/// - Type-safe configuration access
/// - Multiple configuration sources
/// - Change notification
///
/// # Thread Safety
/// All methods are designed to be called from any thread and implement
/// proper isolation through Swift actors in their implementations.
///
/// # Error Handling
/// Methods use Swift's structured error handling with domain-specific
/// error types from UmbraErrors.
public protocol ConfigurationServiceProtocol: Sendable {
  /// Initialises the configuration service with the provided source
  /// - Parameter source: The primary configuration source to use
  /// - Throws: UmbraErrors.ConfigError if initialisation fails
  func initialise(source: ConfigSourceDTO) async throws

  /// Adds a configuration source with the specified priority
  /// - Parameters:
  ///   - source: The configuration source to add
  ///   - priority: The priority of the source (higher values take precedence)
  /// - Throws: UmbraErrors.ConfigError if the source cannot be added
  func addSource(source: ConfigSourceDTO, priority: Int) async throws

  /// Removes a configuration source
  /// - Parameter identifier: The identifier of the source to remove
  /// - Throws: UmbraErrors.ConfigError if the source cannot be removed
  func removeSource(identifier: String) async throws

  /// Gets a configuration value as a string
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as a string
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  func getString(for key: String) async throws -> String

  /// Gets a configuration value as a boolean
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as a boolean
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  func getBool(for key: String) async throws -> Bool

  /// Gets a configuration value as an integer
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as an integer
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  func getInt(for key: String) async throws -> Int

  /// Gets a configuration value as a double
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as a double
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  func getDouble(for key: String) async throws -> Double

  /// Gets a secure configuration value (e.g., API keys, tokens)
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The secure configuration value as a string
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  func getSecureValue(for key: String) async throws -> String

  /// Sets a configuration value
  /// - Parameters:
  ///   - value: The value to set
  ///   - key: The configuration key to set
  ///   - source: Optional source identifier to specify where to store the value
  /// - Throws: UmbraErrors.ConfigError if the value cannot be set
  func setValue(_ value: ConfigValueDTO, for key: String, in source: String?) async throws

  /// Removes a configuration value
  /// - Parameters:
  ///   - key: The configuration key to remove
  ///   - source: Optional source identifier to specify where to remove the value from
  /// - Throws: UmbraErrors.ConfigError if the value cannot be removed
  func removeValue(for key: String, from source: String?) async throws

  /// Saves configuration changes to persistent storage
  /// - Parameter source: Optional source identifier to specify which source to save
  /// - Throws: UmbraErrors.ConfigError if the configuration cannot be saved
  func saveChanges(to source: String?) async throws

  /// Subscribes to configuration change events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of ConfigChangeEventDTO objects
  func subscribeToChanges(filter: ConfigChangeFilterDTO?) -> AsyncStream<ConfigChangeEventDTO>

  /// Gets all available configuration keys
  /// - Parameter source: Optional source identifier to limit the keys to a specific source
  /// - Returns: An array of configuration keys
  func getAllKeys(from source: String?) async -> [String]
}
