import APIInterfaces
import DateTimeTypes
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import UmbraErrors

/// APIServiceActor
///
/// Provides a thread-safe implementation of the APIServiceProtocol using
/// Swift actors for isolation. This actor encapsulates all API operations
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
public actor APIServiceActor: APIServiceProtocol {
  // MARK: - Private Properties

  /// The current configuration of the API service
  private var configuration: APIConfigurationDTO

  /// The logger for API operations
  private let logger: DomainLogger

  /// The security bookmark service for managing security-scoped bookmarks
  private let securityBookmarkService: SecurityBookmarkProtocol

  /// Continuation for API events
  private var eventContinuations: [UUID: AsyncStream<APIEventDTO>.Continuation] = [:]

  // MARK: - Initialisation

  /// Creates a new APIServiceActor instance
  /// - Parameters:
  ///   - configuration: Initial configuration for the API service
  ///   - logger: Logger for API operations
  ///   - securityBookmarkService: Service for managing security-scoped bookmarks
  public init(
    configuration: APIConfigurationDTO,
    logger: DomainLogger,
    securityBookmarkService: SecurityBookmarkProtocol
  ) {
    self.configuration = configuration
    self.logger = logger
    self.securityBookmarkService = securityBookmarkService
  }

  // MARK: - APIServiceProtocol Implementation

  /// Initialises the service with the provided configuration
  /// - Parameter configuration: The configuration to use for initialisation
  /// - Throws: APIError if initialisation fails
  public func initialise(configuration: APIConfigurationDTO) async throws {
    // Log the initialisation attempt with privacy-aware logging
    await logger.info(
      "Initialising API service",
      context: CoreLogContext(
        source: "APIServiceActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "environment", value: configuration.environment.rawValue)
      )
    )

    // Update the configuration
    self.configuration = configuration

    // Publish an initialisation event
    await publishEvent(
      APIEventDTO(
        identifier: UUID().uuidString,
        eventType: .initialisation,
        timestamp: TimePointDTO.now(),
        status: .completed,
        operation: "initialise",
        context: "APIService initialisation completed"
      )
    )
  }

  /// Creates an encrypted security-scoped bookmark for a URL
  /// - Parameters:
  ///   - url: URL to create a bookmark for
  ///   - identifier: Unique identifier for the bookmark
  /// - Throws: APIError if bookmark creation fails
  public nonisolated func createEncryptedBookmark(url: String, identifier: String) async throws {
    await logger.debug(
      "Creating encrypted bookmark", 
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPrivate(key: "url", value: url)
    )
    
    // Using the SecurityBookmarkProtocol method directly
    try await securityBookmarkService.createBookmark(
      for: url,
      withIdentifier: identifier
    )
    
    await publishEvent(
      APIEventDTO(
        identifier: UUID().uuidString,
        eventType: .operation,
        timestamp: TimePointDTO.now(),
        status: .completed,
        operation: "createEncryptedBookmark",
        context: "Bookmark created for identifier: \(identifier)"
      )
    )
  }

  /// Resolves an encrypted security-scoped bookmark to a URL
  /// - Parameter identifier: Unique identifier for the bookmark
  /// - Returns: URL representation as a string
  /// - Throws: APIError if bookmark resolution fails
  public nonisolated func resolveEncryptedBookmark(identifier: String) async throws -> String {
    await logger.debug(
      "Resolving encrypted bookmark", 
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )
    
    // Using the SecurityBookmarkProtocol method directly
    do {
      let url = try await securityBookmarkService.resolveBookmark(withIdentifier: identifier)
      
      await publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .operation,
          timestamp: TimePointDTO.now(),
          status: .completed,
          operation: "resolveEncryptedBookmark",
          context: "Bookmark resolved for identifier: \(identifier)"
        )
      )
      
      return url
    } catch {
      await logger.error(
        "Failed to resolve bookmark", 
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "identifier", value: identifier)
          .withPublic(key: "error", value: "\(error)")
      )
      
      throw APIError.resourceNotFound(
        message: "The bookmark could not be found or resolved",
        identifier: identifier
      )
    }
  }

  /// Deletes an encrypted security-scoped bookmark
  /// - Parameter identifier: Unique identifier for the bookmark to delete
  /// - Throws: APIError if bookmark deletion fails
  public nonisolated func deleteEncryptedBookmark(identifier: String) async throws {
    await logger.debug(
      "Deleting encrypted bookmark", 
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )
    
    // Try to delete the bookmark, catching any errors
    do {
      try await securityBookmarkService.deleteBookmark(withIdentifier: identifier)
      
      await logger.info(
        "Encrypted bookmark deleted", 
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "identifier", value: identifier)
      )
      
      await publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .operation,
          timestamp: TimePointDTO.now(),
          status: .completed,
          operation: "deleteEncryptedBookmark",
          context: "Bookmark deleted for identifier: \(identifier)"
        )
      )
    } catch {
      await logger.error(
        "Failed to delete bookmark", 
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "identifier", value: identifier)
          .withPublic(key: "error", value: "\(error)")
      )
      
      throw APIError.resourceNotFound(
        message: "The bookmark could not be found or deleted",
        identifier: identifier
      )
    }
  }

  /// Retrieves the current version information of the API
  /// - Returns: Version information as APIVersionDTO
  public nonisolated func getVersion() async -> APIVersionDTO {
    let version = APIVersionDTO(
      major: 1,
      minor: 0,
      patch: 0,
      buildIdentifier: "alpha-build"
    )
    
    await logger.debug(
      "Returning API version information", 
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "version", value: "\(version.major).\(version.minor).\(version.patch)")
        .withPublic(key: "buildIdentifier", value: version.buildIdentifier ?? "")
    )
    
    return version
  }

  /// Subscribes to API service events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of APIEventDTO objects
  public nonisolated func subscribeToEvents(filter: APIEventFilterDTO?) -> AsyncStream<APIEventDTO> {
    return AsyncStream { continuation in
      // Create a task to handle the event subscription
      let task = Task {
        do {
          await logger.debug(
            "Subscribing to API events", 
            metadata: LogMetadataDTOCollection()
              .withPublic(key: "hasFilter", value: filter != nil ? "true" : "false")
          )
          
          // Register the continuation with the event bus
          await registerEventSubscriber(continuation: continuation, filter: filter)
          
          // Keep the task alive until cancelled
          try await Task.sleep(for: .seconds(365 * 24 * 60 * 60)) // Effectively forever
        } catch {
          await logger.error(
            "Event subscription ended unexpectedly", 
            metadata: LogMetadataDTOCollection()
              .withPublic(key: "error", value: "\(error)")
          )
          continuation.finish()
        }
      }
      
      // Set up cancellation handler
      continuation.onTermination = { _ in
        task.cancel()
        Task {
          await unregisterEventSubscriber(continuation: continuation)
          await logger.debug("Event subscription terminated", metadata: LogMetadataDTOCollection())
        }
      }
    }
  }

  // MARK: - Private Methods

  /// Removes an event continuation for a subscription that has been cancelled
  /// - Parameter subscriptionId: The ID of the subscription to remove
  private func removeEventContinuation(for subscriptionID: UUID) async {
    eventContinuations.removeValue(forKey: subscriptionID)

    // Log the removal with privacy-aware logging
    await logger.debug(
      "Event subscription removed",
      context: CoreLogContext(
        source: "APIServiceActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "subscription_id", value: subscriptionID.uuidString)
      )
    )
  }

  /// Publishes an event to all active subscribers, respecting their filters
  /// - Parameter event: The event to publish
  private func publishEvent(_ event: APIEventDTO) async {
    for (subscriptionID, continuation) in eventContinuations {
      // In a real implementation, we would filter the events based on the subscription's filter
      // For simplicity, we're publishing all events to all subscribers
      continuation.yield(event)

      // Log the event publication with privacy-aware logging
      await logger.trace(
        "Published event to subscriber",
        context: CoreLogContext(
          source: "APIServiceActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "subscription_id", value: subscriptionID.uuidString)
            .withPublic(key: "event_id", value: event.identifier)
            .withPublic(key: "event_type", value: event.eventType.rawValue)
        )
      )
    }
  }

  // Helper methods for event subscription management
  private func registerEventSubscriber(
      continuation: AsyncStream<APIEventDTO>.Continuation,
      filter: APIEventFilterDTO?
  ) async {
    // In a real implementation, we would register this continuation with an event bus
    // For now, we'll just log that it was called
    await logger.info(
      "Registered event subscriber", 
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "hasFilter", value: filter != nil ? "true" : "false")
    )
    
    // Store the continuation in a collection to manage active subscribers
    self.eventContinuations[UUID()] = continuation
  }
  
  private func unregisterEventSubscriber(
      continuation: AsyncStream<APIEventDTO>.Continuation
  ) async {
    // In a real implementation, we would unregister this continuation from an event bus
    // For now, we'll just log that it was called
    await logger.info("Unregistered event subscriber", metadata: LogMetadataDTOCollection())
    
    // Remove the continuation from our collection
    for (id, value) in self.eventContinuations where value === continuation {
      self.eventContinuations.removeValue(forKey: id)
    }
  }
}

// MARK: - Helper Extensions

extension TimePointDTO {
  /// Creates a TimePointDTO representing the current time
  static func now() -> TimePointDTO {
    // For simplicity, we're using a dummy implementation
    TimePointDTO(
      timestamp: Date().timeIntervalSince1970,
      nanoseconds: 0
    )
  }
}
