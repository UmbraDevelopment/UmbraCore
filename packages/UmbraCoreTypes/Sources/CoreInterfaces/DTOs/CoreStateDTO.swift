/// CoreStateDTO
///
/// Represents the current state of the UmbraCore framework.
/// This DTO captures the runtime state of the framework including
/// initialisation status, active services, and operational status.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct CoreStateDTO: Sendable, Equatable {
    /// Flag indicating whether the framework has been initialised
    public let isInitialised: Bool
    
    /// The current operational status of the framework
    public let status: CoreOperationalStatus
    
    /// The list of active services currently running
    public let activeServices: [String]
    
    /// The environment the framework is running in
    public let environment: CoreEnvironment
    
    /// Optional diagnostic information about the framework state
    public let diagnosticInfo: [String: String]?
    
    /// Creates a new CoreStateDTO instance
    /// - Parameters:
    ///   - isInitialised: Whether the framework has been initialised
    ///   - status: The current operational status
    ///   - activeServices: List of active services
    ///   - environment: Runtime environment
    ///   - diagnosticInfo: Optional diagnostic information
    public init(
        isInitialised: Bool,
        status: CoreOperationalStatus,
        activeServices: [String],
        environment: CoreEnvironment,
        diagnosticInfo: [String: String]? = nil
    ) {
        self.isInitialised = isInitialised
        self.status = status
        self.activeServices = activeServices
        self.environment = environment
        self.diagnosticInfo = diagnosticInfo
    }
}

/// Represents the operational status of the framework
public enum CoreOperationalStatus: String, Sendable, Equatable, CaseIterable {
    case starting
    case running
    case degraded
    case shuttingDown
    case stopped
    case error
}
