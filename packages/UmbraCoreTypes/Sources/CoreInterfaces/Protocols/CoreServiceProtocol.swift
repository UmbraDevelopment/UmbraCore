/// CoreServiceProtocol
///
/// Defines the contract for core framework services within the UmbraCore framework.
/// This protocol provides a comprehensive interface for managing the lifecycle
/// and core functionality of the UmbraCore framework.
///
/// # Key Features
/// - Thread-safe framework initialisation
/// - Service dependency management
/// - System information access
/// - Framework state monitoring
///
/// # Thread Safety
/// All methods are designed to be called from any thread and implement
/// proper isolation through Swift actors in their implementations.
///
/// # Error Handling
/// Methods use Swift's structured error handling with domain-specific
/// error types from UmbraErrors.
public protocol CoreServiceProtocol: Sendable {
  /// Initialises the core framework with the provided configuration
  /// - Parameter configuration: The configuration to use for initialisation
  /// - Throws: UmbraErrors.CoreError if initialisation fails
  func initialise(configuration: CoreConfigurationDTO) async throws

  /// Checks if the core framework has been initialised
  /// - Returns: True if initialised, false otherwise
  func isInitialised() async -> Bool

  /// Retrieves the current framework state
  /// - Returns: The current state of the framework
  func getState() async -> CoreStateDTO

  /// Retrieves the current version information of the framework
  /// - Returns: Version information as CoreVersionDTO
  func getVersion() async -> CoreVersionDTO

  /// Subscribes to core framework events
  /// - Parameter filter: Optional filter to limit the events received
  /// - Returns: An async sequence of CoreEventDTO objects
  func subscribeToEvents(filter: CoreEventFilterDTO?) -> AsyncStream<CoreEventDTO>

  /// Retrieves information about the system environment
  /// - Returns: System environment information
  func getSystemInfo() async -> SystemInfoDTO

  /// Shuts down the core framework gracefully
  /// - Parameter force: If true, forces an immediate shutdown even if operations are in progress
  /// - Throws: UmbraErrors.CoreError if shutdown fails
  func shutdown(force: Bool) async throws
}
