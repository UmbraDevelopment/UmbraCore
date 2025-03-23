/// UmbraMocks Module
///
/// Provides mock implementations of UmbraCore protocols for testing and development.
/// These mocks are designed to be predictable, controllable, and suitable for
/// unit testing and interface development.
///
/// # Key Features
/// - Thread-safe mock implementations
/// - Configurable behaviour
/// - Test-friendly interfaces
/// - Comprehensive state tracking
///
/// # Module Organisation
/// The module provides mock implementations for core services:
///
/// ## Security Mocks
/// ```swift
/// MockSecurityProvider
/// MockCredentialProvider
/// ```
///
/// ## Cryptographic Mocks
/// ```swift
/// MockCryptoService
/// MockKeychain
/// ```
///
/// ## Storage Mocks
/// ```swift
/// MockBookmarkStorage
/// MockSecureStorage
/// ```
///
/// # Usage in Tests
/// Mock implementations are designed for easy setup in tests:
/// ```swift
/// let mockSecurity = MockSecurityProvider()
/// mockSecurity.shouldSucceed = true
/// let result = try await mockSecurity.validateAccess(to: path)
/// ```
///
/// # State Inspection
/// Mocks provide methods to inspect their state:
/// ```swift
/// let mockCrypto = MockCryptoService()
/// await mockCrypto.encrypt(data, using: key)
/// XCTAssertEqual(mockCrypto.encryptionCount, 1)
/// ```
///
/// # Thread Safety
/// All mock implementations are thread-safe and properly handle concurrent access.
/// State tracking uses appropriate synchronisation mechanisms to ensure accurate
/// test results.
///
/// # Error Simulation
/// Mocks can be configured to simulate various error conditions:
/// - Network failures
/// - Access denials
/// - Timeouts
/// - Invalid states
///
/// This allows thorough testing of error handling paths in client code.
public enum UmbraMocks {
  /// Current version of the UmbraMocks module
  public static let version="1.0.0"

  /// Initialise UmbraMocks with default configuration
  public static func initialize() {
    // Configure mock services
  }
}
