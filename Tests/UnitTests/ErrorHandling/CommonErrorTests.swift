@testable import CoreTypesInterfaces
@testable import ErrorHandling
@testable import ErrorHandlingModels
import Testing

final class CommonErrorTests {
  func testErrorDescriptions() {
    // Test dependency unavailable error
    let depError=CommonError.dependencyUnavailable("Database connection")
    #expect(depError.errorDescription == "Required dependency unavailable: Database connection")

    // Test invalid state error
    let stateError=CommonError.invalidState("Repository not initialized")
    #expect(stateError.errorDescription == "Invalid state: Repository not initialized")

    // Test resource unavailable error
    let resourceError=CommonError.resourceUnavailable("Config file missing")
    #expect(resourceError.errorDescription == "Resource unavailable: Config file missing")

    // Test system constraint error
    let sysError=CommonError.systemConstraint("Insufficient permissions")
    #expect(sysError.errorDescription == "System constraint: Insufficient permissions")

    // Test security violation error
    let secError=CommonError.securityViolation("Invalid credentials")
    #expect(secError.errorDescription == "Security violation: Invalid credentials")

    // Test timeout error
    let timeoutError=CommonError.timeout("Network request")
    #expect(timeoutError.errorDescription == "Operation timed out: Network request")
  }

  func testErrorContext() {
    let error=CommonError.dependencyUnavailable("Test service")
    let context=error.withContext(
      source: "TestModule",
      operation: "serviceInit",
      details: "Service initialization failed"
    )

    #expect(context.source == "TestModule")
    #expect(context.message.contains("Service initialization failed"))
    #expect(context.metadata?["operation"] == "serviceInit")
    #expect(error.localizedDescription == "Required dependency unavailable: Test service")
  }
}
