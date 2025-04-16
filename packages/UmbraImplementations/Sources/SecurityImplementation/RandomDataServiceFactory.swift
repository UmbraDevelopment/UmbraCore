import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/// Factory for creating instances of the RandomDataServiceProtocol.
///
/// This factory provides methods for creating fully configured random data service
/// instances with various entropy sources and security levels, adhering to the Alpha Dot Five
/// architecture principles.
///
/// The factory utilises privacy-aware logging to ensure sensitive information is handled in
/// accordance with data protection regulations.
public enum RandomDataServiceFactory {
  /// Creates a default random data service instance with standard configuration.
  ///
  /// - Returns: A fully configured random data service.
  public static func createDefault() async -> RandomDataServiceProtocol {
    let factory=LoggingServiceFactory.shared
    let logger=await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "RandomDataService"
    )

    // Create a proper LoggingProtocol instance from the PrivacyAwareLoggingActor.
    let loggingAdapter=PrivacyAwareLoggingAdapter(logger: logger)

    return RandomDataServiceActor(logger: loggingAdapter)
  }

  /// Creates a custom random data service instance with the specified logger.
  ///
  /// - Parameter logger: The logger to use for logging random data generation events.
  /// - Returns: A fully configured random data service.
  public static func createCustom(logger: LoggingProtocol) -> RandomDataServiceProtocol {
    RandomDataServiceActor(logger: logger)
  }

  /// Creates a high-security random data service instance with enhanced security settings.
  ///
  /// - Returns: A fully configured high-security random data service.
  public static func createHighSecurity() async -> RandomDataServiceProtocol {
    let factory=LoggingServiceFactory.shared
    let logger=await factory.createComprehensivePrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "RandomDataService",
      environment: .production
    )

    // Create a proper LoggingProtocol instance from the PrivacyAwareLoggingActor.
    let loggingAdapter=PrivacyAwareLoggingAdapter(logger: logger)

    let service=RandomDataServiceActor(logger: loggingAdapter)

    // Initialise with hardware entropy source for maximum security.
    Task {
      try? await service.initialise(entropySource: .hardware)
    }

    return service
  }

  /// Creates a minimal random data service instance with basic configuration.
  ///
  /// - Returns: A minimally configured random data service.
  public static func createMinimal() async -> RandomDataServiceProtocol {
    let factory=LoggingServiceFactory.shared
    let logger=await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "RandomDataService",
      environment: .production
    )

    // Create a proper LoggingProtocol instance from the PrivacyAwareLoggingActor.
    let loggingAdapter=PrivacyAwareLoggingAdapter(logger: logger)

    let service=RandomDataServiceActor(logger: loggingAdapter)

    // Initialise with system entropy source for better performance.
    Task {
      try? await service.initialise(entropySource: .system)
    }

    return service
  }
}

/// Adapter to convert PrivacyAwareLoggingActor to LoggingProtocol.
private final actor PrivacyAwareLoggingAdapter: LoggingProtocol {
  /// The underlying logger actor instance.
  private let logger: PrivacyAwareLoggingActor

  /// Required by LoggingProtocol - access to the underlying logging actor.
  nonisolated var loggingActor: LoggingActor {
    fatalError("Direct LoggingActor access not supported in this adapter")
  }

  init(logger: PrivacyAwareLoggingActor) {
    self.logger=logger
  }

  /// Core protocol requirement for the LoggingProtocol.
  func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    await logger.log(level, message, context: context)
  }

  func debug(_ message: String, metadata: LogMetadataDTOCollection?) async {
    await logger.debug(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        metadata: metadata ?? LogMetadataDTOCollection()
      )
    )
  }

  func info(_ message: String, metadata: LogMetadataDTOCollection?) async {
    await logger.info(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        metadata: metadata ?? LogMetadataDTOCollection()
      )
    )
  }

  @available(*, deprecated, message: "Use info(_:context:) instead")
  func info(_ message: String, metadata _: PrivacyMetadata?, source: String) async {
    // Create a simple metadata collection instead of trying to convert.
    let logMetadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: "info")
      .withPublic(key: "source", value: source)

    await logger.info(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: source,
        metadata: logMetadata
      )
    )
  }

  func warning(_ message: String, metadata: LogMetadataDTOCollection?) async {
    await logger.warning(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        metadata: metadata ?? LogMetadataDTOCollection()
      )
    )
  }

  func error(_ message: String, metadata: LogMetadataDTOCollection?) async {
    await logger.error(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        metadata: metadata ?? LogMetadataDTOCollection()
      )
    )
  }

  @available(*, deprecated, message: "Use error(_:context:) instead")
  func error(_ message: String, metadata _: PrivacyMetadata?, source: String) async {
    // Create a simple metadata collection instead of trying to convert.
    let logMetadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: "error")
      .withPublic(key: "source", value: source)

    await logger.error(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: source,
        metadata: logMetadata
      )
    )
  }

  func critical(_ message: String, metadata: LogMetadataDTOCollection?) async {
    await logger.critical(
      message,
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        metadata: metadata ?? LogMetadataDTOCollection()
      )
    )
  }

  func info(_ message: String, context: LogContextDTO) async {
    await logger.info(message, context: context)
  }

  func notice(_ message: String, context: LogContextDTO) async {
    await logger.notice(message, context: context)
  }

  func error(_ message: String, context: LogContextDTO) async {
    await logger.error(message, context: context)
  }

  func debug(_ message: String, context: LogContextDTO) async {
    await logger.debug(message, context: context)
  }

  func warning(_ message: String, context: LogContextDTO) async {
    await logger.warning(message, context: context)
  }

  func critical(_ message: String, context: LogContextDTO) async {
    await logger.critical(message, context: context)
  }
}
