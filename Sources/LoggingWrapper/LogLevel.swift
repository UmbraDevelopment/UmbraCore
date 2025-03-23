import Foundation
import LoggingWrapperInterfaces

/// Re-export of LogLevel from LoggingWrapperInterfaces
///
/// This type alias maintains compatibility with existing code while implementing
/// the isolation pattern for third-party dependencies.
///
/// ## Re-export Pattern
///
/// The re-export pattern is used here to:
/// - Ensure backward compatibility with existing code using `LoggingWrapper.LogLevel`
/// - Maintain the separation between interface and implementation
/// - Allow for future changes to the underlying implementation without breaking clients
///
/// ## Usage
///
/// For modules with library evolution enabled, import directly from LoggingWrapperInterfaces:
/// ```swift
/// import LoggingWrapperInterfaces
///
/// func logAtLevel(level: LogLevel) { ... }
/// ```
///
/// For other modules, either approach works:
/// ```swift
/// import LoggingWrapper
///
/// func logAtLevel(level: LogLevel) { ... }
/// ```
public typealias LogLevel = LoggingWrapperInterfaces.LogLevel
