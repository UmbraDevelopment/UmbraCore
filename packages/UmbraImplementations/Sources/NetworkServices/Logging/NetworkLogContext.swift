import Foundation
import LoggingInterfaces
import LoggingTypes
import NetworkInterfaces

/**
 # Network Log Context

 Provides structured logging context for network operations with privacy controls.
 This context implements the LogContextDTO protocol to ensure proper handling of
 privacy-sensitive information in network operations.

 ## Privacy Considerations

 - URLs may contain sensitive information in paths or query parameters and are treated as private data
 - Headers may contain authentication tokens and are treated as sensitive
 - Request and response bodies may contain sensitive data and are handled accordingly
 - HTTP methods, status codes, and timing information are considered public
 */
public struct NetworkLogContext: LogContextDTO {
  /// The domain name for this context
  public let domainName: String="Network"

  /// The operation being performed
  public let operation: String

  /// The source of the log entry
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The metadata collection with privacy annotations
  public let metadata: LogMetadataDTOCollection

  /**
   Initialises a new NetworkLogContext.

   - Parameters:
      - operation: The network operation being performed
      - source: The source component (defaults to "NetworkService")
      - correlationID: Optional correlation ID for tracing related events
      - metadata: Privacy-aware metadata collection
   */
  public init(
    operation: String,
    source: String?="NetworkService",
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  /**
   Adds a URL to the context with appropriate privacy controls.

   - Parameter url: The URL to add
   - Returns: A new context with the URL added
   */
  public func withURL(_ url: URL) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPrivate(key: "url", value: url.absoluteString)
    )
  }

  /**
   Adds HTTP method information to the context.

   - Parameter method: The HTTP method
   - Returns: A new context with the HTTP method added
   */
  public func withMethod(_ method: String) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPublic(key: "method", value: method)
    )
  }

  /**
   Adds HTTP status code information to the context.

   - Parameter statusCode: The HTTP status code
   - Returns: A new context with the status code added
   */
  public func withStatusCode(_ statusCode: Int) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPublic(key: "statusCode", value: "\(statusCode)")
    )
  }

  /**
   Adds request ID information to the context.

   - Parameter requestId: The request ID
   - Returns: A new context with the request ID added
   */
  public func withRequestID(_ requestID: String) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPublic(key: "requestId", value: requestID)
    )
  }

  /**
   Adds timing information to the context.

   - Parameter durationMs: The request duration in milliseconds
   - Returns: A new context with the timing information added
   */
  public func withDuration(_ durationMs: Double) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPublic(key: "durationMs", value: String(format: "%.2f", durationMs))
    )
  }

  /**
   Adds size information to the context.

   - Parameters:
      - requestSize: The request size in bytes
      - responseSize: The response size in bytes
   - Returns: A new context with the size information added
   */
  public func withSizes(requestSize: Int64, responseSize: Int64) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata
        .withPublic(key: "requestSizeBytes", value: "\(requestSize)")
        .withPublic(key: "responseSizeBytes", value: "\(responseSize)")
    )
  }

  /**
   Adds an error to the context with appropriate privacy controls.

   - Parameter error: The error to add
   - Returns: A new context with the error added
   */
  public func withError(_ error: Error) -> NetworkLogContext {
    NetworkLogContext(
      operation: operation,
      source: source,
      correlationID: correlationID,
      metadata: metadata
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
    )
  }

  /**
   Adds headers to the context with appropriate privacy controls.

   - Parameter headers: The headers to add
   - Returns: A new context with the headers added
   */
  public func withHeaders(_ headers: [String: String]) -> NetworkLogContext {
    var context=self

    // Add public headers
    let publicHeaders=headers.filter { key, _ in
      let lowercaseKey=key.lowercased()
      return lowercaseKey == "content-type" ||
        lowercaseKey == "content-length" ||
        lowercaseKey == "accept" ||
        lowercaseKey == "user-agent"
    }

    if !publicHeaders.isEmpty {
      context=NetworkLogContext(
        operation: operation,
        source: source,
        correlationID: correlationID,
        metadata: context.metadata.withPublic(key: "headers", value: publicHeaders.description)
      )
    }

    // Add sensitive headers (redacted)
    let sensitiveHeadersCount=headers.count - publicHeaders.count
    if sensitiveHeadersCount > 0 {
      context=NetworkLogContext(
        operation: operation,
        source: source,
        correlationID: correlationID,
        metadata: context.metadata.withSensitive(
          key: "sensitiveHeadersCount",
          value: "\(sensitiveHeadersCount)"
        )
      )
    }

    return context
  }

  /**
   Gets the source of this log context.

   - Returns: The source identifier for logging
   */
  public func getSource() -> String {
    if let source {
      return source
    }
    return "\(domainName).\(operation)"
  }

  /**
   Creates a metadata collection from this context.

   - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadata

    // Add standard fields with appropriate privacy levels
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "domain", value: domainName)

    if let correlationID {
      collection=collection.withPublic(key: "correlationId", value: correlationID)
    }

    return collection
  }
}
