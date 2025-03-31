# Alpha Dot Five Error Handling Standards

This document outlines the standardised approach to error handling in the Alpha Dot Five architecture. Following these guidelines ensures proper Swift 6 compliance, actor isolation, and maintainable error management.

## Core Principles

1. **No Typealiases**:
   - ❌ Avoid: `public typealias ErrorType = String`
   - ✅ Use: `public struct ErrorType: Error, Sendable { ... }`

2. **Descriptive Names**:
   - ❌ Avoid: `var err: Error`
   - ✅ Use: `var validationError: ValidationError`

3. **Swift 6 Compliance**:
   - All error types must conform to `Sendable`
   - Nested types (enums, etc.) must also be `Sendable`
   - Error properties must be immutable (`let` not `var`)

4. **Proper Actor Isolation**:
   - Errors must be safely shareable across actor boundaries
   - Factory methods should be properly isolated

5. **British English Spelling**:
   - Use British spelling in documentation and error messages
   - Examples: "unauthorised" (not "unauthorized"), "centralised" (not "centralized")

## Standard Error Structure

```swift
public struct DomainSpecificError: Error, CustomStringConvertible, Sendable {
    /// The specific error classification
    public enum ErrorCode: String, Sendable {
        case specificProblem
        case anotherSpecificProblem
        // Additional cases as needed
    }

    /// The categorised error code
    public let errorCode: ErrorCode

    /// Human-readable description with British spelling
    public let description: String

    /// Source information for error tracing
    public let errorSource: ErrorSource?

    /// Underlying cause if applicable
    public let underlyingError: Error?

    /// Creates a new error with the specified parameters
    public init(
        code: ErrorCode,
        description: String,
        source: ErrorSource? = nil,
        underlyingError: Error? = nil
    ) {
        self.errorCode = code
        self.description = description
        self.errorSource = source
        self.underlyingError = underlyingError
    }
}
```

## Factory Methods Pattern

Provide static factory methods for common error scenarios:

```swift
extension DomainSpecificError {
    public static func specificProblem(
        reason: String,
        source: ErrorSource? = nil
    ) -> DomainSpecificError {
        DomainSpecificError(
            code: .specificProblem,
            description: "Specific problem occurred: \(reason)",
            source: source
        )
    }
}
```

## Error Propagation

When propagating errors across module boundaries:

1. Map domain-specific errors to appropriate error types
2. Preserve original error information where possible
3. Add context information at each level

```swift
do {
    try await someOperation()
} catch let specificError as SpecificError {
    throw HigherLevelError.operationFailed(
        reason: "Higher-level context: \(specificError.description)",
        underlyingError: specificError
    )
}
```

## Actor-Based Error Handling

In actors, ensure error handling is async-compatible:

```swift
public actor SomeActor {
    public func riskyOperation() async throws -> Result {
        do {
            return try await performRiskyTask()
        } catch {
            await logger.error("Operation failed: \(error.localizedDescription)")
            throw DomainError.operationFailed(
                reason: "Could not complete operation", 
                underlyingError: error
            )
        }
    }
}
```

## Migration Guidelines

When migrating legacy error handling to Alpha Dot Five:

1. Replace typealiases with proper struct/enum types
2. Add Sendable conformance to all error types
3. Use descriptive property and method names
4. Eliminate legacy bridges and adapters
5. Update documentation with British spelling
6. Ensure proper actor isolation for concurrent contexts
