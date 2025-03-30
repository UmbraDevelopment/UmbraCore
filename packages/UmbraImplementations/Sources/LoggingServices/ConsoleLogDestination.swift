import LoggingInterfaces
import LoggingTypes

/// A log destination that writes to the console/standard output
///
/// This implementation provides a simple console logging capability with
/// configurable minimum level and formatting options. It follows the
/// Alpha Dot Five architecture patterns with proper thread safety.
public struct ConsoleLogDestination: LoggingTypes.LogDestination {
  /// Unique identifier for this destination
  public let identifier: String

  /// Minimum log level this destination will accept
  public var minimumLevel: LoggingTypes.UmbraLogLevel

  /// Formatter for log entries
  private let formatter: LoggingInterfaces.LogFormatterProtocol

  /// Initialise a console log destination with the given configuration
  /// - Parameters:
  ///   - identifier: Unique identifier for this destination
  ///   - minimumLevel: Minimum log level to display
  ///   - formatter: Optional formatter to use
  public init(
    identifier: String="console",
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) {
    self.identifier=identifier
    self.minimumLevel=minimumLevel
    self.formatter=formatter ?? DefaultLogFormatter()
  }
  
  /// Convert LogLevel to numeric value for comparison
  /// - Parameter level: The LogLevel to convert
  /// - Returns: Numeric value representing severity
  private func logLevelToNumericValue(_ level: LogLevel) -> Int {
    switch level {
    case .trace: return 0
    case .debug: return 1
    case .info: return 2
    case .warning: return 3
    case .error: return 4
    case .critical: return 5
    }
  }
  
  /// Convert UmbraLogLevel to numeric value for comparison
  /// - Parameter level: The UmbraLogLevel to convert
  /// - Returns: Numeric value representing severity
  private func umbraLogLevelToNumericValue(_ level: UmbraLogLevel) -> Int {
    switch level {
    case .verbose: return 0
    case .debug: return 1
    case .info: return 2
    case .warning: return 3
    case .error: return 4
    case .critical: return 5
    }
  }

  /// Write a log entry to the console
  /// - Parameter entry: The log entry to write
  /// - Throws: LoggingError if writing fails
  public func write(_ entry: LoggingTypes.LogEntry) async throws {
    // Check minimum level using numeric values for comparison
    let entryLevelValue = logLevelToNumericValue(entry.level)
    let minimumLevelValue = umbraLogLevelToNumericValue(minimumLevel)
    
    guard entryLevelValue >= minimumLevelValue else {
      return
    }

    // Format and print the entry
    let formattedString=formatter.format(entry)
    print(formattedString)
  }

  /// Flush any pending entries
  /// - Throws: LoggingError if flushing fails
  ///
  /// Console output is written immediately, so this is a no-op.
  public func flush() async throws {
    // No action needed, console output is immediate
  }
}
