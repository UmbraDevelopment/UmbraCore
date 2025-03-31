import Foundation

/// Data transfer object representing a response from a network request.
/// This type is foundation-independent and provides a consistent format for network responses.
public struct NetworkResponseDTO: Sendable {
  /// Status code returned by the server
  public let statusCode: Int

  /// Headers returned by the server
  public let headers: [String: String]

  /// Raw binary data returned in the response body
  public let data: [UInt8]

  /// Indicates whether the request completed successfully
  public let isSuccess: Bool

  /// Any error that occurred during the request
  public let error: NetworkError?

  /// Create a new NetworkResponseDTO for a successful response
  /// - Parameters:
  ///   - statusCode: Status code returned by the server
  ///   - headers: Headers returned by the server
  ///   - data: Raw binary data returned in the response body
  /// - Returns: A NetworkResponseDTO representing a successful response
  public static func success(
    statusCode: Int,
    headers: [String: String],
    data: [UInt8]
  ) -> NetworkResponseDTO {
    NetworkResponseDTO(
      statusCode: statusCode,
      headers: headers,
      data: data,
      isSuccess: true,
      error: nil
    )
  }

  /// Create a new NetworkResponseDTO for a failed response
  /// - Parameters:
  ///   - statusCode: Status code returned by the server (0 if no response)
  ///   - headers: Headers returned by the server (empty if no response)
  ///   - data: Raw binary data returned in the response body (empty if no response)
  ///   - error: The error that caused the failure
  /// - Returns: A NetworkResponseDTO representing a failed response
  public static func failure(
    statusCode: Int=0,
    headers: [String: String]=[:],
    data: [UInt8]=[],
    error: NetworkError
  ) -> NetworkResponseDTO {
    NetworkResponseDTO(
      statusCode: statusCode,
      headers: headers,
      data: data,
      isSuccess: false,
      error: error
    )
  }

  /// Initialiser for NetworkResponseDTO
  /// - Parameters:
  ///   - statusCode: Status code returned by the server
  ///   - headers: Headers returned by the server
  ///   - data: Raw binary data returned in the response body
  ///   - isSuccess: Indicates whether the request completed successfully
  ///   - error: Any error that occurred during the request
  public init(
    statusCode: Int,
    headers: [String: String],
    data: [UInt8],
    isSuccess: Bool,
    error: NetworkError?
  ) {
    self.statusCode=statusCode
    self.headers=headers
    self.data=data
    self.isSuccess=isSuccess
    self.error=error
  }
}

/// Extension to provide convenience methods for working with response data
extension NetworkResponseDTO {
  /// Attempt to decode the response data to a specific type
  /// - Parameters:
  ///   - type: The type to decode to
  ///   - decoder: Optional JSON decoder to use (uses a default decoder if not provided)
  /// - Returns: The decoded object or nil if decoding failed
  /// - Throws: NetworkError.decodingFailed if the data cannot be decoded
  public func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder?=nil) throws -> T {
    guard isSuccess else {
      if let error {
        throw error
      }
      throw NetworkError.unknown(message: "Request failed without specific error")
    }

    guard !data.isEmpty else {
      throw NetworkError.noData
    }

    do {
      let decoder=decoder ?? JSONDecoder()
      // We need to convert our [UInt8] to Data for decoding
      return try decoder.decode(type, from: Data(data))
    } catch {
      throw NetworkError.decodingFailed(reason: error.localizedDescription)
    }
  }

  /// Get the response data as a UTF-8 string
  /// - Returns: UTF-8 string representation of the data, or nil if the data is not valid UTF-8
  public var stringValue: String? {
    guard !data.isEmpty else { return nil }
    return String(bytes: data, encoding: .utf8)
  }
}
