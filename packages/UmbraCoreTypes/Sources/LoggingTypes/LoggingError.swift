/// Comprehensive error type for logging system operations
///
/// This enum provides domain-specific error cases for the logging system,
/// following the Alpha Dot Five error handling patterns.
public enum LoggingError: Error, Sendable, Hashable {
  /// Failed to initialise logging system
  case initialisationFailed(reason: String)

  /// Failed to write to log destination
  case destinationWriteFailed(destination: String, reason: String)
  
  /// General write failure
  case writeFailure(String)

  /// Log level filter prevented message from being logged
  case filteredByLevel(messageLevel: UmbraLogLevel, minimumLevel: UmbraLogLevel)

  /// Invalid configuration provided
  case invalidConfiguration(description: String)
  
  /// Invalid destination configuration
  case invalidDestinationConfig(String)

  /// Operation not supported by this logger
  case operationNotSupported(description: String)

  /// Destination with specified identifier not found
  case destinationNotFound(String)

  /// Duplicate destination identifier
  case duplicateDestination(identifier: String)
  
  /// Destination already exists with the given identifier
  case destinationAlreadyExists(identifier: String)

  /// Failed to serialise log entry
  case serialisationFailed(reason: String)
  
  /// General error
  case general(String)
  
  /// Archive operation failed
  case archiveFailed(String)
  
  /// Export operation failed
  case exportFailed(String)
  
  /// Log retrieval failed
  case retrievalFailed(String)
  
  /// Log rotation failed
  case rotationFailed(String)
  
  /// Log deletion failed
  case deletionFailed(String)
  
  /// Log truncation failed
  case truncationFailed(String)
  
  /// Log flushing failed
  case flushingFailed(String)
  
  /// Log metadata retrieval failed
  case metadataRetrievalFailed(String)
  
  /// Log metadata update failed
  case metadataUpdateFailed(String)
  
  /// Log metadata deletion failed
  case metadataDeletionFailed(String)
  
  /// No destinations found for the operation
  case noDestinationsFound(String)
}
