import Foundation
import LoggingInterfaces
import LoggingTypes

/// Factory for creating and configuring logging services
///
/// This factory simplifies the creation of properly configured logging services
/// following the Alpha Dot Five architecture guidelines. It provides standard
/// configurations for common logging scenarios while allowing for customisation.
///
/// As an actor, this factory provides thread safety for logger creation
/// and maintains a cache of created loggers for improved performance.
public actor LoggingServiceFactory {
  /// Shared singleton instance
  public static let shared=LoggingServiceFactory()

  /// Cache of created loggers by configuration key
  private var loggerCache: [String: Any]=[:]

  /// Initialiser
  public init() {}

  /// Create a standard logging service with console output
  /// - Parameters:
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - formatter: Optional custom formatter to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor
  public func createStandardLogger(
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil,
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="standard-\(minimumLevel.rawValue)-\(formatter != nil ? "custom" : "default")"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    let consoleDestination=ConsoleLogDestination(
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    let logger=LoggingServiceActor(
      destinations: [consoleDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a development logging service with more detailed output
  /// - Parameters:
  ///   - minimumLevel: Minimum log level to display (defaults to debug)
  ///   - formatter: Optional custom formatter to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor for development
  public func createDevelopmentLogger(
    minimumLevel: LoggingTypes.UmbraLogLevel = .debug,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil,
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="development-\(minimumLevel.rawValue)-\(formatter != nil ? "custom" : "default")"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    let consoleDestination=ConsoleLogDestination(
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    let logger=LoggingServiceActor(
      destinations: [consoleDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a default logging service with standard configuration
  /// - Parameter useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor with default settings
  public func createDefaultService(useCache: Bool=true) async -> LoggingServiceActor {
    // Create a standard logger with info level and default formatter
    await createStandardLogger(
      minimumLevel: .info,
      formatter: StandardLogFormatter(),
      useCache: useCache
    )
  }

  /// Create a logging service with custom destinations
  /// - Parameters:
  ///   - destinations: The log destinations to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor with the specified destinations
  public func createService(
    destinations: [LoggingTypes.LogDestination],
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="custom-\(destinations.map(\.identifier).joined(separator: "-"))"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    // Create a logger with the specified destinations
    let logger=LoggingServiceActor(
      destinations: destinations,
      minimumLogLevel: .info,
      formatter: StandardLogFormatter()
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a production logging service with file and console output
  /// - Parameters:
  ///   - logDirectoryPath: Directory to store log files
  ///   - logFileName: Name of the log file (without path)
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - maxFileSizeMB: Maximum log file size in megabytes before rotation
  ///   - maxBackupCount: Number of backup log files to keep
  ///   - formatter: Optional custom formatter to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor for production
  public func createProductionLogger(
    logDirectoryPath: String,
    logFileName: String="umbra.log",
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    maxFileSizeMB: UInt64=10,
    maxBackupCount: Int=5,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil,
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="production-\(logDirectoryPath)-\(logFileName)-\(minimumLevel.rawValue)"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    let filePath=(logDirectoryPath as NSString).appendingPathComponent(logFileName)

    let consoleDestination=ConsoleLogDestination(
      identifier: "console-prod",
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    let fileDestination=FileLogDestination(
      identifier: "file-prod",
      filePath: filePath,
      minimumLevel: minimumLevel,
      maxFileSize: maxFileSizeMB * 1024 * 1024,
      maxBackupCount: maxBackupCount,
      formatter: formatter
    )

    let logger=LoggingServiceActor(
      destinations: [consoleDestination, fileDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a custom logging service with specified destinations
  /// - Parameters:
  ///   - destinations: Array of log destinations
  ///   - minimumLevel: Global minimum log level
  ///   - formatter: Optional formatter to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor
  public func createCustomLogger(
    destinations: [LoggingTypes.LogDestination],
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil,
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="custom-\(destinations.map(\.identifier).joined(separator: "-"))-\(minimumLevel.rawValue)"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    let logger=LoggingServiceActor(
      destinations: destinations,
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create an OSLog-based logging service
  /// - Parameters:
  ///   - subsystem: The subsystem identifier (typically reverse-DNS bundle identifier)
  ///   - category: The logging category (module or component name)
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - formatter: Optional custom formatter to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A configured logging service actor that uses OSLog
  public func createOSLogger(
    subsystem: String,
    category: String,
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil,
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="oslog-\(subsystem)-\(category)-\(minimumLevel.rawValue)"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    let osLogDestination=OSLogDestination(
      subsystem: subsystem,
      category: category,
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    let logger=LoggingServiceActor(
      destinations: [osLogDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a comprehensive logging service with OSLog, file and console output
  /// - Parameters:
  ///   - subsystem: The subsystem identifier for OSLog
  ///   - category: The category for OSLog
  ///   - logDirectoryPath: Directory to store log files
  ///   - logFileName: Name of the log file (without path)
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - fileMinimumLevel: Minimum level for file logging (defaults to warning)
  ///   - osLogMinimumLevel: Minimum level for OSLog (defaults to info)
  ///   - consoleMinimumLevel: Minimum level for console (defaults to info)
  ///   - maxFileSizeMB: Maximum log file size in megabytes before rotation
  ///   - maxBackupCount: Number of backup log files to keep
  ///   - formatter: Optional custom formatter to use
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A logging service actor with multiple destinations
  public func createComprehensiveLogger(
    subsystem: String,
    category: String,
    logDirectoryPath: String,
    logFileName: String="umbra.log",
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    fileMinimumLevel: LoggingTypes.UmbraLogLevel = .warning,
    osLogMinimumLevel: LoggingTypes.UmbraLogLevel = .info,
    consoleMinimumLevel: LoggingTypes.UmbraLogLevel = .info,
    maxFileSizeMB: UInt64=10,
    maxBackupCount: Int=5,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil,
    useCache: Bool=true
  ) async -> LoggingServiceActor {
    let cacheKey="comprehensive-\(subsystem)-\(category)-\(logDirectoryPath)-\(logFileName)"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? LoggingServiceActor {
      return cachedLogger
    }

    let filePath=(logDirectoryPath as NSString).appendingPathComponent(logFileName)

    let consoleDestination=ConsoleLogDestination(
      identifier: "console-comprehensive",
      minimumLevel: consoleMinimumLevel,
      formatter: formatter
    )

    let fileDestination=FileLogDestination(
      identifier: "file-comprehensive",
      filePath: filePath,
      minimumLevel: fileMinimumLevel,
      maxFileSize: maxFileSizeMB * 1024 * 1024,
      maxBackupCount: maxBackupCount,
      formatter: formatter
    )

    let osLogDestination=OSLogDestination(
      identifier: "oslog-comprehensive",
      subsystem: subsystem,
      category: category,
      minimumLevel: osLogMinimumLevel,
      formatter: formatter
    )

    let logger=LoggingServiceActor(
      destinations: [consoleDestination, fileDestination, osLogDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a privacy-aware logger with enhanced privacy controls
  /// - Parameters:
  ///   - subsystem: The subsystem identifier for OSLog
  ///   - category: The logging category
  ///   - environment: The deployment environment (affects privacy redaction)
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A privacy-aware logging actor
  public func createPrivacyAwareLogger(
    subsystem: String="com.umbra.core",
    category: String="default",
    environment: DeploymentEnvironment = .development,
    useCache: Bool=true
  ) async -> PrivacyAwareLoggingActor {
    let cacheKey="privacy-aware-\(subsystem)-\(category)-\(environment.rawValue)"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? PrivacyAwareLoggingActor {
      return cachedLogger
    }

    // Create a privacy-aware formatter based on environment
    let formatter=PrivacyAwareLogFormatter(environment: environment)

    // Create OSLog destination for system integration
    let osLogDestination=OSLogDestination(
      identifier: "privacy-oslog",
      subsystem: subsystem,
      category: category,
      minimumLevel: .info,
      formatter: formatter
    )

    // Create console destination for development visibility
    let consoleDestination=ConsoleLogDestination(
      identifier: "privacy-console",
      minimumLevel: .info,
      formatter: formatter
    )

    // Create the base logging service
    let loggingService=LoggingServiceActor(
      destinations: [osLogDestination, consoleDestination],
      minimumLogLevel: .info,
      formatter: formatter
    )

    // Create the privacy-aware logging actor
    let logger=PrivacyAwareLoggingActor(
      loggingService: loggingService,
      environment: environment
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a comprehensive privacy-aware logger with multiple destinations
  /// - Parameters:
  ///   - subsystem: The subsystem identifier for OSLog
  ///   - category: The logging category
  ///   - logDirectoryPath: Directory to store log files
  ///   - environment: The deployment environment (affects privacy redaction)
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A comprehensive privacy-aware logging actor
  public func createComprehensivePrivacyAwareLogger(
    subsystem: String,
    category: String,
    logDirectoryPath: String=NSTemporaryDirectory(),
    environment: DeploymentEnvironment = .development,
    useCache: Bool=true
  ) async -> PrivacyAwareLoggingActor {
    let cacheKey="comprehensive-privacy-\(subsystem)-\(category)-\(environment.rawValue)"

    if useCache, let cachedLogger=loggerCache[cacheKey] as? PrivacyAwareLoggingActor {
      return cachedLogger
    }

    // Create a privacy-aware formatter based on environment
    let formatter=PrivacyAwareLogFormatter(environment: environment)

    // Create OSLog destination for system integration
    let osLogDestination=OSLogDestination(
      identifier: "privacy-comp-oslog",
      subsystem: subsystem,
      category: category,
      minimumLevel: .info,
      formatter: formatter
    )

    // Create console destination for development visibility
    let consoleDestination=ConsoleLogDestination(
      identifier: "privacy-comp-console",
      minimumLevel: environment == .development ? .debug : .info,
      formatter: formatter
    )

    // Create file destination for persistent logs
    let filePath=(logDirectoryPath as NSString)
      .appendingPathComponent("\(subsystem)-\(category).log")
    let fileDestination=FileLogDestination(
      identifier: "privacy-comp-file",
      filePath: filePath,
      minimumLevel: .warning,
      maxFileSize: 10 * 1024 * 1024, // 10 MB
      maxBackupCount: 5,
      formatter: formatter
    )

    // Create the base logging service
    let loggingService=LoggingServiceActor(
      destinations: [osLogDestination, consoleDestination, fileDestination],
      minimumLogLevel: .info,
      formatter: formatter
    )

    // Create the privacy-aware logging actor
    let logger=PrivacyAwareLoggingActor(
      loggingService: loggingService,
      environment: environment
    )

    if useCache {
      loggerCache[cacheKey]=logger
    }

    return logger
  }

  /// Create a production-optimised privacy-aware logger
  /// - Parameters:
  ///   - subsystem: The subsystem identifier for OSLog
  ///   - category: The logging category
  ///   - useCache: Whether to cache and reuse the created logger
  /// - Returns: A production-optimised privacy-aware logging actor
  public func createProductionPrivacyAwareLogger(
    subsystem: String="com.umbra.core",
    category: String="production",
    useCache: Bool=true
  ) async -> PrivacyAwareLoggingActor {
    await createPrivacyAwareLogger(
      subsystem: subsystem,
      category: category,
      environment: .production,
      useCache: useCache
    )
  }

  /// Clears the logger cache
  ///
  /// This can be useful when testing or when loggers need to be recreated
  /// with fresh configurations.
  public func clearCache() {
    loggerCache.removeAll()
  }

  /// Removes a specific logger from the cache
  ///
  /// - Parameter cacheKey: The cache key for the logger to remove
  /// - Returns: True if a logger was removed, false if no logger was found
  public func removeFromCache(cacheKey: String) -> Bool {
    if loggerCache[cacheKey] != nil {
      loggerCache[cacheKey]=nil
      return true
    }
    return false
  }
}
