import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/**
 # Secure Logger Actor Example
 
 This example demonstrates how to use the new SecureLoggerActor for privacy-aware
 logging in security-sensitive applications following the Alpha Dot Five
 architecture principles.
 
 The SecureLoggerActor provides specific features for handling sensitive data:
 
 1. **Privacy Tagging**: Explicit marking of data sensitivity levels
 2. **Actor Isolation**: Thread-safe logging through Swift actors
 3. **Structured Security Events**: Specific methods for logging security operations
 4. **Integration**: Works with the broader logging infrastructure
 
 ## Key Privacy Concepts
 
 In privacy-aware logging, data is categorised into three levels:
 
 - **Public**: Information that can be safely logged in plain text
 - **Private**: Information that should be redacted in most contexts
 - **Sensitive**: Information that should never appear in logs
 
 ## Usage Guidelines
 
 - Always explicitly tag data with privacy levels
 - Use security events for operational logging
 - Never log credentials even with privacy markers
 - Provide proper context for security auditing
 */
public struct SecureLoggerActorExample {
  /// The secure logger instance
  private let secureLogger: SecureLoggerActor
  
  /**
   Creates a new example with a secure logger instance.
   
   - Parameter secureLogger: Optional secure logger (will create one if not provided)
   */
  public init(secureLogger: SecureLoggerActor? = nil) {
    if let secureLogger = secureLogger {
      self.secureLogger = secureLogger
    } else {
      // Create a new secure logger with default settings
      self.secureLogger = SecureLoggerActor(
        subsystem: "com.umbra.example",
        category: "SecureLoggerExample"
      )
    }
  }
  
  /**
   Demonstrates basic secure logging with privacy tagging.
   */
  public func demonstrateBasicSecureLogging() async {
    // Basic informational log with public data
    await secureLogger.info(
      "Application started successfully",
      metadata: [
        "version": PrivacyTaggedValue(value: "1.5.0", privacyLevel: .public),
        "environment": PrivacyTaggedValue(value: "production", privacyLevel: .public)
      ]
    )
    
    // Log containing both public and private data
    await secureLogger.info(
      "User login successful",
      metadata: [
        "sessionId": PrivacyTaggedValue(value: "sess_123456", privacyLevel: .public),
        "userEmail": PrivacyTaggedValue(value: "jane.smith@example.com", privacyLevel: .private),
        "ipAddress": PrivacyTaggedValue(value: "192.168.1.100", privacyLevel: .private)
      ]
    )
    
    // Log containing sensitive data that will be fully redacted
    await secureLogger.info(
      "Payment processed",
      metadata: [
        "transactionId": PrivacyTaggedValue(value: "txn_987654", privacyLevel: .public),
        "cardNumber": PrivacyTaggedValue(value: "4111-1111-1111-1111", privacyLevel: .sensitive),
        "cvv": PrivacyTaggedValue(value: "123", privacyLevel: .sensitive)
      ]
    )
  }
  
  /**
   Demonstrates logging security events with proper context.
   */
  public func demonstrateSecurityEventLogging() async {
    // Log a successful authentication event
    await secureLogger.securityEvent(
      action: "UserAuthentication",
      status: .success,
      subject: "jane.smith@example.com",  // Automatically handled as private
      resource: "UserAccount",
      additionalMetadata: [
        "ipAddress": PrivacyTaggedValue(value: "192.168.1.100", privacyLevel: .private),
        "authMethod": PrivacyTaggedValue(value: "password", privacyLevel: .public),
        "sessionId": PrivacyTaggedValue(value: "sess_123456", privacyLevel: .public)
      ]
    )
    
    // Log a failed encryption operation
    await secureLogger.securityEvent(
      action: "DataEncryption",
      status: .failed,
      subject: nil,
      resource: "document.pdf",
      additionalMetadata: [
        "errorCode": PrivacyTaggedValue(value: "E1001", privacyLevel: .public),
        "errorMessage": PrivacyTaggedValue(value: "Invalid key format", privacyLevel: .public)
      ]
    )
    
    // Log a denied access attempt
    await secureLogger.securityEvent(
      action: "FileAccess",
      status: .denied,
      subject: "jane.smith@example.com",
      resource: "/secure/financial/2024_budget.xlsx",
      additionalMetadata: [
        "reason": PrivacyTaggedValue(value: "Insufficient permissions", privacyLevel: .public),
        "requiredRole": PrivacyTaggedValue(value: "Finance_Admin", privacyLevel: .public)
      ]
    )
  }
  
  /**
   Demonstrates error handling with privacy-aware logging.
   */
  public func demonstrateErrorLogging() async {
    // Simulate an error
    let error = NSError(
      domain: "com.umbra.example",
      code: 404,
      userInfo: [NSLocalizedDescriptionKey: "Resource not found"]
    )
    
    // Log the error with privacy context
    await secureLogger.error(
      "Failed to access resource",
      metadata: [
        "errorCode": PrivacyTaggedValue(value: error.code, privacyLevel: .public),
        "errorDomain": PrivacyTaggedValue(value: error.domain, privacyLevel: .public),
        "resourcePath": PrivacyTaggedValue(value: "/users/123/profile", privacyLevel: .private),
        "requestId": PrivacyTaggedValue(value: "req_abc123", privacyLevel: .public)
      ]
    )
  }
  
  /**
   Demonstrates practical usage of the secure logger in a real-world scenario.
   */
  public func demonstrateSecureTransactionProcessing() async {
    // 1. Log the start of a transaction with appropriate privacy levels
    await secureLogger.info(
      "Starting transaction processing",
      metadata: [
        "transactionId": PrivacyTaggedValue(value: "txn_abc123", privacyLevel: .public),
        "transactionType": PrivacyTaggedValue(value: "purchase", privacyLevel: .public),
        "accountId": PrivacyTaggedValue(value: "acct_12345", privacyLevel: .private),
        "amount": PrivacyTaggedValue(value: "250.00 GBP", privacyLevel: .public)
      ]
    )
    
    // 2. Log a security event for the transaction validation
    await secureLogger.securityEvent(
      action: "TransactionValidation",
      status: .success,
      subject: "acct_12345",
      resource: "txn_abc123",
      additionalMetadata: [
        "validationRule": PrivacyTaggedValue(value: "amount_limit", privacyLevel: .public),
        "ruleOutcome": PrivacyTaggedValue(value: "passed", privacyLevel: .public)
      ]
    )
    
    // 3. Simulate some processing and log the completion (with potential error handling)
    do {
      // Simulate processing...
      
      // 4. Log successful completion
      await secureLogger.info(
        "Transaction completed successfully",
        metadata: [
          "transactionId": PrivacyTaggedValue(value: "txn_abc123", privacyLevel: .public),
          "processingTime": PrivacyTaggedValue(value: "235ms", privacyLevel: .public),
          "status": PrivacyTaggedValue(value: "completed", privacyLevel: .public)
        ]
      )
    } catch {
      // 5. Log failure with appropriate context
      await secureLogger.error(
        "Transaction processing failed",
        metadata: [
          "transactionId": PrivacyTaggedValue(value: "txn_abc123", privacyLevel: .public),
          "errorMessage": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
          "currentStage": PrivacyTaggedValue(value: "payment_processing", privacyLevel: .public)
        ]
      )
    }
  }
  
  /**
   Best practices for logging in cryptographic operations.
   */
  public func demonstrateCryptographicOperationLogging() async {
    // 1. Log the start of an encryption operation (note we don't log the actual key)
    await secureLogger.info(
      "Starting encryption operation",
      metadata: [
        "operationId": PrivacyTaggedValue(value: "op_encrypt_123", privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "AES-256-GCM", privacyLevel: .public),
        "keyIdentifier": PrivacyTaggedValue(value: "key_master_2024", privacyLevel: .private)
      ]
    )
    
    // 2. Log security event for key access
    await secureLogger.securityEvent(
      action: "KeyAccess",
      status: .success,
      subject: "CryptoService",
      resource: "key_master_2024",
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "encrypt", privacyLevel: .public),
        "keyType": PrivacyTaggedValue(value: "AES-256", privacyLevel: .public)
      ]
    )
    
    // 3. Log completion with appropriate metrics but no sensitive data
    await secureLogger.info(
      "Encryption operation completed",
      metadata: [
        "operationId": PrivacyTaggedValue(value: "op_encrypt_123", privacyLevel: .public),
        "durationMs": PrivacyTaggedValue(value: 45, privacyLevel: .public),
        "outputSize": PrivacyTaggedValue(value: "2.5 MB", privacyLevel: .public),
        "status": PrivacyTaggedValue(value: "success", privacyLevel: .public)
      ]
    )
  }
}

/**
 Entry point for running the examples.
 */
public func runSecureLoggerExamples() async {
  print("Running Secure Logger Actor Examples...")
  
  // Create a secure logger instance
  let secureLogger = await LoggingServices.createSecureLogger(
    category: "SecureLoggerExamples"
  )
  
  // Create and run the examples
  let examples = SecureLoggerActorExample(secureLogger: secureLogger)
  
  await examples.demonstrateBasicSecureLogging()
  await examples.demonstrateSecurityEventLogging()
  await examples.demonstrateErrorLogging()
  await examples.demonstrateSecureTransactionProcessing()
  await examples.demonstrateCryptographicOperationLogging()
  
  print("Examples completed. Check logs for output.")
}
