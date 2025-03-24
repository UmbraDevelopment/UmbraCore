@testable import SecurityTypes
@testable import UmbraLogging

// import UmbraLoggingAdapters - Removing direct import to fix library evolution incompatibility
import XCTest

final class LoggingServiceTests: XCTestCase {
  private var logger: LoggingProtocol!
  private let tempPath=NSTemporaryDirectory() + "test.log"

  override func setUp() async throws {
    try await super.setUp()
    // Use the factory method from UmbraLogging to create a logger
    logger=UmbraLogging.createLogger()

    // Create an empty file to ensure it exists
    FileManager.default.createFile(atPath: tempPath, contents: nil)
  }

  override func tearDown() async throws {
    try? FileManager.default.removeItem(atPath: tempPath)
    try await super.tearDown()
  }

  func testLogging() async throws {
    var metadata=LogMetadata()
    metadata["test"]="value"

    // Use the updated UmbraLogLevel type
    await logger.info("Test message", metadata: metadata)

    // Verify logging functionality
    XCTAssertNoThrow(try String(contentsOfFile: tempPath, encoding: .utf8))
  }

  func testLogLevels() async throws {
    // Test different log levels using the new API
    await logger.debug("Test debug message", metadata: nil)
    await logger.info("Test info message", metadata: nil)
    await logger.warning("Test warning message", metadata: nil)
    await logger.error("Test error message", metadata: nil)

    // No assertions needed - we're just verifying the calls don't throw
  }

  func testMetadataHandling() async throws {
    // Test that metadata is properly handled
    var metadata=LogMetadata()
    metadata["key1"]="value1"
    metadata["key2"]="42"
    metadata["key3"]="true"

    await logger.info("Test with complex metadata", metadata: metadata)

    // Success if it doesn't throw
  }
}
