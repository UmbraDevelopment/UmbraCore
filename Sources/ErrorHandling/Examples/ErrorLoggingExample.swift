import Foundation
import Interfaces

/// Example demonstrating integrated error severity and logging patterns
enum ErrorLoggingExample {
  /// Example of how notification levels map to ErrorSeverity
  static func demonstrateSeverityMapping() {
    // Convert notification levels to ErrorSeverity
    _=ErrorSeverity.from(notificationLevel: ErrorNotificationLevel.error)
    _=ErrorSeverity.from(notificationLevel: ErrorNotificationLevel.warning)
    _=ErrorSeverity.from(notificationLevel: ErrorNotificationLevel.info)
    _=ErrorSeverity.from(notificationLevel: ErrorNotificationLevel.debug)

    // Convert ErrorSeverity to notification levels
    _=ErrorSeverity.critical.toNotificationLevel()
    _=ErrorSeverity.error.toNotificationLevel()
    _=ErrorSeverity.warning.toNotificationLevel()
    _=ErrorSeverity.info.toNotificationLevel()
    _=ErrorSeverity.debug.toNotificationLevel()
  }

  /// Simplified placeholder for potential error handling and logging configuration
  static func configureLoggingExample() {
    // This is just a stub for what could be implemented

    // Example of severity mapping
    let severities: [ErrorSeverity]=[
      .critical,
      .error,
      .warning,
      .info,
      .debug,
      .trace
    ]

    // For demonstration only
    for severity in severities {
      print("Severity: \(severity)")
    }
  }
}
