# Privacy-Aware Logging Guide for UmbraCore

This document provides guidelines and best practices for using the privacy-aware logging capabilities in UmbraCore, following the Alpha Dot Five architecture principles.

## Core Concepts

### Privacy Levels

UmbraCore's logging system uses three distinct privacy levels:

1. **Public** - Information that can be safely logged in plain text
   - Version numbers, timestamps, operation types
   - Status codes, error types (without specific details)
   - Public identifiers and metrics

2. **Private** - Information that should be partially redacted
   - User IDs, email addresses
   - IP addresses
   - File paths and resource identifiers
   - Session IDs

3. **Sensitive** - Information that should never appear in logs
   - Passwords, access tokens, API keys
   - Cryptographic keys or seeds
   - Personal data (name, address, phone)
   - Financial information (card numbers, account details)

### Privacy Tagging

All data logged through the system should be explicitly tagged with its privacy level:

```swift
secureLogger.info(
  "User login successful",
  metadata: [
    "sessionId": PrivacyTaggedValue(value: "sess_123456", privacyLevel: .public),
    "userEmail": PrivacyTaggedValue(value: "jane.smith@example.com", privacyLevel: .private),
    "ipAddress": PrivacyTaggedValue(value: "192.168.1.100", privacyLevel: .private)
  ]
)
```

## Actor-Based Secure Logging

The `SecureLoggerActor` is the primary interface for privacy-aware logging in UmbraCore. It provides robust privacy controls while maintaining thread safety through actor isolation.

### Creating a Secure Logger

```swift
// Option 1: Create directly
let secureLogger = SecureLoggerActor(
  subsystem: "com.umbra.myservice",
  category: "SecurityOperations",
  includeTimestamps: true
)

// Option 2: Use LoggingServices factory (recommended)
let secureLogger = await LoggingServices.createSecureLogger(
  category: "SecurityOperations"
)
```

### Basic Logging with Privacy Controls

```swift
await secureLogger.info(
  "Processing payment",
  metadata: [
    "transactionId": PrivacyTaggedValue(value: "txn_123456", privacyLevel: .public),
    "amount": PrivacyTaggedValue(value: "£250.00", privacyLevel: .public),
    "accountId": PrivacyTaggedValue(value: "acct_98765", privacyLevel: .private),
    "cardNumber": PrivacyTaggedValue(value: "4111-1111-1111-1111", privacyLevel: .sensitive)
  ]
)
```

### Security Event Logging

For security-specific events, use the dedicated `securityEvent` method:

```swift
await secureLogger.securityEvent(
  action: "UserAuthentication",
  status: .success,  // .success, .failed, .denied, .unknown
  subject: "jane.smith@example.com",  // Automatically treated as private
  resource: "UserAccount",
  additionalMetadata: [
    "ipAddress": PrivacyTaggedValue(value: "192.168.1.100", privacyLevel: .private),
    "authMethod": PrivacyTaggedValue(value: "password", privacyLevel: .public),
    "sessionId": PrivacyTaggedValue(value: "sess_123456", privacyLevel: .public)
  ]
)
```

## Best Practices

### 1. Always Tag Privacy Levels Explicitly

Never assume a default privacy level:

```swift
// GOOD - Explicit privacy tagging
"userId": PrivacyTaggedValue(value: user.id, privacyLevel: .private)

// BAD - No explicit privacy level
"userId": user.id
```

### 2. Log Operations, Not Data

Focus on the operation being performed, not the data itself:

```swift
// GOOD - Focus on operation
await secureLogger.info(
  "Encryption operation completed",
  metadata: [
    "operationId": PrivacyTaggedValue(value: "op_123", privacyLevel: .public),
    "dataSize": PrivacyTaggedValue(value: "2.5 MB", privacyLevel: .public)
  ]
)

// BAD - Logging the data itself
await logger.info("Encrypted data: \(encryptedString)")
```

### 3. Use Appropriate Log Levels

- **Critical**: System is unusable or severe security incidents
- **Error**: Operation failed but system can continue
- **Warning**: Potential issues or security concerns
- **Info**: Important operational events
- **Debug**: Detailed information for troubleshooting
- **Trace**: Fine-grained details (generally not used in production)

### 4. Structure Security Event Logs

Security events should be structured consistently:

1. **Action**: What operation was performed (e.g., "UserLogin", "FileAccess")
2. **Status**: Result of the operation (success, denied, failed)
3. **Subject**: Who performed the action (always treated as private)
4. **Resource**: What was accessed (file, service, etc.)
5. **Metadata**: Additional contextual information

### 5. Never Log Credentials, Even with Privacy Markers

Even with `.sensitive` privacy level, avoid logging:

- Passwords in any form
- Private keys or certificates
- Authentication tokens
- Biometric data
- Payment details

### 6. Monitor Log Output in Production

- Periodically audit logs to ensure sensitive data isn't leaking
- Set up alerts for potential privacy breaches
- Review logging practices when adding new features

## Integrating SecureLogger in Your Components

### For Service Components

```swift
public actor MySecurityService {
  private let secureLogger: SecureLoggerActor
  
  public init(secureLogger: SecureLoggerActor? = nil) {
    self.secureLogger = secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.myservice",
      category: "MySecurityService"
    )
  }
  
  public func performSecureOperation() async {
    await secureLogger.info("Starting secure operation...")
    
    // Operation implementation
    
    await secureLogger.securityEvent(
      action: "SecureOperation",
      status: .success,
      subject: nil,
      resource: "protected-resource",
      additionalMetadata: [
        "processingTime": PrivacyTaggedValue(value: "125ms", privacyLevel: .public)
      ]
    )
  }
}
```

### For Factory Components

```swift
public enum MyServiceFactory {
  public static func createService() async -> MySecurityService {
    // Create a secure logger
    let secureLogger = await LoggingServices.createSecureLogger(
      category: "MySecurityService"
    )
    
    // Create service with the secure logger
    return MySecurityService(secureLogger: secureLogger)
  }
}
```

## Examples

For complete working examples, see:

- `SecureLoggerActorExample.swift` in the LoggingServices module
- `DefaultCryptoServiceImpl.swift` in the CryptoServices module
- `SecurityBookmarkActor.swift` in the BookmarkServices module

## Migration from Legacy Logging

If you're migrating from the legacy `SecureLogger` class, use this pattern:

```swift
// Old usage
let logger = SecureLogger(category: "Authentication")
logger.info("User login")

// New usage (with LoggingServices)
let secureLogger = await LoggingServices.createSecureLogger(category: "Authentication")
await secureLogger.info("User login")
```

## Further Reading

- [Alpha Dot Five Architecture Guide](link/to/internal/docs)
- [UmbraCore Security Best Practices](link/to/internal/docs)
- [Error Handling and Logging Integration](link/to/internal/docs)
