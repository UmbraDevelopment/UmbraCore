import CoreErrors
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest
@testable import XPCProtocolsCore

/// Basic tests for XPCProtocolsCore module
class XPCProtocolsBasicTests: XCTestCase {
  /// Test error conversion functionality
  func testErrorConversion() {
    // Create a generic NSError
    let nsError=NSError(
      domain: "com.test.error",
      code: 123,
      userInfo: [NSLocalizedDescriptionKey: "Test error"]
    )

    // Test conversion to UmbraErrors.Security.Protocols
    let protocolError=XPCProtocolMigrationFactory.convertErrorToSecurityProtocolError(nsError)

    // Verify the error was properly converted to an internalError
    if case let .internalError(message)=protocolError {
      XCTAssertEqual(message, "Test error")
    } else {
      XCTFail("Error should be converted to .internalError type")
    }
  }

  /// Test DTO struct equality
  func testDTOEquality() {
    // Create service status DTOs
    let status1=XPCProtocolDTOs.ServiceStatusDTO(
      code: 200,
      message: "Service is running",
      timestamp: Date(timeIntervalSince1970: 1000),
      protocolVersion: "1.0",
      serviceVersion: "1.0.0"
    )

    let status2=XPCProtocolDTOs.ServiceStatusDTO(
      code: 200,
      message: "Service is running",
      timestamp: Date(timeIntervalSince1970: 1000),
      protocolVersion: "1.0",
      serviceVersion: "1.0.0"
    )

    let status3=XPCProtocolDTOs.ServiceStatusDTO(
      code: 500,
      message: "Service error",
      timestamp: Date(timeIntervalSince1970: 1000),
      protocolVersion: "1.0",
      serviceVersion: "1.0.0"
    )

    // Test equality
    XCTAssertEqual(status1, status2, "Identical DTOs should be equal")
    XCTAssertNotEqual(status1, status3, "Different DTOs should not be equal")
  }

  /// Test security error converter
  func testSecurityErrorConverter() {
    // Create an error
    let protocolError=ErrorHandlingDomains.UmbraErrors.Security.Protocols
      .internalError("Test error")

    // Convert to DTO
    let errorDTO=XPCProtocolDTOs.SecurityErrorConverter.toDTO(protocolError)

    // Verify conversion
    XCTAssertEqual(errorDTO.message, "Test error")

    // Convert back
    let convertedError=XPCProtocolDTOs.SecurityErrorConverter.fromDTO(errorDTO)

    // Verify the round trip conversion
    if case let .internalError(message)=convertedError {
      XCTAssertEqual(message, "Test error")
    } else {
      XCTFail("Error should be converted back to .internalError type")
    }
  }
}
