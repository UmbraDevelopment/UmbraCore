import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Primary implementation of the logging services actor.

 This actor provides a thread-safe implementation of the PrivacyAwareLoggingProtocol
 using the command pattern to handle all operations.
 */
public actor LoggingServicesActor: PrivacyAwareLoggingProtocol {
  /// Factory for creating logging commands
  private var commandFactory: LogCommandFactory

  /// The configured log providers, keyed by destination type
  private let providers: [LogDestinationType: LoggingProviderProtocol]

  /// The logging actor required by LoggingProtocol
  public nonisolated var loggingActor: LoggingActor {
    .init(destinations: [])
  }

  /// Default log destinations when none are specified
  private var defaultDestinationIDs: [String]=[]

  /// Current minimum log level
  private var minimumLogLevel: LogLevel = .info

  /// Active log destinations by ID
  private var activeDestinations: [String: LogDestinationDTO]=[:]

  /**
   Initializes a new logging services actor.

   - Parameters:
      - providers: Provider implementations by destination type
      - commandFactory: Optional command factory to use
   */
  public init(
    providers: [LogDestinationType: LoggingProviderProtocol]=[:]
  ) {
    // Create a placeholder for the factory - will be properly initialized in postInit
    commandFactory=LogCommandDummyFactory()
    self.providers=providers

    // Complete initialization in postInit()
    Task {
      await postInit()
    }
  }

  /**
   Completes the initialization by setting up proper factories.
   This breaks the circular dependency and allows proper initialization.
   */
  private func postInit() async {
    // Create the real factory with proper dependencies
    let realFactory=LogCommandFactory(
      providers: providers,
      logger: DummyLoggingActor(),
      loggingServicesActor: self
    )

    // Now we can safely assign the real factory since we're in an actor-isolated context
    commandFactory=realFactory
  }

  /**
   Configures the actor after initialization to avoid circular references.

   This method must be called immediately after creating the actor.
   */
  public func configure() async {
    // Create the real command factory now that the actor is fully initialized
    let realFactory=LogCommandFactory(
      providers: providers,
      logger: DummyLoggingActor(),
      loggingServicesActor: self
    )

    // Replace the dummy factory using the new configure method
    configure(commandFactory: realFactory)
  }

  /// Configure this actor with a new command factory.
  /// This method replaces the command factory with a new one, allowing
  /// dependencies to be properly initialized.
  /// - Parameter newFactory: The new command factory
  func configure(commandFactory newFactory: LogCommandFactory) {
    // Now that commandFactory is a var, we can directly assign the new value
    commandFactory=newFactory
  }

  // MARK: - PrivacyAwareLoggingProtocol Methods

  /**
   Logs a message with standard privacy controls.

   - Parameters:
      - level: The log level
      - message: The message to log
      - context: The logging context
   */
  public func log(
    _ level: LogLevel,
    _ message: String,
    context: any LogContextDTO
  ) async {
    // Skip if below minimum level
    if level.rawValue < minimumLogLevel.rawValue {
      return
    }

    // Create a log entry with the provided information
    let entry=LogEntryDTO(
      level: level,
      message: message,
      category: context.category,
      metadata: context.metadata,
      source: context.source ?? ""
    )

    // Log to all active destinations
    for (_, destination) in activeDestinations {
      if destination.isEnabled && level.rawValue >= destination.minimumLevel.rawValue {
        // Get provider for this destination type
        guard let provider=providers[destination.type] else {
          continue
        }

        do {
          // Use nonisolated version to avoid data races
          let localProvider=provider

          // Write log entry to destination using the provider
          // Note: writeLogEntry is defined in the protocol extension as a default implementation
          _=try await localProvider.writeLogEntry(entry: entry, to: destination)
        } catch {
          // Silently ignore provider errors for now
          // In a real implementation, we'd want to handle these more gracefully
          print("Error writing log entry: \(error.localizedDescription)")
        }
      }
    }
  }

  /**
   Logs a privacy-annotated message with context.

   - Parameters:
      - level: The log level
      - message: The privacy-annotated message
      - context: The logging context
   */
  public func log(
    _ level: LogLevel,
    _ message: PrivacyString,
    context: any LogContextDTO
  ) async {
    // Create enhanced metadata with privacy annotations
    var enrichedMetadata=context.metadata

    // Add privacy annotation
    enrichedMetadata=enrichedMetadata.withPrivate(
      key: "__privacy_annotation",
      value: String(describing: message.privacy)
    )

    // Create a context with the enhanced metadata
    let privacyContext=BaseLogContextDTO(
      domainName: context.domainName,
      operation: context.operation,
      category: context.category,
      source: context.source,
      metadata: enrichedMetadata,
      correlationID: context.correlationID
    )

    // Log the message using the standard log method
    await log(level, message.content, context: privacyContext)
  }

  /**
   Logs a message with string value.

   - Parameters:
      - level: The log level
      - message: The message string
      - context: The logging context
   */
  public func logString(_ level: LogLevel, _ message: String, context: any LogContextDTO) async {
    // Convert to privacy string and use privacy-aware logging
    let privacyString=PrivacyString(stringLiteral: message)
    await log(level, privacyString, context: context)
  }

  /**
   Logs a message with privacy annotations function.

   - Parameters:
      - level: The log level
      - privacyScope: Function that returns a privacy-annotated string
      - context: The logging context
   */
  public func logPrivacy(
    _ level: LogLevel,
    _ privacyScope: () -> PrivacyAnnotatedString,
    context: any LogContextDTO
  ) async {
    let annotatedString=privacyScope()
    await log(level, PrivacyString(stringLiteral: annotatedString.stringValue), context: context)
  }

  /**
   Logs sensitive data with appropriate privacy controls.

   - Parameters:
      - level: The log level
      - message: The base message
      - sensitiveValues: Additional sensitive values to log
      - context: The logging context
   */
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    context: any LogContextDTO
  ) async {
    // Create a metadata collection with sensitive values
    var metadataCollection=context.metadata

    // Process each key-value pair from the metadata dictionary
    for key in sensitiveValues.asDictionary.keys {
      if let value=sensitiveValues[key] {
        metadataCollection=metadataCollection.withSensitive(key: key, value: value)
      }
    }

    // Create a sensitive context with the updated metadata
    let sensitiveContext=BaseLogContextDTO(
      domainName: context.domainName,
      operation: context.operation,
      category: context.category,
      source: context.source,
      metadata: metadataCollection,
      correlationID: context.correlationID
    )

    // Log the message with the sensitive context
    await logString(level, message, context: sensitiveContext)
  }

  /**
   Logs an error with appropriate privacy handling.

   - Parameters:
      - error: The error to log
      - privacyLevel: The privacy level to use
      - context: The logging context
   */
  public func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    context: any LogContextDTO
  ) async {
    // Create a metadata collection from the context
    var metadataCollection=context.metadata

    // Add error information to metadata with appropriate privacy level
    switch privacyLevel {
      case .public:
        metadataCollection=metadataCollection.withPublic(
          key: "error_description",
          value: error.localizedDescription
        )
      case .private:
        metadataCollection=metadataCollection.withPrivate(
          key: "error_description",
          value: error.localizedDescription
        )
      case .sensitive:
        metadataCollection=metadataCollection.withSensitive(
          key: "error_description",
          value: error.localizedDescription
        )
      case .hash:
        metadataCollection=metadataCollection.withHashed(
          key: "error_description",
          value: error.localizedDescription
        )
      case .auto:
        metadataCollection=metadataCollection.withAuto(
          key: "error_description",
          value: error.localizedDescription
        )
    }

    // Create an enhanced context with the error information
    let errorContext=BaseLogContextDTO(
      domainName: context.domainName,
      operation: context.operation,
      category: context.category,
      source: context.source,
      metadata: metadataCollection,
      correlationID: context.correlationID
    )

    // Log the error
    await logString(.error, "Error: \(error.localizedDescription)", context: errorContext)
  }

  /**
   Implementation of the original version of logError to maintain compatibility.
   */
  public func logError(
    _ error: Error,
    level _: LogLevel = .error,
    context: any LogContextDTO,
    privacyLevel: LogPrivacyLevel = .private
  ) async {
    await logError(error, privacyLevel: privacyLevel, context: context)
  }

  /**
   Adds a log destination.

   - Parameters:
      - destination: The destination to add
      - options: Options for adding the destination
   - Returns: Whether the operation was successful
   - Throws: LoggingError if the operation fails
   */
  public func addDestination(
    _ destination: LogDestinationDTO,
    options _: LoggingInterfaces.AddDestinationOptionsDTO = .default
  ) async throws -> Bool {
    // Simple implementation during refactoring
    activeDestinations[destination.id]=destination

    // Add to default destinations if this is the first one
    if defaultDestinationIDs.isEmpty {
      defaultDestinationIDs.append(destination.id)
    }

    return true
  }

  /**
   Removes a log destination.

   - Parameters:
      - destinationId: The ID of the destination to remove
      - options: Options for removing the destination
   - Returns: Whether the operation was successful
   - Throws: LoggingError if the operation fails
   */
  public func removeDestination(
    withID destinationID: String,
    options _: LoggingInterfaces.RemoveDestinationOptionsDTO = .default
  ) async throws -> Bool {
    activeDestinations.removeValue(forKey: destinationID)
    defaultDestinationIDs.removeAll { $0 == destinationID }
    return true
  }

  /**
   Updates the minimum log level.

   - Parameters:
      - level: The new minimum log level
   */
  public func setMinimumLogLevel(_ level: LogLevel) async {
    minimumLogLevel=level
  }

  /**
   Gets the current minimum log level.

   - Returns: The current minimum log level
   */
  public func getMinimumLogLevel() async -> LogLevel {
    minimumLogLevel
  }

  /**
   Sets the default destinations to write to when none are specified.

   - Parameters:
      - destinationIds: The IDs of the destinations to use by default
   */
  public func setDefaultDestinations(_ destinationIDs: [String]) async {
    defaultDestinationIDs=destinationIDs
  }

  /**
   Gets the current default destinations.

   - Returns: The IDs of the current default destinations
   */
  public func getDefaultDestinations() async -> [String] {
    defaultDestinationIDs
  }

  /**
   Gets all active log destinations.

   - Returns: All active log destinations
   */
  public func getActiveDestinations() async -> [LogDestinationDTO] {
    Array(activeDestinations.values)
  }

  /**
   Writes a log entry to specific destinations.

   - Parameters:
      - entry: The log entry to write
      - destinationIds: The destination IDs to write to
   - Returns: The results of the write operations
   - Throws: LoggingError if an error occurs
   */
  public func writeLogEntry(
    entry _: LogEntryDTO,
    destinationIDs: [String]
  ) async throws -> [LogWriteResultDTO] {
    var results: [LogWriteResultDTO]=[]

    for destinationID in destinationIDs {
      // Simply record success for each destination during refactoring
      let result=LogWriteResultDTO.success(destinationID: destinationID)
      results.append(result)
    }

    return results
  }

  /**
   Gets a log destination by ID.

   - Parameter id: The destination ID
   - Returns: The destination if found
   */
  public func getDestination(id: String) -> LogDestinationDTO? {
    activeDestinations[id]
  }

  /**
   Gets all registered log destinations.

   - Returns: An array of all destinations
   */
  public func getAllDestinations() -> [LogDestinationDTO] {
    Array(activeDestinations.values)
  }

  /**
   Validates a log destination configuration.

   - Parameters:
      - destination: The destination to validate
      - provider: The provider to use for validation
   - Returns: Validation result
   */
  public func validateDestination(
    _ destination: LogDestinationDTO,
    for _: any LoggingProviderProtocol
  ) -> LogDestinationValidationResultDTO {
    // Basic validation
    if destination.id.isEmpty {
      return LogDestinationValidationResultDTO(
        isValid: false,
        errors: ["Destination ID cannot be empty"]
      )
    }

    // Additional provider-specific validation could be added here

    return LogDestinationValidationResultDTO(isValid: true, errors: [])
  }

  /**
   Apply filter rules to a log entry.

   - Parameters:
      - entry: The log entry to filter
      - rules: The filter rules to apply
   - Returns: Whether the entry should be logged
   */
  public func applyFilterRules(
    to entry: LogEntryDTO,
    rules: [UmbraLogFilterRuleDTO]
  ) -> Bool {
    // If no rules, allow all entries
    if rules.isEmpty {
      return true
    }

    // Check each rule
    for rule in rules {
      if checkRuleMatch(entry: entry, rule: rule) {
        return rule.action == .include
      }
    }

    // Default behavior depends on rule types
    let hasIncludeRules=rules.contains { $0.action == .include }
    return !hasIncludeRules // If we have include rules and none matched, exclude by default
  }

  /**
   Checks if a log filter rule matches a log entry.

   - Parameters:
      - entry: The log entry to check
      - rule: The rule to apply
   - Returns: Whether the rule matches
   */
  private func checkRuleMatch(entry: LogEntryDTO, rule: UmbraLogFilterRuleDTO) -> Bool {
    // Level match
    if let level=rule.criteria.level, String(level.rawValue) != String(entry.level.rawValue) {
      return false
    }

    // Source match
    if let source=rule.criteria.source, source != entry.source {
      return false
    }

    // Message content match
    if let messagePattern=rule.criteria.messageContains, !entry.message.contains(messagePattern) {
      return false
    }

    // Metadata key existence check
    if let key=rule.criteria.hasMetadataKey {
      if entry.metadata == nil || entry.metadata?.getString(key: key) == nil {
        return false
      }
    }

    // Metadata key-value match
    if let key=rule.criteria.metadataKey, let value=rule.criteria.metadataValue {
      if entry.metadata == nil || entry.metadata?.getString(key: key) != value {
        return false
      }
    }

    // All checks passed
    return true
  }

  /// Update the switch statement to be exhaustive for log privacy levels
  func mapPrivacyLevel(_ privacyLevel: LogPrivacyLevel) -> PrivacyClassification {
    switch privacyLevel {
      case .public:
        return .public
      case .private:
        return .private
      case .sensitive:
        return .sensitive
      case .hash:
        return .hash
      case .auto:
        return .auto
      @unknown default:
        return .public
    }
  }

  /**
   Get a provider for a specific destination type.

   - Parameter type: The destination type
   - Returns: The provider, or nil if none is available
   */
  public func getProvider(for type: LogDestinationType) -> LoggingProviderProtocol? {
    providers[type]
  }
}
