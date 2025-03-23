import Foundation
import UmbraLogging

// This mock implementation provides the UmbraLoggingAdapters functionality needed for tests
public enum UmbraLoggingAdapters {
  public static func createLogger() -> LoggingProtocol {
    MockLogger()
  }

  public static func createLoggerWithDestinations(_: [Any]) -> LoggingProtocol {
    MockLogger()
  }
}

// Mock implementation of LoggingProtocol for testing
private final class MockLogger: LoggingProtocol {
  func debug(_ message: String, metadata _: LogMetadata?) async {
    print("[DEBUG] \(message)")
  }

  func info(_ message: String, metadata _: LogMetadata?) async {
    print("[INFO] \(message)")
  }

  func warning(_ message: String, metadata _: LogMetadata?) async {
    print("[WARNING] \(message)")
  }

  func error(_ message: String, metadata _: LogMetadata?) async {
    print("[ERROR] \(message)")
  }
}
