# Rate Limiting Documentation

## Overview

The rate limiting system in UmbraCore prevents abuse and ensures fair resource usage for API operations. This system is particularly important for high-security operations that need protection against brute force attacks and other security threats.

## Table of Contents

1. [Architecture](#architecture)
2. [Token Bucket Algorithm](#token-bucket-algorithm)
3. [Key Components](#key-components)
4. [Usage Examples](#usage-examples)
5. [Best Practices](#best-practices)
6. [Configuration Guidelines](#configuration-guidelines)
7. [High-Security Operations](#high-security-operations)

## Architecture

The rate limiting system follows a simple but effective architecture:

1. **RateLimiter**: Implements the token bucket algorithm for individual rate limits.
2. **RateLimiterFactory**: Creates and manages rate limiters for different operations.
3. **Actor-Based Design**: Ensures thread safety for concurrent access.
4. **Domain-Operation Scoping**: Rate limits are scoped to specific domain-operation pairs.

## Token Bucket Algorithm

The rate limiting system uses the token bucket algorithm, which provides flexible rate limiting with burst capabilities:

1. **Bucket Capacity**: Each rate limiter has a maximum capacity of tokens.
2. **Refill Rate**: Tokens are added to the bucket at a specified rate (tokens per second).
3. **Token Consumption**: Each operation consumes one or more tokens from the bucket.
4. **Burst Handling**: The bucket can temporarily handle bursts of traffic up to its capacity.

### Advantages

- **Flexibility**: Allows for both average rate limiting and burst handling.
- **Simplicity**: Easy to understand and implement.
- **Efficiency**: Low computational overhead.
- **Fairness**: Provides fair resource allocation.

## Key Components

### RateLimiter

Implements the token bucket algorithm for individual rate limits.

```swift
public actor RateLimiter {
    private let capacity: Int
    private let refillRate: Double
    private var tokens: Double
    private var lastRefillTimestamp: Date
    
    public init(capacity: Int, refillRate: Double)
    
    public func tryConsume(count: Int = 1) -> Bool
    public func consume(count: Int = 1, timeout: TimeInterval? = nil) async -> Bool
    private func refillTokens()
    public func reset()
}
```

### RateLimiterFactory

Creates and manages rate limiters for different operations.

```swift
public actor RateLimiterFactory {
    public static let shared = RateLimiterFactory()
    private var limiters: [String: RateLimiter] = [:]
    
    public func getRateLimiter(
        domain: String,
        operation: String,
        capacity: Int = 10,
        refillRate: Double = 1.0
    ) async -> RateLimiter
    
    public func getHighSecurityRateLimiter(
        domain: String,
        operation: String
    ) async -> RateLimiter
    
    public func resetAll() async
    public func reset(domain: String, operation: String) async
}
```

## Usage Examples

### Basic Rate Limiting

```swift
// Get a rate limiter for an operation
let rateLimiter = await RateLimiterFactory.shared.getRateLimiter(
    domain: "security",
    operation: "encryptData",
    capacity: 10,
    refillRate: 1.0  // 1 token per second
)

// Try to consume a token
if await rateLimiter.tryConsume() {
    // Proceed with the operation
    try await performOperation()
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for encryption operations",
        retryAfter: 1
    )
}
```

### High-Security Rate Limiting

```swift
// Get a rate limiter for a high-security operation
let rateLimiter = await RateLimiterFactory.shared.getHighSecurityRateLimiter(
    domain: "security",
    operation: "generateKey"
)

// Try to consume a token
if await rateLimiter.tryConsume() {
    // Proceed with the high-security operation
    try await generateKey()
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for key generation operations",
        retryAfter: 5
    )
}
```

### Waiting for Tokens

```swift
// Get a rate limiter
let rateLimiter = await RateLimiterFactory.shared.getRateLimiter(
    domain: "repository",
    operation: "createRepository"
)

// Try to consume a token, waiting up to 5 seconds if necessary
if await rateLimiter.consume(timeout: 5.0) {
    // Proceed with the operation
    try await createRepository()
} else {
    // Rate limit exceeded and timeout expired
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for repository creation",
        retryAfter: 1
    )
}
```

### Consuming Multiple Tokens

```swift
// Get a rate limiter
let rateLimiter = await RateLimiterFactory.shared.getRateLimiter(
    domain: "backup",
    operation: "createSnapshot"
)

// Try to consume multiple tokens based on operation weight
let dataSize = calculateDataSize()
let tokensNeeded = max(1, dataSize / (1024 * 1024))  // 1 token per MB

if await rateLimiter.tryConsume(count: tokensNeeded) {
    // Proceed with the operation
    try await createSnapshot()
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for snapshot creation",
        retryAfter: Double(tokensNeeded)
    )
}
```

## Best Practices

When working with the rate limiting system, follow these best practices:

1. **Use Domain-Specific Rate Limits**: Configure rate limits based on the specific requirements of each domain and operation.

2. **Apply Stricter Limits for Sensitive Operations**: Use stricter rate limits for high-security operations.

3. **Consider Resource Consumption**: Adjust token consumption based on the resource intensity of operations.

4. **Handle Rate Limit Errors Gracefully**: Provide clear feedback to users when rate limits are exceeded.

5. **Include Retry-After Information**: When returning rate limit errors, include information about when the operation can be retried.

6. **Reset Rate Limiters When Appropriate**: Reset rate limiters when conditions change (e.g., after authentication).

7. **Monitor Rate Limit Hits**: Log and monitor rate limit hits to identify potential abuse.

8. **Test Rate Limiting Behaviour**: Verify that rate limiting works correctly in different scenarios.

9. **Use the Factory Pattern**: Always create rate limiters through the `RateLimiterFactory` to ensure proper configuration and reuse.

10. **Consider User Experience**: Balance security with user experience when configuring rate limits.

## Configuration Guidelines

### Standard Operations

For standard operations, consider the following guidelines:

| Operation Type | Capacity | Refill Rate | Notes |
|----------------|----------|-------------|-------|
| Read           | 20-50    | 10-20/sec   | Higher limits for read operations |
| Write          | 5-10     | 1-5/sec     | Lower limits for write operations |
| List           | 5-10     | 1-5/sec     | Moderate limits for list operations |
| Delete         | 2-5      | 0.5-1/sec   | Stricter limits for delete operations |

### High-Security Operations

For high-security operations, consider the following guidelines:

| Operation Type | Capacity | Refill Rate | Notes |
|----------------|----------|-------------|-------|
| Authentication | 3-5      | 0.2-1/sec   | Prevent brute force attacks |
| Key Generation | 2-3      | 0.1-0.2/sec | Very strict limits for key generation |
| Encryption     | 5-10     | 1-2/sec     | Moderate limits for encryption |
| Decryption     | 5-10     | 1-2/sec     | Moderate limits for decryption |

## High-Security Operations

High-security operations require special consideration for rate limiting:

### Key Generation

Key generation operations should have strict rate limits to prevent abuse:

```swift
// Get a high-security rate limiter for key generation
let rateLimiter = await RateLimiterFactory.shared.getHighSecurityRateLimiter(
    domain: "security",
    operation: "generateKey"
)

// Try to consume a token
if await rateLimiter.tryConsume() {
    // Proceed with key generation
    let key = try await securityService.generateKey(algorithm: "AES-256")
    return key
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for key generation operations",
        retryAfter: 5
    )
}
```

### Authentication

Authentication operations should have strict rate limits to prevent brute force attacks:

```swift
// Get a high-security rate limiter for authentication
let rateLimiter = await RateLimiterFactory.shared.getHighSecurityRateLimiter(
    domain: "auth",
    operation: "login"
)

// Try to consume a token
if await rateLimiter.tryConsume() {
    // Proceed with authentication
    let result = try await authService.authenticate(username: username, password: password)
    return result
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Too many login attempts. Please try again later.",
        retryAfter: 30
    )
}
```

### Sensitive Data Access

Operations that access sensitive data should have appropriate rate limits:

```swift
// Get a high-security rate limiter for sensitive data access
let rateLimiter = await RateLimiterFactory.shared.getHighSecurityRateLimiter(
    domain: "data",
    operation: "accessSensitive"
)

// Try to consume a token
if await rateLimiter.tryConsume() {
    // Proceed with sensitive data access
    let data = try await dataService.getSensitiveData(id: dataId)
    return data
} else {
    // Rate limit exceeded
    throw APIError.rateLimitExceeded(
        message: "Rate limit exceeded for sensitive data access",
        retryAfter: 10
    )
}
```
