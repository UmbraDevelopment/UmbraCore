import CoreInterfaces
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/// CoreServiceActor
///
/// Provides a thread-safe implementation of the CoreServiceProtocol using
/// Swift actors for isolation. This actor encapsulates all core framework operations
/// and manages state in a thread-safe manner.
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
public actor CoreServiceActor: CoreServiceProtocol {
  // MARK: - Private Properties

  /// The current configuration of the core framework
  private var configuration: CoreConfigurationDTO

  /// Flag indicating whether the framework has been initialised
  private var initialised: Bool = false

  /// The current operational status of the framework
  private var operationalStatus: CoreOperationalStatus = .stopped

  /// The list of active services
  private var activeServicesList: [String] = []

  /// The logger for core operations
  private let logger: DomainLogger

  /// Dependency service registry
  private var serviceRegistry: [String: Any] = [:]

  /// Continuation for core events
  private var eventContinuations: [UUID: AsyncStream<CoreEventDTO>.Continuation] = [:]

  // MARK: - Initialisation

  /// Creates a new CoreServiceActor instance
  /// - Parameters:
  ///   - configuration: Initial configuration for the core framework
  ///   - logger: Logger for core operations
  public init(
    configuration: CoreConfigurationDTO,
    logger: DomainLogger
  ) {
    self.configuration = configuration
    self.logger = logger
    
    Task {
      await self.logInitialisation()
    }
  }
  
  /// Log the initialisation of the CoreServiceActor
  private func logInitialisation() async {
    let context = CoreLogContext.initialisation(
      source: "CoreServiceActor.init",
      metadata: {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "version", value: configuration.version)
        return metadata
      }()
    )
    
    await logger.info("Core service actor initialised", context: context)
  }

  // MARK: - Core Lifecycle Methods

  /// Start the core framework
  /// - Parameters:
  ///   - options: Optional startup options
  /// - Returns: Operational status after startup attempt
  public func start(options: CoreStartupOptionsDTO?) async -> CoreOperationalStatus {
    let context = CoreLogContext.initialisation(
      source: "CoreServiceActor.start",
      metadata: {
        var metadata = LogMetadataDTOCollection()
        if let environmentName = options?.environmentName {
          metadata = metadata.withPublic(key: "environment", value: environmentName)
        }
        metadata = metadata.withPublic(key: "previousState", value: operationalStatus.rawValue)
        return metadata
      }()
    )
    
    await logger.info("Starting core framework", context: context)

    if !initialised {
      do {
        try await initialise()
      } catch {
        await logger.error(
          error,
          context: context,
          privacyLevel: .private
        )
        return .error
      }
    }

    // Update operational status
    operationalStatus = .running
    
    await logger.info(
      "Core framework started successfully", 
      context: context
    )
    
    // Notify all subscribers
    broadcastEvent(CoreEventDTO(
      type: .statusChanged,
      data: ["status": operationalStatus.rawValue]
    ))
    
    return operationalStatus
  }

  /// Stop the core framework
  /// - Returns: Operational status after shutdown attempt
  public func stop() async -> CoreOperationalStatus {
    let context = CoreLogContext.initialisation(
      source: "CoreServiceActor.stop",
      metadata: {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "previousState", value: operationalStatus.rawValue)
        return metadata
      }()
    )
    
    await logger.info("Stopping core framework", context: context)
    
    // Notify subscribers before shutdown
    broadcastEvent(CoreEventDTO(
      type: .willShutdown,
      data: ["timestamp": String(Int(Date().timeIntervalSince1970))]
    ))
    
    // Update operational status
    operationalStatus = .stopped
    
    // Clear all subscriptions
    for (id, continuation) in eventContinuations {
      continuation.finish()
      eventContinuations.removeValue(forKey: id)
    }
    
    await logger.info(
      "Core framework stopped successfully", 
      context: context
    )
    
    return operationalStatus
  }

  /// Subscribe to core events
  /// - Parameter filter: Optional filter for events
  /// - Returns: Async stream of core events
  public func subscribeToEvents(filter: CoreEventFilterDTO?) -> AsyncStream<CoreEventDTO> {
    // Generate a unique identifier for this subscription
    let subscriptionID = UUID()
    
    let context = CoreLogContext(
      source: "CoreServiceActor.subscribeToEvents",
      metadata: {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "subscriptionID", value: subscriptionID.uuidString)
        if let filter = filter {
          metadata = metadata.withPublic(key: "filterType", value: filter.eventType?.rawValue ?? "all")
        }
        return metadata
      }()
    )

    Task {
      await logger.debug("New event subscription registered", context: context)
    }

    return AsyncStream { continuation in
      // Store the continuation for later event broadcasting
      eventContinuations[subscriptionID] = continuation
      
      // Set up cancellation handler
      continuation.onTermination = { [weak self] _ in
        Task { [weak self] in
          guard let self = self else { return }
          await self.removeEventContinuation(for: subscriptionID)
        }
      }
    }
  }

  // MARK: - Private Methods

  /// Broadcast an event to all subscribers
  /// - Parameter event: The event to broadcast
  private func broadcastEvent(_ event: CoreEventDTO) {
    for (_, continuation) in eventContinuations {
      continuation.yield(event)
    }
  }
  
  /// Remove an event subscription when it's cancelled
  /// - Parameter subscriptionID: The ID of the subscription to remove
  private func removeEventContinuation(for subscriptionID: UUID) {
    eventContinuations.removeValue(forKey: subscriptionID)

    // Log the removal with privacy-aware logging
    Task {
      let context = CoreLogContext(
        source: "CoreServiceActor.removeEventContinuation",
        metadata: {
          var metadata = LogMetadataDTOCollection()
          metadata = metadata.withPublic(key: "subscriptionID", value: subscriptionID.uuidString)
          metadata = metadata.withPublic(key: "activeSubscriptions", value: String(eventContinuations.count))
          return metadata
        }()
      )
      
      await logger.debug("Event subscription removed", context: context)
    }
  }
  
  /// Initialise the core framework
  /// - Throws: Core framework initialisation errors
  private func initialise() async throws {
    let context = CoreLogContext.initialisation(
      source: "CoreServiceActor.initialise"
    )
    
    await logger.info("Initialising core framework", context: context)
    
    guard !initialised else {
      await logger.warning(
        "Core framework already initialised", 
        context: context
      )
      return
    }
    
    do {
      // Initialize critical subsystems here
      // ...
      
      initialised = true
      
      await logger.info(
        "Core framework initialised successfully", 
        context: context
      )
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to initialise core framework",
        details: "Initialisation failed during startup sequence"
      )
      
      await logger.critical(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw CoreError.initialisation(
        message: "Failed to initialise core framework: \(error.localizedDescription)"
      )
    }
  }
} // End of CoreServiceActor

// MARK: - Helper Extensions

extension TimePointDTO {
  /// Convert to a human-readable string
  func toHumanReadableString() -> String {
    // Format the time point in a standardised format
    return "\(year)-\(month)-\(day) \(hour):\(minute):\(second)"
  }
}
