import CoreDTOs
import ErrorHandling
import ErrorHandlingDomains
import Foundation
import UmbraCoreTypes

/// Foundation-independent adapter for network operations
public final class NetworkServiceDTOAdapter: NetworkServiceDTOProtocol {
  // MARK: - Private Properties

  private let session: URLSession
  private let errorDomain=ErrorHandlingDomains.UmbraErrors.Network.self

  // MARK: - Initialization

  /// Initialize a new NetworkServiceDTOAdapter with a custom URLSession
  /// - Parameter session: The URLSession to use for network operations
  public init(session: URLSession) {
    self.session=session
  }

  /// Initialize a new NetworkServiceDTOAdapter with default URLSession configuration
  public init() {
    let config=URLSessionConfiguration.default
    config.timeoutIntervalForRequest=30.0
    config.timeoutIntervalForResource=60.0
    session=URLSession(configuration: config)
  }

  // MARK: - NetworkServiceDTOProtocol Implementation

  /// Send a network request asynchronously
  /// - Parameter request: The request to send
  /// - Returns: A result containing either the response or an error
  public func sendRequest(_ request: NetworkRequestDTO) async
  -> OperationResultDTO<NetworkResponseDTO> {
    guard let urlRequest=request.toURLRequest() else {
      return .failure(SecurityErrorDTO(
        code: errorDomain.invalidURL.code,
        domain: errorDomain.invalidURL.domain,
        message: "Could not create URL request from request DTO"
      ))
    }

    do {
      let startTime=Date()
      let (data, response)=try await session.data(for: urlRequest)
      let duration=Date().timeIntervalSince(startTime)

      guard let httpResponse=response as? HTTPURLResponse else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.invalidResponse.code,
          domain: errorDomain.invalidResponse.domain,
          message: "Response is not an HTTP response"
        ))
      }

      // Create headers dictionary
      var headers=[String: String]()
      for (key, value) in httpResponse.allHeaderFields {
        if let keyStr=key as? String, let valueStr=value as? String {
          headers[keyStr]=valueStr
        }
      }

      // Create the response DTO
      let responseDTO=NetworkResponseDTO(
        requestID: request.id,
        statusCode: httpResponse.statusCode,
        statusMessage: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
        headers: headers,
        bodyData: [UInt8](data),
        mimeType: httpResponse.mimeType,
        textEncodingName: httpResponse.textEncodingName,
        isFromCache: (httpResponse.allHeaderFields["X-Cache"] as? String)?.lowercased()
          .contains("hit") ?? false,
        duration: duration,
        timestamp: UInt64(Date().timeIntervalSince1970),
        metadata: [:]
      )

      return .success(responseDTO)
    } catch let urlError as URLError {
      return .failure(convertURLError(urlError, requestID: request.id))
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.networkError.code,
        domain: errorDomain.networkError.domain,
        message: "Network request failed: \(error.localizedDescription)"
      ))
    }
  }

  /// Download data from a URL
  /// - Parameters:
  ///   - urlString: The URL string to download from
  ///   - headers: Optional headers for the request
  /// - Returns: A result containing either the downloaded data or an error
  public func downloadData(
    from urlString: String,
    headers: [String: String]?=nil
  ) async -> OperationResultDTO<[UInt8]> {
    // Create a GET request
    let request=NetworkRequestDTO.get(
      id: UUID().uuidString,
      urlString: urlString,
      headers: headers ?? [:],
      timeout: 60.0
    )

    // Send the request
    let response=await sendRequest(request)

    // Process the response
    switch response {
      case let .success(responseDTO):
        // Check for successful status code (200-299)
        if responseDTO.statusCode >= 200 && responseDTO.statusCode < 300 {
          return .success(responseDTO.bodyData)
        } else {
          return .failure(SecurityErrorDTO(
            code: errorDomain.httpError.code,
            domain: errorDomain.httpError.domain,
            message: "HTTP error: \(responseDTO.statusCode) \(responseDTO.statusMessage)"
          ))
        }
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Download data with progress reporting
  /// - Parameters:
  ///   - urlString: The URL string to download from
  ///   - headers: Optional headers for the request
  ///   - progressHandler: A closure that will be called periodically with download progress
  /// - Returns: A result containing either the downloaded data or an error
  public func downloadData(
    from urlString: String,
    headers: [String: String]?=nil,
    progressHandler: @escaping (Double) -> Void
  ) async -> OperationResultDTO<[UInt8]> {
    guard let url=URL(string: urlString) else {
      return .failure(SecurityErrorDTO(
        code: errorDomain.invalidURL.code,
        domain: errorDomain.invalidURL.domain,
        message: "Invalid URL: \(urlString)"
      ))
    }

    // Create the request
    var request=URLRequest(url: url)

    // Add headers if provided
    if let headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    // Use a delegate-based approach for progress tracking
    let delegate=ProgressTrackingDelegate(progressHandler: progressHandler)
    let progressSession=URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

    do {
      let (downloadLocation, _)=try await progressSession.download(for: request)
      let data=try Data(contentsOf: downloadLocation)
      return .success([UInt8](data))
    } catch let urlError as URLError {
      return .failure(convertURLError(urlError, requestID: UUID().uuidString))
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.downloadError.code,
        domain: errorDomain.downloadError.domain,
        message: "Download failed: \(error.localizedDescription)"
      ))
    }
  }

  /// Upload data to a URL
  /// - Parameters:
  ///   - data: The data to upload
  ///   - urlString: The URL string to upload to
  ///   - method: The HTTP method to use (default: POST)
  ///   - headers: Optional headers for the request
  /// - Returns: A result containing either the server response or an error
  public func uploadData(
    _ data: [UInt8],
    to urlString: String,
    method: NetworkRequestDTO.HTTPMethod = .post,
    headers: [String: String]?=nil
  ) async -> OperationResultDTO<NetworkResponseDTO> {
    // Create the request DTO
    let request=NetworkRequestDTO(
      id: UUID().uuidString,
      urlString: urlString,
      method: method,
      headers: headers ?? [:],
      queryParams: [:],
      bodyData: data,
      timeout: 60.0,
      cachePolicy: .useProtocolCachePolicy,
      authType: .none,
      metadata: [:]
    )

    // Send the request
    return await sendRequest(request)
  }

  /// Upload data with progress reporting
  /// - Parameters:
  ///   - data: The data to upload
  ///   - urlString: The URL string to upload to
  ///   - method: The HTTP method to use (default: POST)
  ///   - headers: Optional headers for the request
  ///   - progressHandler: A closure that will be called periodically with upload progress
  /// - Returns: A result containing either the server response or an error
  public func uploadData(
    _ data: [UInt8],
    to urlString: String,
    method: NetworkRequestDTO.HTTPMethod = .post,
    headers: [String: String]?=nil,
    progressHandler: @escaping (Double) -> Void
  ) async -> OperationResultDTO<NetworkResponseDTO> {
    guard let url=URL(string: urlString) else {
      return .failure(SecurityErrorDTO(
        code: errorDomain.invalidURL.code,
        domain: errorDomain.invalidURL.domain,
        message: "Invalid URL: \(urlString)"
      ))
    }

    // Create the request
    var request=URLRequest(url: url)
    request.httpMethod=method.rawValue

    // Add headers if provided
    if let headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    // Create Data from bytes
    let uploadData=Data(data)

    // Use a delegate-based approach for progress tracking
    let delegate=ProgressTrackingDelegate(progressHandler: progressHandler)
    let progressSession=URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

    do {
      let requestStartTime=Date()
      let (responseData, response)=try await progressSession.upload(for: request, from: uploadData)
      let duration=Date().timeIntervalSince(requestStartTime)

      guard let httpResponse=response as? HTTPURLResponse else {
        return .failure(SecurityErrorDTO(
          code: errorDomain.invalidResponse.code,
          domain: errorDomain.invalidResponse.domain,
          message: "Response is not an HTTP response"
        ))
      }

      // Create headers dictionary
      var responseHeaders=[String: String]()
      for (key, value) in httpResponse.allHeaderFields {
        if let keyStr=key as? String, let valueStr=value as? String {
          responseHeaders[keyStr]=valueStr
        }
      }

      // Create the response DTO
      let responseDTO=NetworkResponseDTO(
        requestID: UUID().uuidString,
        statusCode: httpResponse.statusCode,
        statusMessage: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
        headers: responseHeaders,
        bodyData: [UInt8](responseData),
        mimeType: httpResponse.mimeType,
        textEncodingName: httpResponse.textEncodingName,
        isFromCache: false,
        duration: duration,
        timestamp: UInt64(Date().timeIntervalSince1970),
        metadata: [:]
      )

      return .success(responseDTO)
    } catch let urlError as URLError {
      return .failure(convertURLError(urlError, requestID: UUID().uuidString))
    } catch {
      return .failure(SecurityErrorDTO(
        code: errorDomain.uploadError.code,
        domain: errorDomain.uploadError.domain,
        message: "Upload failed: \(error.localizedDescription)"
      ))
    }
  }

  /// Checks if a URL is reachable
  /// - Parameter urlString: The URL string to check
  /// - Returns: A result containing either a boolean indicating reachability or an error
  public func isReachable(urlString: String) async -> OperationResultDTO<Bool> {
    // Create a HEAD request which is lightweight
    let request=NetworkRequestDTO.head(
      id: UUID().uuidString,
      urlString: urlString,
      timeout: 10.0
    )

    // Send the request
    let response=await sendRequest(request)

    switch response {
      case let .success(responseDTO):
        // Any valid HTTP response (even error codes) indicates the URL is reachable
        return .success(true)
      case let .failure(error):
        // Check if the error is specifically about connectivity
        if
          error.error.code == errorDomain.notConnected.code ||
          error.error.code == errorDomain.cannotConnectToHost.code ||
          error.error.code == errorDomain.networkConnectionLost.code
        {
          return .success(false)
        }

        // For other errors, propagate the failure
        return .failure(error)
    }
  }

  // MARK: - Private Helper Methods

  private func convertURLError(_ error: URLError, requestID _: String) -> SecurityErrorDTO {
    let code: Int
    let domain: String
    let message: String

    switch error.code {
      case .badURL:
        code=errorDomain.invalidURL.code
        domain=errorDomain.invalidURL.domain
        message="Invalid URL"
      case .unsupportedURL:
        code=errorDomain.invalidURL.code
        domain=errorDomain.invalidURL.domain
        message="Unsupported URL"
      case .cannotFindHost, .cannotConnectToHost:
        code=errorDomain.cannotConnectToHost.code
        domain=errorDomain.cannotConnectToHost.domain
        message="Cannot connect to host"
      case .timedOut:
        code=errorDomain.timeout.code
        domain=errorDomain.timeout.domain
        message="Request timed out"
      case .networkConnectionLost:
        code=errorDomain.networkConnectionLost.code
        domain=errorDomain.networkConnectionLost.domain
        message="Network connection lost"
      case .notConnectedToInternet:
        code=errorDomain.notConnected.code
        domain=errorDomain.notConnected.domain
        message="Not connected to the internet"
      default:
        code=errorDomain.networkError.code
        domain=errorDomain.networkError.domain
        message="Network error: \(error.localizedDescription)"
    }

    return SecurityErrorDTO(
      code: code,
      domain: domain,
      message: message
    )
  }
}

/// A delegate for tracking progress of URLSession tasks
private class ProgressTrackingDelegate: NSObject, URLSessionTaskDelegate,
URLSessionDownloadDelegate {
  let progressHandler: (Double) -> Void

  init(progressHandler: @escaping (Double) -> Void) {
    self.progressHandler=progressHandler
    super.init()
  }

  func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didSendBodyData _: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
  ) {
    if totalBytesExpectedToSend > 0 {
      let progress=Double(totalBytesSent) / Double(totalBytesExpectedToSend)
      progressHandler(progress)
    }
  }

  func urlSession(
    _: URLSession,
    downloadTask _: URLSessionDownloadTask,
    didWriteData _: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    if totalBytesExpectedToWrite > 0 {
      let progress=Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
      progressHandler(progress)
    } else {
      // When we don't know the total size, just report bytes downloaded
      progressHandler(Double(totalBytesWritten))
    }
  }

  func urlSession(
    _: URLSession,
    downloadTask _: URLSessionDownloadTask,
    didFinishDownloadingTo _: URL
  ) {
    // Final progress notification
    progressHandler(1.0)
  }
}
