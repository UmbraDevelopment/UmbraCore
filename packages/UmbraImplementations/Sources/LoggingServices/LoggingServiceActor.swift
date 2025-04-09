import Foundation
import LoggingInterfaces
import LoggingTypes

/// Thread-safe logging service implementation based on the actor model
///
/// This implementation follows the Alpha Dot Five architecture patterns:
/// - Actor-based for thread safety
/// - Clear separation of concerns
/// - Proper error handling
/// - No unnecessary typealiases
public actor LoggingServiceActor: LoggingServiceProtocol {
  /// Registered log destinations, keyed by identifier
  private var destinations: [String: LoggingTypes.LogDestination]

  /// Minimum level that will be logged
  private var minimumLogLevel: LoggingTypes.UmbraLogLevel

  /// Default formatter for log entries
  private let formatter: LoggingInterfaces.LogFormatterProtocol

  /// Initialise the logging service with specified configuration
  /// - Parameters:
  ///   - destinations: Initial log destinations
  ///   - minimumLogLevel: Global minimum log level
  ///   - formatter: Log formatter to use
  public init(
    destinations: [LoggingTypes.LogDestination]=[],
    minimumLogLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) {
    self.destinations=Dictionary(uniqueKeysWithValues: destinations.map { ($0.identifier, $0) })
    self.minimumLogLevel=minimumLogLevel
    self.formatter=formatter ?? DefaultLogFormatter()
  }

  // MARK: - LoggingServiceProtocol Implementation

  /// Log a verbose message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func verbose(
    _ message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    await log(
      level: .verbose,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func debug(
    _ message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    await log(
      level: .debug,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func info(
    _ message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    await log(
      level: .info,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func warning(
    _ message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    await log(
      level: .warning,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func error(
    _ message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    await log(
      level: .error,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func critical(
    _ message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    await log(
      level: .critical,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log a message with a specified level
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func log(
    level: LoggingTypes.UmbraLogLevel,
    message: String,
    metadata: LoggingTypes.LogMetadataDTOCollection?=nil,
    source: String?=nil
  ) async {
    // Check if we should log at this level
    guard level.rawValue >= minimumLogLevel.rawValue else {
      return
    }

    // Create log entry
    Task {
      // Convert UmbraLogLevel to LogLevel
      let logLevel: LogLevel=switch level {
        case .verbose: .trace
        case .debug: .debug
        case .info: .info
        case .warning: .warning
        case .error: .error
        case .critical: .critical
      }

      // Convert metadata to PrivacyMetadata
      let privacyMetadata: PrivacyMetadata?=metadata.map { metadata in
        var result=PrivacyMetadata()
        for entry in metadata.entries {
          // Default to private privacy level for all converted metadata
          result[entry.key]=LoggingTypes.PrivacyMetadataValue(
            value: entry.value,
            privacy: entry.privacyLevel.toLogPrivacyLevel()
          )
        }
        return result
      }

      // Use async LogTimestamp.now()
      let timestamp=await LogTimestamp.now()

      // Convert PrivacyMetadata to LogMetadataDTOCollection if needed
      let metadataDTO: LogMetadataDTOCollection? = metadata ?? {
        // If we have privacyMetadata, convert it to LogMetadataDTOCollection
        guard let privacyMetadata else { return nil }
        
        // Convert PrivacyMetadata to LogMetadataDTOCollection
        var collection = LogMetadataDTOCollection()
        for key in privacyMetadata.keys {
          if let value = privacyMetadata[key] {
            switch value.privacy {
              case .public:
                collection = collection.withPublic(key: key, value: value.valueString)
              case .private:
                collection = collection.withPrivate(key: key, value: value.valueString)
              case .sensitive:
                collection = collection.withSensitive(key: key, value: value.valueString)
              case .hash:
                collection = collection.withHashed(key: key, value: value.valueString)
              case .auto:
                collection = collection.withAuto(key: key, value: value.valueString)
            }
          }
        }
        return collection
      }()

      let entry=LoggingTypes.LogEntry(
        level: logLevel,
        message: message,
        metadata: metadataDTO,
        source: source ?? "LoggingServiceActor",
        entryID: nil,
        timestamp: timestamp
      )

      // Log to all destinations
      for destination in destinations.values {
        do {
          try await destination.write(entry)
        } catch {
          // Swallow errors from individual destinations
          continue
        }
      }
    }
  }

  // MARK: - Configuration

  /// Add a log destination
  /// - Parameter destination: The destination to add
  /// - Throws: LoggingError if the destination cannot be added
  public func addDestination(_ destination: LoggingTypes.LogDestination) async throws {
    let identifier=destination.identifier

    // Check if a destination with this ID already exists
    if destinations[identifier] != nil {
      throw LoggingError.destinationAlreadyExists(identifier: identifier)
    }

    destinations[identifier]=destination
  }

  /// Set minimum log level for a specific destination
  /// - Parameters:
  ///   - level: The minimum log level
  ///   - identifier: Identifier of the destination
  /// - Returns: true if destination was found and updated, false otherwise
  public func setMinimumLogLevel(
    _ level: LoggingTypes.UmbraLogLevel,
    forDestination identifier: String
  ) async -> Bool {
    guard let destination=destinations[identifier] else {
      return false
    }

    // Since we cannot directly modify the destination's minimumLevel if it's get-only,
    // we need to create a new destination with the desired level
    // We'll remove the current destination and add a new one with the same identifier but new level

    // First, get all the properties we need to preserve
    let destinationID=destination.identifier

    // Create a new destination with the same properties but different minimum level
    // We'll handle this differently based on the concrete type
    switch destination {
      case is FileLogDestination:
        // We need to recreate the file destination with the new level
        // This is a simplified approach; in practice you'd need to preserve all configuration
        if let fileDestination=destination as? FileLogDestination {
          let newDestination=FileLogDestination(
            identifier: destinationID,
            filePath: fileDestination.filePath,
            minimumLevel: level
          )
          destinations[identifier]=newDestination
          return true
        }
        return false

      case is ConsoleLogDestination:
        // Create a new console destination with the new level
        let newDestination=ConsoleLogDestination(
          identifier: destinationID,
          minimumLevel: level
        )
        destinations[identifier]=newDestination
        return true

      case is OSLogDestination:
        // Create a new OSLog destination with the new level
        if let osLogDestination=destination as? OSLogDestination {
          let newDestination=OSLogDestination(
            identifier: destinationID,
            subsystem: osLogDestination.subsystem,
            category: osLogDestination.category,
            minimumLevel: level
          )
          destinations[identifier]=newDestination
          return true
        }
        return false

      default:
        // We don't know how to recreate this destination type
        return false
    }
  }

  /// Set the global minimum log level
  /// - Parameter level: The minimum log level to record
  public func setMinimumLogLevel(_ level: LoggingTypes.UmbraLogLevel) async {
    minimumLogLevel=level
  }

  /// Get the current global minimum log level
  /// - Returns: The minimum log level
  public func getMinimumLogLevel() async -> LoggingTypes.UmbraLogLevel {
    minimumLogLevel
  }

  /// Check if a destination with the given identifier exists
  /// - Parameter identifier: The destination identifier
  /// - Returns: true if a destination with this identifier exists
  public func hasDestination(identifier: String) async -> Bool {
    destinations[identifier] != nil
  }

  /// Get all registered destination identifiers
  /// - Returns: Array of destination identifiers
  public func getDestinationIdentifiers() async -> [String] {
    Array(destinations.keys)
  }

  /// Flush all destinations
  /// - Throws: Error if any destination fails to flush
  public func flush() async throws {
    for destination in destinations.values {
      try await destination.flush()
    }
  }

  /// Log an entry directly
  /// - Parameter entry: The log entry to write
  public func logEntry(_ entry: LogEntry) async {
    // Check if we should log at this level
    // Convert to the same type for comparison
    let entryLevel=switch entry.level {
      case .trace: 0
      case .debug: 1
      case .info: 2
      case .warning: 3
      case .error: 4
      case .critical: 5
    }

    let minLevel=switch minimumLogLevel {
      case .verbose: 0 // UmbraLogLevel uses .verbose instead of .trace
      case .debug: 1
      case .info: 2
      case .warning: 3
      case .error: 4
      case .critical: 5
    }

    guard entryLevel >= minLevel else {
      return
    }

    // Log to all destinations
    for destination in destinations.values {
      do {
        try await destination.write(entry)
      } catch {
        // Swallow errors from individual destinations
        continue
      }
    }
  }

  /// Remove a log destination by identifier
  /// - Parameter identifier: Unique identifier of the destination to remove
  /// - Returns: true if the destination was removed, false if not found
  public func removeDestination(withIdentifier identifier: String) async -> Bool {
    guard destinations[identifier] != nil else {
      return false
    }

    destinations.removeValue(forKey: identifier)
    return true
  }

  /// Flush all destinations, ensuring pending logs are written
  /// - Throws: LoggingError if any destination fails to flush
  public func flushAllDestinations() async throws {
    var errors=[LoggingError]()

    for (_, destination) in destinations {
      do {
        try await destination.flush()
      } catch {
        // Collect any errors but continue trying to flush other destinations
        errors.append(LoggingError.flushFailed(
          destinationID: destination.identifier,
          underlyingError: error
        ))
      }
    }

    // If any flush operations failed, throw a combined error
    if !errors.isEmpty {
      throw LoggingError.multipleFlushFailures(errors: errors)
    }
  }
}

/// Default implementation of LogFormatterProtocol
public struct DefaultLogFormatter: LoggingInterfaces.LogFormatterProtocol, Sendable {
  /// Configuration for the formatter
  public struct Configuration: Sendable {
    /// Include timestamp in formatted output
    public var includeTimestamp: Bool

    /// Include log level in formatted output
    public var includeLevel: Bool

    /// Include metadata in formatted output
    public var includeMetadata: Bool

    /// Include source in formatted output
    public var includeSource: Bool

    /// Include entry ID in formatted output
    public var includeEntryID: Bool

    /// Date format style to use
    public var dateFormat: String

    /// Initialise a new configuration
    /// - Parameters:
    ///   - includeTimestamp: Include timestamp
    ///   - includeLevel: Include log level
    ///   - includeMetadata: Include metadata
    ///   - includeSource: Include source
    ///   - includeEntryId: Include entry ID
    ///   - dateFormat: Date format string
    public init(
      includeTimestamp: Bool=true,
      includeLevel: Bool=true,
      includeMetadata: Bool=true,
      includeSource: Bool=true,
      includeEntryID: Bool=false,
      dateFormat: String="yyyy-MM-dd HH:mm:ss.SSS"
    ) {
      self.includeTimestamp=includeTimestamp
      self.includeLevel=includeLevel
      self.includeMetadata=includeMetadata
      self.includeSource=includeSource
      self.includeEntryID=includeEntryID
      self.dateFormat=dateFormat
    }
  }

  /// Configuration for this formatter
  private let configuration: Configuration

  /// Initialise a new formatter with the given configuration
  /// - Parameter configuration: Formatter configuration
  public init(configuration: Configuration=Configuration()) {
    self.configuration=configuration
  }

  /// Format a log level to a string representation
  /// - Parameter level: The log level to format
  /// - Returns: A formatted string representation
  private func formatLogLevel(_ level: LogLevel) -> String {
    switch level {
      case .trace: "TRACE"
      case .debug: "DEBUG"
      case .info: "INFO"
      case .warning: "WARN"
      case .error: "ERROR"
      case .critical: "CRIT"
    }
  }

  /// Format a log level to a string representation
  /// - Parameter level: The log level to format
  /// - Returns: A formatted string representation
  public func formatLogLevel(_ level: LoggingTypes.UmbraLogLevel) -> String {
    switch level {
      case .verbose: "TRACE"
      case .debug: "DEBUG"
      case .info: "INFO"
      case .warning: "WARN"
      case .error: "ERROR"
      case .critical: "CRIT"
    }
  }

  /// Format a timestamp to a string
  /// - Parameter timestamp: The timestamp to format
  /// - Returns: Formatted string representation of the timestamp
  public func formatTimestamp(_ timestamp: LoggingTypes.TimePointAdapter) -> String {
    // Extract components directly from the timeIntervalSince1970
    let seconds = Int(timestamp.timeIntervalSince1970)
    let milliseconds = Int((timestamp.timeIntervalSince1970 - Double(seconds)) * 1000)
    
    // Format date components manually
    let year = seconds / 31536000 + 1970
    let month = (seconds % 31536000) / 2592000 + 1
    let day = ((seconds % 31536000) % 2592000) / 86400 + 1
    
    // Format time components
    let hour = (seconds % 86400) / 3600
    let minute = (seconds % 3600) / 60
    let second = seconds % 60
    
    // Create formatted timestamp string based on configuration format
    // Default to standard format if not specified
    let format = configuration.dateFormat.isEmpty ? "yyyy-MM-dd HH:mm:ss.SSS" : configuration.dateFormat
    
    // Simple format handling - this could be expanded for more complex format strings
    if format == "yyyy-MM-dd HH:mm:ss.SSS" {
      return String(format: "%04d-%02d-%02d %02d:%02d:%02d.%03d", 
                   year, month, day, hour, minute, second, milliseconds)
    } else {
      // Basic fallback for other formats
      return String(format: "%04d-%02d-%02d %02d:%02d:%02d", 
                   year, month, day, hour, minute, second)
    }
  }

  /// Format metadata to a string
  /// - Parameter metadata: Metadata to format
  /// - Returns: Formatted string representation of the metadata
  public func formatMetadata(_ metadata: LoggingTypes.LogMetadataDTOCollection?) -> String? {
    guard let metadata, !metadata.isEmpty else {
      return nil
    }

    let metadataItems = metadata.entries
      .map { entry in "\(entry.key): \(entry.value)" }
      .joined(separator: ", ")

    return "{ \(metadataItems) }"
  }

  /// Format a log entry to a string
  /// - Parameter entry: The log entry to format
  /// - Returns: A string representation of the log entry
  public func formatEntry(_ entry: LoggingTypes.LogEntry) -> String {
    var components: [String]=[]

    // Add level if configured
    if configuration.includeLevel {
      components.append(formatLogLevel(entry.level))
    }

    // Add timestamp if configured
    if configuration.includeTimestamp {
      // Format the timestamp directly
      let seconds = Int(entry.timestamp.secondsSinceEpoch)
      let milliseconds = Int((entry.timestamp.secondsSinceEpoch - Double(seconds)) * 1000)
      
      // Format date components manually
      let year = seconds / 31536000 + 1970
      let month = (seconds % 31536000) / 2592000 + 1
      let day = ((seconds % 31536000) % 2592000) / 86400 + 1
      
      // Format time components
      let hour = (seconds % 86400) / 3600
      let minute = (seconds % 3600) / 60
      let second = seconds % 60
      
      // Create formatted timestamp string
      let timestamp = String(format: "%04d-%02d-%02d %02d:%02d:%02d.%03d", 
                           year, month, day, hour, minute, second, milliseconds)
      components.append(timestamp)
    }

    // Add message
    components.append(entry.message)

    // Add source if configured
    if configuration.includeSource, let source=entry.source, !source.isEmpty {
      components.append("[\(source)]")
    }

    // Add metadata if configured
    if configuration.includeMetadata, let metadataString=formatMetadata(entry.metadata) {
      components.append(metadataString)
    }

    return components.joined(separator: " ")
  }

  /// Customise the format based on configuration
  /// - Parameters:
  ///   - includeTimestamp: Whether to include timestamps in the output
  ///   - includeLevel: Whether to include log levels in the output
  ///   - includeSource: Whether to include source information in the output
  ///   - includeMetadata: Whether to include metadata in the output
  /// - Returns: A new formatter with the specified configuration
  public func withConfiguration(
    includeTimestamp: Bool,
    includeLevel: Bool,
    includeSource: Bool,
    includeMetadata: Bool
  ) -> LoggingInterfaces.LogFormatterProtocol {
    DefaultLogFormatter(
      configuration: Configuration(
        includeTimestamp: includeTimestamp,
        includeLevel: includeLevel,
        includeMetadata: includeMetadata,
        includeSource: includeSource
      )
    )
  }
}
