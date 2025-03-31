import CoreDTOs
import DomainSecurityTypes
import UmbraErrors

/**
 # XPC Service Protocol

 Defines the core interface for XPC services in the Umbra system.
 This protocol provides a standardised way for processes to communicate
 securely across process boundaries following actor isolation principles.

 ## Thread Safety

 All implementations must ensure thread safety through proper actor isolation
 and structured concurrency patterns.
 */
public protocol XPCServiceProtocol: Sendable {
  /**
   Starts the XPC service.

   This method initialises the underlying XPC connection and prepares
   the service for receiving messages. It must be called before any
   other operations on the service.

   - Throws: XPCServiceError if the service cannot be started
   */
  func start() async throws

  /**
   Stops the XPC service.

   This method terminates the underlying XPC connection and cleans up
   any resources. After calling this method, the service cannot be used
   until start() is called again.
   */
  func stop() async

  /**
   Sends a message to the XPC service and awaits a response.

   - Parameters:
      - message: The message to send, must be a value type conforming to Sendable
      - endpoint: Optional endpoint identifier for routing the message

   - Returns: The response data
   - Throws: XPCServiceError if the message cannot be sent or processed
   */
  func sendMessage<T: Sendable, R: Sendable>(
    _ message: T,
    to endpoint: XPCEndpointIdentifier?
  ) async throws -> R

  /**
   Registers a message handler for processing incoming messages.

   - Parameters:
      - endpoint: The endpoint identifier to register the handler for
      - handler: The async function to handle messages sent to this endpoint

   - Throws: XPCServiceError if the handler cannot be registered
   */
  func registerHandler<T: Sendable, R: Sendable>(
    for endpoint: XPCEndpointIdentifier,
    handler: @Sendable @escaping (T) async throws -> R
  ) async throws

  /**
   Checks if the service is currently running.

   - Returns: True if the service is running, false otherwise
   */
  func isRunning() async -> Bool

  /**
   Gets the service's listener endpoint for clients to connect to.

   - Returns: The endpoint identifier or nil if the service is not running
   */
  func getListenerEndpoint() async -> XPCEndpointIdentifier?
}

/**
 Unique identifier for an XPC service endpoint.
 This type provides a type-safe way to reference XPC endpoints.
 */
public struct XPCEndpointIdentifier: Hashable, Sendable {
  /// The raw endpoint name
  public let name: String

  /**
   Initialises a new XPC endpoint identifier.

   - Parameter name: The endpoint name
   */
  public init(name: String) {
    self.name=name
  }
}
