import LoggingTypes

/// A thread-safe actor that manages logging operations
/// This is the primary entry point for the actor-based logging system
public actor LoggingActor {
  /// Collection of log destinations
  private var destinations: [any ActorLogDestination]

  /// The minimum log level to process
  private var minimumLogLevel: LogLevel

  /// Flag to enable/disable all logging
  private var isEnabled: Bool=true

  /// Initialise a new logging actor with the specified destinations and minimum log level
  /// - Parameters:
  ///   - destinations: Array of log destinations
  ///   - minimumLogLevel: The minimum log level to process, defaults to info
  public init(
    destinations: [any ActorLogDestination],
    minimumLogLevel: LogLevel = .info
  ) {
    self.destinations=destinations
    self.minimumLogLevel=minimumLogLevel
  }

  /// Log a message with a specific level and context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log
  public func log(level: LogLevel, message: String, context: LogContext) async {
    guard isEnabled && level >= minimumLogLevel else { return }

    // Map LogLevel from LoggingInterfaces to LoggingTypes
    let mappedLevel = mapLogLevel(level)

    let entry=LogEntry(level: mappedLevel, message: message, context: context)

    // Write to all destinations
    for destination in destinations {
      // Each destination can have its own level filtering
      if await destination.shouldLog(level: level) {
        await destination.write(entry)
      }
    }
  }

  /// Helper function to map LogLevel
  private func mapLogLevel(_ interfaceLevel: LogLevel) -> LoggingTypes.LogLevel {
    // Assuming LoggingTypes.LogLevel has corresponding cases
    // This mapping might need adjustment based on the exact definitions
    switch interfaceLevel {
    case .trace: return .trace
    case .debug: return .debug
    case .info: return .info
    case .notice: return .info // Map notice to info as it's not directly in LoggingTypes.LogLevel
    case .warning: return .warning
    case .error: return .error
    case .critical: return .critical
    @unknown default:
      // Handle potential future log levels gracefully
      return .info // Default to info for unknown levels
    }
  }

  /// Add a new log destination
  /// - Parameter destination: The destination to add
  public func addDestination(_ destination: any ActorLogDestination) {
    destinations.append(destination)
  }

  /// Remove a log destination by identifier
  /// - Parameter identifier: The identifier of the destination to remove
  /// - Returns: True if a destination was removed
  @discardableResult
  public func removeDestination(withIdentifier identifier: String) async -> Bool {
    let initialCount=destinations.count
    var destinationsToKeep: [any ActorLogDestination]=[]

    for destination in destinations {
      if await destination.identifier != identifier {
        destinationsToKeep.append(destination)
      }
    }

    let removed=destinationsToKeep.count < initialCount
    destinations=destinationsToKeep
    return removed
  }

  /// Set the minimum log level
  /// - Parameter level: The new minimum log level
  public func setMinimumLogLevel(_ level: LogLevel) {
    minimumLogLevel=level
  }

  /// Enable or disable logging
  /// - Parameter enabled: Whether logging should be enabled
  public func setEnabled(_ enabled: Bool) {
    isEnabled=enabled
  }

  /// Get the current minimum log level
  /// - Returns: The current minimum log level
  public func getMinimumLogLevel() -> LogLevel {
    minimumLogLevel
  }

  /// Check if a specific level would be logged
  /// - Parameter level: The log level to check
  /// - Returns: True if logs of this level would be processed
  public func isLoggable(_ level: LogLevel) -> Bool {
    isEnabled && level >= minimumLogLevel
  }
}
