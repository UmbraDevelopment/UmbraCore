# UmbraCoreTests

The UmbraCoreTests module provides testing utilities and helpers for developing and validating UmbraCore components.

## Overview

UmbraCoreTests offers a comprehensive testing infrastructure for UmbraCore, including mock objects, test helpers, and utilities to facilitate unit testing, integration testing, and performance testing of UmbraCore components.

## Features

- Mock implementations of UmbraCore protocols
- Test fixtures and factory methods
- Assertion utilities for UmbraCore-specific validation
- Performance testing helpers
- Sandbox testing utilities
- XPC service testing infrastructure

## Architecture

UmbraCoreTests is organised by the components it helps test:

1. **CoreMocks**: Mock implementations of core protocols
2. **TestFixtures**: Pre-configured test data
3. **TestUtilities**: Helper functions for common testing tasks
4. **SandboxTestHelpers**: Tools for testing in a sandboxed environment
5. **XPCTestHelpers**: Tools for testing XPC service communication

## Usage

```swift
import UmbraCoreTests
import XCTest

class RepositoryTests: XCTestCase {
    private var sut: RepositoryManager!
    private var mockStorage: MockStorageProvider!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockStorageProvider()
        sut = RepositoryManager(storageProvider: mockStorage)
    }
    
    func testRepositoryInitialisation() async throws {
        // Given
        let testRepo = TestFixtures.createTestRepository()
        mockStorage.stubInitialisation(forPath: testRepo.path, toSucceed: true)
        
        // When
        let result = try await sut.initialiseRepository(
            path: testRepo.path,
            password: testRepo.password
        )
        
        // Then
        XCTAssertEqual(result.path, testRepo.path)
        XCTAssertTrue(mockStorage.initialisationWasCalled)
    }
}
```

## Integration

UmbraCoreTests is designed to be used in both unit tests and integration tests for UmbraCore components, providing a consistent testing approach across the framework.
