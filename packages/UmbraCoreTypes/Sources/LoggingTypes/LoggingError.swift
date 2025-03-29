/// Comprehensive error type for logging system operations
///
/// This enum provides domain-specific error cases for the logging system,
/// following the Alpha Dot Five error handling patterns.
public enum LoggingError: Error, Sendable, Hashable {
    /// Failed to initialise logging system
    case initialisationFailed(reason: String)
    
    /// Failed to write to log destination
    case destinationWriteFailed(destination: String, reason: String)
    
    /// Log level filter prevented message from being logged
    case filteredByLevel(messageLevel: UmbraLogLevel, minimumLevel: UmbraLogLevel)
    
    /// Invalid configuration provided
    case invalidConfiguration(description: String)
    
    /// Operation not supported by this logger
    case operationNotSupported(description: String)
    
    /// Destination with specified identifier not found
    case destinationNotFound(identifier: String)
    
    /// Duplicate destination identifier
    case duplicateDestination(identifier: String)
    
    /// Failed to serialise log entry
    case serialisationFailed(reason: String)
}
