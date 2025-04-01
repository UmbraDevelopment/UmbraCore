import ConfigInterfaces
import LoggingInterfaces
import UmbraErrors
import DateTimeTypes
import CoreTypesInterfaces

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
public actor ConfigurationServiceActor: ConfigurationServiceProtocol {
    // MARK: - Private Properties
    
    /// The logger for configuration operations
    private let logger: DomainLogger
    
    /// Configuration sources ordered by priority (highest first)
    private var sources: [(source: ConfigSourceDTO, priority: Int)] = []
    
    /// In-memory cache of configuration values
    private var configurationCache: [String: ConfigValueDTO] = [:]
    
    /// Continuation for configuration change events
    private var changeContinuations: [UUID: AsyncStream<ConfigChangeEventDTO>.Continuation] = [:]
    
    // MARK: - Initialisation
    
    /// Creates a new ConfigurationServiceActor instance
    /// - Parameter logger: Logger for configuration operations
    public init(logger: DomainLogger) {
        self.logger = logger
    }
    
    // MARK: - ConfigurationServiceProtocol Implementation
    
    /// Initialises the configuration service with the provided source
    /// - Parameter source: The primary configuration source to use
    /// - Throws: UmbraErrors.ConfigError if initialisation fails
    public func initialise(source: ConfigSourceDTO) async throws {
        // Log the initialisation attempt with privacy-aware logging
        logger.info(
            "Initialising configuration service",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "source": .public(source.name),
                "source_type": .public(source.sourceType.rawValue),
                "location": source.isSecure ? .sensitive(source.location) : .public(source.location)
            ]
        )
        
        // Check if we already have sources (already initialised)
        if !sources.isEmpty {
            let message = "Configuration service is already initialised"
            logger.warning(message, context: ["service": "ConfigurationServiceActor"])
            throw UmbraErrors.ConfigError.initialisationError(message: message)
        }
        
        do {
            // Add the source with maximum priority
            try await addSource(source: source, priority: 100)
            
            // Load configuration values from the source
            try await loadConfigurationFromSource(source.identifier)
            
            // Publish initialisation event
            publishChangeEvent(
                ConfigChangeEventDTO(
                    identifier: UUID().uuidString,
                    key: "",
                    changeType: .initialised,
                    sourceIdentifier: source.identifier,
                    timestamp: TimePointDTO.now(),
                    context: ["service": "ConfigurationServiceActor"]
                )
            )
            
            logger.info("Configuration service initialised successfully", context: ["service": "ConfigurationServiceActor"])
        } catch {
            // Log the error with privacy-aware logging
            logger.error(
                "Failed to initialise configuration service",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "source": .public(source.name),
                    "error": .public(error.localizedDescription)
                ]
            )
            
            // Map to a ConfigError
            throw UmbraErrors.ConfigError.initialisationError(
                message: "Failed to initialise configuration service: \(error.localizedDescription)",
                underlyingError: error
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
        logger.info(
            "Adding configuration source",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "source": .public(source.name),
                "priority": .public("\(priority)"),
                "source_type": .public(source.sourceType.rawValue)
            ]
        )
        
        // Check if the source already exists
        if sources.contains(where: { $0.source.identifier == source.identifier }) {
            let message = "Configuration source with identifier '\(source.identifier)' already exists"
            logger.warning(message, context: ["service": "ConfigurationServiceActor"])
            throw UmbraErrors.ConfigError.duplicateSource(message: message)
        }
        
        do {
            // Add the source to the list and sort by priority
            sources.append((source: source, priority: priority))
            sources.sort { $0.priority > $1.priority }
            
            // Publish source added event
            publishChangeEvent(
                ConfigChangeEventDTO(
                    identifier: UUID().uuidString,
                    key: "",
                    changeType: .sourceAdded,
                    sourceIdentifier: source.identifier,
                    timestamp: TimePointDTO.now(),
                    context: ["service": "ConfigurationServiceActor"]
                )
            )
            
            logger.info("Configuration source added successfully", context: ["service": "ConfigurationServiceActor"])
        } catch {
            // Log the error with privacy-aware logging
            logger.error(
                "Failed to add configuration source",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "source": .public(source.name),
                    "error": .public(error.localizedDescription)
                ]
            )
            
            // Map to a ConfigError
            throw UmbraErrors.ConfigError.sourceError(
                message: "Failed to add configuration source: \(error.localizedDescription)",
                underlyingError: error
            )
        }
    }
    
    /// Removes a configuration source
    /// - Parameter identifier: The identifier of the source to remove
    /// - Throws: UmbraErrors.ConfigError if the source cannot be removed
    public func removeSource(identifier: String) async throws {
        // Log the operation with privacy-aware logging
        logger.info(
            "Removing configuration source",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["source_id": .public(identifier)]
        )
        
        // Find the source index
        guard let index = sources.firstIndex(where: { $0.source.identifier == identifier }) else {
            let message = "Configuration source with identifier '\(identifier)' not found"
            logger.warning(message, context: ["service": "ConfigurationServiceActor"])
            throw UmbraErrors.ConfigError.sourceNotFound(message: message)
        }
        
        do {
            // Get the source before removing it
            let source = sources[index].source
            
            // Remove the source
            sources.remove(at: index)
            
            // Refresh the configuration cache after removing the source
            await refreshConfigurationCache()
            
            // Publish source removed event
            publishChangeEvent(
                ConfigChangeEventDTO(
                    identifier: UUID().uuidString,
                    key: "",
                    changeType: .sourceRemoved,
                    sourceIdentifier: source.identifier,
                    timestamp: TimePointDTO.now(),
                    context: ["service": "ConfigurationServiceActor"]
                )
            )
            
            logger.info("Configuration source removed successfully", context: ["service": "ConfigurationServiceActor"])
        } catch {
            // Log the error with privacy-aware logging
            logger.error(
                "Failed to remove configuration source",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "source_id": .public(identifier),
                    "error": .public(error.localizedDescription)
                ]
            )
            
            // Map to a ConfigError
            throw UmbraErrors.ConfigError.sourceError(
                message: "Failed to remove configuration source: \(error.localizedDescription)",
                underlyingError: error
            )
        }
    }
    
    /// Gets a configuration value as a string
    /// - Parameter key: The configuration key to retrieve
    /// - Returns: The configuration value as a string
    /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
    public func getString(for key: String) async throws -> String {
        let value = try await getConfigValue(for: key)
        
        // Log the operation with privacy-aware logging
        if value.isSensitive {
            logger.debug(
                "Retrieved sensitive string configuration value",
                context: ["service": "ConfigurationServiceActor"],
                metadata: ["key": .public(key)]
            )
        } else {
            logger.debug(
                "Retrieved string configuration value",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "key": .public(key),
                    "value": .public(value.stringValue)
                ]
            )
        }
        
        // Ensure the value is a string
        if value.valueType != .string {
            throw UmbraErrors.ConfigError.typeMismatch(
                message: "Configuration value for key '\(key)' is not a string"
            )
        }
        
        return value.stringValue
    }
    
    /// Gets a configuration value as a boolean
    /// - Parameter key: The configuration key to retrieve
    /// - Returns: The configuration value as a boolean
    /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
    public func getBool(for key: String) async throws -> Bool {
        let value = try await getConfigValue(for: key)
        
        // Log the operation with privacy-aware logging
        logger.debug(
            "Retrieved boolean configuration value",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "key": .public(key),
                "value": .public(value.stringValue)
            ]
        )
        
        // Parse as boolean
        guard let boolValue = value.boolValue() else {
            throw UmbraErrors.ConfigError.typeMismatch(
                message: "Configuration value for key '\(key)' is not a boolean"
            )
        }
        
        return boolValue
    }
    
    /// Gets a configuration value as an integer
    /// - Parameter key: The configuration key to retrieve
    /// - Returns: The configuration value as an integer
    /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
    public func getInt(for key: String) async throws -> Int {
        let value = try await getConfigValue(for: key)
        
        // Log the operation with privacy-aware logging
        logger.debug(
            "Retrieved integer configuration value",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "key": .public(key),
                "value": .public(value.stringValue)
            ]
        )
        
        // Parse as integer
        guard let intValue = value.intValue() else {
            throw UmbraErrors.ConfigError.typeMismatch(
                message: "Configuration value for key '\(key)' is not an integer"
            )
        }
        
        return intValue
    }
    
    /// Gets a configuration value as a double
    /// - Parameter key: The configuration key to retrieve
    /// - Returns: The configuration value as a double
    /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
    public func getDouble(for key: String) async throws -> Double {
        let value = try await getConfigValue(for: key)
        
        // Log the operation with privacy-aware logging
        logger.debug(
            "Retrieved double configuration value",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "key": .public(key),
                "value": .public(value.stringValue)
            ]
        )
        
        // Parse as double
        guard let doubleValue = value.doubleValue() else {
            throw UmbraErrors.ConfigError.typeMismatch(
                message: "Configuration value for key '\(key)' is not a double"
            )
        }
        
        return doubleValue
    }
    
    /// Gets a secure configuration value (e.g., API keys, tokens)
    /// - Parameter key: The configuration key to retrieve
    /// - Returns: The secure configuration value as a string
    /// - Throws: UmbraErrors.ConfigError if the key is not found or has an incompatible type
    public func getSecureValue(for key: String) async throws -> String {
        let value = try await getConfigValue(for: key)
        
        // Log the operation with privacy-aware logging - note that we're not logging the value
        logger.debug(
            "Retrieved secure configuration value",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["key": .public(key)]
        )
        
        // Ensure the value is a string and sensitive
        if value.valueType != .string {
            throw UmbraErrors.ConfigError.typeMismatch(
                message: "Configuration value for key '\(key)' is not a string"
            )
        }
        
        if !value.isSensitive {
            logger.warning(
                "Accessing non-sensitive value through secure API",
                context: ["service": "ConfigurationServiceActor"],
                metadata: ["key": .public(key)]
            )
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
        if value.isSensitive {
            logger.info(
                "Setting sensitive configuration value",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "key": .public(key),
                    "source": .public(source ?? "default")
                ]
            )
        } else {
            logger.info(
                "Setting configuration value",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "key": .public(key),
                    "value": .public(value.stringValue),
                    "source": .public(source ?? "default")
                ]
            )
        }
        
        // Determine which source to use
        let sourceId = source ?? findWritableSource()?.identifier
        guard let sourceId = sourceId else {
            throw UmbraErrors.ConfigError.noWritableSource(
                message: "No writable configuration source available"
            )
        }
        
        // Find the source
        guard let sourceEntry = sources.first(where: { $0.source.identifier == sourceId }) else {
            throw UmbraErrors.ConfigError.sourceNotFound(
                message: "Configuration source with identifier '\(sourceId)' not found"
            )
        }
        
        // Check if the source is read-only
        if sourceEntry.source.isReadOnly {
            throw UmbraErrors.ConfigError.sourceReadOnly(
                message: "Configuration source '\(sourceEntry.source.name)' is read-only"
            )
        }
        
        do {
            // Get the old value if it exists
            let oldValue = configurationCache[key]
            
            // Update the cache
            configurationCache[key] = value
            
            // In a real implementation, this would persist the value to the source
            // For now, we'll just update the cache
            
            // Publish value changed event
            publishChangeEvent(
                ConfigChangeEventDTO(
                    identifier: UUID().uuidString,
                    key: key,
                    changeType: oldValue == nil ? .added : .modified,
                    sourceIdentifier: sourceId,
                    timestamp: TimePointDTO.now(),
                    oldValue: oldValue,
                    newValue: value,
                    context: ["service": "ConfigurationServiceActor"]
                )
            )
            
            logger.debug(
                "Configuration value set successfully",
                context: ["service": "ConfigurationServiceActor"],
                metadata: ["key": .public(key)]
            )
        } catch {
            // Log the error with privacy-aware logging
            logger.error(
                "Failed to set configuration value",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "key": .public(key),
                    "source": .public(sourceId),
                    "error": .public(error.localizedDescription)
                ]
            )
            
            // Map to a ConfigError
            throw UmbraErrors.ConfigError.operationFailed(
                message: "Failed to set configuration value: \(error.localizedDescription)",
                underlyingError: error
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
        logger.info(
            "Removing configuration value",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "key": .public(key),
                "source": .public(source ?? "all")
            ]
        )
        
        // Determine which source to use
        let sourceId = source ?? findWritableSource()?.identifier
        guard let sourceId = sourceId else {
            throw UmbraErrors.ConfigError.noWritableSource(
                message: "No writable configuration source available"
            )
        }
        
        // Find the source
        guard let sourceEntry = sources.first(where: { $0.source.identifier == sourceId }) else {
            throw UmbraErrors.ConfigError.sourceNotFound(
                message: "Configuration source with identifier '\(sourceId)' not found"
            )
        }
        
        // Check if the source is read-only
        if sourceEntry.source.isReadOnly {
            throw UmbraErrors.ConfigError.sourceReadOnly(
                message: "Configuration source '\(sourceEntry.source.name)' is read-only"
            )
        }
        
        do {
            // Get the old value if it exists
            let oldValue = configurationCache[key]
            
            // If the value doesn't exist, there's nothing to remove
            guard oldValue != nil else {
                logger.debug(
                    "Configuration value does not exist, nothing to remove",
                    context: ["service": "ConfigurationServiceActor"],
                    metadata: ["key": .public(key)]
                )
                return
            }
            
            // Remove from the cache
            configurationCache.removeValue(forKey: key)
            
            // In a real implementation, this would remove the value from the source
            // For now, we'll just update the cache
            
            // Publish value removed event
            publishChangeEvent(
                ConfigChangeEventDTO(
                    identifier: UUID().uuidString,
                    key: key,
                    changeType: .removed,
                    sourceIdentifier: sourceId,
                    timestamp: TimePointDTO.now(),
                    oldValue: oldValue,
                    newValue: nil,
                    context: ["service": "ConfigurationServiceActor"]
                )
            )
            
            logger.debug(
                "Configuration value removed successfully",
                context: ["service": "ConfigurationServiceActor"],
                metadata: ["key": .public(key)]
            )
        } catch {
            // Log the error with privacy-aware logging
            logger.error(
                "Failed to remove configuration value",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "key": .public(key),
                    "source": .public(sourceId),
                    "error": .public(error.localizedDescription)
                ]
            )
            
            // Map to a ConfigError
            throw UmbraErrors.ConfigError.operationFailed(
                message: "Failed to remove configuration value: \(error.localizedDescription)",
                underlyingError: error
            )
        }
    }
    
    /// Saves configuration changes to persistent storage
    /// - Parameter source: Optional source identifier to specify which source to save
    /// - Throws: UmbraErrors.ConfigError if the configuration cannot be saved
    public func saveChanges(to source: String?) async throws {
        // Log the operation with privacy-aware logging
        logger.info(
            "Saving configuration changes",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["source": .public(source ?? "all")]
        )
        
        // If a specific source is provided, save only that source
        if let sourceId = source {
            // Find the source
            guard let sourceEntry = sources.first(where: { $0.source.identifier == sourceId }) else {
                throw UmbraErrors.ConfigError.sourceNotFound(
                    message: "Configuration source with identifier '\(sourceId)' not found"
                )
            }
            
            // Check if the source is read-only
            if sourceEntry.source.isReadOnly {
                throw UmbraErrors.ConfigError.sourceReadOnly(
                    message: "Configuration source '\(sourceEntry.source.name)' is read-only"
                )
            }
            
            try await saveConfigurationToSource(sourceId)
        } else {
            // Otherwise, save all writable sources
            for sourceEntry in sources where !sourceEntry.source.isReadOnly {
                try await saveConfigurationToSource(sourceEntry.source.identifier)
            }
        }
        
        logger.info("Configuration changes saved successfully", context: ["service": "ConfigurationServiceActor"])
    }
    
    /// Subscribes to configuration change events
    /// - Parameter filter: Optional filter to limit the events received
    /// - Returns: An async sequence of ConfigChangeEventDTO objects
    public func subscribeToChanges(filter: ConfigChangeFilterDTO?) -> AsyncStream<ConfigChangeEventDTO> {
        // Generate a unique identifier for this subscription
        let subscriptionId = UUID()
        
        // Log the subscription with privacy-aware logging
        logger.debug(
            "New configuration change subscription",
            context: ["service": "ConfigurationServiceActor"],
            metadata: [
                "subscription_id": .public(subscriptionId.uuidString),
                "filter_types": .public(filter?.changeTypes?.map { $0.rawValue }.joined(separator: ", ") ?? "all")
            ]
        )
        
        // Create an AsyncStream that will receive events
        let stream = AsyncStream<ConfigChangeEventDTO> { continuation in
            // Store the continuation for publishing events
            changeContinuations[subscriptionId] = continuation
            
            // Set up cancellation handler to clean up when the stream is cancelled
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeChangeEventContinuation(for: subscriptionId)
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
        logger.debug(
            "Getting all configuration keys",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["source": .public(source ?? "all")]
        )
        
        // If a specific source is provided, get only keys from that source
        if let sourceId = source {
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
    private func removeChangeEventContinuation(for subscriptionId: UUID) {
        changeContinuations.removeValue(forKey: subscriptionId)
        
        // Log the removal with privacy-aware logging
        logger.debug(
            "Configuration change subscription removed",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["subscription_id": .public(subscriptionId.uuidString)]
        )
    }
    
    /// Publishes a configuration change event to all active subscribers
    /// - Parameter event: The event to publish
    private func publishChangeEvent(_ event: ConfigChangeEventDTO) {
        for (subscriptionId, continuation) in changeContinuations {
            // In a real implementation, we would filter the events based on the subscription's filter
            // For simplicity, we're publishing all events to all subscribers
            continuation.yield(event)
            
            // Log the event publication with privacy-aware logging
            logger.trace(
                "Published configuration change event to subscriber",
                context: ["service": "ConfigurationServiceActor"],
                metadata: [
                    "subscription_id": .public(subscriptionId.uuidString),
                    "event_id": .public(event.identifier),
                    "event_type": .public(event.changeType.rawValue),
                    "key": .public(event.key)
                ]
            )
        }
    }
    
    /// Gets a configuration value for the specified key
    /// - Parameter key: The configuration key to retrieve
    /// - Returns: The configuration value
    /// - Throws: UmbraErrors.ConfigError if the key is not found
    private func getConfigValue(for key: String) async throws -> ConfigValueDTO {
        // Check the cache
        if let cachedValue = configurationCache[key] {
            return cachedValue
        }
        
        // If not in the cache, throw an error
        throw UmbraErrors.ConfigError.keyNotFound(
            message: "Configuration key '\(key)' not found"
        )
    }
    
    /// Finds the first writable configuration source
    /// - Returns: The first writable source, or nil if none exists
    private func findWritableSource() -> ConfigSourceDTO? {
        return sources.first { !$0.source.isReadOnly }?.source
    }
    
    /// Loads configuration values from a source
    /// - Parameter sourceId: The identifier of the source to load from
    /// - Throws: UmbraErrors.ConfigError if the source cannot be loaded
    private func loadConfigurationFromSource(_ sourceId: String) async throws {
        // In a real implementation, this would load values from the source
        // For now, we'll just log it
        logger.debug(
            "Loading configuration from source",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["source_id": .public(sourceId)]
        )
    }
    
    /// Saves configuration values to a source
    /// - Parameter sourceId: The identifier of the source to save to
    /// - Throws: UmbraErrors.ConfigError if the source cannot be saved
    private func saveConfigurationToSource(_ sourceId: String) async throws {
        // In a real implementation, this would save values to the source
        // For now, we'll just log it
        logger.debug(
            "Saving configuration to source",
            context: ["service": "ConfigurationServiceActor"],
            metadata: ["source_id": .public(sourceId)]
        )
    }
    
    /// Refreshes the configuration cache from all sources
    private func refreshConfigurationCache() async {
        // In a real implementation, this would rebuild the cache from all sources
        // For now, we'll just log it
        logger.debug(
            "Refreshing configuration cache",
            context: ["service": "ConfigurationServiceActor"]
        )
        
        // Mock refreshing the cache - this would actually merge values from all sources
        // respecting their priority
    }
}

// MARK: - Helper Extensions

extension TimePointDTO {
    /// Creates a TimePointDTO representing the current time
    static func now() -> TimePointDTO {
        // In a real implementation, this would use a proper time source
        // For simplicity, we're using a dummy implementation
        return TimePointDTO(
            epochSeconds: UInt64(Date().timeIntervalSince1970),
            nanoseconds: 0
        )
    }
}
