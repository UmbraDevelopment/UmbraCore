import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Factory for creating logging services components.

 This factory provides methods for creating various logging service components
 with proper dependency injection and configuration.
 */
public enum LoggingServicesFactory {
  /**
   Creates a new logging service with the specified configuration.

   - Returns: A properly configured logging service
   */
  public static func createLoggingService() -> any PrivacyAwareLoggingProtocol {
    // During refactoring, return a no-op logger that meets the protocol requirements
    NoOpLogger()
  }

  /**
   Creates a privacy-aware logger with specific configuration.

   - Returns: A properly configured privacy-aware logger
   */
  public static func createPrivacyAwareLogger() -> any PrivacyAwareLoggingProtocol {
    // During refactoring, return a no-op logger that meets the protocol requirements
    NoOpLogger()
  }
}

/**
 Simple no-op logger implementation that satisfies the protocol requirements
 but doesn't perform any actual logging operations.
 */
private actor NoOpLogger: PrivacyAwareLoggingProtocol {
  // Required by LoggingProtocol
  public nonisolated var loggingActor: LoggingActor {
    _loggingActor
  }

  private let _loggingActor: LoggingActor = .init(destinations: [])

  // Required by PrivacyAwareLoggingProtocol
  public func log(_: LogLevel, _: PrivacyString, context _: any LogContextDTO) async {
    // No-op implementation
  }

  public func log(_: LogLevel, _: String, context _: any LogContextDTO) async {
    // No-op implementation
  }

  public func logPrivacy(
    _: LogLevel,
    _: () -> PrivacyAnnotatedString,
    context _: any LogContextDTO
  ) async {
    // No-op implementation
  }

  public func logSensitive(
    _: LogLevel,
    _: String,
    sensitiveValues _: LogMetadata,
    context _: any LogContextDTO
  ) async {
    // No-op implementation
  }

  public func logError(
    _: Error,
    privacyLevel _: LogPrivacyLevel,
    context _: any LogContextDTO
  ) async {
    // No-op implementation
  }
}
