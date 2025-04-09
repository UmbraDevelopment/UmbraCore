import Foundation
import LoggingTypes
import CoreSecurityTypes
import LoggingInterfaces
import LoggingServices

/// Factory for creating instances of the RandomDataServiceProtocol.
///
/// This factory provides methods for creating fully configured random data service
/// instances with various entropy sources and security levels, adhering to the Alpha Dot Five architecture principles.
///
/// The factory utilises privacy-aware logging to ensure sensitive information is handled in accordance with data protection regulations.
public enum RandomDataServiceFactory {
  /// Creates a default random data service instance with standard configuration
  /// - Returns: A fully configured random data service
  public static func createDefault() async -> RandomDataServiceProtocol {
    let factory = LoggingServiceFactory.shared
    let logger = await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "RandomDataService"
    )

    // Create a proper LoggingProtocol instance from the PrivacyAwareLoggingActor
    let loggingAdapter = PrivacyAwareLoggingAdapter(logger: logger)
    
    return RandomDataServiceActor(logger: loggingAdapter)
  }

  /// Creates a custom random data service instance with the specified logger
  /// - Parameter logger: The logger to use for logging random data generation events
  /// - Returns: A fully configured random data service
  public static func createCustom(
    logger: LoggingProtocol
  ) -> RandomDataServiceProtocol {
    RandomDataServiceActor(logger: logger)
  }

  /// Creates a high-security random data service instance with enhanced security settings
  /// - Returns: A fully configured high-security random data service
  public static func createHighSecurity() async -> RandomDataServiceProtocol {
    let factory = LoggingServiceFactory.shared
    let logger = await factory.createComprehensivePrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "RandomDataService",
      environment: .production
    )
    
    // Create a proper LoggingProtocol instance from the PrivacyAwareLoggingActor
    let loggingAdapter = PrivacyAwareLoggingAdapter(logger: logger)

    let service = RandomDataServiceActor(logger: loggingAdapter)

    // Initialise with hardware entropy source for maximum security
    Task {
      try? await service.initialise(entropySource: .hardware)
    }

    return service
  }

  /// Creates a minimal random data service instance with basic configuration
  /// - Returns: A minimally configured random data service
  public static func createMinimal() async -> RandomDataServiceProtocol {
    let factory = LoggingServiceFactory.shared
    let logger = await factory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "RandomDataService",
      environment: .production
    )
    
    // Create a proper LoggingProtocol instance from the PrivacyAwareLoggingActor
    let loggingAdapter = PrivacyAwareLoggingAdapter(logger: logger)

    let service = RandomDataServiceActor(logger: loggingAdapter)

    // Initialise with system entropy source for better performance
    Task {
      try? await service.initialise(entropySource: .system)
    }

    return service
  }
}

/// Adapter to convert PrivacyAwareLoggingActor to LoggingProtocol
private class PrivacyAwareLoggingAdapter: LoggingProtocol {
  private let logger: PrivacyAwareLoggingActor
  
  init(logger: PrivacyAwareLoggingActor) {
    self.logger = logger
  }
  
  func debug(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.debug(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func info(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.info(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func warning(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.warning(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func error(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.error(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func critical(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.critical(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
}
