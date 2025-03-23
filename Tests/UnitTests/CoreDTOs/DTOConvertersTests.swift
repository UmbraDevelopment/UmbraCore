@testable import CoreDTOs
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

final class DTOConvertersTests: XCTestCase {
  // MARK: - SecurityDTOConverters Tests

  func testOperationResultToSecurityResultDTOConversion() {
    // Arrange - Success case with data
    let secureBytes=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let successResult=OperationResultDTO<SecureBytes>.success(secureBytes)

    // Act
    let securityResult=successResult.toSecurityResultDTO()

    // Assert
    XCTAssertTrue(securityResult.success)
    XCTAssertEqual(securityResult.data, secureBytes)
    XCTAssertNil(securityResult.errorCode)
    XCTAssertNil(securityResult.errorMessage)

    // Arrange - Failure case
    let failureResult=OperationResultDTO<SecureBytes>.failure(
      errorCode: 1002,
      errorMessage: "Operation failed"
    )

    // Act
    let failureSecurityResult=failureResult.toSecurityResultDTO()

    // Assert
    XCTAssertFalse(failureSecurityResult.success)
    XCTAssertNil(failureSecurityResult.data)
    XCTAssertEqual(failureSecurityResult.errorCode, 1002)
    XCTAssertEqual(failureSecurityResult.errorMessage, "Operation failed")
  }

  func testSecurityResultDTOToOperationResultConversion() {
    // Arrange - Success case with data
    let secureBytes=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let securityResult=SecurityProtocolsCore.SecurityResultDTO(data: secureBytes)

    // Act
    let operationResult=OperationResultDTO<SecureBytes>.fromSecurityResultDTO(securityResult)

    // Assert
    XCTAssertEqual(operationResult.status, .success)
    XCTAssertEqual(operationResult.value, secureBytes)
    XCTAssertNil(operationResult.errorCode)
    XCTAssertNil(operationResult.errorMessage)

    // Arrange - Failure case
    let failureSecurityResult=SecurityProtocolsCore.SecurityResultDTO(
      errorCode: 1002,
      errorMessage: "Operation failed"
    )

    // Act
    let failureOperationResult=OperationResultDTO<SecureBytes>
      .fromSecurityResultDTO(failureSecurityResult)

    // Assert
    XCTAssertEqual(failureOperationResult.status, .failure)
    XCTAssertNil(failureOperationResult.value)
    XCTAssertEqual(failureOperationResult.errorCode, 1002)
    XCTAssertEqual(failureOperationResult.errorMessage, "Operation failed")
  }

  func testSecurityConfigDTOConversion() {
    // Arrange
    let securityConfig=SecurityConfigDTO(
      options: [
        "algorithm": "AES-GCM",
        "keySizeInBits": "256",
        "keyIdentifier": "test-key-id",
        "iterations": "10000"
      ],
      inputData: [1, 2, 3, 4, 5]
    )

    // Act
    let protocolsConfig=securityConfig.toSecurityProtocolsCoreConfig()

    // Assert
    XCTAssertEqual(protocolsConfig.algorithm, "AES-GCM")
    XCTAssertEqual(protocolsConfig.keySizeInBits, 256)
    XCTAssertEqual(protocolsConfig.keyIdentifier, "test-key-id")
    XCTAssertEqual(protocolsConfig.iterations, 10000)

    // Convert input data to SecureBytes for comparison
    let secureBytes=SecureBytes(bytes: [1, 2, 3, 4, 5])

    // Compare bytes one by one as SecureBytes doesn't have direct equality
    XCTAssertEqual(protocolsConfig.inputData?.count, secureBytes.count)
    if let inputData=protocolsConfig.inputData {
      for i in 0..<inputData.count {
        XCTAssertEqual(inputData[i], secureBytes[i])
      }
    }

    // Convert back
    let reconvertedConfig=SecurityConfigDTO.fromSecurityProtocolsCoreConfig(protocolsConfig)

    // Assert round-trip conversion
    XCTAssertEqual(reconvertedConfig.options["algorithm"], "AES-GCM")
    XCTAssertEqual(reconvertedConfig.options["keySizeInBits"], "256")
    XCTAssertEqual(reconvertedConfig.options["keyIdentifier"], "test-key-id")
    XCTAssertEqual(reconvertedConfig.options["iterations"], "10000")
    XCTAssertEqual(reconvertedConfig.inputData, [1, 2, 3, 4, 5])
  }

  func testNotificationDTOForSecurityError() {
    // Arrange
    let securityError=UmbraErrors.Security.Protocols.encryptionFailed("Test encryption error")
    let timestamp: UInt64=1_625_000_000

    // Act
    let notification=NotificationDTO.forSecurityError(
      securityError,
      details: "Detailed error message",
      timestamp: timestamp
    )

    // Assert
    XCTAssertEqual(notification.severity, .error)
    XCTAssertEqual(notification.title, "Security Error")
    XCTAssertEqual(notification.message, "Detailed error message")
    XCTAssertEqual(notification.source, "SecurityProvider")
    XCTAssertEqual(notification.timestamp, timestamp)
    XCTAssertTrue(notification.id.starts(with: "sec_err_"))
    XCTAssertEqual(notification.metadata["errorCode"], "1008") // Code for encryptionFailed
    XCTAssertEqual(notification.metadata["category"], "security")
  }

  // MARK: - SchedulingDTOConverters Tests

  func testDateExtensions() {
    // Arrange
    let date=Date(timeIntervalSince1970: 1_625_000_000)

    // Act & Assert
    XCTAssertEqual(date.timestampInSeconds, 1_625_000_000)
    XCTAssertEqual(Date.fromTimestamp(1_625_000_000).timeIntervalSince1970, 1_625_000_000)
  }

  func testScheduleDTODateConversion() {
    // Arrange
    let now=Date()
    let calendar=Calendar.current

    // Calculate 8 AM today
    var components=calendar.dateComponents([.year, .month, .day], from: now)
    components.hour=8
    components.minute=0
    components.second=0
    let eightAM=calendar.date(from: components)!

    // Calculate 6 PM today
    components.hour=18
    let sixPM=calendar.date(from: components)!

    // Act
    let schedule=ScheduleDTO.fromDates(
      frequencyType: .daily,
      startDate: now,
      windowStartTime: eightAM,
      windowEndTime: sixPM
    )

    // Assert
    XCTAssertEqual(schedule.startTimestamp, UInt64(now.timeIntervalSince1970))

    // Window start should be 8 AM = 8 hours * 3600 seconds = 28800 seconds from midnight
    XCTAssertEqual(schedule.windowStartTime, 8 * 3600)

    // Window end should be 6 PM = 18 hours * 3600 seconds = 64800 seconds from midnight
    XCTAssertEqual(schedule.windowEndTime, 18 * 3600)

    // Test conversion back to dates
    let startDate=schedule.startDate()
    XCTAssertEqual(
      Int(startDate.timeIntervalSince1970),
      Int(now.timeIntervalSince1970),
      accuracy: 1
    )

    // Verify window start/end time conversion
    let windowStartDate=schedule.windowStartDate()
    let windowEndDate=schedule.windowEndDate()

    XCTAssertNotNil(windowStartDate)
    XCTAssertNotNil(windowEndDate)

    if let windowStartDate, let windowEndDate {
      let startComponents=calendar.dateComponents([.hour, .minute], from: windowStartDate)
      let endComponents=calendar.dateComponents([.hour, .minute], from: windowEndDate)

      XCTAssertEqual(startComponents.hour, 8)
      XCTAssertEqual(endComponents.hour, 18)
    }
  }

  func testScheduledTaskDTODateConversion() {
    // Arrange
    let now=Date()
    let lastRun=now.addingTimeInterval(-86400) // Yesterday
    let nextRun=now.addingTimeInterval(86400) // Tomorrow

    let schedule=ScheduleDTO.daily(
      startTimestamp: UInt64(now.timeIntervalSince1970 - 604_800) // A week ago
    )

    // Act
    let task=ScheduledTaskDTO.fromDates(
      taskID: "test-task",
      schedule: schedule,
      lastRunDate: lastRun,
      nextRunDate: nextRun,
      creationDate: now
    )

    // Assert
    XCTAssertEqual(task.lastRunTimestamp, UInt64(lastRun.timeIntervalSince1970))
    XCTAssertEqual(task.nextRunTimestamp, UInt64(nextRun.timeIntervalSince1970))
    XCTAssertEqual(task.creationTimestamp, UInt64(now.timeIntervalSince1970))

    // Test conversion back to dates
    XCTAssertEqual(
      Int(task.lastRunDate()!.timeIntervalSince1970),
      Int(lastRun.timeIntervalSince1970),
      accuracy: 1
    )
    XCTAssertEqual(
      Int(task.nextRunDate()!.timeIntervalSince1970),
      Int(nextRun.timeIntervalSince1970),
      accuracy: 1
    )
    XCTAssertEqual(
      Int(task.creationDate().timeIntervalSince1970),
      Int(now.timeIntervalSince1970),
      accuracy: 1
    )
  }

  // MARK: - NetworkDTOConverters Tests

  func testNetworkRequestDTOURLRequestConversion() {
    // Arrange
    let originalRequest=NetworkRequestDTO(
      requestID: "req-123",
      url: "https://api.example.com/test",
      httpMethod: "POST",
      headers: ["Content-Type": "application/json"],
      queryParameters: ["param1": "value1"],
      bodyData: Array("{\"key\":\"value\"}".utf8),
      timeoutSeconds: 30,
      authType: "bearer",
      metadata: ["token": "test-token"]
    )

    // Act
    guard let urlRequest=originalRequest.toURLRequest() else {
      XCTFail("Failed to convert to URLRequest")
      return
    }

    // Convert back
    let roundTripRequest=NetworkRequestDTO.fromURLRequest(urlRequest)

    // Assert roundtrip conversion retained important properties
    XCTAssertEqual(roundTripRequest.url, "https://api.example.com/test?param1=value1")
    XCTAssertEqual(roundTripRequest.httpMethod, "POST")
    XCTAssertEqual(roundTripRequest.headers["Content-Type"], "application/json")
    XCTAssertEqual(roundTripRequest.bodyData, Array("{\"key\":\"value\"}".utf8))
    XCTAssertEqual(roundTripRequest.timeoutSeconds, 30)

    // Authorization header should be set
    XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer test-token")
  }

  func testNetworkResponseDTOURLResponseConversion() {
    // Arrange
    let url=URL(string: "https://api.example.com/test")!
    let urlRequest=URLRequest(url: url)

    let httpResponse=HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )!

    let responseData=Data(Array("{\"key\":\"value\"}".utf8))

    // Act
    let dto=NetworkResponseDTO.fromHTTPURLResponse(
      httpResponse,
      data: responseData,
      requestID: "req-123",
      duration: 0.5,
      timestamp: 1_625_000_000,
      isFromCache: false
    )

    // Convert back to HTTPURLResponse
    let convertedResponse=dto.toHTTPURLResponse(for: urlRequest)

    // Assert
    XCTAssertNotNil(convertedResponse)
    XCTAssertEqual(convertedResponse?.statusCode, 200)
    XCTAssertEqual(
      convertedResponse?.allHeaderFields["Content-Type"] as? String,
      "application/json"
    )

    // Convert body to data
    let bodyAsData=dto.bodyAsData()
    XCTAssertEqual(bodyAsData, responseData)
  }

  func testOperationProgressDTOForNetworkOperation() {
    // Arrange
    let timestamp: UInt64=1_625_000_000

    // Act - Test upload progress
    let uploadProgress=OperationProgressDTO.forNetworkOperation(
      bytesTransferred: 50,
      totalBytes: 100,
      requestID: "req-123",
      isUpload: true,
      timestamp: timestamp
    )

    // Assert
    XCTAssertEqual(uploadProgress.operationType, "network.upload")
    XCTAssertEqual(uploadProgress.percentage, 50.0)
    XCTAssertEqual(uploadProgress.message, "Uploading data...")
    XCTAssertEqual(uploadProgress.timestamp, timestamp)
    XCTAssertEqual(uploadProgress.operationID, "req-123")
    XCTAssertEqual(uploadProgress.metadata["bytesTransferred"], "50")
    XCTAssertEqual(uploadProgress.metadata["totalBytes"], "100")
    XCTAssertEqual(uploadProgress.metadata["isUpload"], "true")

    // Act - Test download progress
    let downloadProgress=OperationProgressDTO.forNetworkOperation(
      bytesTransferred: 75,
      totalBytes: 150,
      requestID: "req-456",
      isUpload: false,
      timestamp: timestamp
    )

    // Assert
    XCTAssertEqual(downloadProgress.operationType, "network.download")
    XCTAssertEqual(downloadProgress.percentage, 50.0)
    XCTAssertEqual(downloadProgress.message, "Downloading data...")
    XCTAssertEqual(downloadProgress.operationID, "req-456")
    XCTAssertEqual(downloadProgress.metadata["bytesTransferred"], "75")
    XCTAssertEqual(downloadProgress.metadata["totalBytes"], "150")
    XCTAssertEqual(downloadProgress.metadata["isUpload"], "false")

    // Act - Test indeterminate progress
    let indeterminateProgress=OperationProgressDTO.forNetworkOperation(
      bytesTransferred: 100,
      totalBytes: nil,
      requestID: "req-789",
      isUpload: false,
      timestamp: timestamp
    )

    // Assert
    XCTAssertEqual(indeterminateProgress.percentage, -1.0)
    XCTAssertEqual(indeterminateProgress.metadata["totalBytes"], "unknown")
  }
}
