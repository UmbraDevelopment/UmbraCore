/// LoggingServices Module
///
/// This module provides thread-safe, actor-based logging implementations following
/// the Alpha Dot Five architecture principles. It includes:
///
/// - **LoggingServiceActor**: Core actor-based implementation of LoggingServiceProtocol
/// - **ConsoleLogDestination**: Log destination that writes to standard output
/// - **FileLogDestination**: Log destination that writes to files with rotation support
/// - **LoggingServiceFactory**: Convenience factory for creating common logger configurations
///
/// ## Usage Example
///
/// ```swift
/// // Create a standard console logger
/// let logger = LoggingServiceFactory.createStandardLogger()
///
/// // Log messages at different levels
/// await logger.info("Application started", metadata: nil, source: "AppDelegate")
/// await logger.warning("Network connectivity limited", metadata: nil, source: "NetworkMonitor")
/// await logger.error("Failed to save file", metadata: LogMetadata(dictionary: ["path":
/// "/tmp/file.txt"]), source: "FileManager")
///
/// // Create a production logger with file output
/// let prodLogger = LoggingServiceFactory.createProductionLogger(
///     logDirectoryPath: "/var/log/myapp"
/// )
/// ```
///
/// ## Alpha Dot Five Compliance
///
/// This implementation follows the Alpha Dot Five architectural principles:
///
/// - **Actor-based concurrency**: Thread safety through Swift actors
/// - **Foundation independence**: Core types avoid Foundation dependencies where possible
/// - **British spelling in documentation**: All user-facing documentation uses British English
/// - **Descriptive naming**: All components have clear, descriptive names
/// - **No unnecessary type aliases**: Direct type references are used throughout
///
/// All implementations are Swift 6 compliant with proper concurrency annotations.

@_exported import LoggingInterfaces
@_exported import LoggingTypes
