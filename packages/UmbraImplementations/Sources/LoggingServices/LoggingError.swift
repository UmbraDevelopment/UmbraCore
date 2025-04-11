import LoggingTypes

/// Errors that can occur during logging operations
public enum LoggingError: Error, Sendable {
  /// Destination with the given identifier already exists
  case destinationAlreadyExists(identifier: String)

  /// Failed to flush a destination
  case flushFailed(destinationID: String, underlyingError: Error)

  /// Multiple flush operations failed
  case multipleFlushFailures(errors: [LoggingError])

  /// Failed to create a log destination
  case destinationCreationFailed(reason: String)

  /// Failed to write to a log destination
  case writeError(destinationID: String, reason: String)
  
  /// Destination configuration is invalid
  case invalidDestinationConfig(_ message: String)
  
  /// Failed to write to a destination
  case writeFailure(_ message: String)
  
  /// Failed to initialise a component
  case initialisationFailed(reason: String)
  
  /// Specified destination not found
  case destinationNotFound(_ message: String)
  
  /// Failed to serialise or deserialise log data
  case serialisationFailed(reason: String)
  
  /// No log destinations were found
  case noDestinationsFound(_ message: String)
}

extension LoggingError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .destinationAlreadyExists(identifier):
        return "Log destination with identifier '\(identifier)' already exists"
      case let .flushFailed(destinationID, error):
        return "Failed to flush log destination '\(destinationID)': \(error)"
      case let .multipleFlushFailures(errors):
        let errorMessages=errors.map(\.description).joined(separator: ", ")
        return "Multiple flush failures occurred: \(errorMessages)"
      case let .destinationCreationFailed(reason):
        return "Failed to create log destination: \(reason)"
      case let .writeError(destinationID, reason):
        return "Failed to write to log destination '\(destinationID)': \(reason)"
      case let .invalidDestinationConfig(message):
        return "Invalid destination configuration: \(message)"
      case let .writeFailure(message):
        return "Write failure: \(message)"
      case let .initialisationFailed(reason):
        return "Initialisation failed: \(reason)"
      case let .destinationNotFound(message):
        return "Destination not found: \(message)"
      case let .serialisationFailed(reason):
        return "Serialisation failed: \(reason)"
      case let .noDestinationsFound(message):
        return "No destinations found: \(message)"
    }
  }
}
