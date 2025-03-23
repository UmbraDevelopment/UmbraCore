import XCTest

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
  // This is the default XCTest entry point used for Apple platforms
  // When running on Apple platforms, test discovery happens automatically
  @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  final class UmbraTestKitTests {
    // This empty class serves as an entry point for Apple platforms
  }
#else
  // On Linux and other platforms, we need to manually list all test cases
  @main
  struct UmbraTestKitTests {
    static func main() {
      XCTMain([
        testCase(MockSecurityProviderTests.allTests),
        testCase(SecurityErrorHandlerTests.allTests),
        testCase(SecurityErrorTests.allTests)
      ])
    }
  }
#endif
