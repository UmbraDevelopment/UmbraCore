import CoreErrors
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest
@testable import XPCProtocolsCore

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Basic tests for XPCProtocolsCore module
class XPCProtocolsBasicTests: XCTestCase {
  /// Test error conversion functionality
  func testErrorConversion() {
    // Create a generic NSError
    let nsError = NSError(
      domain: "com.test.error",
      code: 123,
      userInfo: [NSLocalizedDescriptionKey: "Test error"]
    )

    // Test conversion to UmbraErrors.Security.Protocols
    let protocolError = XPCProtocolMigrationFactory.convertErrorToSecurityProtocolError(nsError)

    // Verify the error was properly converted to an internalError
    if case let .internalError(message) = protocolError {
      XCTAssertEqual(message, "Test error")
    } else {
      XCTFail("Error should be converted to .internalError type")
    }
  }

  /// Test DTO struct equality
  func testDTOEquality() {
    // Create service status DTOs
    let status1 = XPCProtocolDTOs.ServiceStatusDTO(
      code: 200,
      message: "Service is running",
      timestamp: Date(timeIntervalSince1970: 1_000),
      protocolVersion: "1.0",
      serviceVersion: "1.0.0"
    )

    let status2 = XPCProtocolDTOs.ServiceStatusDTO(
      code: 200,
      message: "Service is running",
      timestamp: Date(timeIntervalSince1970: 1_000),
      protocolVersion: "1.0",
      serviceVersion: "1.0.0"
    )

    let status3 = XPCProtocolDTOs.ServiceStatusDTO(
      code: 500,
      message: "Service error",
      timestamp: Date(timeIntervalSince1970: 1_000),
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
    let protocolError = ErrorHandlingDomains.UmbraErrors.Security.Protocols
      .internalError("Test error")

    // Convert to DTO
    let errorDTO = XPCProtocolDTOs.SecurityErrorConverter.toDTO(protocolError)

    // Verify conversion
    XCTAssertEqual(errorDTO.message, "Test error")

    // Convert back
    let convertedError = XPCProtocolDTOs.SecurityErrorConverter.fromDTO(errorDTO)

    // Verify the round trip conversion
    if case let .internalError(message) = convertedError {
      XCTAssertEqual(message, "Test error")
    } else {
      XCTFail("Error should be converted back to .internalError type")
    }
  }
}
