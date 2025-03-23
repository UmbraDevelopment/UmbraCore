import Foundation
import UmbraCoreTypes

// MARK: - Network DTO Converters for Foundation Types

extension NetworkRequestDTO {
  /// Create a URLRequest from this NetworkRequestDTO
  /// - Returns: A URLRequest configured with the contents of this DTO
  public func toURLRequest() -> URLRequest? {
    // Validate URL
    guard let urlObj=URL(string: urlString) else {
      return nil
    }

    // Create base request with URL
    var request=URLRequest(url: urlObj)

    // Set HTTP method
    request.httpMethod=method.rawValue

    // Add headers
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }

    // Add query parameters if present
    if !queryParams.isEmpty {
      // Check if URL already has query components
      var urlComponents=URLComponents(url: urlObj, resolvingAgainstBaseURL: true)

      // Build query items
      var queryItems=[URLQueryItem]()
      for (key, value) in queryParams {
        queryItems.append(URLQueryItem(name: key, value: value))
      }

      // Append to any existing query items
      if let existingItems=urlComponents?.queryItems {
        queryItems.append(contentsOf: existingItems)
      }

      urlComponents?.queryItems=queryItems

      // Update URL if we have a valid one with query parameters
      if let updatedURL=urlComponents?.url {
        request.url=updatedURL
      }
    }

    // Set body data if present
    if let bodyData, !bodyData.isEmpty {
      request.httpBody=Data(bodyData)
    }

    // Set timeout if different from default
    if timeoutInterval > 0 {
      request.timeoutInterval=timeoutInterval
    }

    return request
  }

  /// Create a NetworkRequestDTO from a URLRequest
  /// - Parameter urlRequest: The URLRequest to convert
  /// - Returns: A new NetworkRequestDTO
  public static func fromURLRequest(_ urlRequest: URLRequest) -> NetworkRequestDTO {
    // Extract URL
    let urlString=urlRequest.url?.absoluteString ?? ""

    // Extract HTTP method
    let methodStr=urlRequest.httpMethod ?? "GET"
    let method=HTTPMethod(rawValue: methodStr) ?? .get

    // Extract headers
    var headers: [String: String]=[:]
    if let allHTTPHeaderFields=urlRequest.allHTTPHeaderFields {
      headers=allHTTPHeaderFields
    }

    // Extract query parameters
    var queryParams: [String: String]=[:]
    if
      let url=urlRequest.url, let components=URLComponents(
        url: url,
        resolvingAgainstBaseURL: true
      ),
      let queryItems=components.queryItems
    {
      for item in queryItems {
        queryParams[item.name]=item.value ?? ""
      }
    }

    // Extract body data
    var bodyData: [UInt8]?
    if let httpBody=urlRequest.httpBody {
      bodyData=[UInt8](httpBody)
    }

    // Extract timeout
    let timeout=urlRequest.timeoutInterval

    // Current timestamp
    let timestamp=UInt64(Date().timeIntervalSince1970)

    return NetworkRequestDTO(
      id: UUID().uuidString,
      urlString: urlString,
      method: method,
      headers: headers,
      queryParams: queryParams,
      bodyData: bodyData,
      timeoutInterval: timeout,
      authentication: .none,
      useCache: true,
      followRedirects: true,
      createdAt: timestamp
    )
  }
}

extension NetworkResponseDTO {
  /// Create an HTTPURLResponse from this NetworkResponseDTO
  /// - Parameter request: The original URLRequest
  /// - Returns: An HTTPURLResponse if possible, nil otherwise
  public func toHTTPURLResponse(for request: URLRequest) -> HTTPURLResponse? {
    guard let url=request.url else {
      return nil
    }

    return HTTPURLResponse(
      url: url,
      statusCode: Int(statusCode),
      httpVersion: nil,
      headerFields: headers
    )
  }

  /// Create a NetworkResponseDTO from an HTTPURLResponse
  /// - Parameters:
  ///   - response: The HTTPURLResponse
  ///   - data: The response data
  /// - Returns: A new NetworkResponseDTO
  public static func fromHTTPURLResponse(
    _ response: HTTPURLResponse,
    data: Data?
  ) -> NetworkResponseDTO {
    // Extract status code
    let statusCode=Int(response.statusCode)

    // Extract HTTP status string
    let statusMessage=HTTPURLResponse.localizedString(forStatusCode: response.statusCode)

    // Extract headers
    let headers=response.allHeaderFields as? [String: String] ?? [:]

    // Extract MIME type
    let mimeType=response.mimeType

    // Extract text encoding
    let textEncodingName=response.textEncodingName

    // Extract body data
    var bodyData: [UInt8]=[]
    if let data {
      bodyData=[UInt8](data)
    }

    // Current timestamp
    let timestamp=UInt64(Date().timeIntervalSince1970)

    return NetworkResponseDTO(
      requestID: UUID().uuidString,
      statusCode: statusCode,
      statusMessage: statusMessage,
      headers: headers,
      bodyData: bodyData,
      mimeType: mimeType,
      textEncodingName: textEncodingName,
      isFromCache: false,
      duration: 0,
      timestamp: timestamp
    )
  }
}
