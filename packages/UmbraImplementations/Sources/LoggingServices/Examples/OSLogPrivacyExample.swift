import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/// A string with privacy annotations for logging.
/// This provides an easy way to specify the privacy level of string data for logging purposes.
public struct PrivacyAnnotatedString {
  /// The privacy level to apply to the string content
  public enum PrivacyLevel {
    /// Public data that can be freely logged
    case `public`
    /// Private data that should be redacted in production logs
    case `private`
    /// Sensitive data that should always be redacted
    case sensitive
  }

  /// The original string content
  public let content: String

  /// The privacy level for this string
  public let privacy: PrivacyLevel

  /// Create a new privacy-annotated string
  /// - Parameters:
  ///   - content: The string content
  ///   - privacy: The privacy level to apply
  public init(_ content: String, privacy: PrivacyLevel) {
    self.content=content
    self.privacy=privacy
  }

  /// Returns a string representation with privacy annotations applied
  public var description: String {
    switch privacy {
      case .public:
        content
      case .private:
        content // In a real implementation, this would be appropriately marked
      case .sensitive:
        content // In a real implementation, this would be strongly redacted
    }
  }
}

/// This example demonstrates the use of OSLog with privacy controls
/// throughout the UmbraCore logging system. It shows how to:
///
/// - Create an OSLog-based logger
/// - Log messages with different privacy levels
/// - Apply privacy annotations to different parts of log messages
/// - Configure OSLog for different subsystems and categories
/// - Combine multiple log destinations with privacy awareness
///
/// These examples follow Alpha Dot Five architecture principles and
/// use British spelling in documentation comments.

class OSLogPrivacyExampleRunner {

  /// Run a comprehensive example of privacy-aware logging with OSLog
  static func runExample() async {
    print("Starting OSLog Privacy Example...")

    // MARK: - Basic OSLog with Privacy

    // Create a simple OSLog logger for a specific subsystem and category
    let osLogger=LoggingServiceFactory.createOSLogger(
      subsystem: "com.umbraapp.example",
      category: "PrivacyExample",
      minimumLevel: .debug
    )

    // Log with different privacy levels
    await logBasicPrivacyExamples(using: osLogger)

    // MARK: - Mixed Logging Destinations with Privacy

    // Create a comprehensive logger with multiple destinations
    let mixedLogger=LoggingServiceFactory.createComprehensiveLogger(
      subsystem: "com.umbraapp.example",
      category: "MixedExample",
      logDirectoryPath: FileManager.default.temporaryDirectory.path,
      logFileName: "privacy_example.log",
      minimumLevel: .debug
    )

    // Log more complex examples with mixed destinations
    await logAdvancedPrivacyExamples(using: mixedLogger)

    // MARK: - Real-world Scenarios

    // Create a logger specifically for user-related operations
    let userLogger=LoggingServiceFactory.createOSLogger(
      subsystem: "com.umbraapp.example",
      category: "UserServices",
      minimumLevel: .info
    )

    // Demonstrate real-world privacy scenarios
    await logRealWorldScenarios(using: userLogger)

    print("OSLog Privacy Example completed. Check Console.app to view the OSLog output.")
  }

  // MARK: - Example Implementations

  /// Basic privacy examples with simple annotations
  private static func logBasicPrivacyExamples(using logger: LoggingServiceProtocol) async {
    print("Running basic privacy examples...")

    // Public information - visible in logs without restrictions
    let publicInfo=PrivacyAnnotatedString("System started at boot time", privacy: .public)
    await logger.info(publicInfo.description, metadata: nil, source: "PrivacyExample")

    // Private information - redacted in logs unless debug mode enabled
    let privateInfo=PrivacyAnnotatedString("User visited profile page", privacy: .private)
    await logger.debug(privateInfo.description, metadata: nil, source: "PrivacyExample")

    // Sensitive information - strongly redacted in logs
    let sensitiveInfo=PrivacyAnnotatedString("Password reset initiated", privacy: .sensitive)
    await logger.warning(sensitiveInfo.description, metadata: nil, source: "PrivacyExample")

    // Mixing privacy levels in metadata
    var metadata=LogMetadata()
    metadata["feature"]="login"
    metadata["timestamp"]="\(Date())"

    await logger.info(
      PrivacyAnnotatedString("User authentication", privacy: .public).description,
      metadata: metadata,
      source: "PrivacyExample"
    )
  }

  /// More advanced examples showing complex privacy scenarios
  private static func logAdvancedPrivacyExamples(using logger: LoggingServiceProtocol) async {
    print("Running advanced privacy examples...")

    // Example 1: User credential handling
    let username=PrivacyAnnotatedString("johndoe@example.com", privacy: .private)
    let deviceID=PrivacyAnnotatedString("A1B2-C3D4-E5F6", privacy: .private)

    var credentialMetadata=LogMetadata()
    credentialMetadata["auth_method"]="password"
    credentialMetadata["success"]="true"
    credentialMetadata["attempt_count"]="1"

    await logger.info("User login successful", metadata: nil, source: "MixedExample")
    await logger.debug(username.description, metadata: nil, source: "MixedExample")

    // Explicitly log with privacy annotation and metadata privacy level
    await logger.debug(
      deviceID.description,
      metadata: credentialMetadata,
      source: "MixedExample"
    )

    // Example 2: Payment processing
    let creditCardLastFour=PrivacyAnnotatedString("1234", privacy: .public)
    let fullCardNumber=PrivacyAnnotatedString("1234-5678-9012-3456", privacy: .sensitive)
    let transactionAmount=PrivacyAnnotatedString("£49.99", privacy: .public)

    var paymentMetadata=LogMetadata()
    paymentMetadata["payment_processor"]="Stripe"
    paymentMetadata["transaction_id"]="txn_12345"
    paymentMetadata["currency"]="GBP"

    await logger.info("Processing payment", metadata: nil, source: "MixedExample")
    await logger.info(
      PrivacyAnnotatedString(
        "Payment of \(transactionAmount.content) with card ending in \(creditCardLastFour.content)",
        privacy: .public
      ).description,
      metadata: paymentMetadata,
      source: "MixedExample"
    )

    // The sensitive information is logged at debug level with appropriate privacy
    await logger.debug(
      fullCardNumber.description,
      metadata: paymentMetadata,
      source: "MixedExample"
    )
  }

  /// Examples that show real-world privacy scenarios
  private static func logRealWorldScenarios(using logger: LoggingServiceProtocol) async {
    print("Running real-world privacy scenarios...")

    // Scenario 1: User registration
    let newEmail=PrivacyAnnotatedString("newuser@example.com", privacy: .private)
    let ipAddress=PrivacyAnnotatedString("192.168.1.1", privacy: .private)
    let passwordStrength=PrivacyAnnotatedString("Strong", privacy: .public)

    var registrationMeta=LogMetadata()
    registrationMeta["source"]="iOS App"
    registrationMeta["app_version"]="2.1.3"
    registrationMeta["successful"]="true"

    await logger.info("New user registration", metadata: nil, source: "UserServices")
    await logger.debug(newEmail.description, metadata: nil, source: "UserServices")
    await logger.debug(
      ipAddress.description,
      metadata: registrationMeta,
      source: "UserServices"
    )
    await logger.info(
      PrivacyAnnotatedString("Password strength: \(passwordStrength.content)", privacy: .public)
        .description,
      metadata: nil,
      source: "UserServices"
    )

    // Scenario 2: Error reporting with stack trace
    let errorMessage=PrivacyAnnotatedString("Failed to save user preferences", privacy: .public)
    let stackTrace=PrivacyAnnotatedString("""
      at UserPreferencesManager.save(preferences:) line 42
      at ProfileViewController.saveButtonTapped() line 87
      at UIButton.sendAction() line unknown
      """, privacy: .private) // Stack traces might contain sensitive path information

    var errorMeta=LogMetadata()
    errorMeta["error_code"]="E1001"
    errorMeta["recoverable"]="true"

    await logger.error(errorMessage.description, metadata: nil, source: "UserServices")
    await logger.debug(
      stackTrace.description,
      metadata: errorMeta,
      source: "UserServices"
    )

    // Scenario 3: Health app data
    let healthMetric=PrivacyAnnotatedString("Steps", privacy: .public)
    let healthValue=PrivacyAnnotatedString("9,876", privacy: .private) // Private but not sensitive
    let healthCondition=PrivacyAnnotatedString("Diagnosed medical condition", privacy: .sensitive)

    var healthMeta=LogMetadata()
    healthMeta["data_source"]="Apple Health"
    healthMeta["time_period"]="Today"

    await logger.info(
      PrivacyAnnotatedString("Health data sync: \(healthMetric.content)", privacy: .public)
        .description,
      metadata: nil,
      source: "UserServices"
    )
    await logger.debug(
      PrivacyAnnotatedString("Value: \(healthValue.content)", privacy: .private).description,
      metadata: nil,
      source: "UserServices"
    )
    await logger.debug(
      healthCondition.description,
      metadata: healthMeta,
      source: "UserServices"
    )
  }
}

// Example runner
// This function could be called from your application to demonstrate the privacy logging
public func demonstrateOSLogPrivacy() async {
  await OSLogPrivacyExampleRunner.runExample()
}
