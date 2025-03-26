import Foundation
import XCTest

/// Utility functions for testing
public enum TestUtils {
  /// Generate random data of specified size
  /// - Parameter size: Size in bytes
  /// - Returns: Random data
  public static func generateRandomData(size: Int) -> Data {
    var data=Data(count: size)
    _=data.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, size, bytes.baseAddress!)
    }
    return data
  }

  /// Generate a temporary file URL
  /// - Parameter prefix: Optional prefix for the filename
  /// - Returns: URL to a temporary file
  public static func temporaryFileURL(prefix: String="") -> URL {
    let fileName="\(prefix)\(UUID().uuidString)"
    return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
  }

  /// Create a temporary directory
  /// - Parameter prefix: Optional prefix for the directory name
  /// - Returns: URL to the temporary directory
  public static func createTemporaryDirectory(prefix: String="") throws -> URL {
    let dirName="\(prefix)\(UUID().uuidString)"
    let url=FileManager.default.temporaryDirectory.appendingPathComponent(dirName)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  /// Wait for a condition to be true
  /// - Parameters:
  ///   - timeout: Maximum time to wait
  ///   - interval: Time between checks
  ///   - description: Description of what we're waiting for
  ///   - condition: Condition to check
  public static func wait(
    timeout: TimeInterval=5,
    interval: TimeInterval=0.1,
    description: String,
    condition: () -> Bool
  ) throws {
    let start=Date()
    while !condition() {
      if Date().timeIntervalSince(start) > timeout {
        throw TestError.timeout(description)
      }
      Thread.sleep(forTimeInterval: interval)
    }
  }

  /// Wait for an async condition to be true
  /// - Parameters:
  ///   - timeout: Maximum time to wait
  ///   - interval: Time between checks
  ///   - description: Description of what we're waiting for
  ///   - condition: Async condition to check
  public static func wait(
    timeout: TimeInterval=5,
    interval: TimeInterval=0.1,
    description: String,
    condition: () async throws -> Bool
  ) async throws {
    let start=Date()
    while try await !condition() {
      if Date().timeIntervalSince(start) > timeout {
        throw TestError.timeout(description)
      }
      try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
  }
}

/// Errors that can occur during testing
public enum TestError: LocalizedError {
  /// Timed out waiting for condition
  case timeout(String)

  public var errorDescription: String? {
    switch self {
      case let .timeout(description):
        "Timed out waiting for: \(description)"
    }
  }
}
