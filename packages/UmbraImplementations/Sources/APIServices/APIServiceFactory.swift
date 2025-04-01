import APIInterfaces
import LoggingInterfaces
import SecurityCoreInterfaces

/// APIServiceFactory
///
/// Factory for creating instances of APIServiceProtocol.
/// This factory follows the dependency injection pattern to create
/// properly configured API service instances with their dependencies.
///
/// # Usage Example
/// ```swift
/// let apiService = APIServiceFactory.createDefault()
/// try await apiService.initialise(configuration: config)
/// ```
public enum APIServiceFactory {
  /// Creates a default instance of APIServiceProtocol with standard configuration
  /// - Parameters:
  ///   - logger: Optional logger for API operations. If nil, a default logger will be created.
  ///   - securityBookmarkService: Optional security bookmark service. If nil, a default service
  /// will be created.
  /// - Returns: A configured instance of APIServiceProtocol
  public static func createDefault(
    logger: DomainLogger?=nil,
    securityBookmarkService: SecurityBookmarkProtocol?=nil
  ) -> APIServiceProtocol {
    // Create the default configuration
    let defaultConfiguration=APIConfigurationDTO(
      environment: .development,
      loggingLevel: .info,
      timeoutMilliseconds: 30000 // 30 seconds
    )

    // Use provided logger or create a default one
    let apiLogger=logger ?? LoggerFactory.createLogger(
      domain: "APIService",
      category: "Service"
    )

    // Use provided security bookmark service or create a default one
    let bookmarkService=securityBookmarkService ?? SecurityBookmarkFactory.createDefault()

    // Create and return the API service actor
    return APIServiceActor(
      configuration: defaultConfiguration,
      logger: apiLogger,
      securityBookmarkService: bookmarkService
    )
  }

  /// Creates a custom instance of APIServiceProtocol with the specified configuration
  /// - Parameters:
  ///   - configuration: Custom configuration for the API service
  ///   - logger: Logger for API operations
  ///   - securityBookmarkService: Service for managing security-scoped bookmarks
  /// - Returns: A configured instance of APIServiceProtocol
  public static func createCustom(
    configuration: APIConfigurationDTO,
    logger: DomainLogger,
    securityBookmarkService: SecurityBookmarkProtocol
  ) -> APIServiceProtocol {
    // Create and return the API service actor with custom dependencies
    APIServiceActor(
      configuration: configuration,
      logger: logger,
      securityBookmarkService: securityBookmarkService
    )
  }
}
