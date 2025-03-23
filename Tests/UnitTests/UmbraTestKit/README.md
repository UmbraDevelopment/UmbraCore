# UmbraTestKit

UmbraTestKit is a comprehensive test utilities library for UmbraCore, providing mock implementations and test infrastructure for secure, sandbox-aware testing.

## Overview

The module provides a robust set of testing utilities specifically designed for UmbraCore's security-focused features:

- Mock implementations of core services
- Sandbox-aware test infrastructure
- Security-scoped resource simulation
- Thread-safe testing utilities

## Module Structure

```
UmbraTestKit/
├── Core/           # Core test utilities
├── Mocks/         # Mock implementations
├── Protocols/     # Test-specific protocols
└── TestCases/     # Base test case classes
```

## Key Components

### Mock Implementations

- `MockCryptoService`: Simulates cryptographic operations
- `MockKeychain`: Simulates secure storage operations
- `MockSecurityProvider`: Simulates security and permission checks
- `MockFileManager`: Simulates file system operations
- `MockURLProvider`: Simulates URL handling

### Test Infrastructure

- `SandboxTestCase`: Base class for sandbox-aware tests
  - Provides temporary directory management
  - Simulates security-scoped resource access
  - Handles test file creation and cleanup

## Usage

### Basic Test Setup

```swift
class MyTests: SandboxTestCase {
    func testSecureFileAccess() async throws {
        // Create a test file with specific permissions
        let fileURL = try await createTestFile(
            name: "test.txt",
            content: "Test content",
            access: .readWrite
        )
        
        // Test your code using the mock file system
        let result = try await yourCode.processFile(at: fileURL)
        
        // Verify results
        XCTAssertEqual(result.content, "Test content")
    }
}
```

### Using Mock Services

```swift
// Initialize mock services
let mockSecurity = MockSecurityProvider()
let mockCrypto = MockCryptoService()

// Configure behaviour
mockSecurity.setPermission(.readWrite, for: "path/to/file")

// Use in your tests
let result = try await mockSecurity.validateAccess(to: "path/to/file")
XCTAssertTrue(result)
```

## Thread Safety

All mock implementations are thread-safe and properly handle concurrent access:

- Uses Swift actors for state isolation
- Supports async/await patterns
- Maintains strict concurrency checking

## Build Configuration

The module is configured with strict safety checks:

```python
swift_library(
    name = "UmbraTestKit",
    testonly = True,
    copts = [
        "-strict-concurrency=complete",
        "-warn-concurrency",
        "-enable-actor-data-race-checks",
    ],
)
```

## Contributing

When adding new test utilities:

1. Ensure thread safety through proper actor isolation
2. Maintain strict concurrency checking
3. Follow existing mock patterns
4. Add comprehensive documentation
5. Include usage examples in tests
