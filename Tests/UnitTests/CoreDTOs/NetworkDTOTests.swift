@testable import CoreDTOs
import Foundation
import UmbraCoreTypes
import XCTest

final class NetworkDTOTests: XCTestCase {
  // MARK: - NetworkRequestDTO Tests

  func testNetworkRequestDTOInitialization() {
    // Arrange & Act
    let request=NetworkRequestDTO(
      requestID: "req-123",
      url: "https://api.example.com/test",
      httpMethod: "POST",
      headers: ["Content-Type": "application/json"],
      queryParameters: ["param1": "value1"],
      bodyData: [1, 2, 3, 4, 5],
      timeoutSeconds: 30,
      authType: "bearer",
      metadata: ["token": "test-token"]
    )

    // Assert
    XCTAssertEqual(request.requestID, "req-123")
    XCTAssertEqual(request.url, "https://api.example.com/test")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.headers["Content-Type"], "application/json")
    XCTAssertEqual(request.queryParameters["param1"], "value1")
    XCTAssertEqual(request.bodyData, [1, 2, 3, 4, 5])
    XCTAssertEqual(request.timeoutSeconds, 30)
    XCTAssertEqual(request.authType, "bearer")
    XCTAssertEqual(request.metadata["token"], "test-token")
  }

  func testNetworkRequestDTOFactoryMethods() {
    // Test GET request
    let getRequest=NetworkRequestDTO.get(
      url: "https://api.example.com/users",
      queryParameters: ["page": "1", "limit": "10"]
    )

    XCTAssertEqual(getRequest.httpMethod, "GET")
    XCTAssertEqual(getRequest.url, "https://api.example.com/users")
    XCTAssertEqual(getRequest.queryParameters["page"], "1")
    XCTAssertEqual(getRequest.queryParameters["limit"], "10")
    XCTAssertTrue(getRequest.bodyData.isEmpty)

    // Test POST request
    let postBody: [UInt8]=Array("test data".utf8)
    let postRequest=NetworkRequestDTO.post(
      url: "https://api.example.com/users",
      body: postBody,
      contentType: "text/plain"
    )

    XCTAssertEqual(postRequest.httpMethod, "POST")
    XCTAssertEqual(postRequest.url, "https://api.example.com/users")
    XCTAssertEqual(postRequest.bodyData, postBody)
    XCTAssertEqual(postRequest.headers["Content-Type"], "text/plain")

    // Test PUT request
    let putBody: [UInt8]=Array("{\"id\":1}".utf8)
    let putRequest=NetworkRequestDTO.put(
      url: "https://api.example.com/users/1",
      body: putBody
    )

    XCTAssertEqual(putRequest.httpMethod, "PUT")
    XCTAssertEqual(putRequest.url, "https://api.example.com/users/1")
    XCTAssertEqual(putRequest.bodyData, putBody)
    XCTAssertEqual(putRequest.headers["Content-Type"], "application/json")

    // Test DELETE request
    let deleteRequest=NetworkRequestDTO.delete(
      url: "https://api.example.com/users/1"
    )

    XCTAssertEqual(deleteRequest.httpMethod, "DELETE")
    XCTAssertEqual(deleteRequest.url, "https://api.example.com/users/1")
    XCTAssertTrue(deleteRequest.bodyData.isEmpty)
  }

  func testNetworkRequestDTOConversionToURLRequest() {
    // Arrange
    let dto=NetworkRequestDTO(
      requestID: "req-123",
      url: "https://api.example.com/test?existing=param",
      httpMethod: "POST",
      headers: [
        "Content-Type": "application/json",
        "Accept": "application/json"
      ],
      queryParameters: ["param1": "value1", "param2": "value2"],
      bodyData: Array("{\"key\":\"value\"}".utf8),
      timeoutSeconds: 30,
      authType: "bearer",
      metadata: ["token": "test-token"]
    )

    // Act
    guard let urlRequest=dto.toURLRequest() else {
      XCTFail("Failed to convert to URLRequest")
      return
    }

    // Assert
    XCTAssertEqual(urlRequest.httpMethod, "POST")
    XCTAssertNotNil(urlRequest.url)
    XCTAssertTrue(urlRequest.url?.absoluteString.contains("https://api.example.com/test") ?? false)
    XCTAssertTrue(urlRequest.url?.absoluteString.contains("param1=value1") ?? false)
    XCTAssertTrue(urlRequest.url?.absoluteString.contains("param2=value2") ?? false)
    XCTAssertTrue(urlRequest.url?.absoluteString.contains("existing=param") ?? false)
    XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/json")
    XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json")
    XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer test-token")
    XCTAssertEqual(urlRequest.httpBody, Data(Array("{\"key\":\"value\"}".utf8)))
    XCTAssertEqual(urlRequest.timeoutInterval, 30)
  }

  func testNetworkRequestDTOConversionFromURLRequest() {
    // Arrange
    var urlRequest=URLRequest(url: URL(string: "https://api.example.com/test?param=value")!)
    urlRequest.httpMethod="POST"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.httpBody=Data(Array("{\"key\":\"value\"}".utf8))
    urlRequest.timeoutInterval=30

    // Act
    let dto=NetworkRequestDTO.fromURLRequest(urlRequest)

    // Assert
    XCTAssertEqual(dto.url, "https://api.example.com/test?param=value")
    XCTAssertEqual(dto.httpMethod, "POST")
    XCTAssertEqual(dto.headers["Content-Type"], "application/json")
    XCTAssertEqual(dto.headers["Accept"], "application/json")
    XCTAssertEqual(dto.queryParameters["param"], "value")
    XCTAssertEqual(dto.bodyData, Array("{\"key\":\"value\"}".utf8))
    XCTAssertEqual(dto.timeoutSeconds, 30)
  }

  // MARK: - NetworkResponseDTO Tests

  func testNetworkResponseDTOInitialization() {
    // Arrange & Act
    let response=NetworkResponseDTO(
      requestID: "req-123",
      statusCode: 200,
      statusMessage: "OK",
      headers: ["Content-Type": "application/json"],
      bodyData: [1, 2, 3, 4, 5],
      mimeType: "application/json",
      textEncodingName: "utf-8",
      isFromCache: false,
      duration: 0.5,
      timestamp: 1_625_000_000,
      metadata: ["key": "value"]
    )

    // Assert
    XCTAssertEqual(response.requestID, "req-123")
    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(response.statusMessage, "OK")
    XCTAssertEqual(response.headers["Content-Type"], "application/json")
    XCTAssertEqual(response.bodyData, [1, 2, 3, 4, 5])
    XCTAssertEqual(response.mimeType, "application/json")
    XCTAssertEqual(response.textEncodingName, "utf-8")
    XCTAssertFalse(response.isFromCache)
    XCTAssertEqual(response.duration, 0.5)
    XCTAssertEqual(response.timestamp, 1_625_000_000)
    XCTAssertEqual(response.metadata["key"], "value")
  }

  func testNetworkResponseDTOFactoryMethods() {
    // Test success response
    let successResponse=NetworkResponseDTO.success(
      requestID: "req-123",
      bodyData: [1, 2, 3, 4, 5],
      headers: ["Content-Type": "application/json"],
      mimeType: "application/json",
      duration: 0.5,
      timestamp: 1_625_000_000
    )

    XCTAssertEqual(successResponse.statusCode, 200)
    XCTAssertEqual(successResponse.statusMessage, "OK")
    XCTAssertEqual(successResponse.bodyData, [1, 2, 3, 4, 5])
    XCTAssertEqual(successResponse.headers["Content-Type"], "application/json")
    XCTAssertEqual(successResponse.mimeType, "application/json")
    XCTAssertEqual(successResponse.duration, 0.5)
    XCTAssertEqual(successResponse.timestamp, 1_625_000_000)
    XCTAssertTrue(successResponse.isSuccess)
    XCTAssertFalse(successResponse.isError)

    // Test error response
    let errorResponse=NetworkResponseDTO.error(
      requestID: "req-123",
      statusCode: 404,
      statusMessage: "Not Found",
      errorData: [1, 2, 3],
      duration: 0.3,
      timestamp: 1_625_000_000
    )

    XCTAssertEqual(errorResponse.statusCode, 404)
    XCTAssertEqual(errorResponse.statusMessage, "Not Found")
    XCTAssertEqual(errorResponse.bodyData, [1, 2, 3])
    XCTAssertEqual(errorResponse.duration, 0.3)
    XCTAssertEqual(errorResponse.timestamp, 1_625_000_000)
    XCTAssertEqual(errorResponse.metadata["error"], "true")
    XCTAssertFalse(errorResponse.isSuccess)
    XCTAssertTrue(errorResponse.isClientError)
    XCTAssertFalse(errorResponse.isServerError)
    XCTAssertTrue(errorResponse.isError)

    // Test network failure response
    let networkFailure=NetworkResponseDTO.networkFailure(
      requestID: "req-123",
      errorMessage: "Connection timeout",
      duration: 1.5,
      timestamp: 1_625_000_000
    )

    XCTAssertEqual(networkFailure.statusCode, -1)
    XCTAssertEqual(networkFailure.statusMessage, "Connection timeout")
    XCTAssertEqual(networkFailure.duration, 1.5)
    XCTAssertEqual(networkFailure.timestamp, 1_625_000_000)
    XCTAssertEqual(networkFailure.metadata["error"], "true")
    XCTAssertEqual(networkFailure.metadata["networkError"], "true")
    XCTAssertFalse(networkFailure.isSuccess)
    XCTAssertFalse(networkFailure.isClientError)
    XCTAssertFalse(networkFailure.isServerError)
    XCTAssertTrue(networkFailure.isError)
  }

  func testNetworkResponseDTOComputedProperties() {
    // Success response
    let successResponse=NetworkResponseDTO.success(
      requestID: "req-123",
      bodyData: [1, 2, 3, 4, 5],
      timestamp: 1_625_000_000
    )

    XCTAssertTrue(successResponse.isSuccess)
    XCTAssertFalse(successResponse.isClientError)
    XCTAssertFalse(successResponse.isServerError)
    XCTAssertFalse(successResponse.isError)
    XCTAssertEqual(successResponse.bodySize, 5)

    // Client error response
    let clientErrorResponse=NetworkResponseDTO.error(
      requestID: "req-123",
      statusCode: 400,
      statusMessage: "Bad Request",
      timestamp: 1_625_000_000
    )

    XCTAssertFalse(clientErrorResponse.isSuccess)
    XCTAssertTrue(clientErrorResponse.isClientError)
    XCTAssertFalse(clientErrorResponse.isServerError)
    XCTAssertTrue(clientErrorResponse.isError)
    XCTAssertEqual(clientErrorResponse.bodySize, 0)

    // Server error response
    let serverErrorResponse=NetworkResponseDTO.error(
      requestID: "req-123",
      statusCode: 500,
      statusMessage: "Internal Server Error",
      timestamp: 1_625_000_000
    )

    XCTAssertFalse(serverErrorResponse.isSuccess)
    XCTAssertFalse(serverErrorResponse.isClientError)
    XCTAssertTrue(serverErrorResponse.isServerError)
    XCTAssertTrue(serverErrorResponse.isError)
  }

  func testNetworkResponseDTOUtilityMethods() {
    // Test bodyAsUTF8String
    let jsonResponse=NetworkResponseDTO.success(
      requestID: "req-123",
      bodyData: Array("{\"key\":\"value\"}".utf8),
      timestamp: 1_625_000_000
    )

    XCTAssertEqual(jsonResponse.bodyAsUTF8String(), "{\"key\":\"value\"}")

    // Test getHeader (case-insensitive)
    let headerResponse=NetworkResponseDTO.success(
      requestID: "req-123",
      bodyData: [],
      headers: ["Content-Type": "application/json", "X-Custom-Header": "test"],
      timestamp: 1_625_000_000
    )

    XCTAssertEqual(headerResponse.getHeader("content-type"), "application/json")
    XCTAssertEqual(headerResponse.getHeader("Content-Type"), "application/json")
    XCTAssertEqual(headerResponse.getHeader("x-custom-header"), "test")
    XCTAssertNil(headerResponse.getHeader("non-existent"))

    // Test withUpdatedMetadata
    let originalResponse=NetworkResponseDTO.success(
      requestID: "req-123",
      bodyData: [],
      timestamp: 1_625_000_000,
      metadata: ["original": "value"]
    )

    let updatedResponse=originalResponse.withUpdatedMetadata([
      "new": "value",
      "original": "updated"
    ])

    XCTAssertEqual(updatedResponse.metadata["original"], "updated")
    XCTAssertEqual(updatedResponse.metadata["new"], "value")
  }

  func testNetworkResponseDTOConversion() {
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

    // Assert
    XCTAssertEqual(dto.statusCode, 200)
    XCTAssertEqual(dto.statusMessage, "OK")
    XCTAssertEqual(dto.headers["Content-Type"], "application/json")
    XCTAssertEqual(dto.bodyData, Array("{\"key\":\"value\"}".utf8))
    XCTAssertEqual(dto.requestID, "req-123")
    XCTAssertEqual(dto.duration, 0.5)
    XCTAssertEqual(dto.timestamp, 1_625_000_000)
    XCTAssertFalse(dto.isFromCache)

    // Convert back to Data
    let bodyData=dto.bodyAsData()
    XCTAssertEqual(bodyData, responseData)

    // Convert to HTTPURLResponse
    let convertedResponse=dto.toHTTPURLResponse(for: urlRequest)
    XCTAssertNotNil(convertedResponse)
    XCTAssertEqual(convertedResponse?.statusCode, 200)
    XCTAssertEqual(
      convertedResponse?.allHeaderFields["Content-Type"] as? String,
      "application/json"
    )
  }
}
