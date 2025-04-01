import Foundation
import LoggingInterfaces
import LoggingServices

/// Factory for creating instances of the RandomDataServiceProtocol.
///
/// This factory provides methods for creating fully configured random data service
/// instances with various entropy sources and security levels.
public enum RandomDataServiceFactory {
  /// Creates a default random data service instance with standard configuration
  /// - Returns: A fully configured random data service
  public static func createDefault() -> RandomDataServiceProtocol {
    let logger=LoggingServiceFactory.createDefault(
      subsystem: "uk.co.umbra.security",
      category: "RandomDataService"
    )

    return RandomDataServiceActor(logger: logger)
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
  public static func createHighSecurity() -> RandomDataServiceProtocol {
    let logger=LoggingServiceFactory.createDefault(
      subsystem: "uk.co.umbra.security",
      category: "HighSecurityRandomDataService"
    )

    let service=RandomDataServiceActor(logger: logger)

    // Initialise with hardware entropy source
    Task {
      try? await service.initialise(entropySource: EntropySource.hardware)
    }

    return service
  }

  /// Creates a minimal random data service instance for resource-constrained environments
  /// - Returns: A minimally configured random data service
  public static func createMinimal() -> RandomDataServiceProtocol {
    let logger=LoggingServiceFactory.createDefault(
      subsystem: "uk.co.umbra.security",
      category: "MinimalRandomDataService"
    )

    let service=RandomDataServiceActor(logger: logger)

    // Initialise with system entropy source (more efficient)
    Task {
      try? await service.initialise(entropySource: EntropySource.system)
    }

    return service
  }
}
