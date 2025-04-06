import CoreInterfaces
import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Core Service Implementation

 This actor is the central implementation of the CoreServiceProtocol,
 providing access to all core services throughout the application.

 ## Architecture

 - Follows the singleton pattern to ensure a single point of service access
 - Uses dependency injection via a service container
 - Implements the façade pattern to simplify access to subsystems
 - Uses adapters to isolate core components from implementation details
 - Ensures thread safety through the actor concurrency model
 */
public actor CoreServiceImpl: CoreServiceProtocol {
  // MARK: - Properties

  /**
   Shared instance of the core service

   This follows the singleton pattern to ensure there is only one instance
   of the core service throughout the application.
   */
  public static let shared = CoreServiceImpl()

  /**
   Container for resolving service dependencies

   This container manages registration and resolution of all services,
   facilitating dependency injection throughout the application.
   */
  public nonisolated let container: ServiceContainerProtocol

  /**
   Flag indicating if the service has been initialised

   Used to prevent multiple initialisation attempts.
   */
  private var isInitialised = false
  
  /**
   Current operational status of the service
   */
  private var operationalStatus: CoreOperationalStatus = .stopped
  
  /**
   Domain-specific logger for core operations
   */
  private let logger: DomainLogger
  
  /**
   Event continuations for subscribers
   */
  private var eventContinuations: [UUID: AsyncStream<CoreEventDTO>.Continuation] = [:]

  // MARK: - Initialisation

  /**
   Private initialiser to enforce singleton pattern

   Creates a new core service with a default service container.
   */
  private init() {
    container = ServiceContainerImpl()
    
    // Create a domain logger for core services
    // In a real implementation, this would be injected via DI
    logger = LoggerFactory.createCoreLogger(source: "CoreServiceImpl")
    
    Task {
      await logInitialisation()
    }
  }
  
  /**
   Log the initialisation of the service
   */
  private func logInitialisation() async {
    let context = createLogContext(source: "CoreServiceImpl.init")
    
    await logger.info("Core service singleton initialised", context: context)
  }

  /**
   Initialises all core services

   Performs necessary setup and initialisation of all managed services,
   ensuring they are ready for use.

   - Throws: CoreError if initialisation fails for any required service
   */
  public func initialise() async throws {
    let context = createLogContext(source: "CoreServiceImpl.initialise")
    
    // Prevent multiple initialisation
    guard !isInitialised else {
      await logger.warning("Core service already initialised", context: context)
      return
    }
    
    await logger.info("Initialising core services", context: context)

    do {
      // Initialise critical services
      try await initialiseSecurityServices()
      try await initialiseCryptoServices()

      // Mark as initialised
      isInitialised = true
      operationalStatus = .running
      
      await logger.info("Core services initialised successfully", context: context)
      
      // Broadcast event to subscribers
      broadcastEvent(CoreEventDTO(
        type: .statusChanged,
        data: ["status": operationalStatus.rawValue]
      ))
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to initialise core services",
        details: "Error occurred during core services initialisation sequence"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw CoreError.initialisation(
        message: "Failed to initialise core services: \(error.localizedDescription)"
      )
    }
  }

  /**
   Initialises security-related services

   - Throws: CoreError if initialisation fails
   */
  private func initialiseSecurityServices() async throws {
    let context = createSecurityLogContext(source: "CoreServiceImpl.initialiseSecurityServices")
    
    await logger.debug("Initialising security services", context: context)
    
    // Services are initialised on demand in this implementation
    
    await logger.debug("Security services initialisation complete", context: context)
  }

  /**
   Initialises cryptography-related services

   - Throws: CoreError if initialisation fails
   */
  private func initialiseCryptoServices() async throws {
    let context = createCryptoLogContext(source: "CoreServiceImpl.initialiseCryptoServices")
    
    await logger.debug("Initialising cryptography services", context: context)
    
    // Services are initialised on demand in this implementation
    
    await logger.debug("Cryptography services initialisation complete", context: context)
  }
  
  // MARK: - CoreServiceProtocol Implementation
  
  /**
   Start the core framework
   
   - Parameters:
     - options: Optional startup options
   - Returns: Operational status after startup
   */
  public func start(options: CoreStartupOptionsDTO?) async -> CoreOperationalStatus {
    let context = createLogContext(source: "CoreServiceImpl.start")
    
    await logger.info("Starting core services", context: context)
    
    if !isInitialised {
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
    
    operationalStatus = .running
    
    await logger.info("Core services started successfully", context: context)
    
    // Notify all subscribers
    broadcastEvent(CoreEventDTO(
      type: .statusChanged,
      data: ["status": operationalStatus.rawValue]
    ))
    
    return operationalStatus
  }
  
  /**
   Stop the core framework
   
   - Returns: Operational status after shutdown
   */
  public func stop() async -> CoreOperationalStatus {
    let context = createLogContext(source: "CoreServiceImpl.stop")
    
    await logger.info("Stopping core services", context: context)
    
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
    
    await logger.info("Core services stopped successfully", context: context)
    
    return operationalStatus
  }
  
  /**
   Subscribe to core events
   
   - Parameter filter: Optional filter for events
   - Returns: Async stream of events
   */
  public func subscribeToEvents(filter: CoreEventFilterDTO?) -> AsyncStream<CoreEventDTO> {
    // Generate a unique identifier for this subscription
    let subscriptionID = UUID()
    
    let context = createLogContext(source: "CoreServiceImpl.subscribeToEvents")
    
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
  
  /**
   Broadcast an event to all subscribers
   
   - Parameter event: The event to broadcast
   */
  private func broadcastEvent(_ event: CoreEventDTO) {
    for (_, continuation) in eventContinuations {
      continuation.yield(event)
    }
  }
  
  /**
   Remove an event subscription when it's cancelled
   
   - Parameter subscriptionID: The ID of the subscription to remove
   */
  private func removeEventContinuation(for subscriptionID: UUID) {
    eventContinuations.removeValue(forKey: subscriptionID)
    
    Task {
      let context = createLogContext(source: "CoreServiceImpl.removeEventContinuation")
      
      await logger.debug("Event subscription removed", context: context)
    }
  }
  
  private func createLogContext(source: String) -> CoreLogContext {
    let metadata = {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "component", value: "CoreService")
        return metadata
    }()
    
    return CoreLogContext(
        source: source,
        metadata: metadata
    )
  }
  
  private func createSecurityLogContext(source: String) -> CoreLogContext {
    let metadata = {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "component", value: "SecurityServices")
        return metadata
    }()
    
    return CoreLogContext(
        source: source,
        metadata: metadata
    )
  }
  
  private func createCryptoLogContext(source: String) -> CoreLogContext {
    let metadata = {
        var metadata = LogMetadataDTOCollection()
        metadata = metadata.withPublic(key: "component", value: "CryptoServices")
        return metadata
    }()
    
    return CoreLogContext(
        source: source,
        metadata: metadata
    )
  }
}

// MARK: - Error Definitions

/**
 Domain-specific errors for the Core Service
 
 These errors follow the privacy-aware logging pattern and provide
 detailed information about failure scenarios.
 */
public enum CoreError: Error, Sendable {
  /// Initialisation of a core service failed
  case initialisation(message: String)

  /// A requested service is not available
  case serviceNotAvailable(serviceName: String)
  
  /// An operation failed due to the service being in the wrong state
  case invalidState(message: String, currentState: CoreOperationalStatus)
}

// MARK: - CoreError Extensions

extension CoreError: LoggableError {
  public var loggableDescription: String {
    switch self {
    case .initialisation(let message):
      return "Core initialisation failed: \(message)"
    case .serviceNotAvailable(let serviceName):
      return "Service not available: \(serviceName)"
    case .invalidState(let message, let currentState):
      return "Invalid state: \(message) (current: \(currentState.rawValue))"
    }
  }
  
  public var privacyClassification: PrivacyClassification {
    // Most core errors are safe to log publicly
    switch self {
    case .initialisation:
      return .private  // May contain sensitive path information
    case .serviceNotAvailable:
      return .public
    case .invalidState:
      return .public
    }
  }
  
  public var errorCode: String {
    switch self {
    case .initialisation:
      return "CORE_INIT_FAILED"
    case .serviceNotAvailable:
      return "CORE_SERVICE_UNAVAILABLE"
    case .invalidState:
      return "CORE_INVALID_STATE"
    }
  }
  
  public var errorDomain: String {
    return "CoreServices"
  }
  
  public var errorSeverity: ErrorSeverity {
    switch self {
    case .initialisation:
      return .critical
    case .serviceNotAvailable:
      return .error
    case .invalidState:
      return .warning
    }
  }
}
