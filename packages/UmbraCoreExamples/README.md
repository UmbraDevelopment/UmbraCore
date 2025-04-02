# UmbraCore Examples

This package centralises all example code for the UmbraCore project, serving as reference material for developers. These examples demonstrate best practices and usage patterns aligned with the Alpha Dot Five architecture.

## Organisation

The examples are organised by functional domain:

- **Logging**: 
  - Demonstrates privacy-aware logging techniques
  - Shows proper usage of SecureLoggerActor
  - Illustrates logging adapters and integration patterns

- **Crypto**: 
  - Provides examples of cryptographic operations
  - Shows integration between crypto services and secure logging
  - Demonstrates proper key management workflows

- **ErrorHandling**: 
  - Shows domain-specific error handling patterns
  - Illustrates proper error logging with privacy controls
  - Demonstrates error propagation in asynchronous contexts

- **Security**: 
  - Demonstrates the security provider implementation
  - Shows actor-based security service integration
  - Illustrates privacy-by-design principles in action

## Using These Examples

These examples are provided for reference purposes only and need not be compiled as part of the main build process. To make the best use of them:

1. Study the examples relevant to your current development task
2. Note the patterns for actor isolation and concurrency
3. Follow the demonstrated practices for privacy-aware logging
4. Observe how interfaces are separated from implementations

## Alpha Dot Five Architecture Compliance

All examples follow the Alpha Dot Five architectural principles:

1. **Actor-Based Concurrency**: Services utilise Swift actors for thread safety
2. **Provider-Based Abstraction**: Multiple implementation strategies are supported
3. **Privacy-By-Design**: Enhanced privacy-aware error handling and logging
4. **Type Safety**: Using strongly-typed interfaces 
5. **Async/Await**: Full adoption of Swift's modern concurrency model

## Documentation

Additional documentation for specific components can be found in the Documentation directories within each category.
