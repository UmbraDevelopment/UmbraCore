import CoreDTOs
import Foundation

/// Protocol defining the requirements for a network request.
/// This protocol is foundation-independent and provides a clean interface for making network
/// requests.
public protocol NetworkRequestProtocol: Sendable {
  /// The URL string for the request
  var urlString: String { get }

  /// HTTP method to use for the request
  var method: HTTPMethod { get }

  /// Headers to include with the request
  var headers: [String: String] { get }

  /// Query parameters to include in the request URL
  var queryParameters: [String: String] { get }

  /// Body data to include with the request (for POST, PUT, etc.)
  var body: RequestBody? { get }

  /// Cache policy for the request
  var cachePolicy: CachePolicy { get }

  /// Timeout interval in seconds
  var timeoutInterval: Double { get }
}

/// Default implementation of NetworkRequestProtocol
extension NetworkRequestProtocol {
  public var method: HTTPMethod { .get }
  public var headers: [String: String] { [:] }
  public var queryParameters: [String: String] { [:] }
  public var body: RequestBody? { nil }
  public var cachePolicy: CachePolicy { .useProtocolCachePolicy }
  public var timeoutInterval: Double { 60.0 }
}

/// HTTP methods supported by the NetworkService
public enum HTTPMethod: String, Sendable {
  case get="GET"
  case post="POST"
  case put="PUT"
  case delete="DELETE"
  case patch="PATCH"
  case head="HEAD"
  case options="OPTIONS"
}

/// Cache policies for network requests
public enum CachePolicy: Sendable {
  /// Use the caching logic specified in the protocol implementation
  case useProtocolCachePolicy

  /// Ignore local cache data and always fetch from the origin server
  case reloadIgnoringLocalCache

  /// Return cache data if valid, else fetch from origin server
  case returnCacheDataElseLoad

  /// Return cache data even if expired (don't refresh from network)
  case returnCacheDataDontLoad
}

/// Type representing the body of a network request
public enum RequestBody: Sendable {
  /// JSON data (encoded from a Swift object)
  case json(encodable: any Encodable & Sendable)

  /// Raw data
  case data(bytes: [UInt8])

  /// Form URL encoded parameters
  case form(parameters: [String: String])

  /// Multipart form data
  case multipart(boundary: String, parts: [MultipartFormData])

  /// No body content
  case empty
}

/// Represents a part in a multipart form data request
public struct MultipartFormData: Sendable {
  /// Name of the form field
  public let name: String

  /// Filename (optional, for file uploads)
  public let filename: String?

  /// MIME type of the content
  public let contentType: String

  /// The data for this part
  public let data: [UInt8]

  /// Create a new multipart form part
  /// - Parameters:
  ///   - name: Name of the form field
  ///   - filename: Optional filename for file uploads
  ///   - contentType: MIME type of the content
  ///   - data: The data for this part
  public init(name: String, filename: String?=nil, contentType: String, data: [UInt8]) {
    self.name=name
    self.filename=filename
    self.contentType=contentType
    self.data=data
  }
}
