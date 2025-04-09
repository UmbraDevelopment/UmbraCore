# Secure Logging Integration Guide for UmbraCore Security Services

This guide outlines the remaining security services that should be updated to use `SecureLoggerActor` for privacy-aware logging, following the Alpha Dot Five architecture principles.

## Overview

The Alpha Dot Five architecture requires all security-sensitive components to use privacy-aware logging to prevent data leakage and ensure proper handling of sensitive information. We have already updated the following components:

- `DefaultCryptoServiceImpl`
- `SecurityServiceActor`
- `SecureLoggerActor` itself
- `SecureStorageActor`
- `KeyManagementActor`
- `SecurityLogger`

This document identifies the remaining components that need to be updated and provides guidance on integration patterns.

## Remaining Components to Update

### 1. Core Security Provider Service (`CoreSecurityProviderService`)

The core security provider service in `SecurityProviderImpl.swift` needs to be updated to use `SecureLoggerActor` for all security-sensitive operations.

**Priority: High**

Current implementation uses regular logging for security operations:
```swift
await logger.info("Initializing security provider service")
// Should use secureLogger.securityEvent instead for sensitive operations
```

Pattern to follow:
```swift
await secureLogger.securityEvent(
  action: "SecurityProviderInitialisation",
  status: .success,
  subject: nil,
  resource: nil,
  additionalMetadata: [
    "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
  ]
)
```

### 2. Component Services in the Security Provider

The following component services used by the security provider should be updated:

- **EncryptionService**
- **SignatureService**
- **SecureStorageService**
- **HashingService**

**Priority: High**

Each of these services should accept a `SecureLoggerActor` in their initialiser and use it for privacy-aware logging of sensitive operations.

### 3. Security Service Factory

Already updated in the recent changes to use `SecureLoggerActor` for all factory methods.

### 4. Security Utilities

The following security utility classes should be updated:

- **SecurityUtilities**
- **SecurityOperationsErrorHandler**
- **SecurityMetricsCollector**

**Priority: Medium**

These utilities should be updated to work with `SecureLoggerActor` for privacy-aware error handling and metrics collection.

### 5. SecurityProvider Extensions

The following extensions should be updated:

- **SecurityProvider+Logging**
- **SecurityProvider+Operations**
- **SecurityProvider+Validation**

**Priority: Medium**

These extensions should be updated to use `SecureLoggerActor` for all security-sensitive operations.

### 6. SecurityDomainHandler

The security domain handler in the API layer should be updated to use `SecureLoggerActor` for logging security-related API operations.

**Priority: Medium**

### 7. Security Bookmark Actor

Already updated to use `SecureLoggerActor` for privacy-aware logging.

## Integration Patterns

When updating these components, follow these integration patterns:

### 1. Constructor Injection

```swift
public init(
  // other dependencies
  logger: LoggingProtocol,
  secureLogger: SecureLoggerActor? = nil
) {
  self.logger = logger
  self.secureLogger = secureLogger ?? SecureLoggerActor(
    subsystem: "com.umbra.security",
    category: "ComponentName",
    includeTimestamps: true
  )
  // other initialisation
}
```

### 2. Factory Method Integration

```swift
public static func create(
  // other parameters
  logger: LoggingProtocol? = nil,
  secureLogger: SecureLoggerActor? = nil
) -> Self {
  let actualLogger = logger ?? LoggingServices.createService()
  let actualSecureLogger = secureLogger ?? LoggingServices.createSecureLogger(
    category: "ComponentName"
  )
  
  return Self(
    // other arguments
    logger: actualLogger,
    secureLogger: actualSecureLogger
  )
}
```

### 3. Privacy-Aware Logging Pattern

```swift
// General info logging with standard logger
await logger.info("Operation starting")

// Security-sensitive logging with secure logger
await secureLogger.securityEvent(
  action: "SecurityOperation",
  status: .success,
  subject: nil,
  resource: resourceIdentifier,
  additionalMetadata: [
    "operation": PrivacyTaggedValue(value: operationType, privacyLevel: .public),
    "dataSize": PrivacyTaggedValue(value: dataSize, privacyLevel: .public),
    "keyIdentifier": PrivacyTaggedValue(value: keyId, privacyLevel: .private),
    "phase": PrivacyTaggedValue(value: "start", privacyLevel: .public)
  ]
)
```

## Testing

When updating components to use `SecureLoggerActor`, ensure that:

1. All security-sensitive operations are logged with appropriate privacy tags
2. No sensitive data is logged without proper privacy controls
3. Log events include appropriate context (operation type, phase, etc.)
4. Error cases are properly logged with privacy controls

## References

- [PrivacyAwareLoggingGuide.md](/Users/mpy/CascadeProjects/UmbraCore/packages/UmbraImplementations/Sources/LoggingServices/Documentation/PrivacyAwareLoggingGuide.md) - Comprehensive guide to privacy-aware logging in UmbraCore
- [SecureLoggerActorExample.swift](/Users/mpy/CascadeProjects/UmbraCore/packages/UmbraImplementations/Sources/LoggingServices/Examples/SecureLoggerActorExample.swift) - Example usage patterns
- [CryptoServicesWithSecureLoggingExample.swift](/Users/mpy/CascadeProjects/UmbraCore/packages/UmbraImplementations/Sources/CryptoServices/Examples/CryptoServicesWithSecureLoggingExample.swift) - Example of integration with crypto services
