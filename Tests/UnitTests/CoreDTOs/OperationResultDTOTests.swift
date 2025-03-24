@testable import CoreDTOs
import UmbraCoreTypes
import XCTest

final class OperationResultDTOTests: XCTestCase {
  // Test initialization with success value
  func testInitializationWithSuccessValue() {
    // Arrange & Act
    let result=OperationResultDTO<String>.success("Test Successful")

    // Assert
    XCTAssertEqual(result.status, .success)
    XCTAssertEqual(result.value, "Test Successful")
    XCTAssertNil(result.errorCode)
    XCTAssertNil(result.errorMessage)
    XCTAssertTrue(result.isSuccess)
    XCTAssertFalse(result.isFailure)
    XCTAssertFalse(result.isCancelled)
  }

  // Test initialization with failure
  func testInitializationWithFailure() {
    // Arrange & Act
    let result=OperationResultDTO<String>.failure(errorCode: 404, errorMessage: "Not Found")

    // Assert
    XCTAssertEqual(result.status, .failure)
    XCTAssertNil(result.value)
    XCTAssertEqual(result.errorCode, 404)
    XCTAssertEqual(result.errorMessage, "Not Found")
    XCTAssertFalse(result.isSuccess)
    XCTAssertTrue(result.isFailure)
    XCTAssertFalse(result.isCancelled)
  }

  // Test initialization with cancellation
  func testInitializationWithCancellation() {
    // Arrange & Act
    let result=OperationResultDTO<String>.cancelled("Operation was cancelled")

    // Assert
    XCTAssertEqual(result.status, .cancelled)
    XCTAssertNil(result.value)
    XCTAssertNil(result.errorCode)
    XCTAssertEqual(result.errorMessage, "Operation was cancelled")
    XCTAssertFalse(result.isSuccess)
    XCTAssertFalse(result.isFailure)
    XCTAssertTrue(result.isCancelled)
  }

  // Test the map function for success case
  func testMapFunctionWithSuccess() {
    // Arrange
    let result=OperationResultDTO<Int>.success(42)

    // Act
    let mapped=result.map { String($0) }

    // Assert
    XCTAssertEqual(mapped.status, .success)
    XCTAssertEqual(mapped.value, "42")
  }

  // Test the map function for failure case
  func testMapFunctionWithFailure() {
    // Arrange
    let result=OperationResultDTO<Int>.failure(errorCode: 500, errorMessage: "Server Error")

    // Act
    let mapped=result.map { String($0) }

    // Assert
    XCTAssertEqual(mapped.status, .failure)
    XCTAssertNil(mapped.value)
    XCTAssertEqual(mapped.errorCode, 500)
    XCTAssertEqual(mapped.errorMessage, "Server Error")
  }

  // Test the mapError function
  func testMapErrorFunction() {
    // Arrange
    let result=OperationResultDTO<Int>.failure(errorCode: 404, errorMessage: "Not Found")

    // Act
    let mapped=result.mapError { code, message in
      (code + 1000, "Error: \(message)")
    }

    // Assert
    XCTAssertEqual(mapped.status, .failure)
    XCTAssertNil(mapped.value)
    XCTAssertEqual(mapped.errorCode, 1404)
    XCTAssertEqual(mapped.errorMessage, "Error: Not Found")
  }

  // Test combining results with AND operator
  func testAndOperator() {
    // Arrange
    let success1=OperationResultDTO<Int>.success(42)
    let success2=OperationResultDTO<String>.success("Hello")
    let failure=OperationResultDTO<Double>.failure(errorCode: 500, errorMessage: "Error")

    // Act & Assert
    let successAndSuccess=success1.and(success2)
    XCTAssertEqual(successAndSuccess.status, .success)
    XCTAssertEqual(successAndSuccess.value?.0, 42)
    XCTAssertEqual(successAndSuccess.value?.1, "Hello")

    let successAndFailure=success1.and(failure)
    XCTAssertEqual(successAndFailure.status, .failure)
    XCTAssertNil(successAndFailure.value)
    XCTAssertEqual(successAndFailure.errorCode, 500)
    XCTAssertEqual(successAndFailure.errorMessage, "Error")

    let failureAndSuccess=failure.and(success1)
    XCTAssertEqual(failureAndSuccess.status, .failure)
    XCTAssertNil(failureAndSuccess.value)
    XCTAssertEqual(failureAndSuccess.errorCode, 500)
    XCTAssertEqual(failureAndSuccess.errorMessage, "Error")
  }

  // Test the flatMap function
  func testFlatMapFunction() {
    // Arrange
    let result=OperationResultDTO<Int>.success(10)

    // Act
    let mapped=result.flatMap { value in
      if value > 5 {
        OperationResultDTO<String>.success("Greater than 5")
      } else {
        OperationResultDTO<String>.failure(errorCode: 400, errorMessage: "Too small")
      }
    }

    // Assert
    XCTAssertEqual(mapped.status, .success)
    XCTAssertEqual(mapped.value, "Greater than 5")

    // Test with a value that will cause the flatMap to return failure
    let result2=OperationResultDTO<Int>.success(3)

    // Act
    let mapped2=result2.flatMap { value in
      if value > 5 {
        OperationResultDTO<String>.success("Greater than 5")
      } else {
        OperationResultDTO<String>.failure(errorCode: 400, errorMessage: "Too small")
      }
    }

    // Assert
    XCTAssertEqual(mapped2.status, .failure)
    XCTAssertEqual(mapped2.errorCode, 400)
    XCTAssertEqual(mapped2.errorMessage, "Too small")
  }

  // Test with SecureBytes for SecurityResultDTO conversion
  func testSecureBytesConversion() {
    // Arrange
    let secureBytes=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let result=OperationResultDTO<SecureBytes>.success(secureBytes)

    // Act & Assert
    XCTAssertEqual(result.status, .success)
    XCTAssertEqual(result.value, secureBytes)
  }

  // Test the recover function
  func testRecoverFunction() {
    // Arrange
    let failureResult=OperationResultDTO<String>.failure(errorCode: 404, errorMessage: "Not Found")

    // Act
    let recovered=failureResult.recover { code, message in
      "Recovered from error \(code): \(message)"
    }

    // Assert
    XCTAssertEqual(recovered.status, .success)
    XCTAssertEqual(recovered.value, "Recovered from error 404: Not Found")
  }

  // Test the recover function on success (shouldn't change)
  func testRecoverFunctionOnSuccess() {
    // Arrange
    let successResult=OperationResultDTO<String>.success("Original Value")

    // Act
    let recovered=successResult.recover { _, _ in
      "Recovered Value"
    }

    // Assert
    XCTAssertEqual(recovered.status, .success)
    XCTAssertEqual(recovered.value, "Original Value", "Recovery should not affect success cases")
  }
}
