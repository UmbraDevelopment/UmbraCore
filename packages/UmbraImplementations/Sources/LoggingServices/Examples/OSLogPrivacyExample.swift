import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingServices

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
        let osLogger = LoggingServiceFactory.createOSLogger(
            subsystem: "com.umbraapp.example",
            category: "PrivacyExample",
            minimumLevel: .debug
        )
        
        // Log with different privacy levels
        await logBasicPrivacyExamples(using: osLogger)
        
        // MARK: - Mixed Logging Destinations with Privacy
        
        // Create a comprehensive logger with multiple destinations
        let mixedLogger = LoggingServiceFactory.createComprehensiveLogger(
            identifier: "CompleteLogger",
            minimumLevel: .debug,
            osLogSubsystem: "com.umbraapp.example",
            osLogCategory: "MixedExample",
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("privacy_example.log")
        )
        
        // Log more complex examples with mixed destinations
        await logAdvancedPrivacyExamples(using: mixedLogger)
        
        // MARK: - Real-world Scenarios
        
        // Create a logger specifically for user-related operations
        let userLogger = LoggingServiceFactory.createOSLogger(
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
        let publicInfo = PrivacyAnnotatedString("System started at boot time", privacy: .public)
        await logger.info(publicInfo)
        
        // Private information - redacted in logs unless debug mode enabled
        let privateInfo = PrivacyAnnotatedString("User visited profile page", privacy: .private)
        await logger.debug(privateInfo)
        
        // Sensitive information - strongly redacted in logs
        let sensitiveInfo = PrivacyAnnotatedString("Password reset initiated", privacy: .sensitive)
        await logger.warning(sensitiveInfo)
        
        // Mixing privacy levels in metadata
        var metadata = LogMetadata()
        metadata["feature"] = "login"
        metadata["timestamp"] = "\(Date())"
        
        await logger.log(
            level: .info,
            message: PrivacyAnnotatedString("User authentication", privacy: .public),
            metadata: metadata,
            metadataPrivacy: .private  // Metadata is considered private
        )
    }
    
    /// More advanced examples showing complex privacy scenarios
    private static func logAdvancedPrivacyExamples(using logger: LoggingServiceProtocol) async {
        print("Running advanced privacy examples...")
        
        // Example 1: User credential handling
        let username = PrivacyAnnotatedString("johndoe@example.com", privacy: .private)
        let deviceId = PrivacyAnnotatedString("A1B2-C3D4-E5F6", privacy: .private)
        
        var credentialMetadata = LogMetadata()
        credentialMetadata["auth_method"] = "password"
        credentialMetadata["success"] = "true"
        credentialMetadata["attempt_count"] = "1"
        
        await logger.info("User login successful")  // Public message
        await logger.debug(username)  // Private email address
        
        // Explicitly log with privacy annotation and metadata privacy level
        await logger.log(
            level: .debug,
            message: deviceId,
            metadata: credentialMetadata,
            metadataPrivacy: .private
        )
        
        // Example 2: Payment processing
        let creditCardLastFour = PrivacyAnnotatedString("1234", privacy: .public)
        let fullCardNumber = PrivacyAnnotatedString("1234-5678-9012-3456", privacy: .sensitive)
        let transactionAmount = PrivacyAnnotatedString("£49.99", privacy: .public)
        
        var paymentMetadata = LogMetadata()
        paymentMetadata["payment_processor"] = "Stripe"
        paymentMetadata["transaction_id"] = "txn_12345"
        paymentMetadata["currency"] = "GBP"
        
        await logger.info("Processing payment")
        await logger.log(
            level: .info,
            message: PrivacyAnnotatedString("Payment of \(transactionAmount.content) with card ending in \(creditCardLastFour.content)", privacy: .public),
            metadata: paymentMetadata,
            metadataPrivacy: .public
        )
        
        // The sensitive information is logged at debug level with appropriate privacy
        await logger.log(
            level: .debug,
            message: fullCardNumber,
            metadata: paymentMetadata,
            metadataPrivacy: .sensitive
        )
    }
    
    /// Examples that show real-world privacy scenarios
    private static func logRealWorldScenarios(using logger: LoggingServiceProtocol) async {
        print("Running real-world privacy scenarios...")
        
        // Scenario 1: User registration
        let newEmail = PrivacyAnnotatedString("newuser@example.com", privacy: .private)
        let ipAddress = PrivacyAnnotatedString("192.168.1.1", privacy: .private)
        let passwordStrength = PrivacyAnnotatedString("Strong", privacy: .public)
        
        var registrationMeta = LogMetadata()
        registrationMeta["source"] = "iOS App"
        registrationMeta["app_version"] = "2.1.3"
        registrationMeta["successful"] = "true"
        
        await logger.info("New user registration")
        await logger.debug(newEmail)
        await logger.log(level: .debug, message: ipAddress, metadata: registrationMeta)
        await logger.info(PrivacyAnnotatedString("Password strength: \(passwordStrength.content)", privacy: .public))
        
        // Scenario 2: Error reporting with stack trace
        let errorMessage = PrivacyAnnotatedString("Failed to save user preferences", privacy: .public)
        let stackTrace = PrivacyAnnotatedString("""
            at UserPreferencesManager.save(preferences:) line 42
            at ProfileViewController.saveButtonTapped() line 87
            at UIButton.sendAction() line unknown
            """, privacy: .private)  // Stack traces might contain sensitive path information
        
        var errorMeta = LogMetadata()
        errorMeta["error_code"] = "E1001"
        errorMeta["recoverable"] = "true"
        
        await logger.error(errorMessage)
        await logger.log(level: .debug, message: stackTrace, metadata: errorMeta)
        
        // Scenario 3: Health app data
        let healthMetric = PrivacyAnnotatedString("Steps", privacy: .public)
        let healthValue = PrivacyAnnotatedString("9,876", privacy: .private)  // Private but not sensitive
        let healthCondition = PrivacyAnnotatedString("Diagnosed medical condition", privacy: .sensitive)
        
        var healthMeta = LogMetadata()
        healthMeta["data_source"] = "Apple Health"
        healthMeta["time_period"] = "Today"
        
        await logger.info(PrivacyAnnotatedString("Health data sync: \(healthMetric.content)", privacy: .public))
        await logger.debug(PrivacyAnnotatedString("Value: \(healthValue.content)", privacy: .private))
        await logger.log(level: .debug, message: healthCondition, metadata: healthMeta, metadataPrivacy: .sensitive)
    }
}

// Example runner
// This function could be called from your application to demonstrate the privacy logging
public func demonstrateOSLogPrivacy() async {
    await OSLogPrivacyExampleRunner.runExample()
}
