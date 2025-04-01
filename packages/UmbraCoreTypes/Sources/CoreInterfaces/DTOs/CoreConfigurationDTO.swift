/// CoreConfigurationDTO
///
/// Represents configuration options for the UmbraCore framework.
/// This DTO is Foundation-independent to ensure it can be used
/// across module boundaries and in concurrent contexts.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct CoreConfigurationDTO: Sendable, Equatable {
  /// The environment in which the framework operates
  public let environment: CoreEnvironment

  /// Optional logging level for framework operations
  public let loggingLevel: CoreLoggingLevel?

  /// Feature flags for enabling or disabling specific features
  public let featureFlags: [String: Bool]

  /// Application identifier
  public let applicationIdentifier: String

  /// Creates a new CoreConfigurationDTO instance
  /// - Parameters:
  ///   - environment: The operating environment
  ///   - loggingLevel: Optional logging level
  ///   - featureFlags: Feature flags for enabling/disabling features
  ///   - applicationIdentifier: Unique identifier for the application
  public init(
    environment: CoreEnvironment,
    loggingLevel: CoreLoggingLevel?=nil,
    featureFlags: [String: Bool]=[:],
    applicationIdentifier: String
  ) {
    self.environment=environment
    self.loggingLevel=loggingLevel
    self.featureFlags=featureFlags
    self.applicationIdentifier=applicationIdentifier
  }

  /// Creates a development configuration with sensible defaults
  /// - Parameter applicationIdentifier: Unique identifier for the application
  /// - Returns: A configuration suitable for development
  public static func development(applicationIdentifier: String) -> CoreConfigurationDTO {
    CoreConfigurationDTO(
      environment: .development,
      loggingLevel: .debug,
      featureFlags: [
        "enableDetailedLogging": true,
        "enablePerformanceMonitoring": true,
        "strictErrorHandling": false
      ],
      applicationIdentifier: applicationIdentifier
    )
  }

  /// Creates a production configuration with sensible defaults
  /// - Parameter applicationIdentifier: Unique identifier for the application
  /// - Returns: A configuration suitable for production
  public static func production(applicationIdentifier: String) -> CoreConfigurationDTO {
    CoreConfigurationDTO(
      environment: .production,
      loggingLevel: .info,
      featureFlags: [
        "enableDetailedLogging": false,
        "enablePerformanceMonitoring": true,
        "strictErrorHandling": true
      ],
      applicationIdentifier: applicationIdentifier
    )
  }
}

/// Represents the environment in which the framework operates
public enum CoreEnvironment: String, Sendable, Equatable, CaseIterable {
  case development
  case staging
  case production
}

/// Represents logging levels for framework operations
public enum CoreLoggingLevel: String, Sendable, Equatable, CaseIterable {
  case trace
  case debug
  case info
  case warning
  case error
  case none
}
