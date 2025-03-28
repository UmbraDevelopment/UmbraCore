import CoreDTOs
import Foundation
import NetworkInterfaces
import UmbraErrors

/// Foundation-based implementation of the NetworkServiceProtocol
public final class NetworkServiceImpl: NetworkServiceProtocol {
    // MARK: - Private Properties

    private let session: URLSession
    
    // MARK: - Initialization

    /// Initialise a new NetworkServiceImpl with a custom URLSession
    /// - Parameter session: The URLSession to use for network operations
    public init(session: URLSession) {
        self.session = session
    }

    /// Initialise a new NetworkServiceImpl with default URLSession configuration
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        session = URLSession(configuration: config)
    }

    // MARK: - NetworkServiceProtocol Implementation

    /// Send a network request asynchronously
    /// - Parameter request: The request to send
    /// - Returns: A result containing either the response or an error
    public func sendRequest(_ request: NetworkRequestDTO) async -> OperationResultDTO<NetworkResponseDTO> {
        // Create URL request manually since NetworkRequestDTO doesn't have toURLRequest()
        guard let url = URL(string: request.urlString) else {
            return .failure(SecurityErrorDTO(
                code: NetworkError.invalidURL.rawValue,
                domain: "Network",
                message: "Could not create URL from request DTO"
            ))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add query parameters if needed
        if !request.queryParams.isEmpty {
            guard var components = URLComponents(string: request.urlString) else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.invalidURL.rawValue,
                    domain: "Network",
                    message: "Could not create URL components from request"
                ))
            }
            
            components.queryItems = request.queryParams.map { 
                URLQueryItem(name: $0.key, value: $0.value)
            }
            
            if let updatedURL = components.url {
                urlRequest.url = updatedURL
            }
        }
        
        // Add body data if present
        if let bodyData = request.bodyData {
            urlRequest.httpBody = Data(bodyData)
        }

        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: urlRequest)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.invalidResponse.rawValue,
                    domain: "Network",
                    message: "Response was not a valid HTTP response"
                ))
            }

            var metadata: [String: String] = [
                "request_id": request.id,
                "duration_ms": String(format: "%.2f", duration * 1000),
                "status_code": String(httpResponse.statusCode)
            ]

            // Add response headers to metadata
            for (key, value) in httpResponse.allHeaderFields {
                if let headerKey = key as? String, let headerValue = value as? String {
                    metadata["header_\(headerKey.lowercased())"] = headerValue
                }
            }
            
            // Extract status message from the HTTP response
            let statusMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            
            // Convert headers to string dictionary
            var headerFields = [String: String]()
            for (key, value) in httpResponse.allHeaderFields {
                if let keyString = key as? String, let valueString = value as? String {
                    headerFields[keyString] = valueString
                }
            }
            
            return .success(NetworkResponseDTO(
                requestID: request.id,
                statusCode: httpResponse.statusCode,
                statusMessage: statusMessage,
                headers: headerFields,
                bodyData: [UInt8](data),
                mimeType: httpResponse.mimeType,
                textEncodingName: httpResponse.textEncodingName,
                isFromCache: false,
                duration: duration,
                timestamp: UInt64(Date().timeIntervalSince1970),
                metadata: metadata
            ))
        } catch {
            if let urlError = error as? URLError {
                return .failure(convertURLError(urlError, requestID: request.id))
            } else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.unknown.rawValue,
                    domain: "Network",
                    message: "Unknown error: \(error.localizedDescription)"
                ))
            }
        }
    }

    /// Download data from a URL
    /// - Parameters:
    ///   - urlString: The URL string to download from
    ///   - headers: Optional headers for the request
    /// - Returns: A result containing either the downloaded data or an error
    public func downloadData(
        from urlString: String,
        headers: [String: String]?
    ) async -> OperationResultDTO<[UInt8]> {
        guard let url = URL(string: urlString) else {
            return .failure(SecurityErrorDTO(
                code: NetworkError.invalidURL.rawValue,
                domain: "Network",
                message: "Invalid URL: \(urlString)"
            ))
        }

        var request = URLRequest(url: url)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.invalidResponse.rawValue,
                    domain: "Network",
                    message: "Response was not a valid HTTP response"
                ))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.from(statusCode: httpResponse.statusCode).rawValue,
                    domain: "Network",
                    message: "HTTP error: \(httpResponse.statusCode)"
                ))
            }
            
            return .success([UInt8](data))
        } catch {
            if let urlError = error as? URLError {
                return .failure(convertURLError(urlError, requestID: UUID().uuidString))
            } else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.unknown.rawValue,
                    domain: "Network",
                    message: "Unknown error: \(error.localizedDescription)"
                ))
            }
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
        headers: [String: String]?,
        progressHandler: @escaping (Double) -> Void
    ) async -> OperationResultDTO<[UInt8]> {
        guard let url = URL(string: urlString) else {
            return .failure(SecurityErrorDTO(
                code: NetworkError.invalidURL.rawValue,
                domain: "Network",
                message: "Invalid URL: \(urlString)"
            ))
        }

        var request = URLRequest(url: url)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let delegate = ProgressTrackingDelegate(progressHandler: progressHandler)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.invalidResponse.rawValue,
                    domain: "Network",
                    message: "Response was not a valid HTTP response"
                ))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.from(statusCode: httpResponse.statusCode).rawValue,
                    domain: "Network",
                    message: "HTTP error: \(httpResponse.statusCode)"
                ))
            }
            
            return .success([UInt8](data))
        } catch {
            if let urlError = error as? URLError {
                return .failure(convertURLError(urlError, requestID: UUID().uuidString))
            } else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.unknown.rawValue,
                    domain: "Network",
                    message: "Unknown error: \(error.localizedDescription)"
                ))
            }
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
        method: NetworkRequestDTO.HTTPMethod,
        headers: [String: String]?
    ) async -> OperationResultDTO<NetworkResponseDTO> {
        guard let url = URL(string: urlString) else {
            return .failure(SecurityErrorDTO(
                code: NetworkError.invalidURL.rawValue,
                domain: "Network",
                message: "Invalid URL: \(urlString)"
            ))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = Data(data)

        do {
            let startTime = Date()
            let (responseData, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.invalidResponse.rawValue,
                    domain: "Network",
                    message: "Response was not a valid HTTP response"
                ))
            }
            
            let requestID = UUID().uuidString
            var metadata: [String: String] = [
                "request_id": requestID,
                "duration_ms": String(format: "%.2f", duration * 1000),
                "status_code": String(httpResponse.statusCode)
            ]
            
            // Add response headers to metadata
            for (key, value) in httpResponse.allHeaderFields {
                if let headerKey = key as? String, let headerValue = value as? String {
                    metadata["header_\(headerKey.lowercased())"] = headerValue
                }
            }
            
            // Extract status message from the HTTP response
            let statusMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            
            // Convert headers to string dictionary
            var headerFields = [String: String]()
            for (key, value) in httpResponse.allHeaderFields {
                if let keyString = key as? String, let valueString = value as? String {
                    headerFields[keyString] = valueString
                }
            }
            
            return .success(NetworkResponseDTO(
                requestID: requestID,
                statusCode: httpResponse.statusCode,
                statusMessage: statusMessage,
                headers: headerFields,
                bodyData: [UInt8](responseData),
                mimeType: httpResponse.mimeType,
                textEncodingName: httpResponse.textEncodingName,
                isFromCache: false,
                duration: duration,
                timestamp: UInt64(Date().timeIntervalSince1970),
                metadata: metadata
            ))
        } catch {
            if let urlError = error as? URLError {
                return .failure(convertURLError(urlError, requestID: UUID().uuidString))
            } else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.unknown.rawValue,
                    domain: "Network",
                    message: "Unknown error: \(error.localizedDescription)"
                ))
            }
        }
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
        method: NetworkRequestDTO.HTTPMethod,
        headers: [String: String]?,
        progressHandler: @escaping (Double) -> Void
    ) async -> OperationResultDTO<NetworkResponseDTO> {
        guard let url = URL(string: urlString) else {
            return .failure(SecurityErrorDTO(
                code: NetworkError.invalidURL.rawValue,
                domain: "Network",
                message: "Invalid URL: \(urlString)"
            ))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let delegate = ProgressTrackingDelegate(progressHandler: progressHandler)
        let uploadSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        do {
            let startTime = Date()
            let (responseData, response) = try await uploadSession.upload(for: request, from: Data(data))
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.invalidResponse.rawValue,
                    domain: "Network",
                    message: "Response was not a valid HTTP response"
                ))
            }
            
            let requestID = UUID().uuidString
            var metadata: [String: String] = [
                "request_id": requestID,
                "duration_ms": String(format: "%.2f", duration * 1000),
                "status_code": String(httpResponse.statusCode)
            ]
            
            // Add response headers to metadata
            for (key, value) in httpResponse.allHeaderFields {
                if let headerKey = key as? String, let headerValue = value as? String {
                    metadata["header_\(headerKey.lowercased())"] = headerValue
                }
            }
            
            // Extract status message from the HTTP response
            let statusMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            
            // Convert headers to string dictionary
            var headerFields = [String: String]()
            for (key, value) in httpResponse.allHeaderFields {
                if let keyString = key as? String, let valueString = value as? String {
                    headerFields[keyString] = valueString
                }
            }
            
            return .success(NetworkResponseDTO(
                requestID: requestID,
                statusCode: httpResponse.statusCode,
                statusMessage: statusMessage,
                headers: headerFields,
                bodyData: [UInt8](responseData),
                mimeType: httpResponse.mimeType,
                textEncodingName: httpResponse.textEncodingName,
                isFromCache: false,
                duration: duration,
                timestamp: UInt64(Date().timeIntervalSince1970),
                metadata: metadata
            ))
        } catch {
            if let urlError = error as? URLError {
                return .failure(convertURLError(urlError, requestID: UUID().uuidString))
            } else {
                return .failure(SecurityErrorDTO(
                    code: NetworkError.unknown.rawValue,
                    domain: "Network",
                    message: "Unknown error: \(error.localizedDescription)"
                ))
            }
        }
    }

    /// Checks if a URL is reachable
    /// - Parameter urlString: The URL string to check
    /// - Returns: A result containing either a boolean indicating reachability or an error
    public func isReachable(urlString: String) async -> OperationResultDTO<Bool> {
        guard let url = URL(string: urlString) else {
            return .failure(SecurityErrorDTO(
                code: NetworkError.invalidURL.rawValue,
                domain: "Network",
                message: "Invalid URL: \(urlString)"
            ))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .success(false)
            }
            
            return .success((200...399).contains(httpResponse.statusCode))
        } catch {
            return .success(false)
        }
    }
    
    // MARK: - Factory Methods
    
    /// Creates a configured instance with default settings
    /// - Returns: A network service instance with default configuration
    public static func createDefault() -> NetworkServiceImpl {
        NetworkServiceImpl()
    }
    
    /// Creates a configured instance with custom timeout and policies
    /// - Parameters:
    ///   - timeout: Timeout interval for requests in seconds
    ///   - cachePolicy: Cache policy to use for requests
    ///   - allowsCellularAccess: Whether to allow cellular network access
    /// - Returns: A network service instance with custom configuration
    public static func createWithConfiguration(
        timeout: Double = 60.0,
        cachePolicy: Int = 0, // 0 corresponds to URLRequest.CachePolicy.useProtocolCachePolicy
        allowsCellularAccess: Bool = true
    ) -> NetworkServiceImpl {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.requestCachePolicy = URLRequest.CachePolicy(rawValue: UInt(cachePolicy)) ?? .useProtocolCachePolicy
        config.allowsCellularAccess = allowsCellularAccess

        let session = URLSession(configuration: config)
        return NetworkServiceImpl(session: session)
    }
    
    /// Creates a configured instance with authentication
    /// - Parameters:
    ///   - authType: The type of authentication to use
    ///   - timeout: Timeout interval for requests in seconds
    /// - Returns: A network service instance with authentication configured
    public static func createWithAuthentication(
        authType: NetworkRequestDTO.AuthType,
        timeout: Double = 60.0
    ) -> NetworkServiceImpl {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2

        // Configure auth headers
        var defaultHeaders = [String: String]()

        switch authType {
            case let .bearer(token):
                defaultHeaders["Authorization"] = "Bearer \(token)"
            case let .basic(username, password):
                if let authData = "\(username):\(password)".data(using: .utf8) {
                    let base64Auth = authData.base64EncodedString()
                    defaultHeaders["Authorization"] = "Basic \(base64Auth)"
                }
            case let .apiKey(key, paramName, inHeader):
                if inHeader {
                    defaultHeaders[paramName] = key
                }
            // For URL param API keys, these will need to be added on the request level
            case let .custom(headers):
                defaultHeaders = headers
            case .none:
                break
        }

        if !defaultHeaders.isEmpty {
            config.httpAdditionalHeaders = defaultHeaders
        }

        let session = URLSession(configuration: config)
        return NetworkServiceImpl(session: session)
    }
    
    // MARK: - Private Helpers
    
    private func convertURLError(_ error: URLError, requestID: String) -> SecurityErrorDTO {
        let code: Int32
        let domain: String = "Network"
        let message: String

        switch error.code {
        case .badURL, .unsupportedURL:
            code = NetworkError.invalidURL.rawValue
            message = "Invalid URL: \(error.localizedDescription)"
        case .timedOut:
            code = NetworkError.timeout.rawValue
            message = "Request timed out"
        case .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
             .notConnectedToInternet, .internationalRoamingOff, .callIsActive,
             .dataNotAllowed:
            code = NetworkError.connectionFailed.rawValue
            message = "Connection failed: \(error.localizedDescription)"
        case .serverCertificateUntrusted, .clientCertificateRejected,
             .clientCertificateRequired:
            code = NetworkError.authenticationFailed.rawValue
            message = "Security error: \(error.localizedDescription)"
        default:
            code = NetworkError.unknown.rawValue
            message = "Unknown error: \(error.localizedDescription)"
        }

        return SecurityErrorDTO(
            code: code,
            domain: domain,
            message: message
        )
    }
}

/// A delegate for tracking progress of URLSession tasks
private class ProgressTrackingDelegate: NSObject, URLSessionTaskDelegate {
    private let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
        super.init()
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        if totalBytesExpectedToSend > 0 {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            progressHandler(progress)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progressHandler(progress)
        }
    }
}
