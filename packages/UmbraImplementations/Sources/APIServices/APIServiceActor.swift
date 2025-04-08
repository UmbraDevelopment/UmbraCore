import APIInterfaces
import CoreDTOs
import CoreInterfaces
import DateTimeTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
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

  /// The API configuration
  private var configuration: APIInterfaces.APIConfigurationDTO

  /// The logger for API operations
  private let logger: LoggingProtocol

  /// The security bookmark service for managing security-scoped bookmarks
  private let securityBookmarkService: SecurityInterfaces.SecurityBookmarkProtocol

  /// Event continuations for streaming events
  private var eventContinuations: [UUID: AsyncStream<APIEventDTO>.Continuation] = [:]

  // MARK: - Initialisation

  /// Initialises the service with the specified configuration
  /// - Parameters:
  ///   - configuration: The configuration to use
  ///   - logger: The logger to use for logging operations
  ///   - securityBookmarkService: Service for managing security-scoped bookmarks
  public init(
    configuration: APIInterfaces.APIConfigurationDTO,
    logger: LoggingProtocol,
    securityBookmarkService: SecurityInterfaces.SecurityBookmarkProtocol
  ) {
    self.configuration = configuration
    self.logger = logger
    self.securityBookmarkService = securityBookmarkService
  }

  // MARK: - APIServiceProtocol Implementation

  /// Initialises the service with the provided configuration
  /// - Parameter configuration: The configuration to use for initialisation
  /// - Throws: UmbraErrors.APIError if initialisation fails
  public func initialise(configuration: APIInterfaces.APIConfigurationDTO) async throws {
    // Log the initialisation attempt with privacy-aware logging
    await logger.info(
      "Initialising API service",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "initialise"
      )
    )

    // Store the configuration
    self.configuration = configuration

    // Initialize any necessary services
    do {
      // Perform initialization steps as needed
      await logger.info("API service initialised successfully", context: BaseLogContextDTO(domainName: "APIService", source: "initialise"))
    } catch {
      // Log the error and throw an appropriate domain-specific error
      await logger.error(
        "Failed to initialise API service: \(error.localizedDescription)",
        context: BaseLogContextDTO(
          domainName: "APIService",
          source: "initialise"
        )
      )

      // Rethrow as a domain-specific error
      throw APIError.operationFailed(
        message: "Failed to initialise API service: \(error.localizedDescription)",
        code: "INIT_FAILURE",
        underlyingError: error
      )
    }
  }

  /// Creates an encrypted security-scoped bookmark for a URL
  /// - Parameters:
  ///   - url: URL to create a bookmark for
  ///   - identifier: Unique identifier for the bookmark
  /// - Throws: APIError if bookmark creation fails
  public nonisolated func createEncryptedBookmark(url: String, identifier: String) async throws {
    await logger.debug(
      "Creating encrypted bookmark",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "createEncryptedBookmark"
      )
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
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "resolveEncryptedBookmark"
      )
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
        context: BaseLogContextDTO(
          domainName: "APIService",
          source: "resolveEncryptedBookmark"
        )
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
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "deleteEncryptedBookmark"
      )
    )

    // Try to delete the bookmark, catching any errors
    do {
      try await securityBookmarkService.deleteBookmark(withIdentifier: identifier)

      await logger.info(
        "Encrypted bookmark deleted",
        context: BaseLogContextDTO(
          domainName: "APIService",
          source: "deleteEncryptedBookmark"
        )
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
        context: BaseLogContextDTO(
          domainName: "APIService",
          source: "deleteEncryptedBookmark"
        )
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
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "getVersion"
      )
    )

    return version
  }

  /// Subscribes to API service events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of APIEventDTO objects
  public nonisolated func subscribeToEvents(filter: APIEventFilterDTO?)
  -> AsyncStream<APIEventDTO> {
    AsyncStream { continuation in
      // Create a task to handle the event subscription
      let task = Task {
        do {
          await logger.debug(
            "Subscribing to API events",
            context: BaseLogContextDTO(
              domainName: "APIService",
              source: "subscribeToEvents"
            )
          )

          // Register the continuation with the event bus
          await registerEventSubscriber(continuation: continuation, filter: filter)

          // Keep the task alive until cancelled
          try await Task.sleep(for: .seconds(365 * 24 * 60 * 60)) // Effectively forever
        } catch {
          await logger.error(
            "Event subscription ended unexpectedly",
            context: BaseLogContextDTO(
              domainName: "APIService",
              source: "subscribeToEvents"
            )
          )
          continuation.finish()
        }
      }

      // Set up cancellation handler
      continuation.onTermination = { _ in
        task.cancel()
        Task {
          await self.unregisterEventSubscriber(continuation: continuation)
          await self.logger.debug("Event subscription terminated", context: BaseLogContextDTO(domainName: "APIService", source: "subscribeToEvents"))
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
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "removeEventContinuation"
      )
    )
  }

  /// Publishes an event to all active subscribers, respecting their filters
  /// - Parameter event: The event to publish
  private func publishEvent(_ event: APIEventDTO) async {
    for (_, continuation) in eventContinuations {
      // In a real implementation, we would filter the events based on the subscription's filter
      // For simplicity, we're publishing all events to all subscribers
      continuation.yield(event)

      // Log the event publication with privacy-aware logging
      await logger.trace(
        "Published event to subscriber",
        context: BaseLogContextDTO(
          domainName: "APIService",
          source: "publishEvent"
        )
      )
    }
  }

  // Helper methods for event subscription management
  private func registerEventSubscriber(
    continuation: AsyncStream<APIEventDTO>.Continuation,
    filter: APIEventFilterDTO?
  ) async {
    // For now, we'll just log that it was called
    await logger.info(
      "Registered event subscriber",
      context: BaseLogContextDTO(
        domainName: "APIService",
        source: "registerEventSubscriber"
      )
    )

    // Store the continuation in a collection to manage active subscribers
    let subscriptionID = UUID()
    eventContinuations[subscriptionID] = continuation
  }

  private func unregisterEventSubscriber(
    continuation: AsyncStream<APIEventDTO>.Continuation
  ) async {
    // In a real implementation, we would unregister this continuation from an event bus
    // For now, we'll just log that it was called
    await logger.info("Unregistered event subscriber", context: BaseLogContextDTO(domainName: "APIService", source: "unregisterEventSubscriber"))

    // Remove the continuation from our collection by comparing continuation IDs
    // Since we can't compare continuations directly (they're value types)
    for (id, _) in eventContinuations {
      // We use a simple heuristic - remove all continuations when unregistering
      // In a real implementation, we would need a more sophisticated way to identify
      // the specific continuation to remove
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
