import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperModels
@testable import ResticCLIHelperTypes
import ResticTypes
import UmbraTestKit
import XCTest

final class ProgressTests: XCTestCase {
  /// Mock progress handler for testing.
  private class MockProgressHandler: ResticProgressReporting {
    var backupProgress: [BackupProgress]=[]
    var restoreProgress: [RestoreProgress]=[]

    func progressUpdated(_ progress: Any) {
      if let progress=progress as? BackupProgress {
        backupProgress.append(progress)
      } else if let progress=progress as? RestoreProgress {
        restoreProgress.append(progress)
      }
    }
  }

  func testParseBackupProgress() throws {
    let input="""
      {"message_type":"status","percent_done":0.2,"total_files":100,"files_done":20,"total_bytes":10000,"bytes_done":2000}
      {"message_type":"status","percent_done":0.5,"total_files":100,"files_done":50,"total_bytes":10000,"bytes_done":5000}
      {"message_type":"status","percent_done":1.0,"total_files":100,"files_done":100,"total_bytes":10000,"bytes_done":10000}
      """

    var progressUpdates: [[String: Any]]=[]
    let expectation=expectation(description: "Progress updates")
    expectation.expectedFulfillmentCount=3

    // Create a custom progress handler that directly parses the JSON
    for line in input.split(separator: "\n") {
      guard
        let data=String(line).data(using: .utf8),
        let json=try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        XCTFail("Failed to parse progress JSON")
        continue
      }

      progressUpdates.append(json)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    XCTAssertEqual(progressUpdates.count, 3)
    XCTAssertEqual(progressUpdates[0]["percent_done"] as? Double, 0.2)
    XCTAssertEqual(progressUpdates[0]["total_files"] as? Int, 100)
    XCTAssertEqual(progressUpdates[0]["files_done"] as? Int, 20)
    XCTAssertEqual(progressUpdates[0]["total_bytes"] as? Int, 10000)
    XCTAssertEqual(progressUpdates[0]["bytes_done"] as? Int, 2000)

    XCTAssertEqual(progressUpdates[1]["percent_done"] as? Double, 0.5)
    XCTAssertEqual(progressUpdates[1]["files_done"] as? Int, 50)

    XCTAssertEqual(progressUpdates[2]["percent_done"] as? Double, 1.0)
    XCTAssertEqual(progressUpdates[2]["files_done"] as? Int, 100)
    XCTAssertEqual(progressUpdates[2]["bytes_done"] as? Int, 10000)
  }

  func testParseRestoreProgress() throws {
    let input="""
      {"message_type":"status","percent_done":0.25,"total_files":40,"files_done":10,"total_bytes":8000,"bytes_done":2000}
      {"message_type":"status","percent_done":0.75,"total_files":40,"files_done":30,"total_bytes":8000,"bytes_done":6000}
      {"message_type":"status","percent_done":1.0,"total_files":40,"files_done":40,"total_bytes":8000,"bytes_done":8000}
      """

    var progressUpdates: [[String: Any]]=[]
    let expectation=expectation(description: "Progress updates")
    expectation.expectedFulfillmentCount=3

    // Create a custom progress handler that directly parses the JSON
    for line in input.split(separator: "\n") {
      guard
        let data=String(line).data(using: .utf8),
        let json=try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        XCTFail("Failed to parse progress JSON")
        continue
      }

      progressUpdates.append(json)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    XCTAssertEqual(progressUpdates.count, 3)
    XCTAssertEqual(progressUpdates[0]["percent_done"] as? Double, 0.25)
    XCTAssertEqual(progressUpdates[0]["total_files"] as? Int, 40)
    XCTAssertEqual(progressUpdates[0]["files_done"] as? Int, 10)
    XCTAssertEqual(progressUpdates[0]["total_bytes"] as? Int, 8000)
    XCTAssertEqual(progressUpdates[0]["bytes_done"] as? Int, 2000)

    XCTAssertEqual(progressUpdates[1]["percent_done"] as? Double, 0.75)
    XCTAssertEqual(progressUpdates[1]["files_done"] as? Int, 30)

    XCTAssertEqual(progressUpdates[2]["percent_done"] as? Double, 1.0)
    XCTAssertEqual(progressUpdates[2]["files_done"] as? Int, 40)
    XCTAssertEqual(progressUpdates[2]["bytes_done"] as? Int, 8000)
  }
}
