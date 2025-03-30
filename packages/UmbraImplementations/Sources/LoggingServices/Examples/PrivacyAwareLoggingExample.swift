import Foundation
import LoggingTypes
import LoggingInterfaces

/// Example usage of the privacy-aware logging system
public struct PrivacyAwareLoggingExample {
    /// The logger instance
    private let logger: any PrivacyAwareLoggingProtocol
    
    /// Creates a new example with the specified logger
    /// - Parameter logger: The logger to use
    public init(logger: any PrivacyAwareLoggingProtocol) {
        self.logger = logger
    }
    
    /// Demonstrates basic logging with privacy annotations
    public func demonstrateBasicLogging() async {
        // Basic log with no privacy annotations
        await logger.info(
            "Starting application initialisation",
            metadata: [
                "version": (value: "1.0.0", privacy: .public),
                "buildNumber": (value: "12345", privacy: .public)
            ],
            source: "ApplicationService"
        )
        
        // Log with privacy annotations using PrivacyString
        await logger.log(
            .info,
            "Processing authentication for user \(private: "john.doe@example.com") from IP \(private: "192.168.1.100")",
            metadata: [
                "sessionId": (value: UUID().uuidString, privacy: .public),
                "userAgent": (value: "Mozilla/5.0", privacy: .public)
            ],
            source: "AuthenticationService"
        )
        
        // Log sensitive information
        await logger.logSensitive(
            .debug,
            "Payment processing details",
            sensitiveValues: [
                "cardNumber": "4111-1111-1111-1111",
                "expiryDate": "12/25",
                "cvv": "123"
            ],
            source: "PaymentService"
        )
    }
    
    /// Demonstrates error logging with privacy controls
    public func demonstrateErrorLogging() async {
        do {
            // Simulate an error
            throw ExampleError.processingFailed(
                reason: "Invalid account: john.doe@example.com",
                accountId: "A12345"
            )
        } catch let error as ExampleError {
            // Log the error with privacy controls
            await logger.logError(
                error,
                privacyLevel: .private,
                metadata: [
                    "errorCode": (value: error.errorCode, privacy: .public),
                    "recoverable": (value: error.isRecoverable, privacy: .public),
                    "accountId": (value: error.accountId, privacy: .private)
                ],
                source: "ErrorHandlingService"
            )
        } catch {
            // Log unexpected errors
            await logger.error(
                "Unexpected error: \(error.localizedDescription)",
                metadata: nil,
                source: "ErrorHandlingService"
            )
        }
    }
    
    /// Demonstrates advanced logging with different privacy levels
    public func demonstrateAdvancedLogging() async {
        // Create a user object with sensitive information
        let user = ExampleUser(
            id: "U98765",
            email: "jane.smith@example.com",
            fullName: "Jane Smith",
            dateOfBirth: Date(timeIntervalSince1970: 639532800), // 1990-04-15
            address: "123 Main St, London, UK",
            phoneNumber: "+44 20 1234 5678",
            accountBalance: 1250.75
        )
        
        // Log user information with appropriate privacy levels
        await logger.log(
            .info,
            "User profile accessed: ID: \(public: user.id), Name: \(private: user.fullName)",
            metadata: [
                "userId": (value: user.id, privacy: .public),
                "email": (value: user.email, privacy: .private),
                "fullName": (value: user.fullName, privacy: .private),
                "dateOfBirth": (value: user.dateOfBirth, privacy: .sensitive),
                "address": (value: user.address, privacy: .sensitive),
                "phoneNumber": (value: user.phoneNumber, privacy: .sensitive),
                "accountBalanceRange": (value: getBalanceRange(user.accountBalance), privacy: .public)
            ],
            source: "UserProfileService"
        )
        
        // Log a security event with hash to allow correlation without revealing data
        await logger.log(
            .warning,
            "Multiple failed login attempts for email \(hash: user.email)",
            metadata: [
                "attemptCount": (value: 5, privacy: .public),
                "timeWindow": (value: "10 minutes", privacy: .public),
                "ipAddresses": (value: ["192.168.1.100", "192.168.1.101"], privacy: .hash)
            ],
            source: "SecurityService"
        )
    }
    
    /// Utility method to get a balance range instead of exact value
    /// - Parameter balance: The exact balance
    /// - Returns: A string representation of the balance range
    private func getBalanceRange(_ balance: Double) -> String {
        switch balance {
        case ..<0:
            return "Negative"
        case 0..<100:
            return "0-100"
        case 100..<1000:
            return "100-1000"
        case 1000..<10000:
            return "1000-10000"
        default:
            return "10000+"
        }
    }
}

/// Example error type for demonstration
public enum ExampleError: Error {
    case processingFailed(reason: String, accountId: String)
    
    /// Error code for public logging
    var errorCode: String {
        switch self {
        case .processingFailed:
            return "E001"
        }
    }
    
    /// Whether the error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .processingFailed:
            return true
        }
    }
    
    /// Account ID associated with the error
    var accountId: String {
        switch self {
        case .processingFailed(_, let accountId):
            return accountId
        }
    }
}

/// Example user type for demonstration
public struct ExampleUser {
    let id: String
    let email: String
    let fullName: String
    let dateOfBirth: Date
    let address: String
    let phoneNumber: String
    let accountBalance: Double
}
