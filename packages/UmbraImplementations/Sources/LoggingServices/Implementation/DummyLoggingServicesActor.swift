import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 A dummy implementation of LoggingServicesProtocol used only for initialization.

 This actor provides no-op implementations of all required methods to avoid
 circular references during the initialization of the real LoggingServicesActor.
 */
public actor DummyLoggingServicesActor: PrivacyAwareLoggingProtocol {
  /// Provider dictionary for logging operations
  private var providers: [LogDestinationType: LoggingProviderProtocol]

  /// Logging actor for this service
  public nonisolated var loggingActor: LoggingActor {
    LoggingActor(destinations: [])
  }

  /**
   Initialises a new dummy logging services actor.
   */
  public init(
    providers: [LogDestinationType: LoggingProviderProtocol]=[:]
  ) {
    self.providers=providers
  }

  /**
   No-op implementation for log method.
   */
  public func log(
    _: LogLevel,
    _: PrivacyString,
    context _: LogContextDTO
  ) async {
    // No-op implementation
  }

  /**
   No-op implementation for log method with string.
   */
  public func logString(
    _: LogLevel,
    _: String,
    context _: LogContextDTO
  ) async {
    // No-op implementation
  }

  /**
   No-op implementation for logging sensitive data.
   */
  public func logSensitive(
    _: LogLevel,
    _: String,
    sensitiveValues _: LoggingTypes.LogMetadata,
    context _: LogContextDTO
  ) async {
    // No-op implementation
  }

  /**
   No-op implementation for logging errors.
   */
  public func logError(
    _: Error,
    privacyLevel _: LogPrivacyLevel,
    context _: LogContextDTO
  ) async {
    // No-op implementation
  }

  /**
   No-op implementation for log method for LoggingProtocol conformance.
   */
  public func log(
    _: LogLevel,
    _: String,
    context _: LogContextDTO
  ) async {
    // No-op implementation
  }

  // Stub implementation of validateDestination for LoggingServicesProtocol conformance
  public func validateDestination(
    _: LoggingInterfaces.LogDestinationDTO,
    for _: LoggingInterfaces.LoggingProviderProtocol
  ) async -> LoggingInterfaces.LogDestinationValidationResultDTO {
    LogDestinationValidationResultDTO(
      isValid: true,
      errors: [],
      validationMessages: []
    )
  }
}
