import APIInterfaces
import LoggingInterfaces
import SecurityCoreInterfaces
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
  private var eventContinuations: [UUID: AsyncStream<APIEventDTO>.Continuation]=[:]

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
    self.configuration=configuration
    self.logger=logger
    self.securityBookmarkService=securityBookmarkService
  }

  // MARK: - APIServiceProtocol Implementation

  /// Initialises the service with the provided configuration
  /// - Parameter configuration: The configuration to use for initialisation
  /// - Throws: UmbraErrors.APIError if initialisation fails
  public func initialise(configuration: APIConfigurationDTO) async throws {
    // Log the initialisation attempt with privacy-aware logging
    logger.info(
      "Initialising API service",
      metadata: ["environment": .public(configuration.environment.rawValue)]
    )

    // Update the configuration
    self.configuration=configuration

    // Publish an initialisation event
    publishEvent(
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

  /// Creates an encrypted security-scoped bookmark for the specified URL
  /// - Parameters:
  ///   - url: URL representation as a string
  ///   - identifier: Unique identifier for the bookmark
  /// - Throws: UmbraErrors.APIError if bookmark creation fails
  public func createEncryptedBookmark(url: String, identifier: String) async throws {
    // Log the operation with privacy-aware logging
    logger.info(
      "Creating encrypted bookmark",
      metadata: [
        "identifier": .public(identifier),
        "url": .private(url) // URL might contain sensitive path information
      ]
    )

    do {
      // Delegate to the security bookmark service
      try await securityBookmarkService.createBookmark(
        for: url,
        identifier: identifier
      )

      // Publish a success event
      publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .operation,
          timestamp: TimePointDTO.now(),
          status: .completed,
          operation: "createEncryptedBookmark",
          context: "Bookmark created for identifier: \(identifier)"
        )
      )
    } catch {
      // Log the error with privacy-aware logging
      logger.error(
        "Failed to create encrypted bookmark",
        metadata: [
          "identifier": .public(identifier),
          "error": .public(error.localizedDescription)
        ]
      )

      // Publish an error event
      publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .error,
          timestamp: TimePointDTO.now(),
          status: .failed,
          operation: "createEncryptedBookmark",
          context: "Error creating bookmark: \(error.localizedDescription)"
        )
      )

      // Map the error to an APIError
      throw UmbraErrors.APIError.operationFailed(
        message: "Failed to create encrypted bookmark",
        underlyingError: error
      )
    }
  }

  /// Resolves an encrypted security-scoped bookmark to a URL
  /// - Parameter identifier: Unique identifier for the bookmark
  /// - Returns: URL representation as a string
  /// - Throws: UmbraErrors.APIError if bookmark resolution fails
  public func resolveEncryptedBookmark(identifier: String) async throws -> String {
    // Log the operation with privacy-aware logging
    logger.info(
      "Resolving encrypted bookmark",
      metadata: ["identifier": .public(identifier)]
    )

    do {
      // Delegate to the security bookmark service
      let url=try await securityBookmarkService.resolveBookmark(
        withIdentifier: identifier
      )

      // Publish a success event
      publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .operation,
          timestamp: TimePointDTO.now(),
          status: .completed,
          operation: "resolveEncryptedBookmark",
          context: "Bookmark resolved for identifier: \(identifier)"
        )
      )

      // Return the resolved URL
      return url
    } catch {
      // Log the error with privacy-aware logging
      logger.error(
        "Failed to resolve encrypted bookmark",
        metadata: [
          "identifier": .public(identifier),
          "error": .public(error.localizedDescription)
        ]
      )

      // Publish an error event
      publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .error,
          timestamp: TimePointDTO.now(),
          status: .failed,
          operation: "resolveEncryptedBookmark",
          context: "Error resolving bookmark: \(error.localizedDescription)"
        )
      )

      // Map the error to an APIError
      throw UmbraErrors.APIError.operationFailed(
        message: "Failed to resolve encrypted bookmark",
        underlyingError: error
      )
    }
  }

  /// Deletes an encrypted security-scoped bookmark
  /// - Parameter identifier: Unique identifier for the bookmark to delete
  /// - Throws: UmbraErrors.APIError if bookmark deletion fails
  public func deleteEncryptedBookmark(identifier: String) async throws {
    // Log the operation with privacy-aware logging
    logger.info(
      "Deleting encrypted bookmark",
      metadata: ["identifier": .public(identifier)]
    )

    do {
      // Delegate to the security bookmark service
      try await securityBookmarkService.deleteBookmark(
        withIdentifier: identifier
      )

      // Publish a success event
      publishEvent(
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
      // Log the error with privacy-aware logging
      logger.error(
        "Failed to delete encrypted bookmark",
        metadata: [
          "identifier": .public(identifier),
          "error": .public(error.localizedDescription)
        ]
      )

      // Publish an error event
      publishEvent(
        APIEventDTO(
          identifier: UUID().uuidString,
          eventType: .error,
          timestamp: TimePointDTO.now(),
          status: .failed,
          operation: "deleteEncryptedBookmark",
          context: "Error deleting bookmark: \(error.localizedDescription)"
        )
      )

      // Map the error to an APIError
      throw UmbraErrors.APIError.operationFailed(
        message: "Failed to delete encrypted bookmark",
        underlyingError: error
      )
    }
  }

  /// Retrieves the current version information of the API
  /// - Returns: Version information as APIVersionDTO
  public func getVersion() async -> APIVersionDTO {
    // Log the operation with privacy-aware logging
    logger.debug(
      "Getting API version",
      metadata: ["environment": .public(configuration.environment.rawValue)]
    )

    // Return the current version (in a real implementation, this would be fetched from a
    // configuration)
    return APIVersionDTO(major: 1, minor: 0, patch: 0)
  }

  /// Subscribes to API service events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of APIEventDTO objects
  public func subscribeToEvents(filter: APIEventFilterDTO?) -> AsyncStream<APIEventDTO> {
    // Generate a unique identifier for this subscription
    let subscriptionID=UUID()

    // Log the subscription with privacy-aware logging
    logger.debug(
      "New event subscription",
      metadata: [
        "subscription_id": .public(subscriptionID.uuidString),
        "filter_types": .public(filter?.eventTypes?.map(\.rawValue)
          .joined(separator: ", ") ?? "all")
      ]
    )

    // Create an AsyncStream that will receive events
    let stream=AsyncStream<APIEventDTO> { continuation in
      // Store the continuation for publishing events
      eventContinuations[subscriptionID]=continuation

      // Set up cancellation handler to clean up when the stream is cancelled
      continuation.onTermination={ [weak self] _ in
        Task { [weak self] in
          await self?.removeEventContinuation(for: subscriptionID)
        }
      }
    }

    return stream
  }

  // MARK: - Private Methods

  /// Removes an event continuation for a subscription that has been cancelled
  /// - Parameter subscriptionId: The ID of the subscription to remove
  private func removeEventContinuation(for subscriptionID: UUID) {
    eventContinuations.removeValue(forKey: subscriptionID)

    // Log the removal with privacy-aware logging
    logger.debug(
      "Event subscription removed",
      metadata: ["subscription_id": .public(subscriptionID.uuidString)]
    )
  }

  /// Publishes an event to all active subscribers, respecting their filters
  /// - Parameter event: The event to publish
  private func publishEvent(_ event: APIEventDTO) {
    for (subscriptionID, continuation) in eventContinuations {
      // In a real implementation, we would filter the events based on the subscription's filter
      // For simplicity, we're publishing all events to all subscribers
      continuation.yield(event)

      // Log the event publication with privacy-aware logging
      logger.trace(
        "Published event to subscriber",
        metadata: [
          "subscription_id": .public(subscriptionID.uuidString),
          "event_id": .public(event.identifier),
          "event_type": .public(event.eventType.rawValue)
        ]
      )
    }
  }
}

// MARK: - Helper Extensions

extension TimePointDTO {
  /// Creates a TimePointDTO representing the current time
  static func now() -> TimePointDTO {
    // In a real implementation, this would use a proper time source
    // For simplicity, we're using a dummy implementation
    TimePointDTO(
      epochSeconds: UInt64(Date().timeIntervalSince1970),
      nanoseconds: 0
    )
  }
}
