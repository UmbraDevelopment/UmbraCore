import ConfigInterfaces
import CoreInterfaces
import DateTimeTypes
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/// ConfigurationServiceActor
///
/// Provides a thread-safe implementation of the ConfigurationServiceProtocol using
/// Swift actors for isolation. This actor encapsulates all configuration management
/// operations and maintains isolated state for configuration sources and values.
///
/// This implementation follows the Alpha Dot Five architecture principles:
/// - Actor-based concurrency for thread safety
/// - Privacy-aware logging for sensitive operations
/// - Foundation-independent DTOs for data exchange
/// - Proper error handling with domain-specific errors
///
/// # Thread Safety
/// All mutable state is properly isolated within the actor.
/// All methods use Swift's structured concurrency for safe asynchronous operations.
@preconcurrency
public actor ConfigurationServiceActor: ConfigurationServiceProtocol {
  // MARK: - Private Properties

  /// The logger for this service - optional
  private let logger: LoggingInterfaces.DomainLogger?

  /// Configuration sources ordered by priority (highest first)
  private var sources: [(source: ConfigSourceDTO, priority: Int)]=[]

  /// In-memory cache of configuration values
  private var configurationCache: [String: ConfigValueDTO]=[:]

  /// Continuation for configuration change events
  private var changeContinuations: [UUID: AsyncStream<ConfigChangeEventDTO>.Continuation]=[:]

  // MARK: - Initialisation

  /// Initialises a new instance of the ConfigurationServiceActor.
  /// - Parameter logger: Optional domain logger
  public init(logger: LoggingInterfaces.DomainLogger?=nil) {
    self.logger=logger
    sources=[]
    configurationCache=[:]
    changeContinuations=[:]
  }

  // MARK: - ConfigurationServiceProtocol Implementation

  /// Initialises the configuration service with the provided source
  /// - Parameter source: The primary configuration source to use
  /// - Throws: UmbraErrors.ConfigError if initialisation fails
  public func initialise(source: ConfigSourceDTO) async throws {
    // Log the operation for debugging
    if let logger {
      await logger.debug(
        "Initialising configuration service",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "source_name": (source.name, .public),
            "source_type": (source.sourceType.rawValue, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Check if we already have sources (already initialised)
    if !sources.isEmpty {
      let message="Configuration service is already initialised"
      if let logger {
        await logger.warning(message, context: createLogContext(source: "ConfigurationServiceActor"))
      }
      throw UmbraErrors.ConfigError.initialisationError(message: message)
    }

    try await addSource(source: source, priority: 100)
    try await loadConfigurationFromSource(source.identifier)

    // Publish initialisation event
    await publishChangeEvent(
      ConfigChangeEventDTO(
        identifier: UUID().uuidString,
        key: "",
        changeType: .initialised,
        sourceIdentifier: source.identifier,
        timestamp: TimePointDTO.now()
      )
    )

    if let logger {
      await logger.info(
        "Configuration service initialised successfully",
        context: createLogContext(source: "ConfigurationServiceActor")
      )
    }
  }

  /// Adds a configuration source with the specified priority
  /// - Parameters:
  ///   - source: The configuration source to add
  ///   - priority: The priority of the source (higher values take precedence)
  /// - Throws: UmbraErrors.ConfigError if the source cannot be added
  public func addSource(source: ConfigSourceDTO, priority: Int) async throws {
    // Log the operation with privacy-aware logging
    if let logger {
      await logger.info(
        "Adding configuration source",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "source": (source.name, .public),
            "priority": ("\(priority)", .public),
            "source_type": (source.sourceType.rawValue, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Check if the source already exists
    if sources.firstIndex(where: { $0.source.identifier == source.identifier }) != nil {
      // Log the error with privacy-aware logging
      if let logger {
        await logger.warning(
          "Configuration source already exists",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "source_id": (source.identifier, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }

      // Return without error - idempotent operation
      return
    }

    sources.append((source: source, priority: priority))
    sources.sort { $0.priority > $1.priority }

    // Publish source added event
    await publishChangeEvent(
      ConfigChangeEventDTO(
        identifier: UUID().uuidString,
        key: "",
        changeType: .sourceAdded,
        sourceIdentifier: source.identifier,
        timestamp: TimePointDTO.now()
      )
    )

    if let logger {
      await logger.info(
        "Configuration source added successfully",
        context: createLogContext(source: "ConfigurationServiceActor")
      )
    }
  }

  /// Removes a configuration source
  /// - Parameter identifier: The identifier of the source to remove
  /// - Throws: UmbraErrors.ConfigError if the source cannot be removed
  public func removeSource(identifier: String) async throws {
    // Log the operation with privacy-aware logging
    if let logger {
      await logger.info(
        "Removing configuration source",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "source_id": (identifier, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Find the source index
    guard let index=sources.firstIndex(where: { $0.source.identifier == identifier }) else {
      // Log the error with privacy-aware logging
      if let logger {
        await logger.warning(
          "Configuration source does not exist",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "source_id": (identifier, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }

      throw UmbraErrors.ConfigError.sourceNotFound(
        message: "Configuration source with identifier '\(identifier)' not found"
      )
    }

    // Get the source before removing it
    let source=sources[index].source

    // Remove the source
    sources.remove(at: index)

    // Refresh the configuration cache after removing the source
    await refreshConfigurationCache()

    // Publish source removed event
    await publishChangeEvent(
      ConfigChangeEventDTO(
        identifier: UUID().uuidString,
        key: "",
        changeType: .sourceRemoved,
        sourceIdentifier: source.identifier,
        timestamp: TimePointDTO.now()
      )
    )

    if let logger {
      await logger.info(
        "Configuration source removed successfully",
        context: createLogContext(source: "ConfigurationServiceActor")
      )
    }
  }

  /// Gets a configuration value as a string
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as a string
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  public func getString(for key: String) async throws -> String {
    let value=try await getConfigValue(for: key)

    // Log the operation with privacy-aware logging
    if let logger {
      if value.isSensitive {
        await logger.debug(
          "Retrieved sensitive string configuration value",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "key": (key, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      } else {
        await logger.debug(
          "Retrieved string configuration value",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "key": (key, .public),
              "value": (value.stringValue, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }
    }

    // Ensure the value is a string
    if value.valueType != .string {
      throw UmbraErrors.ConfigError.typeMismatch(
        message: "Configuration value for key '\(key)' is not a string",
        expected: "string",
        actual: value.valueType.rawValue
      )
    }

    return value.stringValue
  }

  /// Gets a configuration value as a boolean
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as a boolean
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  public func getBool(for key: String) async throws -> Bool {
    let value=try await getConfigValue(for: key)

    // Log the operation with privacy-aware logging
    if let logger {
      await logger.debug(
        "Retrieved boolean configuration value",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public),
            "value": (value.stringValue, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Parse as boolean
    guard let boolValue=value.boolValue() else {
      throw UmbraErrors.ConfigError.typeMismatch(
        message: "Configuration value for key '\(key)' is not a boolean",
        expected: "boolean",
        actual: value.valueType.rawValue
      )
    }

    return boolValue
  }

  /// Gets a configuration value as an integer
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as an integer
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  public func getInt(for key: String) async throws -> Int {
    let value=try await getConfigValue(for: key)

    // Log the operation with privacy-aware logging
    if let logger {
      await logger.debug(
        "Retrieved integer configuration value",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public),
            "value": (value.stringValue, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Parse as integer
    guard let intValue=value.intValue() else {
      throw UmbraErrors.ConfigError.typeMismatch(
        message: "Configuration value for key '\(key)' is not an integer",
        expected: "integer",
        actual: value.valueType.rawValue
      )
    }

    return intValue
  }

  /// Gets a configuration value as a double
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value as a double
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  public func getDouble(for key: String) async throws -> Double {
    let value=try await getConfigValue(for: key)

    // Log the operation with privacy-aware logging
    if let logger {
      await logger.debug(
        "Retrieved double configuration value",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public),
            "value": (value.stringValue, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Parse as double
    guard let doubleValue=value.doubleValue() else {
      throw UmbraErrors.ConfigError.typeMismatch(
        message: "Configuration value for key '\(key)' is not a double",
        expected: "double",
        actual: value.valueType.rawValue
      )
    }

    return doubleValue
  }

  /// Gets a secure configuration value (e.g., API keys, tokens)
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The secure configuration value as a string
  /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
  public func getSecureValue(for key: String) async throws -> String {
    let value=try await getConfigValue(for: key)

    // Log the operation with privacy-aware logging - note that we're not logging the value
    if let logger {
      await logger.debug(
        "Retrieved secure configuration value",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Ensure the value is a string and sensitive
    if value.valueType != .string {
      throw UmbraErrors.ConfigError.typeMismatch(
        message: "Configuration value for key '\(key)' is not a string",
        expected: "string",
        actual: value.valueType.rawValue
      )
    }

    if !value.isSensitive {
      if let logger {
        await logger.warning(
          "Accessing non-sensitive value through secure API",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "key": (key, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }
    }

    return value.stringValue
  }

  /// Sets a configuration value
  /// - Parameters:
  ///   - value: The value to set
  ///   - key: The configuration key to set
  ///   - source: Optional source identifier to specify where to store the value
  /// - Throws: UmbraErrors.ConfigError if the value cannot be set
  public func setValue(_ value: ConfigValueDTO, for key: String, in source: String?) async throws {
    // Log the operation with privacy-aware logging
    if let logger {
      if value.isSensitive {
        await logger.info(
          "Setting sensitive configuration value",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "key": (key, .public),
              "source": (source ?? "default", .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      } else {
        await logger.info(
          "Setting configuration value",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "key": (key, .public),
              "value": (value.stringValue, .public),
              "source": (source ?? "default", .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }
    }

    // Determine which source to use
    let sourceID=source ?? findWritableSource()?.identifier
    guard let sourceID else {
      throw UmbraErrors.ConfigError.noWritableSource(
        message: "No writable configuration source available"
      )
    }

    // Find the source
    guard sources.firstIndex(where: { $0.source.identifier == sourceID }) != nil else {
      throw UmbraErrors.ConfigError.sourceNotFound(
        message: "Configuration source with identifier '\(sourceID)' not found"
      )
    }

    // Check if the source is read-only
    if sources.first(where: { $0.source.identifier == sourceID })?.source.isReadOnly ?? true {
      throw UmbraErrors.ConfigError.sourceReadOnly(
        message: "Configuration source '\(sourceID)' is read-only"
      )
    }

    // Get the old value if it exists
    let oldValue=configurationCache[key]

    // Update the cache
    configurationCache[key]=value

    // In a real implementation, this would persist the value to the source
    // For now, we'll just update the cache

    // Publish value changed event
    await publishChangeEvent(
      ConfigChangeEventDTO(
        identifier: UUID().uuidString,
        key: key,
        changeType: oldValue == nil ? .added : .modified,
        sourceIdentifier: sourceID,
        timestamp: TimePointDTO.now(),
        oldValue: oldValue,
        newValue: value
      )
    )

    if let logger {
      await logger.debug(
        "Configuration value set successfully",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }
  }

  /// Removes a configuration value
  /// - Parameters:
  ///   - key: The configuration key to remove
  ///   - source: Optional source identifier to specify where to remove the value from
  /// - Throws: UmbraErrors.ConfigError if the value cannot be removed
  public func removeValue(for key: String, from source: String?) async throws {
    // Log the operation with privacy-aware logging
    if let logger {
      await logger.info(
        "Removing configuration value",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public),
            "source": (source ?? "all", .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // Determine which source to use
    let sourceID=source ?? findWritableSource()?.identifier
    guard let sourceID else {
      throw UmbraErrors.ConfigError.noWritableSource(
        message: "No writable configuration source available"
      )
    }

    // Find the source
    guard sources.firstIndex(where: { $0.source.identifier == sourceID }) != nil else {
      throw UmbraErrors.ConfigError.sourceNotFound(
        message: "Configuration source with identifier '\(sourceID)' not found"
      )
    }

    // Check if the source is read-only
    if sources.first(where: { $0.source.identifier == sourceID })?.source.isReadOnly ?? true {
      throw UmbraErrors.ConfigError.sourceReadOnly(
        message: "Configuration source '\(sourceID)' is read-only"
      )
    }

    // Get the old value if it exists
    let oldValue=configurationCache[key]

    // If the value doesn't exist, there's nothing to remove
    guard oldValue != nil else {
      if let logger {
        await logger.debug(
          "Configuration value does not exist, nothing to remove",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "key": (key, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }
      return
    }

    // Remove from the cache
    configurationCache.removeValue(forKey: key)

    // In a real implementation, this would remove the value from the source
    // For now, we'll just update the cache

    // Publish value removed event
    await publishChangeEvent(
      ConfigChangeEventDTO(
        identifier: UUID().uuidString,
        key: key,
        changeType: .removed,
        sourceIdentifier: sourceID,
        timestamp: TimePointDTO.now(),
        oldValue: oldValue,
        newValue: nil
      )
    )

    if let logger {
      await logger.debug(
        "Configuration value removed successfully",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "key": (key, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }
  }

  /// Saves configuration changes to persistent storage
  /// - Parameter source: Optional source identifier to specify which source to save
  /// - Throws: UmbraErrors.ConfigError if the configuration cannot be saved
  public func saveChanges(to source: String?) async throws {
    // Log the operation with privacy-aware logging
    if let logger {
      await logger.info(
        "Saving configuration changes",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "source": (source ?? "all", .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // If a specific source is provided, save only that source
    if let sourceID=source {
      // Find the source
      guard sources.firstIndex(where: { $0.source.identifier == sourceID }) != nil else {
        throw UmbraErrors.ConfigError.sourceNotFound(
          message: "Configuration source with identifier '\(sourceID)' not found"
        )
      }

      // Check if the source is read-only
      if sources.first(where: { $0.source.identifier == sourceID })?.source.isReadOnly ?? true {
        throw UmbraErrors.ConfigError.sourceReadOnly(
          message: "Configuration source '\(sourceID)' is read-only"
        )
      }

      try await saveConfigurationToSource(sourceID)
    } else {
      // Otherwise, save all writable sources
      for sourceEntry in sources where !sourceEntry.source.isReadOnly {
        try await saveConfigurationToSource(sourceEntry.source.identifier)
      }
    }

    if let logger {
      await logger.info(
        "Configuration changes saved successfully",
        context: createLogContext(source: "ConfigurationServiceActor")
      )
    }
  }

  /// Subscribes to configuration change events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of ConfigChangeEventDTO objects
  public nonisolated func subscribeToChanges(filter: ConfigChangeFilterDTO?)
  -> AsyncStream<ConfigChangeEventDTO> {
    // Generate a unique identifier for this subscription
    let subscriptionID=UUID()

    // Log the subscription with privacy-aware logging
    if let logger {
      Task {
        await logger.debug(
          "New configuration change subscription",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "subscription_id": (subscriptionID.uuidString, .public),
              "filter_types": (filter?.changeTypes?.map(\.rawValue).joined(separator: ", ") ?? "all",
                               .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }
    }

    // Create an AsyncStream that will receive events
    let stream=AsyncStream<ConfigChangeEventDTO> { continuation in
      // Store the continuation for publishing events
      Task {
        await self.isolatedStoreSubscription(
          subscriptionID: subscriptionID,
          continuation: continuation
        )
      }

      // Set up cancellation handler to clean up when the stream is cancelled
      continuation.onTermination={ [weak self] _ in
        Task { [weak self] in
          await self?.removeChangeEventContinuation(for: subscriptionID)
        }
      }
    }

    return stream
  }

  /// Gets all available configuration keys
  /// - Parameter source: Optional source identifier to limit the keys to a specific source
  /// - Returns: An array of configuration keys
  public func getAllKeys(from source: String?) async -> [String] {
    // Log the operation with privacy-aware logging
    if let logger {
      await logger.debug(
        "Getting all configuration keys",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "source": (source ?? "all", .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }

    // If a specific source is provided, get only keys from that source
    if source != nil {
      // In a real implementation, this would fetch keys from the specified source
      // For now, we'll just return all keys from the cache
      return Array(configurationCache.keys)
    } else {
      // Otherwise, return all keys from all sources
      return Array(configurationCache.keys)
    }
  }

  // MARK: - Private Methods

  /// Removes a change event continuation for a subscription that has been cancelled
  /// - Parameter subscriptionId: The ID of the subscription to remove
  private func removeChangeEventContinuation(for subscriptionID: UUID) async {
    changeContinuations.removeValue(forKey: subscriptionID)

    // Log the removal with privacy-aware logging
    if let logger {
      await logger.debug(
        "Configuration change subscription removed",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "subscription_id": (subscriptionID.uuidString, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }
  }

  /// Publishes a configuration change event to all active subscribers
  /// - Parameter event: The event to publish
  private func publishChangeEvent(_ event: ConfigChangeEventDTO) async {
    for (subscriptionID, continuation) in changeContinuations {
      // In a real implementation, we would filter the events based on the subscription's filter
      // For simplicity, we're publishing all events to all subscribers
      continuation.yield(event)

      // Log the event publication with privacy-aware logging
      if let logger {
        await logger.trace(
          "Published configuration change event to subscriber",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "subscription_id": (subscriptionID.uuidString, .public),
              "event_id": (event.identifier, .public),
              "event_type": (event.changeType.rawValue, .public),
              "key": (event.key, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }
    }
  }

  /// Store a subscription in the actor-isolated dictionary
  /// - Parameters:
  ///   - subscriptionID: The subscription ID
  ///   - continuation: The continuation to store
  private func isolatedStoreSubscription(
    subscriptionID: UUID,
    continuation: AsyncStream<ConfigChangeEventDTO>.Continuation
  ) {
    changeContinuations[subscriptionID]=continuation
  }

  /// Gets a configuration value for the specified key
  /// - Parameter key: The configuration key to retrieve
  /// - Returns: The configuration value
  /// - Throws: UmbraErrors.ConfigError if the key is not found
  private func getConfigValue(for key: String) async throws -> ConfigValueDTO {
    // Check the cache
    if let cachedValue=configurationCache[key] {
      return cachedValue
    }

    // If not in the cache, throw an error
    throw UmbraErrors.ConfigError.sourceNotFound(
      message: "Configuration key '\(key)' not found"
    )
  }

  /// Finds the first writable configuration source
  /// - Returns: The first writable source, or nil if none exists
  private func findWritableSource() -> ConfigSourceDTO? {
    sources.first { !$0.source.isReadOnly }?.source
  }

  /// Loads configuration values from a source
  /// - Parameter sourceId: The identifier of the source to load from
  /// - Throws: UmbraErrors.ConfigError if the source cannot be loaded
  private func loadConfigurationFromSource(_ sourceID: String) async throws {
    // Get the source
    guard sources.firstIndex(where: { $0.source.identifier == sourceID }) != nil else {
      if let logger {
        await logger.error(
          "Cannot load configuration from unknown source",
          context: createLogContext(
            metadata: PrivacyMetadata([
              "source_id": (sourceID, .public)
            ]),
            source: "ConfigurationServiceActor"
          )
        )
      }

      throw UmbraErrors.ConfigError.sourceNotFound(
        message: "Configuration source with identifier '\(sourceID)' not found"
      )
    }

    // In a real implementation, this would load configuration from the source
    // For now, we'll just use what's already in the cache

    // Refresh the configuration cache
    await refreshConfigurationCache()

    // Publish initialisation event
    await publishChangeEvent(
      ConfigChangeEventDTO(
        identifier: UUID().uuidString,
        key: "",
        changeType: .initialised,
        sourceIdentifier: sourceID,
        timestamp: TimePointDTO.now()
      )
    )
  }

  /// Saves configuration values to a source
  /// - Parameter sourceId: The identifier of the source to save to
  /// - Throws: UmbraErrors.ConfigError if the source cannot be saved
  private func saveConfigurationToSource(_ sourceID: String) async throws {
    // In a real implementation, this would save values to the source
    // For now, we'll just log it
    if let logger {
      await logger.debug(
        "Saving configuration to source",
        context: createLogContext(
          metadata: PrivacyMetadata([
            "source_id": (sourceID, .public)
          ]),
          source: "ConfigurationServiceActor"
        )
      )
    }
  }

  /// Refreshes the configuration cache from all sources
  private func refreshConfigurationCache() async {
    // In a real implementation, this would rebuild the cache from all sources
    // For now, we'll just log it
    if let logger {
      await logger.debug(
        "Refreshing configuration cache",
        context: createLogContext(source: "ConfigurationServiceActor")
      )
    }

    // Mock refreshing the cache - this would actually merge values from all sources
    // respecting their priority
  }

  /// Create a LogContextDTO from metadata and source
  /// - Parameters:
  ///   - metadata: The privacy metadata
  ///   - source: Optional source identifier
  /// - Returns: A LogContextDTO suitable for logging
  private func createLogContext(metadata: PrivacyMetadata?, source: String) -> LogContextDTO {
    var metadataCollection = LogMetadataDTOCollection()
    
    if let metadata = metadata {
      // Convert PrivacyMetadata to LogMetadataDTOCollection using public APIs
      // Use the appropriate builder methods for each privacy level
      for entry in metadata.entriesArray {
        switch entry.privacy {
        case .public:
          metadataCollection = metadataCollection.withPublic(key: entry.key, value: entry.value)
        case .private:
          metadataCollection = metadataCollection.withPrivate(key: entry.key, value: entry.value)
        case .sensitive:
          metadataCollection = metadataCollection.withSensitive(key: entry.key, value: entry.value)
        case .auto:
          // For auto, default to public
          metadataCollection = metadataCollection.withPublic(key: entry.key, value: entry.value)
        default:
          // For any other cases like .hash, default to private
          metadataCollection = metadataCollection.withPrivate(key: entry.key, value: entry.value)
        }
      }
    }
    
    return BaseLogContextDTO(
      domainName: "Configuration",
      source: source,
      metadata: metadataCollection
    )
  }
  
  /// Create a LogContextDTO with just a source identifier
  /// - Parameter source: Source identifier
  /// - Returns: A LogContextDTO suitable for logging
  private func createLogContext(source: String) -> LogContextDTO {
    return createLogContext(metadata: nil, source: source)
  }
}

// MARK: - Helper Extensions

extension TimePointDTO {
  /// Static helper to get the current time
  static func now() -> TimePointDTO {
    // For simplicity, we're using a dummy implementation
    TimePointDTO(
      timestamp: Date().timeIntervalSince1970,
      nanoseconds: 0
    )
  }
}
