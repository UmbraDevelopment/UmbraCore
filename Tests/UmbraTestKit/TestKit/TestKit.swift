import Foundation
import TestKit

/// Umbra test utilities
public enum UmbraTestKit {
  /// Set up function
  public static func setUp() {
    TestKit.setUp()
  }

  /// Tear down function
  public static func tearDown() {
    TestKit.tearDown()
  }
}
